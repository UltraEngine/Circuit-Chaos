#ifndef _LIGHTINFO
    #define _LIGHTINFO

#include "UniformBlocks.glsl"

//Matrix offsets
#define LIGHT_INFO_OFFSET 11
#define LIGHT_SHADOW_RENDER_MATRIX_OFFSET 12

//Light falloff mode
#define LIGHTFALLOFF_INVERSESQUARE 0
#define LIGHTFALLOFF_LINEAR 1

//Light types
#define LIGHT_POINT 0
#define LIGHT_SPOT 1
#define LIGHT_STRIP 2
#define LIGHT_BOX 3
#define LIGHT_PROBE 4
#define LIGHT_DIRECTIONAL 5// this one always last

#define PROBE_INFO_OFFSET 21

mat4 ExtractLightShadowRenderMatrix(in uint lightID)
{
    return entityMatrix[lightID + LIGHT_SHADOW_RENDER_MATRIX_OFFSET];
}

vec3 ExtractLightShadowRenderPosition(in uint lightID)
{
    return entityMatrix[lightID + LIGHT_SHADOW_RENDER_MATRIX_OFFSET][3].xyz;
}

#ifdef DOUBLE_FLOAT
void ExtractLightInfo(in uint lightID, out uint shadowmaplayer, out int shadowcachemapID, out dvec2 range, out dvec2 coneangles, out vec2 shadowrange, out uint lightflags, out int shadowkernel)
{
	const dmat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	#ifdef USE_VSM
	shadowmaplayer = int(lightinfo[2][1]);
	#else
	shadowmaplayer = floatBitsToUint(lightinfo[2][0]);
	//shadowcachemapID = int(lightinfo[3][0]);
	#endif
	shadowkernel = int(lightinfo[3][2]);
	lightflags = uint(lightinfo[3][3]);
#else
void ExtractLightInfo(in uint lightID, out uint shadowmaplayer, out int shadowcachemapID, out vec2 range, out vec2 coneangles, out vec2 shadowrange, out uint lightflags, out int shadowkernel)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	shadowmaplayer = floatBitsToUint(lightinfo[2][0]);
	shadowkernel = floatBitsToInt(lightinfo[3][2]);
	lightflags = floatBitsToUint(lightinfo[3][3]);
#endif
	range = lightinfo[0].xy;
    coneangles = lightinfo[0].zw;
	shadowrange = lightinfo[2].zw;
}

void ExtractLightInfo(in uint lightID, out vec2 coneangles, out int shadowkernel, out uint shadowmaplayer)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	coneangles = vec2(lightinfo[0].zw);
#ifdef DOUBLE_FLOAT
	shadowkernel = int(lightinfo[3][2]);
	shadowmaplayer = uint(lightinfo[2][0]);
#else
	shadowkernel = floatBitsToInt(lightinfo[3][2]);
	shadowmaplayer = floatBitsToUint(lightinfo[2][0]);
#endif
}

uint ExtractLightFlags(in uint lightID)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	return floatBitsToUint(lightinfo[3][3]);
}

mat4 ExtractProbeInfo(in uint lightID)
{
	return entityMatrix[lightID + PROBE_INFO_OFFSET];
}

#ifdef DOUBLE_FLOAT
int ExtractLightShadowMapIndex(in uint lightID)
{
	const dmat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	#ifdef USE_VSM
	return int(lightinfo[2][0]);
	#else
	return int(lightinfo[2][0]);
	#endif
}
#else 
int ExtractLightShadowMapIndex(in uint lightID)
{
	const mat4 lightinfo = entityMatrix[lightID + LIGHT_INFO_OFFSET];
	#ifdef USE_VSM
	return floatBitsToInt(lightinfo[2][0]);
	#else
	return floatBitsToInt(lightinfo[2][0]);
	#endif
}
#endif

#endif