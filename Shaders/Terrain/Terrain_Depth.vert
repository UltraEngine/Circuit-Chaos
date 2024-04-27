#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable
#ifdef GL_GOOGLE_include_directive
    #extension GL_GOOGLE_include_directive : enable
#endif

#define WRITE_COLOR

#include "../Base/VertexLayout.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "TerrainInfo.glsl"
#include "Vertex.glsl"