#version 460
#extension GL_ARB_bindless_texture : enable

#include "../Base/Materials.glsl"

layout(location = 0) out vec4 outcolor;

layout(location = 0) in vec4 vertexcolor;
layout(location = 1) in vec4 texcoords;
layout(location = 2) in flat uint materialID;

void main()
{
    vec4 basecolor = vertexcolor;

    if (materialID != 0)
    {
        Material mtl = materials[materialID];
        if (mtl.textureHandle[0] != uvec2(0))
        {
            basecolor *= texture(sampler2D(mtl.textureHandle[0]), texCoords.xy);
        }
    }

    if (basecolor.a < 0.5f) discard;

    outcolor = basecolor;
}