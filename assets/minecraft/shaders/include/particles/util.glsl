#ifndef PARTICLE_UTIL_H
#define PARTICLE_UTIL_H

#define M_PI 3.1415926535897932384626433832795

#define PARTICLE_FLAG_HAS_FORCED_ROT_X 0x0001u
#define PARTICLE_FLAG_HAS_FORCED_ROT_Y 0x0002u
#define PARTICLE_FLAG_HAS_X_SIZE 0x0004u
#define PARTICLE_FLAG_HAS_Y_SIZE 0x0008u
#define PARTICLE_FLAG_IGNORE_LIGHTING 0x0010u

vec4 quat_xy(float x, float y) {
	float sx = sin(x * 0.5f);
	float cx = cos(x * 0.5f);
	float sy = sin(y * 0.5f);
	float cy = cos(y * 0.5f);

	return vec4(cy * sx, sy * cx, -sy * sx, cy * cx);
}

vec3 quat_rotate(vec3 v, vec4 q) {
    float xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z, ww = q.w * q.w;
    float xy = q.x * q.y, xz = q.x * q.z, yz = q.y * q.z, xw = q.x * q.w;
    float zw = q.z * q.w, yw = q.y * q.w, k = 1 / (xx + yy + zz + ww);

    return vec3(
    	((xx - yy - zz + ww) * k * v.x) + (2 * (xy - zw) * k * v.y) + ((2 * (xz + yw) * k) * v.z),
    	(2 * (xy + zw) * k * v.x) + ((yy - xx - zz + ww) * k * v.y) + ((2 * (yz - xw) * k) * v.z),
    	(2 * (xz - yw) * k * v.x) + (2 * (yz + xw) * k * v.y) + (((zz - xx - yy + ww) * k) * v.z)
    );
}

ivec4 data_tex_read_raw(sampler2D samp, ivec2 base, int index) {
	ivec2 offset = ivec2(index % PARTICLE_TEX_WIDTH, index / PARTICLE_TEX_WIDTH);
	ivec2 pixel_pos = base + offset;

	return ivec4(texelFetch(samp, pixel_pos, 0) * 255f);
}

uint data_tex_read_uint(sampler2D samp, ivec2 base, int index) {
	ivec4 raw = data_tex_read_raw(samp, base, index);
	return uint((raw.r << 24) | (raw.g << 16) | (raw.b << 8) | raw.a);
}

float data_tex_read_float(sampler2D samp, ivec2 base, int index) {
	uint raw = data_tex_read_uint(samp, base, index);
	return uintBitsToFloat(raw);
}

bool data_tex_read_bool(sampler2D samp, ivec2 base, int index) {
	ivec4 raw = data_tex_read_raw(samp, base, index);
	return raw.r != 0;
}

uvec2 data_tex_read_uvec2(sampler2D samp, ivec2 base, int index) {
	ivec4 raw = data_tex_read_raw(samp, base, index);
	return uvec2(
		uint((raw.r << 8) | raw.g),
		uint((raw.b << 8) | raw.a)
	);
}

ivec2 data_tex_read_ivec2(sampler2D samp, ivec2 base, int index) {
	ivec4 raw = data_tex_read_raw(samp, base, index);
	return ivec2(
		(raw.r << 8) | raw.g,
		(raw.b << 8) | raw.a
	);
}

#endif