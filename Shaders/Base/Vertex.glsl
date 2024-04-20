

#ifndef _BASE_VERTEX
#define _BASE_VERTEX

#include "../Utilities/ISO646.glsl"
#include "InstanceInfo.glsl"
#include "PushConstants.glsl"
#include "VertexLayout.glsl"
#include "Limits.glsl"
#include "../Math/Math.glsl"
#include "EntityInfo.glsl"
#include "CameraInfo.glsl"
#include "UniformBlocks.glsl"
#ifdef VERTEX_SKINNING
#include "VertexSkinning.glsl"
#endif
#ifdef TESSELLATION
#include "Materials.glsl"
#include "TextureArrays.glsl"
#endif
#ifdef TERRAIN
#include "Materials.glsl"
#include "TextureArrays.glsl"
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

#endif