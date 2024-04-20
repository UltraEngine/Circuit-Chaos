#ifndef _INSTANCEINFO
    #define _INSTANCEINFO

#include "UniformBlocks.glsl"
#include "../Math/Math.glsl"

uint meshflags = 0;

#define DRAWIDSIZE 2

#if DRAWIDSIZE == 4
	#define INSTANCEOFFSET_ENTITYIDS 7
#endif
#if DRAWIDSIZE == 2
	#define INSTANCEOFFSET_ENTITYIDS 8
#endif

//uint ExtractInstanceMaterialID()
//{
//	uint id_over_four = gl_BaseInstanceARB / 4;
//	return instanceID[ id_over_four ][  gl_BaseInstanceARB - id_over_four * 4 ];
//}

uint ExtractMaterialID()
{
//#if DRAWIDSIZE == 2
	uint id = gl_BaseInstanceARB / 8;
	uvec4 params = instanceID[ id ];
	vec2 fval;
	//Extract material ID
	uvec2 uval = unpackUshort2x16(params.x);
	return uval.x;
//#endif
}

uint MaterialID = ExtractMaterialID();

#ifdef TESSELLATION
uint PrimitiveID;
#endif

void ExtractInstanceMeshExtents(out vec3 minima, out vec3 maxima)
{
#if DRAWIDSIZE == 4
	uint id = gl_BaseInstanceARB / 4;
	uvec4 params = instanceID[ id ];
	//MaterialID = params.x;
	minima.x = uintBitsToFloat(params.y);
	minima.y = uintBitsToFloat(params.z);
	minima.z = uintBitsToFloat(params.w);
	params = instanceID[ id + 1];
	maxima.x = uintBitsToFloat(params.x);
	maxima.y = uintBitsToFloat(params.y);
	maxima.z = uintBitsToFloat(params.z);
#endif
#if DRAWIDSIZE == 2
	uint id = gl_BaseInstanceARB / 8;
	uvec4 params = instanceID[ id ];
	vec2 fval;

	//Extract material ID
	uvec2 uval = unpackUshort2x16(params.x);
	MaterialID = uval.x;
	meshflags = uval.y;
	// = uval.y;// reserved for???

	//Extract mesh bounds
	fval = unpackHalf2x16(params.y);
	minima.x = fval.x;
	minima.y = fval.y;
	fval = unpackHalf2x16(params.z);
	minima.z = fval.x;
	maxima.x = fval.y;
	fval = unpackHalf2x16(params.w);
	maxima.y = fval.x;
	maxima.z = fval.y;

	//Extract primitive info index
#ifdef TESSELLATION
	params = instanceID[ id + 1 ];
	PrimitiveID = params.x;
#endif

#endif
	//#define INSTANCEOFFSET_MESHBOUNDS 1
	//uint id, id_over_four;
	//id = gl_BaseInstanceARB + INSTANCEOFFSET_MESHBOUNDS;
	//id_over_four = id / 4;
	//minima.x = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
	//++id;
	//id_over_four = id / 4;
	//minima.y = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
	//++id;
	//id_over_four = id / 4;
	//minima.z = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
	//++id;
	//id_over_four = id / 4;
	//maxima.x = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
	//++id;
	//id_over_four = id / 4;
	//maxima.y = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
	//++id;
	//id_over_four = id / 4;
	//maxima.z = uintBitsToFloat(instanceID[ id_over_four ][ id - id_over_four * 4 ]);
}

uint ExtractInstanceEntityID()
{
	uint InstanceIndex = gl_BaseInstanceARB + gl_InstanceID;
#if DRAWIDSIZE == 4
	uint id = InstanceIndex + INSTANCEOFFSET_ENTITYIDS;
#endif
#if DRAWIDSIZE == 2
	uint id = InstanceIndex / 2 + INSTANCEOFFSET_ENTITYIDS;
#endif
	uint id_over_four = id / 4;
	id = instanceID[ id_over_four ][ id - id_over_four * 4 ];
#if DRAWIDSIZE == 2
	uvec2 ids = unpackUshort2x16(id);
	id = ids[InstanceIndex % 2];
#endif
    return id;
}

uint EntityID = ExtractInstanceEntityID();

#endif