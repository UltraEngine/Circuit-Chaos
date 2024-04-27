#version 450
#extension GL_GOOGLE_include_directive : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shader_draw_parameters : enable

#define TESSELLATION
#define WRITE_COLOR

#include "../Base/VertexLayout.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/TextureArrays.glsl"
#include "TerrainInfo.glsl"
#include "Vertex.glsl"