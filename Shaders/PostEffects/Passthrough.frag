#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/PushConstants.glsl"
#include "../Base/TextureArrays.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

void main()
{
    outColor = textureLod(texture2DSampler[PostEffectTextureID0], texCoords, 0);
}