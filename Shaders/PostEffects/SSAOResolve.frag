#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"

float strength = 0.25f;

//Inputs
layout(location = 0) in vec2 texCoords;

layout(location = 0) out vec4 color;

void main(void)
{    
    color = texture(texture2DSampler[PostEffectTextureID0], texCoords);
    //If depth is background exit now
    float depth = texture(texture2DSampler[PostEffectTextureID1], texCoords).r;
    if (depth >= 1.0f) return;
    //color = vec4(1);
    float ao = texture(texture2DSampler[PostEffectTextureID2], texCoords).r;
    color.rgb -= ao * strength;
    //color = vec4(ao);
}