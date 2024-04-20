#ifndef _ENTITYINFO
    #define _ENTITYINFO

#include "UniformBlocks.glsl"
#include "../Math/FloatPrecision.glsl"
#include "../Math/Math.glsl"

// Entity state flags
const int ENTITYFLAGS_NOFOG = 1;
const int ENTITYFLAGS_STATIC = 2;
const int ENTITYFLAGS_MATRIXNORMALIZED = 4;
//const int ENTITYFLAGS_WHITE = 8;
const int ENTITYFLAGS_SHOWGRID = 64;
const int ENTITYFLAGS_SPRITE = 128;

const int ENTITYFLAGS_LIGHT_LINEARFALLOFF = 8;
const int ENTITYFLAGS_LIGHT_DIRECTIONAL = 16;
const int ENTITYFLAGS_LIGHT_SPOT = 32;
const int ENTITYFLAGS_LIGHT_STRIP = 64;
const int ENTITYFLAGS_LIGHT_BOX = 128;
const int ENTITYFLAGS_LIGHT_PROBE = 256;

const int ENTITYFLAGS_CAMERA_PERSPECTIVE_PROJECTION = 8;

const int ENITYFLAGS_CAMERA_SSR = 64;

//Sprite view modes
const int SPRITEVIEW_DEFAULT = 0;
const int SPRITEVIEW_BILLBOARD = 1;
const int SPRITEVIEW_XROTATION = 2;
const int SPRITEVIEW_YROTATION = 3;
const int SPRITEVIEW_ZROTATION = 4;

#define ONE_OVER_255 0.003921568627f
#define MAX_ENTITY_COLOR (ONE_OVER_255 * 8.0f)
#define MAX_ENTITY_VELOCITY (ONE_OVER_255 * 10.0f * 0.5f)
#define MAX_ENTITY_TEXTURE_SCALE (ONE_OVER_255 * 16.0f * 0.5f)
#define PIf 3.1415926538f

#ifdef DOUBLE_FLOAT
void RepairEntityMatrix(inout dmat4 mat)
#else
void RepairEntityMatrix(inout mat4 mat)
#endif
{
    mat[2].xyz = cross(mat[0].xyz, mat[1].xyz) * mat[2][0];
#ifdef DOUBLE_FLOAT
    mat[0][3] = 0.0; mat[1][3] = 0.0; mat[2][3] = 0.0; mat[3][3] = 1.0;
#else
    mat[0][3] = 0.0f; mat[1][3] = 0.0f; mat[2][3] = 0.0f; mat[3][3] = 1.0f;
#endif
}

void ExtractEntityColor(in uint rg, in uint ba, out vec4 color)
{
    color.rg = unpackHalf2x16(rg);
    color.ba = unpackHalf2x16(ba);
}

#ifdef DOUBLE_FLOAT
dmat4 ExtractEntityMatrix(in uint id)
{
    dmat4 mat = entityMatrix[id];
#else
mat4 ExtractEntityMatrix(in uint id)
{
    mat4 mat = entityMatrix[id];
#endif
    RepairEntityMatrix(mat);
    return mat;
}

vec4 ExtractEntityColor(in uint id)
{
    vec4 color;
    uint rgba0, rgba1;
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[id];
    rgba0 = uint(mat[0][3]);
    rgba1 = uint(mat[1][3]);
#else
    mat4 mat = entityMatrix[id];
    rgba0 = floatBitsToUint(mat[0][3]);
    rgba1 = floatBitsToUint(mat[1][3]);
#endif
    ExtractEntityColor(rgba0, rgba1, color);
    return color;
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out vec4 color, out uint flags, out uvec4 cliprect)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out uvec4 cliprect)
#endif
{
    uint rgba, rgba1;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

    //if ((flags & ENTITYFLAGS_WHITE) != 0)
    //{
    //    color = vec4(1.0f);
    //}
    //else
    //{
#ifdef DOUBLE_FLOAT
        rgba = uint(mat[0][3]);
        rgba1 = uint(mat[1][3]);
#else
        rgba = floatBitsToUint(mat[0][3]);
        rgba1 = floatBitsToUint(mat[1][3]);
#endif
        ExtractEntityColor(rgba, rgba1, color);
    //}
    
    //-----------------------------------------------------
    // Extract clipping region
    //-----------------------------------------------------

    float fff = mat[2][1];
    uint packed_ = floatBitsToUint(fff);
    cliprect.xy = unpackUshort2x16(packed_);
    packed_ = floatBitsToUint(mat[2][3]);
    cliprect.zw = unpackUshort2x16(packed_);

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

uint ExtractEntityFlags(in uint id)
{
    uint rgba, rgba1;
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[id];
    rgba = uint(mat[3][3]);
#else
    mat4 mat = entityMatrix[id];
    rgba = floatBitsToUint(mat[3][3]);
#endif
    return (rgba & 0xFF000000) >> 24;
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out vec4 color, out uint flags)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags)
#endif
{
    uint rgba, rgba1;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

    //if ((flags & ENTITYFLAGS_WHITE) != 0)
    //{
    //    color = vec4(1.0f);
    //}
   // else
    {
#ifdef DOUBLE_FLOAT
        rgba = uint(mat[0][3]);
        rgba1 = uint(mat[1][3]);
#else
        rgba = floatBitsToUint(mat[0][3]);
        rgba1 = floatBitsToUint(mat[1][3]);
#endif
        ExtractEntityColor(rgba, rgba1, color);
    }

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

//Gets skeleton or terrain ID
#ifdef DOUBLE_FLOAT
int ExtractEntitySkeletonID(in uint id)
#else
int ExtractEntitySkeletonID(in uint id)
#endif
{
    mat4 mat = entityMatrix[id];
#ifdef DOUBLE_FLOAT
    return int(mat[2][1]);
#else
    return floatBitsToInt(mat[2][1]);
#endif
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dvec3 position, out vec4 color, out uint flags)
#else
void ExtractEntityInfo(in uint id, out vec3 position, out vec4 color, out uint flags)
#endif
{
    uint rgba, rgba1;
#ifdef DOUBLE_FLOAT
    const dmat4 mat = entityMatrix[id];
#else
    const mat4 mat = entityMatrix[id];
#endif

    //-----------------------------------------------------
    // Extract position
    //-----------------------------------------------------

    position = mat[3].xyz;
    
    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

    //if ((flags & ENTITYFLAGS_WHITE) != 0)
    //{
    //    color = vec4(1.0f);
    //}
   // else
    {
#ifdef DOUBLE_FLOAT
        rgba = uint(mat[0][3]);
        rgba1 = uint(mat[1][3]);
#else
        rgba = floatBitsToUint(mat[0][3]);
        rgba1 = floatBitsToUint(mat[1][3]);
#endif
        ExtractEntityColor(rgba, rgba1, color);
    }
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out uint flags, out int skeletonID)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out uint flags, out int skeletonID)
#endif
{
    uint rgba, rgba1;
    float m;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract skeleton ID
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    skeletonID = int(mat[2][1]);
#else
    skeletonID = floatBitsToInt(mat[2][1]);
#endif

    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out vec4 color, out uint flags, out int skeletonID)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out int skeletonID)
#endif
{
    uint rgba, rgba1;
    float m;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract skeleton ID
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    skeletonID = int(mat[2][1]);
#else
    skeletonID = floatBitsToInt(mat[2][1]);
#endif

    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

    //if ((flags & ENTITYFLAGS_WHITE) != 0)
    //{
    //   color = vec4(1.0f);
    //}
   // else
    {
#ifdef DOUBLE_FLOAT
        rgba = uint(mat[0][3]);
        rgba1 = uint(mat[1][3]);
#else
        rgba = floatBitsToUint(mat[0][3]);
        rgba1 = floatBitsToUint(mat[1][3]);
#endif
        ExtractEntityColor(rgba, rgba1, color);
    }

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out int skeletonID)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out int skeletonID)
#endif
{
    uint rgba, rgba1;
    float m;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract skeleton ID
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    skeletonID = int(mat[2][1]);
#else
    skeletonID = floatBitsToInt(mat[2][1]);
#endif

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out vec4 color, out uint flags, out int skeletonID, out vec4 texturemapping, out vec3 velocity, out vec3 omega)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out vec4 color, out uint flags, out int skeletonID, out vec4 texturemapping, out vec3 velocity, out vec3 omega)
#endif
{
    uint rgba, rgba1;
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract skeleton ID
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    skeletonID = int(mat[2][1]);
#else
    skeletonID = floatBitsToInt(mat[2][1]);
#endif

    //-----------------------------------------------------
    // Extract linear and rotational velocity
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[2][3]);
#else
    rgba = floatBitsToUint(mat[2][3]);
#endif
    if (rgba == 0)
    {
        velocity = vec3(0.0f);
        //texturerotation = 0.0f;
    }
    else
    {
        velocity.x = float(int(rgba & 0x000000FF) - 127) * MAX_ENTITY_VELOCITY;
        velocity.y = float(int((rgba & 0x0000FF00) >> 8) - 127) * MAX_ENTITY_VELOCITY;
        velocity.z = float(int((rgba & 0x00FF0000) >> 16) - 127) * MAX_ENTITY_VELOCITY;
        //texturerotation = float(int((rgba & 0x000000FF) >> 24) - 127) * ONE_OVER_255 * 2.0f * PIf;
    }
#ifdef DOUBLE_FLOAT
    rgba = uint(mat[3][3]);
#else
    rgba = floatBitsToUint(mat[3][3]);
#endif
    if (rgba == 0)
    {
        omega = vec3(0.0f);
        flags = 0;
    }
    else
    {
        omega.x = float(int(rgba & 0x000000FF) - 127) * MAX_ENTITY_VELOCITY;
        omega.y = float(int((rgba & 0x0000FF00) >> 8) - 127) * MAX_ENTITY_VELOCITY;
        omega.z = float(int((rgba & 0x00FF0000) >> 16) - 127) * MAX_ENTITY_VELOCITY;
        flags = (rgba & 0xFF000000) >> 24;
    }

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

    //if ((flags & ENTITYFLAGS_WHITE) != 0)
   // {
    //    color = vec4(1.0f);
    //}
   // else
    {
#ifdef DOUBLE_FLOAT
        rgba = uint(mat[0][3]);
        rgba1 = uint(mat[1][3]);
#else
        rgba = floatBitsToUint(mat[0][3]);
        rgba1 = floatBitsToUint(mat[1][3]);
#endif
        ExtractEntityColor(rgba, rgba1, color);
    }
    
    //-----------------------------------------------------
    // Extract texture offset and scale
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    rgba = uint(mat[2][2]);
#else
    rgba = floatBitsToUint(mat[2][2]);
#endif
    if (rgba == 252641280)
    {
        texturemapping = vec4(0.0f,0.0f,1.0f,1.0f);
    }
    else
    {
        texturemapping.x = float(int(rgba & 0x000000FF) - 127) * ONE_OVER_255;
        texturemapping.y = float(int((rgba & 0x0000FF00) >> 8) - 127) * ONE_OVER_255;
        texturemapping.z = float(int((rgba & 0x00FF0000) >> 16) - 127) * MAX_ENTITY_TEXTURE_SCALE;
        texturemapping.w = float(int((rgba & 0xFF000000) >> 24) - 127) * MAX_ENTITY_TEXTURE_SCALE;
    }
    
    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

/*
mat4 ExtractPostEffectParameters(in int index)
{    
	int m = index / 16;
	mat4 mat = entityMatrix[PostEffectDataPosition + m];
	return mat;
}
*/

#endif
