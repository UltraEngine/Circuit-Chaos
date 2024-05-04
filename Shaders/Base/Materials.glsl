#ifndef _MATERIALS_GLSL
#define _MATERIALS_GLSL

#include "StorageBufferBindings.glsl"

#define MATERIAL_REFLECTIVE 1
#define MATERIAL_BLEND_ALPHA 2
#define MATERIAL_EXTRACTNORMALMAPZ 4
#define MATERIAL_BLEND_TRANSMISSION 8
#define MATERIAL_CAST_SHADOWS 16

//Material texture slots
#define TEXTURE_DIFFUSE 0
#define TEXTURE_NORMAL 1
#define TEXTURE_METALLICROUGHNESS 2
#define TEXTURE_SPECULARGLOSSINESS 2
#define TEXTURE_DISPLACEMENT 3
#define TEXTURE_EMISSION 4
#define TEXTURE_AMBIENTOCCLUSION 5

#define TEXTUREFLAGS_DIFFUSE 1
#define TEXTUREFLAGS_NORMAL 2
#define TEXTUREFLAGS_DISPLACEMENT 4
#define TEXTUREFLAGS_EMISSION 8
#define TEXTUREFLAGS_OCCLUSION 16

#define TEXTURE_TERRAINMASK 3
#define TEXTURE_TERRAINHEIGHT 4
#define TEXTURE_TERRAINNORMAL 5
#define TEXTURE_TERRAINMATERIAL 6
#define TEXTURE_TERRAINALPHA 7

#define TEXTURE_CLEARCOAT 7
#define TEXTURE_CLEARCOATROUGHNESS 8
#define TEXTURE_SHEEN 9
#define TEXTURE_SHEENROUGHNESS 10
#define TEXTURE_SHEENLUT 11
#define TEXTURE_CHARLIELUT 12
#define TEXTURE_DETAIL 13

struct Material
{
	vec4 diffuseColor;
	vec4 metalnessRoughness;
	vec4 emissiveColor;
	vec4 displacement;
	vec4 speculargloss;
	uvec2 textureHandle[16];// 8 bytes padding between each element unless std430 is used
};

layout(std430, binding = STORAGE_BUFFER_MATERIALS) readonly buffer MaterialBlock { Material materials[]; };

uint powtable[16] = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768};

/*
float GetMaterialTransmission(in Material mtl)
{
	return mtl.clearcoat.w;
}

vec2 GetMaterialTexCoords(in Material mtl, in vec2 tc, in int index)
{
	return tc * mtl.texturematrix[index].xy + mtl.texturematrix[index].zw;
}

vec2 GetMaterialTexCoords(in Material mtl, in vec4 texcoords, in int index)
{
	vec2 tc;
	if ((floatBitsToUint(mtl.clearcoat.z) & powtable[index]) == 0)
	{
		tc = texcoords.xy;
	}
	else
	{
		tc = texcoords.zw;
	}
	return tc * mtl.texturematrix[index].xy + mtl.texturematrix[index].zw;
}
*/
uint GetMaterialFlags(in Material material)
{
	return floatBitsToUint(material.emissiveColor.w);
}

uvec2 GetMaterialTextureHandle(in Material material, in int n)
{
	return material.textureHandle[n];
	//return material.textureHandle[n / 4][n - (n / 4) * 4];
}
/*
float ExtractMaterialRefractionIndex(in Material material)
{
	return material.refractionThickness.x;
}

float ExtractMaterialThickness(in Material material)
{
	return material.refractionThickness.y;
}
*/

vec2 ExtractMaterialDisplacement(in Material material)
{
	return vec2(0.0f, 0.0f);
}

float ExtractMaterialAlphaCutoff(in Material material)
{
	return material.displacement.z;
}

#endif