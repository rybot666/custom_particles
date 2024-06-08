import struct
import os
import argparse
import math
from PIL import Image

# 0 - marker (R, G) and flags (B, A)
#   0x0001 - forced rotation (x)
#   0x0002 - forced rotation (y)
#   0x0004 - forced size (x)
#   0x0008 - forced size (y)
#   0x0010 - ignore lighting
#
# 1 - particle texture offset (ivec2)
# 2 - particle texture size (uvec2)
# 3 - forced rotation, x (float)
# 4 - forced rotation, y (float)
# 5 - forced size, x (float)
# 6 - forced size, y (float)

FLAG_HAS_FORCED_ROT_X = 0x0001
FLAG_HAS_FORCED_ROT_Y = 0x0002
FLAG_HAS_X_SIZE = 0x0004
FLAG_HAS_Y_SIZE = 0x0008
FLAG_IGNORE_LIGHTING = 0x0010

def unpack_rgba(b):
    return struct.unpack('>BBBB', b)

def generate_output(
    img_in: Image, rotation_x: float | None, rotation_y: float | None, 
    magic: int, output_tex_width: int, output_tex_height: int, 
    x_size: float | None, y_size: float | None, ignore_lighting: bool
) -> Image:
    img_out = Image.new('RGBA', (output_tex_width, output_tex_height))

    if img_in.size[0] > img_out.size[0] or img_in.size[1] > img_out.size[1] - 1:
        raise ValueError('Input image is too large - increase the output texture size')

    # Write out flags and magic.
    flags = 0

    if rotation_x is not None:
        flags |= FLAG_HAS_FORCED_ROT_X

    if rotation_y is not None:
        flags |= FLAG_HAS_FORCED_ROT_Y

    if x_size is not None and x_size != 1:
        flags |= FLAG_HAS_X_SIZE

    if y_size is not None and x_size != 1:
        flags |= FLAG_HAS_Y_SIZE

    if ignore_lighting:
        flags |= FLAG_IGNORE_LIGHTING

    img_out.putpixel((0, 0), unpack_rgba(struct.pack('>HH', magic, flags)))

    # Write out texture offset (hardcoded 0, 1 atm).
    img_out.putpixel((1, 0), unpack_rgba(struct.pack('>hh', 0, 1)))

    # Write out texture size.
    img_out.putpixel((2, 0), unpack_rgba(struct.pack('>hh', img_in.size[0], img_in.size[1])))

    # Write out forced rotations.
    img_out.putpixel((3, 0), unpack_rgba(struct.pack('>f', 
        math.radians(rotation_x or 0))))
    img_out.putpixel((4, 0), unpack_rgba(struct.pack('>f', 
        math.radians(rotation_y or 0))))

    # Write out X/Y size.
    img_out.putpixel((5, 0), unpack_rgba(struct.pack('>f', x_size or 1)))
    img_out.putpixel((6, 0), unpack_rgba(struct.pack('>f', x_size or 1)))

    # Copy input image.
    img_out.paste(img_in, box=(0, 1))

    return img_out

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='create_particle',
        description='Generates textures for custom particle packs'
    )

    parser.add_argument('filename')
    parser.add_argument('--rotation-x', type=float, help='X rotation to force \
        - will billboard in X if not present')
    parser.add_argument('--rotation-y', type=float, help='Y rotation to force \
        - will billboard in Y if not present')
    parser.add_argument('--x-size', type=float, help='X size (in blocks)')
    parser.add_argument('--y-size', type=float, help='Y size (in blocks)')
    parser.add_argument('--ignore-lighting', action='store_true', help='If \
        set, the particle will ignore lighting and always display at full \
        brightness (including if inside a block)')
    parser.add_argument('--magic', type=int, help='Custom magic color \
        (PARTICLE_TEX_MAGIC in config)', default=103)
    parser.add_argument('--output-tex-width', type=int, help='Output texture \
        width (PARTICLE_TEX_WIDTH in config)', default=64)
    parser.add_argument('--output-tex-height', type=int, help='Output texture \
        height (PARTICLE_TEX_HEIGHT in config)', default=65)

    args = parser.parse_args()
    generation_params = dict(vars(args))
    del generation_params['filename']

    with Image.open(args.filename, 'r') as im:
        out_im = generate_output(im, **generation_params)

        (name, ext) = os.path.splitext(args.filename)
        out_im.save(name + '.out' + ext)
        out_im.close()