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
in particle_fv_lerp_data o_lerp_data;

out vec4 fragColor;

void main() {
    #ifdef PARTICLE_DEBUG
    if (o_data.dbg_error) {
        vec2 vert_uv = o_lerp_data.dbg_vertex_uv;

        if ((vert_uv.x < 0.5f) != (vert_uv.y < 0.5f)) {
            fragColor = vec4(0f, 0f, 0f, 1f);
        } else {
            fragColor = vec4(1f, o_data.dbg_error_code, 1f);
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
