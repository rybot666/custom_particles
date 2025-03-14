#version 330

#moj_import <fog.glsl>
#moj_import <particles/config.glsl>
#moj_import <particles/fv_common.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;
flat in particle_fv_data o_data;

#if PARTICLE_DEBUG
in vec2 dbg_vertex_uv;
#endif

out vec4 fragColor;

void main() {
#if PARTICLE_DEBUG
    if (o_data.dbg_error == 1) {
        vec2 vert_uv = dbg_vertex_uv;

        if ((vert_uv.x < 0.5) != (vert_uv.y < 0.5)) {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        } else {
            fragColor = vec4(1.0, o_data.dbg_error_code, 1.0);
        }

        return;
    }
#endif

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
