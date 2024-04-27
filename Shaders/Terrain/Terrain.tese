#version 450
#ifdef GL_GOOGLE_include_directive
	#extension GL_GOOGLE_include_directive : enable
#endif
//#extension GL_EXT_multiview : enable

//#define TERRAIN
#define WRITE_COLOR
#define PATCH_VERTICES 4
#define USERFUNCTION
#define PNQUADS

#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "../Utilities/ISO646.glsl"
#include "TerrainInfo.glsl"

int textureID;

layout(binding = 2) uniform sampler2DArray displacementtextureatlas;
layout(binding = TEXTURE_TERRAINMATERIAL) uniform usampler2D terrainmaterialmap;
layout(binding = TEXTURE_TERRAINALPHA) uniform sampler2D terrainalphamap;
layout(binding = TEXTURE_TERRAINNORMAL) uniform sampler2D terrainnormalmap;

void UserFunction(in uint entityID, inout vec4 position, inout vec3 normal, inout vec4 texCoords, in Material material)
{
	int terrainID = ExtractEntitySkeletonID(uint(entityID));

	/*int textureID = GetMaterialTextureHandle(material, TEXTURE_NORMAL);
	if (textureID != -1)
	{
		mat3 mat = mat3(ExtractEntityMatrix(entityID));
		normal.xz = textureLod(texture2DSampler[textureID], texCoords.xy, 0.0f).rg * 2.0f - 1.0f;
		normal.y = sqrt(max(0.0f, 1.0f - (normal.x * normal.x + normal.z * normal.z)));
		normal = normalize(inverse(mat) * normal);
	}*/

	//textureID = GetMaterialTextureHandle(material, TEXTURE_TERRAINMATERIAL);
	//if (textureID != -1)
	{
		//int alphatexID = GetMaterialTextureHandle(material, TEXTURE_TERRAINALPHA);
		//vec2 imagesize = textureSize(texture2DUIntegerSampler[textureID],0).xy;
		vec2 imagesize = textureSize(terrainmaterialmap,0).xy;
		vec2 alphapixelsize = 0.5 / imagesize;
		vec2 imagepixelsize = 1.0 / imagesize;
		vec2 tilef = texCoords.xy * imagesize;
		vec2 tile = floor(tilef);
		vec2 rem = (tilef - tile);
		vec2 acoords = tile * imagepixelsize + alphapixelsize * 0.5 + rem * alphapixelsize;	
		//vec4 textureAlpha = texture(texture2DSampler[alphatexID],acoords.xy);
		vec4 textureAlpha = texture(terrainalphamap,acoords.xy);
		float terraindisplacement = 0.0;
		Material submtl;
		ivec2 tilecoord;
		tilecoord.x = int(texCoords.x * float(imagesize.x));
		tilecoord.y = int(texCoords.y * float(imagesize.y));
		//uvec4 materialIDs = texelFetch(texture2DUIntegerSampler[textureID], tilecoord, 0);
		uvec4 materialIDs = texelFetch(terrainmaterialmap, tilecoord, 0);
		vec2 terrcoords = texCoords.xy * 32.0f;//* terrainScale.xz;
		TerrainLayerInfo layerinfo;
		vec3 layercoords;
		for (int channel = 0; channel < 4; ++channel)
		{
			if (materialIDs[channel] == 0 or textureAlpha[channel] == 0.0f) break;
			ExtractTerrainLayerInfo(terrainID, materialIDs[channel], layerinfo);

            layercoords.xz = texCoords.xy * layerinfo.scale * 512.0f;
            layercoords.y = texCoords.z * layerinfo.scale;

			int submtlID = layerinfo.materialID;
			//int submtlID = ExtractTerrainLayerInfo(terrainID, materialIDs[channel]);
			if (submtlID == -1) continue;
			submtl = materials[submtlID];
			//int subtex = GetMaterialTextureHandle(submtl, TEXTURE_DISPLACEMENT);			
			//if (subtex != -1)
			if ((layerinfo.flags & TEXTUREFLAGS_DISPLACEMENT) != 0)
			{
				vec2 d = ExtractMaterialDisplacement(submtl);
				float maxDisplacement = d.x;
				float offset = d.y;
				vec3 normal;
				if (layerinfo.mappingmode != 0 && (layerinfo.flags & TEXTUREFLAGS_NORMAL) != 0)
				{
					//int normaltexID = GetMaterialTextureHandle(material, c);
					//normal.xz = texture(texture2DSampler[alphatexID], acoords.xy).xz * 2.0f - 1.0f;
					normal.xz = texture(terrainnormalmap, acoords.xy).xz * 2.0f - 1.0f;
					normal.y = 1.0f - sqrt(normal.x * normal.x + normal.z * normal.z);
				}
				//terraindisplacement += (maxDisplacement + offset) * TerrainSample(texture2DSampler[subtex], layercoords, normal, layerinfo.mappingmode).r * textureAlpha[channel];
				terraindisplacement += (maxDisplacement + offset) * TerrainSample(displacementtextureatlas, layercoords, normal, layerinfo.mappingmode, materialIDs[channel]).r * textureAlpha[channel];
			}
		}
		position.xyz += normal * terraindisplacement;
	}
}

#include "../Tessellation/base_tese.glsl"