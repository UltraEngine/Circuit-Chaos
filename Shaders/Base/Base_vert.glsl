
//#extension GL_ARB_gpu_shader_int64 : enable

#include "../Utilities/ISO646.glsl"
#include "InstanceInfo.glsl"
//#include "Constants.glsl"
#include "PushConstants.glsl"
#include "VertexLayout.glsl"
#include "Limits.glsl"
#include "../Math/Math.glsl"
#include "EntityInfo.glsl"
#include "CameraInfo.glsl"
#include "UniformBlocks.glsl"
#ifdef TEXTURE_ANIMATION
#include "Materials.glsl"
#endif
#ifdef TERRAIN
//#include "Materials.glsl"
//#include "TextureArrays.glsl"
#endif
#ifdef TESSELLATION
#include "Materials.glsl"
#include "TextureArrays.glsl"
#endif
//#ifdef VERTEX_SKINNING
#include "VertexSkinning.glsl"
//#endif
#ifdef TERRAIN
//#include "../Terrain/TerrainInfo.glsl"
#endif

//Outputs
layout(location = 9) out flat uint flags;
layout(location = 25) out flat uint entityindex;
#if defined(WRITE_COLOR) || defined (TESSELLATION)
layout(location = 2) out vec4 texCoords;
layout(location = 3) out vec3 tangent;
layout(location = 4) out vec3 bitangent;
layout(location = 5) flat out uint materialIndex;
#endif
#ifdef WRITE_COLOR
layout(location = 0) out vec4 color;
layout(location = 6) out vec4 vertexCameraPosition;
layout(location = 23) out vec3 screenvelocity;
#else
vec4 color;
#endif
#if defined(WRITE_COLOR) || defined (TESSELLATION) || defined(TERRAIN)
layout(location = 1) out vec3 normal;
layout(location = 7) out vec4 vertexWorldPosition;
#else
vec4 vertexWorldPosition;
#endif
#ifdef TESSELLATION
layout(location = 8) out vec4 maxDisplacedPosition;
layout(location = 11) out float vertexDisplacement;
layout(location = 20) out vec3 tessNormal;
layout(location = 21) out flat uint primitiveID;
#endif
#ifdef PARALLAX_MAPPING
layout(location = 16) out vec3 eyevec;
#endif
#ifdef CLIPPINGREGION
layout(location = 17) out flat uvec4 cliprect;
#endif

#if defined (WRITE_COLOR)  || defined (TESSELLATION) || defined(TERRAIN)
int textureID;
#endif
#ifdef DOUBLE_FLOAT
dmat4 cameraProjectionMatrix;
dmat4 mat;
#ifdef TERRAIN
dmat4 terrainMat;
vec4 terrpos;
#endif
#else
mat4 cameraProjectionMatrix;
mat4 mat;
#ifdef TERRAIN
mat4 terrainMat;
vec3 terrpos;
#endif
#endif
int skeletonID;
vec4 qtangent;

vec4 texturemapping;
vec3 velocity = vec3(0.0f), omega = vec3(0.0f);

void main()
{
	entityindex = EntityID;

#ifdef USERFUNCTION
	UserFunction(color, flags, entitymatrix, normalmatrix, position, normal, texcoords, boneweights, boneindexes);
#endif

#if defined (WRITE_COLOR) || defined(TESSELLATION)
	ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
#endif

#ifdef TERRAIN
	ivec2 patchpos;
	color = vec4(1.0f);
	int terrainID;
	ExtractEntityInfo(EntityID, mat, flags, terrainID, patchpos);
	Material mtl = materials[MaterialID];
	int textureID = GetMaterialTextureHandle(mtl, TEXTURE_TERRAINHEIGHT);
	const float patchsize = 64.0f;
	#if defined(WRITE_COLOR) || defined (TESSELLATION)
	materialIndex = MaterialID;
	#else
	vec2 texCoords;
	#endif
	texCoords.x = (float(patchpos.x) * patchsize + VertexPosition.x) / float(512) - 0.0f;
	texCoords.y = (float(patchpos.y) * patchsize + VertexPosition.z) / float(512) - 0.0f;
	if (textureID != -1)
	{
		VertexPosition.y = textureLod(texture2DSampler[textureID], texCoords.xy, 0).r;
	}
#else
	#if defined(WRITE_COLOR) || defined (TESSELLATION)
	materialIndex = MaterialID;
	#endif
	#if defined(WRITE_COLOR) || defined(VERTEX_SKINNING)
		#ifdef VERTEX_SKINNING
	ExtractEntityInfo(EntityID, mat, color, flags, skeletonID, texturemapping, velocity, omega);
		#else
			#ifdef CLIPPINGREGION
	ExtractEntityInfo(EntityID, mat, color, flags, cliprect);
	//cliprect.xz += uint(mat[3].x + 0.01f);
	//cliprect.yw += uint(BufferSize.y - mat[3].y + 0.01f);
			#else
	ExtractEntityInfo(EntityID, mat, color, flags, skeletonID, texturemapping, velocity, omega);
			#endif
		#endif
	#else
	ExtractEntityInfo(EntityID, mat, flags, skeletonID);
	#endif
#endif

//#ifdef SPRITEVIEW
	if ((flags & ENTITYFLAGS_SPRITE) != 0)
	{
		switch (skeletonID)
		{
			case SPRITEVIEW_DEFAULT:
				break;
			case SPRITEVIEW_BILLBOARD:
				mat[0] = CameraMatrix[0];
				mat[1] = CameraMatrix[1];
				mat[2] = CameraMatrix[2];
				break;
			case SPRITEVIEW_XROTATION:
				break;
			case SPRITEVIEW_YROTATION:
				break;	
			case SPRITEVIEW_ZROTATION:
				break;
		}
	}
//#endif

	cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, PassIndex);
	//cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, gl_Layer);

#ifdef VERTEX_SKINNING
	if (skeletonID > -1)
	{
		mat4 animmatrix = mat4(0.0f);
		vec4 weights = ExtractVertexBoneWeights();
		//if (VertexBoneWeights[0] != 0.0f or VertexBoneWeights[1] != 0.0f or VertexBoneWeights[2] != 0.0f or VertexBoneWeights[3] != 0.0f)
		//{
			for (int n = 0; n < 4; ++n)
			{
				if (VertexBoneWeights[n] > 0.0f)
				{
					animmatrix += GetBoneMatrix(skeletonID, VertexBoneIndices[n], RenderInterpolation) * weights[n];
				}
			}
			VertexPosition = animmatrix * VertexPosition;
			VertexPosition.w = 1.0f;
	#if defined(WRITE_COLOR) || defined(TESSELLATION)
			mat3 nanimmat = mat3(animmatrix);
			normal = nanimmat * normal;
			tangent = nanimmat * tangent;
			bitangent = nanimmat * bitangent;
	#endif
	}
#else
	if (VertexBoneIndices[0] != 255 || VertexBoneIndices[1] != 255 || VertexBoneIndices[2] != 255 || VertexBoneIndices[3] != 255)
	{
		color.r *= float(VertexBoneIndices[0]) / 255.0f;
		color.g *= float(VertexBoneIndices[1]) / 255.0f;
		color.b *= float(VertexBoneIndices[2]) / 255.0f;
		color.a *= float(VertexBoneIndices[3]) / 255.0f;
	}
#endif

#ifdef USE_SCISSOR
	#ifdef DOUBLE_FLOAT
	scissor.x = float(entityMatrix[ id + 1 ][0].x);
	scissor.y = float(entityMatrix[ id + 1 ][0].y);
	scissor.z = float(entityMatrix[ id + 1 ][0].z);
	scissor.w = float(entityMatrix[ id + 1 ][0].w);
	#else
	scissor = entityMatrix[ id + 1 ][0];
	#endif
#endif

#if defined (WRITE_COLOR) || defined(TESSELLATION)
	#ifndef TERRAIN
	texCoords = VertexTexCoords;
	#endif
	bool alreadynormalized = (flags & ENTITYFLAGS_MATRIXNORMALIZED) != 0;
	//if (alreadynormalized) color = vec4(1,0,0,1);
	//#ifdef WRITE_COLOR
	//if (materials[materialIndex].textureHandle[0][1] != -1)
	//{
		//ExtractVertexNormalAndTangent(normal, qtangent);
		//tangent.xyz = CameraNormalMatrix * tangent.xyz;
		mat3 EntityNormalMatrix = mat3(mat);
		normal = EntityNormalMatrix * normal;
		tangent = EntityNormalMatrix * tangent;
		bitangent = EntityNormalMatrix * bitangent;
		//if (!alreadynormalized)
		//{
		normal = normalize(normal);
		tangent = normalize(tangent);
		bitangent = normalize(bitangent);
		//}
		//bitangent = cross(normal, tangent.xyz) * sign(qtangent.w);
	//}
	//else
	//{
	//	ExtractVertexNormal(normal);
	//}
	//bitangent = normalize(CameraNormalMatrix * VertexBitangent);
	//#else
	//	ExtractVertexNormal(normal);
	//	normal = CameraNormalMatrix * normal;
	//#endif
	//if (!alreadynormalized) 
	//normal = normalize(normal);
#endif

#ifdef DOUBLE_FLOAT
	dvec4 dposition = mat * VertexPosition;
#else
	//if ((flags & RENDERNODE_IDENTITYMATRIX) == 0)
	vertexWorldPosition = mat * VertexPosition;
#endif

#ifdef WRITE_COLOR
	#ifdef DOUBLE_FLOAT
	vertexCameraPosition = CameraInverseMatrix * dposition;
	#else
	vertexCameraPosition = CameraInverseMatrix * vertexWorldPosition;
	#endif
#endif

#ifdef PARALLAX_MAPPING
    mat3 TBN = mat3(tangent, bitangent, normal);
	#ifdef DOUBLE_FLOAT
	eyevec = vec3(CameraPosition - dposition.xyz);
	#else
	vec3 eyevec = CameraPosition - vertexWorldPosition.xyz;
	#endif
	eyevec *= TBN;
#endif

#ifdef TEXTURE_ANIMATION
	/*if (materials[materialIndex].animation.x != 0.0f || materials[materialIndex].animation.y != 0.0f || materials[materialIndex].animation.z != 0.0f)
	{
		//Texture scroll
		texCoords.xyz -= materials[materialIndex].animation.xyz * float(CurrentTime) / 1000.0f;
	}*/
#endif

#ifdef TESSELLATION
	primitiveID = PrimitiveID;
	
	/*if (abs(VertexTessNormal.x) < 0.1f && abs(VertexTessNormal.y) < 0.1f && abs(VertexTessNormal.z) < 0.1f)
	{
		tessNormal = normal;//vec3(0.0f);
	}
	else
	{
		tessNormal = normalize(EntityNormalMatrix * VertexTessNormal.xyz);
	}*/
	tessNormal.xyz = normal.xyz;
	maxDisplacedPosition = vertexWorldPosition;
	//#define MAX_DISPLACEMENT 0.025
	//float maxDisplacement = materials[MaterialID].metalnessRoughness[2];
	//maxDisplacedPosition.xyz += normal * maxDisplacement;
	maxDisplacedPosition = cameraProjectionMatrix * maxDisplacedPosition;
	vertexDisplacement = VertexDisplacement;
#endif

#ifdef DOUBLE_FLOAT
	vertexWorldPosition = vec4(dposition);
	gl_Position = vec4(cameraProjectionMatrix * dposition);
#else
	gl_Position = cameraProjectionMatrix * vertexWorldPosition;
#endif

	//gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5f;
#ifdef LINEAR_DEPTH
	gl_Position.z *= gl_Position.w;
#endif
#ifdef WRITE_COLOR
	screenvelocity = CameraNormalMatrix * (velocity - cross(vertexWorldPosition.xyz - mat[3].xyz, omega));
#endif

	// Adjust selection flag based on mesh settings
	//if ((flags & ENTITYFLAGS_SELECTED) != 0)
	//{
	//	if (meshflags == 0) flags -= ENTITYFLAGS_SELECTED;
	//}
	//if (meshflags != 0) flags |= ENTITYFLAGS_SELECTED;

	gl_PointSize = 1.0f;
}