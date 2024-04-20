#ifndef _VERTEXLAYOUT
    #define _VERTEXLAYOUT

#include "InstanceInfo.glsl"
#include "../Math/Quaternion.glsl"

//layout(location = 0) in uvec4 VertexPositionBoneWeightsDisplacement;
layout(location = 0) in vec3 VertexPositionDisplacement;
layout(location = 1) in vec4 VertexTexCoords;
layout(location = 2) in vec4 VertexQTangent;
layout(location = 3) in uvec4 VertexBoneIndices;
layout(location = 4) in vec4 VertexBoneWeights;
//layout(location = 5) in vec4 VertexTessNormal;

const float one_over_16 = 0.0625f;
const float one_over_65535 = 1.0f / 65535.0f;

/*vec3 ExtractVertexTessNormal()
{
    return VertexTessNormal.xyz;
}*/

vec4 ExtractVertexPosition()
{
    vec3 minima, maxima;
    ExtractInstanceMeshExtents(minima, maxima);
	return vec4(VertexPositionDisplacement.xyz, 1.0f);
    /*vec4 position;
    position.x = float(VertexPositionBoneWeightsDisplacement.x);
    position.y = float(VertexPositionBoneWeightsDisplacement.y);
    position.z = float(VertexPositionBoneWeightsDisplacement.z);
    position.w = 1.0f;
    position.xyz *= one_over_65535;
    ExtractInstanceMeshExtents(minima, maxima);
    position.xyz *= (maxima - minima);
    position.xyz += minima;
    return position;*/
}

void ExtractVertexNormal(out vec3 normal)
{
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	normal.x = 2.0f * (xz - wy);    normal.y = 2.0f * (yz + wx);    normal.z = 1.0f - 2.0f * (xx + yy);
}

void ExtractVertexNormalAndTangent(out vec3 normal, out vec4 tangent)
{
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float zz = VertexQTangent.z * VertexQTangent.z;
	const float xy = VertexQTangent.x * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	const float wz = VertexQTangent.w * VertexQTangent.z;
	tangent.x = 1.0f - 2.0f * (yy + zz);	tangent.y = 2.0f * (xy - wz);	tangent.z = 2.0f * (xz + wy);
	normal.x = 2.0f * (xz - wy);		    normal.y = 2.0f * (yz + wx);	normal.z = 1.0f - 2.0f * (xx + yy);
}

void ExtractVertexNormalTangentBitangent(out vec3 normal, out vec3 tangent, out vec3 bitangent)
{
	const float xx = VertexQTangent.x * VertexQTangent.x;
	const float yy = VertexQTangent.y * VertexQTangent.y;
	const float zz = VertexQTangent.z * VertexQTangent.z;
	const float xy = VertexQTangent.x * VertexQTangent.y;
	const float xz = VertexQTangent.x * VertexQTangent.z;
	const float yz = VertexQTangent.y * VertexQTangent.z;
	const float wx = VertexQTangent.w * VertexQTangent.x;
	const float wy = VertexQTangent.w * VertexQTangent.y;
	const float wz = VertexQTangent.w * VertexQTangent.z;
	tangent.x = 1.0f - 2.0f * (yy + zz);	tangent.y = 2.0f * (xy - wz);	tangent.z = 2.0f * (xz + wy);
	normal.x = 2.0f * (xz - wy);		    normal.y = 2.0f * (yz + wx);	normal.z = 1.0f - 2.0f * (xx + yy);
    bitangent = cross(normal, tangent);
    if (VertexQTangent.w < 0.0f) bitangent *= -1.0f;
}

vec4 ExtractVertexBoneWeights()
{
    vec4 weights = VertexBoneWeights;
    weights.w = 1.0f - (weights.x + weights.y + weights.z);
    return weights;
}

float ExtractVertexDisplacement()
{
	return VertexBoneWeights.w;
}

vec4 VertexPosition = ExtractVertexPosition();
float VertexDisplacement = ExtractVertexDisplacement();

#endif