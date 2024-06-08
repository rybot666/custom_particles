# Custom Particles
An implementation of custom particles using `block_marker` particles.

## Usage
Replace the `particle` texture of a block model with a custom particle texture - to generate such a texture, take a look at the `scripts/create_particle.py` script. An example testing texture and model is shown in the assets folder. Feel free to remove it if incorporating this into your own pack. You may also wish to take a look at `assets/minecraft/shaders/include/particles/config.glsl`.

## TODO
- Detect walking on terrain/breaking blocks and use a different texture for them
  - This would make using this pack in survival scenarios more practical
  - Should be easy, just check the quad size
- Possibly add position-based particles (for example, in scenarios where a particle is expected to be used in only one location and using an entire block state isn't helpful)
- Possibly consider a version of this pack based on wolf variants instead (using team invisibility)