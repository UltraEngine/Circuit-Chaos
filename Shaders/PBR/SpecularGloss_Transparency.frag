#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_bindless_texture : enable

#define USE_IBL
//#define LINEAR_OUTPUT
#define MATERIAL_SPECULARGLOSSINESS
#define LIGHTING
//#define MATERIAL_TRANSMISSION
#define DEFERRED_NORMALS 1
#define DEFERRED_METALLICROUGHNESS 2
#define DEFERRED_REFLECTIONCOLOR 3

const int SpecularModel = 1;

#include "Fragment.glsl"