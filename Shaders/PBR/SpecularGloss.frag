#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_bindless_texture : enable

#define MATERIAL_SPECULARGLOSSINESS
#define USE_IBL

const int SpecularModel = 1;

#include "../Base/Settings.glsl"
#include "Fragment.glsl"
