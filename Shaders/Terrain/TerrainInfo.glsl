#ifndef _TERRAININFO
    #define _TERRAININFO

#include "../Base/UniformBlocks.glsl"
#include "../Math/FloatPrecision.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Math/FastSqrt.glsl"

#define TERRAIN_LAYERS_MATRIX_OFFSET 2

#ifdef DOUBLE_FLOAT
void ExtractEntityInfo(in uint id, out dmat4 mat, out uint flags, out int terrainID, out ivec2 patchpos)
#else
void ExtractEntityInfo(in uint id, out mat4 mat, out uint flags, out int terrainID, out ivec2 patchpos)
#endif
{
    mat = entityMatrix[id];

    //-----------------------------------------------------
    // Extract terrain ID
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    terrainID = int(mat[2][1]);
#else
    terrainID = floatBitsToInt(mat[2][1]);
#endif

    //-----------------------------------------------------
    // Extract flags
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    uint rgba = uint(mat[3][3]);
#else
    uint rgba = floatBitsToUint(mat[3][3]);
#endif
    flags = (rgba & 0xFF000000) >> 24;

    //-----------------------------------------------------
    // Extract color
    //-----------------------------------------------------

#ifdef DOUBLE_FLOAT
    patchpos.x = int(mat[0][3]);
    patchpos.y = int(mat[1][3]);
#else
    patchpos.x = floatBitsToInt(mat[0][3]);
    patchpos.y = floatBitsToInt(mat[1][3]);
#endif

    //-----------------------------------------------------
    // Repair matrix
    //-----------------------------------------------------

    RepairEntityMatrix(mat);
}

struct TerrainLayerInfo
{
    int materialID;
    float scale;
    int mappingmode;
    uint flags;
};

/*void ExtractTerrainLayerInfo(in uint terrainID, in uint index, out TerrainLayerInfo layerinfo)
{
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#else
    mat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#endif
    uint id = index - matindex * 16;
    uint row = id / 4;
    dFloat f = mat[row][id - row * 4];
#ifdef DOUBLE_FLOAT
    uint i = int(f);
#else
    uint i = floatBitsToUint(f);
#endif
    layerinfo.scale = float(i & 0x000000FF) / 256.0f * 64.0f;
    layerinfo.mappingmode = (i & 0x0000FF00) >> 8;
    layerinfo.materialID = (i & 0xFFFF0000) >> 16;
}*/

void ExtractTerrainLayerInfo(in uint terrainID, in uint index, out TerrainLayerInfo layerinfo)
{
    uint matindex = index / 4;
#ifdef DOUBLE_FLOAT
    dmat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#else
    mat4 mat = entityMatrix[terrainID + TERRAIN_LAYERS_MATRIX_OFFSET + matindex];
#endif
    uint row = index - matindex * 4;
    layerinfo.materialID = floatBitsToInt(mat[row][0]);
    layerinfo.scale = mat[row][1];
    layerinfo.flags = floatBitsToUint(mat[row][2]);
    layerinfo.mappingmode = floatBitsToInt(mat[row][3]);
}

vec4 TerrainSample(in sampler2DArray tex, in vec3 texcoords, in vec3 normal, in int mappingmode, in uint layer)
{
    float l;
    vec4 color[3];
    if (mappingmode != 1)
    {
        color[1] = texture(tex, vec3(texcoords.xz, float(layer)));// horizontal
    }
    if (mappingmode != 0)
    {
        color[0] = texture(tex, vec3(texcoords.zy, float(layer)));// vertical
        color[2] = texture(tex, vec3(texcoords.xy, float(layer)));// vertical
        normal.x = sqrtFast(abs(normal.x));
        normal.z = sqrtFast(abs(normal.z));
    }
    switch (mappingmode)
    {
    case 0://flat
        return color[1];
        break;
    case 1://vertical
        l = 1.0f / ((normal.x) + (normal.z));
        return color[0] * (normal.x) * l + color[2] * (normal.z) * l;
        break;
    case 2://trilinear
        normal.z = sqrtFast(abs(normal.z));
        l = 1.0f / ((normal.x) + (normal.y) + (normal.z));
        return color[0] * (normal.x) * l + color[1] * (normal.y) * l + color[2] * (normal.z) * l;
        break;
    }
}

#endif