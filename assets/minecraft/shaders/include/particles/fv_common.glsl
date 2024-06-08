#ifndef CUSTOM_PARTICLE_FV_COMMON_H
#define CUSTOM_PARTICLE_FV_COMMON_H

#if PARTICLE_DEBUG
#define PARTICLE_FV_DATA_EMPTY particle_fv_data( \
	false, \
	vec2(0.0), \
	false \
)
#else
#define PARTICLE_FV_DATA_EMPTY particle_fv_data( \
	false \
)
#endif

struct particle_fv_data {
#if PARTICLE_DEBUG
	// true if this particle has a marker pixel, but no matching particle ID is defined
	bool dbg_error;
	vec2 dbg_error_code;
#endif

	// true if this particle has a marker pixel indicating that it's a custom particle
	bool custom;
};

#endif