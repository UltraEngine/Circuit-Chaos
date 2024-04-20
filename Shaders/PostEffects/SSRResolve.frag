#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_EXT_multiview : enable

//#include "SSRMix.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Math/AABB.glsl"
#include "../Math/Plane.glsl"
#include "../Utilities/Dither.glsl"
#include "../Base/LightInfo.glsl"
#include "../Base/Lighting.glsl"
#include "../Utilities/ReconstructPosition.frag"
#include "../Khronos/ibl.glsl"

//Inputs
layout(location = 0) in vec2 texCoords111;

//Outputs
layout(location = 0) out vec4 color;

#define SAMPLE_COUNT 1

//vec2 pattern[SAMPLE_COUNT] = {vec2(0,-1), vec2(0,1), vec2(-1,0), vec2(1,0)};
vec2 pattern[SAMPLE_COUNT] = {vec2(0,0)};

int IncomingDiffuseTextureID = PostEffectTexture0;
int SpecularReflectionTextureID = PostEffectTexture1;
int DepthTextureID = PostEffectTexture2;
int NormalTextureID = PostEffectTexture3;
int MetallicRoughnessTextureID = PostEffectTexture4;
int BaseColorTextureID = PostEffectTexture5;

void main(void)
{
    const float specularWeight = 1.0f;

    vec2 texCoords = gl_FragCoord.xy / BufferSize;

    vec2 texsize = textureSize(texture2DSampler[DepthTextureID], 0);
    vec2 texelsize = 1.0f / texsize;

    vec2 ssrtexsize = textureSize(texture2DSampler[SpecularReflectionTextureID], 0);
    vec2 ssrtexelsize = 1.0f / ssrtexsize;

    float scale = texsize.x / ssrtexsize.x;

    ivec2 coord = ivec2(gl_FragCoord.xy);
    ivec2 ssrcoord = ivec2(texCoords * ssrtexsize);

    color = vec4(0);//texelFetch(texture2DSampler[PostEffectTexture0], coord, 0);

    float d = texelFetch(texture2DSampler[DepthTextureID], coord, 0).r;
    if (d >= 1.0f) return;

    vec3 n = texelFetch(texture2DSampler[NormalTextureID], coord, 0).rgb;    
    vec4 specular = vec4(0);

    //Weighted sampling of SSR image
    d = DepthToPosition(d, CameraRange);

    //specular = texelFetch(texture2DSampler[DiffuseTextureID], ssrcoord, 0);

    float sumweights = 1.0f;

    vec4 ssr = vec4(0);
    //sumweights = 0.0f;

    vec3 basecolor = texture(texture2DSampler[BaseColorTextureID], texCoords, 0).rgb;
    vec4 metalroughness = texture(texture2DSampler[MetallicRoughnessTextureID], texCoords, 0);
    float roughness = metalroughness.g;
    float metallic = metalroughness.b;
    int SpecularModel = int(metalroughness.r + 0.5f);

    roughness = 0;

    vec4 background = textureLod(texture2DSampler[IncomingDiffuseTextureID], texCoords, 0);

    vec3 reflectioncolor = textureLod(texture2DSampler[SpecularReflectionTextureID], texCoords, 0).rgb;

    //Screen-space ray tracing
    int mipcount = textureQueryLevels(texture2DSampler[SpecularReflectionTextureID]);
    //for (int i = 0; i < SAMPLE_COUNT; ++i)
    {
        int i = 0;
        vec2 tc = texCoords + pattern[i] * texelsize;
        //vec3 sn = textureLod(texture2DSampler[NormalTextureID], tc, 0.0f).rgb;
        vec3 sn = texelFetch(texture2DSampler[NormalTextureID], coord + ivec2(pattern[i] * scale), 0).rgb;
        float weight = dot(n, sn);
        //if (weight <= 0.0f) continue;
        //float sd = textureLod(texture2DSampler[DepthTextureID], tc, 0.0f).r;
        float sd = texelFetch(texture2DSampler[DepthTextureID], coord + ivec2(pattern[i] * scale), 0).r;
        sd = DepthToPosition(sd, CameraRange);
        float diff = abs(d - sd);
        if (diff > 0.1f) weight *= max(0.0f, 1.0f - (diff - 0.1f) / 1.0f);
        //if (weight <= 0.0f) continue;
        //sumweights += weight;
        float lod = roughness * float(mipcount - 1);

        ssr = textureLod(texture2DSampler[SpecularReflectionTextureID], texCoords + pattern[i] * ssrtexelsize, lod) * weight;
    }
   
    //ssr.a *= 1.5f;
    ssr.a = clamp(ssr.a, 0.0f, 1.0f);
    //if (ssr.a > 0.97f) ssr.a = 1.0f;
    specular += ssr;    

    //Diffuse reflection
    //vec4 diffusereflection = vec4(0);
    //sumweights = 0;
    /*for (int i = 0; i < SAMPLE_COUNT; ++i)
    {
        vec2 tc = texCoords + pattern[i] * texelsize;
        //vec3 sn = textureLod(texture2DSampler[NormalTextureID], tc, 0.0f).rgb;
        vec3 sn = texelFetch(texture2DSampler[NormalTextureID], coord + ivec2(pattern[i] * scale), 0).rgb;
        float weight = dot(n, sn);
        if (weight <= 0.0f) continue;
        //float sd = textureLod(texture2DSampler[DepthTextureID], tc, 0.0f).r;
        float sd = texelFetch(texture2DSampler[DepthTextureID], coord + ivec2(pattern[i] * scale), 0).r;
        sd = DepthToPosition(sd, CameraRange);
        float diff = abs(d - sd);
        if (diff > 0.1f) weight *= max(0.0f, 1.0f - (diff - 0.1f) / 1.0f);
        if (weight <= 0.0f) continue;
        sumweights += weight;
        float lod = roughness * float(mipcount - 1);
        diffusereflection += textureLod(texture2DSampler[DiffuseReflectionTextureID], texCoords + pattern[i] * ssrtexelsize, 4) * weight;
    }
    diffusereflection /= sumweights;*/
   
    //vec4 diffuse = diffusereflection;

    vec3 pos = GetFragmentWorldPosition(texture2DSampler[DepthTextureID]);    
vec3 v = normalize(pos - CameraPosition);

    //Environment probes
/*    vec3 r = reflect(v, n);
    vec4 iblspecular = vec4(0);
    //vec4 ibldiffuse = vec4(0);
    int u_MipCount;
    float lod;
    vec3 normal = textureLod(texture2DSampler[NormalTextureID], gl_FragCoord.xy / BufferSize, 0).rgb;
    vec3 campos = (CameraInverseMatrix * vec4(pos,1)).xyz;
*/
    //RenderProbes(campos, pos, normal, -v, dot(normal,-v), roughness, ibldiffuse, iblspecular);

    /*diffuse = diffusereflection;

    if (diffuse.a < 1.0f && EnvironmentMap_Diffuse != -1)
    {
        diffuse.rgb += texture(textureCubeSampler[EnvironmentMap_Diffuse], normal).rgb * (1.0f - diffuse.a) * IBLIntensity;
    }*/

    //Sky reflection
    /*if (iblspecular.a < 1.0f && EnvironmentMap_Specular != -1)
    {
        u_MipCount = textureQueryLevels(textureCubeSampler[EnvironmentMap_Specular]);
        lod = roughness * float(u_MipCount - 1); 
        vec3 sky = textureLod(textureCubeSampler[EnvironmentMap_Specular], r, lod).rgb * (1.0f - iblspecular.a) * IBLIntensity;
        const float maxbrightness = 16.0f;
        sky.r = min(sky.r, maxbrightness);
        sky.g = min(sky.g, maxbrightness);
        sky.b = min(sky.b, maxbrightness);
        iblspecular.rgb += sky;
    }
    specular.rgb += iblspecular.rgb * (1.0f - ssr.a);*/
    
    //Add specular lighting
    if (specular.r > 0.0f || specular.g > 0.0f || specular.b > 0.0f)
    {
        vec3 f0 = mix(specular.rgb,  vec3(0.0f), metallic);
        color.rgb += getIBLRadianceGGX(texture2DSampler[Lut_GGX], specular.rgb, n, -v, roughness, f0, specularWeight);
    }

    //color = vec4(ssr.a);
    //return;
    color.rgb = background.rgb * (1.0f - ssr.a) + color.rgb * ssr.a;
    color.a = background.a;

    //Dither final pass
    if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
    {
        color.rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
    }
}