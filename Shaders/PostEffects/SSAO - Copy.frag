#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/ReconstructPosition.frag"
#include "../Utilities/DepthFunctions.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

// Created by Reinder Nijhoff 2016
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/ls3GWS
//
//
// demonstrating post process Screen Space Ambient Occlusion applied to a depth and normal map
// with the geometry of my shader '[SIG15] Matrix Lobby Scene': 
//
// https://www.shadertoy.com/view/MtsXzf
//

#define SAMPLES 16
#define INTENSITY 2.0f
#define SCALE 2.5 * 0.5
#define BIAS 0.05
#define SAMPLE_RAD 0.25
#define MAX_DISTANCE 1.0

#define MOD3 vec3(.1031,.11369,.13787)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

vec3 getPosition(vec2 uv)
{
	float z = textureLod(texture2DSampler[PostEffectTexture0], uv, 0).r;
	//z = DepthToPosition(z, CameraRange);
	return ScreenCoordToWorldPosition(vec3(uv, z));
}

/*vec3 getPosition(vec2 uv) {
    float fl = textureLod(iChannel0, vec2(0.), 0.).x; 
    float d = textureLod(iChannel0, uv, 0.).w;
       
    vec2 p = uv*2.-1.;
    mat3 ca = mat3(1.,0.,0.,0.,1.,0.,0.,0.,-1./1.5);
    vec3 rd = normalize( ca * vec3(p,fl) );
    
	vec3 pos = rd * d;
    return pos;
}*/

vec3 getNormal(vec2 uv)
{
    return textureLod(texture2DSampler[PostEffectTexture1], uv, 0.).xyz;
}

vec2 getRandom(vec2 uv) {
    return normalize(hash22(uv*126.1231) * 2. - 1.);
}

float doAmbientOcclusion(in vec2 tcoord,in vec2 uv, in vec3 p, in vec3 cnorm)
{
    vec3 diff = getPosition(tcoord + uv) - p;
    float l = length(diff);
    vec3 v = diff/l;
    float d = l*SCALE;
    float ao = max(0.0,dot(cnorm,v)-BIAS)*(1.0/(1.0+d));
    ao *= smoothstep(MAX_DISTANCE,MAX_DISTANCE * 0.5, l);
    return ao;

}

float spiralAO(vec2 uv, vec3 p, vec3 n, float rad)
{
    float goldenAngle = 2.4;
    float ao = 0.;
    float inv = 1. / float(SAMPLES);
    float radius = 0.;

    float rotatePhase = hash12( uv*100. ) * 6.28;
    float rStep = inv * rad;
    vec2 spiralUV;

    for (int i = 0; i < SAMPLES; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radius += rStep;
        ao += doAmbientOcclusion(uv, spiralUV * radius, p, n);
        rotatePhase += goldenAngle;
    }
    ao *= inv;
    return ao;
}

void main()
{
	vec2 uv = gl_FragCoord.xy / BufferSize;

    float z = textureLod(texture2DSampler[PostEffectTexture0], uv, 0).r;
    if (z == 1.0f)
    {
        outColor = vec4(0.0f);
        return;
    }
    
    vec3 p = ScreenCoordToWorldPosition(vec3(gl_FragCoord.xy / BufferSize, z));
    vec3 n = textureLod(texture2DSampler[PostEffectTexture1], uv, 0).rgb;
	
    float ao = 0.0f;
    float rad = SAMPLE_RAD / max(10.0f, z);

    ao = spiralAO(uv, p, n, rad);

    z = DepthToPosition(z, CameraRange);
    if (z < 10.0f) ao *= 0.1f + 0.9 * z / 10.0f;

    ao = clamp(ao * INTENSITY, 0.0f, 1.0f);
    
	//outColor = vec4(ao);
	//vec4 scene = textureLod(texture2DSampler[PostEffectTexture2], uv, 0);
	//scene = vec4((scene.r + scene.g + scene.b)/3.0f);
	//scene = scene * 0.25 + 0.75;
	//scene = clamp(scene, vec4(0), vec4(1));
	outColor = vec4(ao);
}