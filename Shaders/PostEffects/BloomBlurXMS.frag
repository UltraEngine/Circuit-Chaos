#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#define UNIFORMSTARTINDEX 8

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2DMS ColorBuffer;

vec4 ctexelFetch(in sampler2DMS tex, in ivec2 coord, in int samp)
{
    ivec2 sz = textureSize(tex);
    coord.x = clamp(coord.x, 0, sz.x - 1);
    coord.y = clamp(coord.y, 0, sz.y - 1);
    return texelFetch(tex, coord, samp);
}

void main()
{
    const int m = 8;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y) * m;    
    outColor += ctexelFetch(ColorBuffer, coord, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-1, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(1, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-2, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(2, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-3, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(3, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-4, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(4, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-5, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(5, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-6, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(6, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(-7, 0)*m, 0);
    outColor += ctexelFetch(ColorBuffer, coord + ivec2(7, 0)*m, 0);
    outColor /= 15.0f;
}