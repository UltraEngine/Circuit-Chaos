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
layout(location = 1) uniform int BlurRadius = 16;

vec4 ctexelFetch(in sampler2DMS tex, in ivec2 coord, in int samp)
{
    ivec2 sz = textureSize(tex);
    coord.x = clamp(coord.x, 0, sz.x - 1);
    coord.y = clamp(coord.y, 0, sz.y - 1);
    return texelFetch(tex, coord, samp);
}

void main()
{
    const int m = textureSize(ColorBuffer).x / DrawViewport.z;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y) * m;

    coord.x -= BlurRadius;
    for (int n = -BlurRadius * 2; n < BlurRadius * 2; ++n)
    {
        outColor += ctexelFetch(ColorBuffer, coord + ivec2(n, 0), 0);
    }

    outColor /= float(BlurRadius * 2 * 2 + 1);
}