#version 450
#ifdef GL_GOOGLE_include_directive
    #extension GL_GOOGLE_include_directive : enable
#endif
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable
//#extension GL_EXT_multiview : enable

#define WRITE_COLOR
#define TESSELLATION

#include "../Base/VertexLayout.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "TerrainInfo.glsl"
#include "Vertex.glsl"