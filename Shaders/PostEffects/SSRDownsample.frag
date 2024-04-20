#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"
#include "../Utilities/Dither.glsl"
#include "SSRBlur.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor[2];

int DepthTextureID = PostEffectTexture1;
int NormalTextureID = PostEffectTexture2;
int MetallicRoughnessTextureID = PostEffectTexture3;

void main()
{
    const float outerweight = 1.0f;
    const float outerweight2 = 0.75f;
    vec2 tc = gl_FragCoord.xy / BufferSize;
    vec2 texelsize = 1.0f / textureSize(texture2DSampler[PostEffectTexture0], PostEffectMipLevel);

    //Specular
    outColor[0] =  textureLod(texture2DSampler[PostEffectTexture0], tc, PostEffectMipLevel - 1);
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc - vec2(texelsize.x, 0.0f), PostEffectMipLevel - 1) * outerweight;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(texelsize.x, 0.0f), PostEffectMipLevel - 1) * outerweight;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc - vec2(0.0f, texelsize.y), PostEffectMipLevel - 1) * outerweight;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(0.0f, texelsize.y), PostEffectMipLevel - 1) * outerweight;

    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(texelsize.x, texelsize.y), PostEffectMipLevel - 1) * outerweight2;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(texelsize.x, -texelsize.y), PostEffectMipLevel - 1) * outerweight2;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(-texelsize.x, texelsize.y), PostEffectMipLevel - 1) * outerweight2;
    outColor[0] += textureLod(texture2DSampler[PostEffectTexture0], tc + vec2(-texelsize.x, -texelsize.y), PostEffectMipLevel - 1) * outerweight2;

    outColor[0] /= 1.0f + 4.0f * outerweight + 4.0f * outerweight2;
}
