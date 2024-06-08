#ifndef PARTICLE_CONFIG_H
#define PARTICLE_CONFIG_H

// The colour value to indicate a custom particle texture.
#define PARTICLE_TEX_MAGIC 103u

// If defined, enables extra debug features which may impact performance.
#define PARTICLE_DEBUG 0

// These values must match the sizes of all custom particle textures. They do 
// not necessarily match the size of the displayed particle. It is usually wise
// to add 1 to the height, as the top row is reserved to store particle metadata.
#define PARTICLE_TEX_WIDTH 64
#define PARTICLE_TEX_HEIGHT 64 + 1

#endif