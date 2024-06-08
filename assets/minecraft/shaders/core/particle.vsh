#version 330

#moj_import <fog.glsl>
#moj_import <particles/config.glsl>
#moj_import <particles/util.glsl>
#moj_import <particles/fv_common.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

out float vertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;
flat out particle_fv_data o_data;

#if PARTICLE_DEBUG
out vec2 dbg_vertex_uv;
#endif

const vec3[] VERTEX_OFFSETS = vec3[](
    vec3(-1.0, -1.0, 0.0),
    vec3(-1.0, 1.0, 0.0),
    vec3(1.0, 1.0, 0.0),
    vec3(1.0, -1.0, 0.0)
);

const ivec2[] MARKER_OFFSET = ivec2[](
    ivec2(PARTICLE_TEX_WIDTH, PARTICLE_TEX_HEIGHT),
    ivec2(PARTICLE_TEX_WIDTH, 0),
    ivec2(0, 0),
    ivec2(0, PARTICLE_TEX_HEIGHT)
);

const vec2[] VERTEX_UVS = vec2[](
    vec2(1.0, 1.0),
    vec2(1.0, 0.0),
    vec2(0.0, 0.0),
    vec2(0.0, 1.0)
);

#define write_out() { \
    gl_Position = ProjMat * ModelViewMat * vec4(o_pos, 1.0); \
    vertexDistance = fog_distance(o_pos, FogShape); \
    texCoord0 = o_uv0; \
    vertexColor = Color; \
    \
    if (!ignore_lighting) { \
        vertexColor *= texelFetch(Sampler2, o_uv2 / 16, 0); \
    } \
    return; \
}

#if PARTICLE_DEBUG
#define dbg_bail(c0, c1) { \
    o_data.dbg_error = 1; \
    o_data.dbg_error_code = vec2(c0, c1); \
    write_out(); \
}
#else
#define dbg_bail(c0, c1) {}
#endif

void main() {
    o_data = PARTICLE_FV_DATA_EMPTY;

    // Get the marker pixel.
    ivec2 marker_offset = MARKER_OFFSET[gl_VertexID % 4];
    ivec2 atlas_size = textureSize(Sampler0, 0);
    ivec2 uv_texel_pos = ivec2(UV0 * vec2(atlas_size));
    ivec2 top_left_pos = uv_texel_pos - marker_offset;
    uint flags = 0u;

    if (top_left_pos.x >= 0 && top_left_pos.y >= 0 && top_left_pos.x <= atlas_size.x && top_left_pos.y <= atlas_size.y) {
        uvec2 marker = data_tex_read_uvec2(Sampler0, top_left_pos, 0);

        if (marker.x == PARTICLE_TEX_MAGIC) {
            o_data.custom = 1;
            flags = marker.y;
        }
    }

    // If we didn't get a custom particle, defer to vanilla handling.
    vec3 o_pos = Position;
    vec2 o_uv0 = UV0;
    ivec2 o_uv2 = UV2;
    bool ignore_lighting = false;

    if (o_data.custom == 1) {
        // Get particle metadata.
        float forced_rot_x = 0;
        bool has_rotation_forcing_x = false;
        float forced_rot_y = 0;
        bool has_rotation_forcing_y = false;
        float custom_x_size = 1;
        bool has_custom_x_size = false;
        float custom_y_size = 1;
        bool has_custom_y_size = false;

        ivec2 texture_offset = data_tex_read_ivec2(Sampler0, top_left_pos, 1);
        uvec2 texture_size = data_tex_read_uvec2(Sampler0, top_left_pos, 2);

        if ((flags & PARTICLE_FLAG_HAS_FORCED_ROT_X) != 0u) {
            forced_rot_x = data_tex_read_float(Sampler0, top_left_pos, 3);
            has_rotation_forcing_x = true;
        }

        if ((flags & PARTICLE_FLAG_HAS_FORCED_ROT_Y) != 0u) {
            forced_rot_y = data_tex_read_float(Sampler0, top_left_pos, 4);
            has_rotation_forcing_y = true;
        }

        if ((flags & PARTICLE_FLAG_HAS_X_SIZE) != 0u) {
            custom_x_size = data_tex_read_float(Sampler0, top_left_pos, 5);
            has_custom_x_size = true;
        }

        if ((flags & PARTICLE_FLAG_HAS_Y_SIZE) != 0u) {
            custom_y_size = data_tex_read_float(Sampler0, top_left_pos, 6);
            has_custom_y_size = true;
        }

        if ((flags & PARTICLE_FLAG_IGNORE_LIGHTING) != 0u) {
            ignore_lighting = true;
        }

        // If rotation forcing is enabled, we need to get camera rotation.
        vec2 camera_rot = vec2(0.0);
        vec3 camera_delta = vec3(0.0);

#if PARTICLE_DEBUG
        dbg_vertex_uv = VERTEX_UVS[gl_VertexID % 4];
#endif

        if (has_custom_x_size || has_custom_y_size || has_rotation_forcing_x || has_rotation_forcing_y) {
            // Extract player camera rotation from ModelViewMat.
            float sin_x = ModelViewMat[1][2];
            float cos_x = ModelViewMat[1][1];
            camera_rot.x = atan(sin_x, cos_x);

            float sin_y = ModelViewMat[2][0];
            float cos_y = ModelViewMat[0][0];
            camera_rot.y = atan(-sin_y, -cos_y);

            // Reverse the calculation the game does for block marker particle rendering to get the position delta 
            // (in world space) between the center of our quad and the player camera.
            vec3 vertex_offset = VERTEX_OFFSETS[gl_VertexID % 4];
            vec3 expected_pos = quat_rotate(vertex_offset, quat_xy(camera_rot.x, -camera_rot.y)) * 0.5;
            camera_delta = Position - expected_pos;

            float new_x_rot = has_rotation_forcing_x ? forced_rot_x : camera_rot.x;
            float new_y_rot = has_rotation_forcing_y ? forced_rot_y : camera_rot.y;

            // Adjust vertex positions based on custom sizes.
            vertex_offset.x *= custom_x_size;
            vertex_offset.y *= custom_y_size;

            o_pos = quat_rotate(vertex_offset, quat_xy(-new_x_rot, new_y_rot)) * 0.5 + camera_delta;
        }

        // Generate new UVs.
        o_uv0 = (top_left_pos + texture_offset + VERTEX_UVS[gl_VertexID % 4] * texture_size) / atlas_size;
    }

    write_out();
}