#version 460
#extension GL_ARB_bindless_texture : enable

#include "../Base/CameraInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Khronos/functions.glsl"
#include "../Khronos/brdf.glsl"
#include "../Khronos/material_info.glsl"
#include "../Khronos/ibl.glsl"
#include "../Base/CameraInfo.glsl"
 
layout(location = 0) out vec4 outcolor;
layout(location = 1) in vec3 normal;
layout(location = 3) in vec3 tangent;
layout(location = 4) in vec3 bitangent;
layout(location = 2) in vec4 texcoords; 
layout(location = 5) in flat uint materialID;
layout(location = 7) in vec4 vertexWorldPosition;

layout(location = 30) flat in vec3 suncolor;
layout(location = 31) flat in vec3 sundirection;
layout(location = 29) flat in float cameraangle;

const uint ditherpattern[64] = {
    1, 32,  8, 40,  2, 34, 10, 42,   /* 8x8 Bayer ordered dithering  */
    48, 16, 56, 24, 50, 18, 58, 26,  /* pattern.  Each input pixel   */
    12, 44,  4, 36, 14, 46,  6, 38,  /* is scaled to the 0..63 range */
    60, 28, 52, 20, 62, 30, 54, 22,  /* before looking in this table */
    3, 35, 11, 43,  1, 33,  9, 41,   /* to determine the action.     */
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21 };

float dither(ivec2 coord)
{
	int dithercoord = coord.x * 8 + coord.y;
	dithercoord = dithercoord % 64;
	return float(ditherpattern[dithercoord]) / 63.0f;
}

void main()
{
    vec4 basecolor = vec4(1,0,1,1);
    vec3 n;

    if (materialID != 0)
    {
        float d = dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));

        const int sides = 32;

        float w = 0.0f;
        float w0, w1, m;
        Material mtl = materials[materialID];
        if (mtl.textureHandle[0] != uvec2(0))
        {
            //ivec3 tsize = textureSize(sampler2DArray(mtl.textureHandle[0]), 0);// using this causes AMD 6600 to stop rendering
            //w = cameraangle / 360.0f * float(tsize.z) + 0.5f;
            w = cameraangle / 360.0f * float(sides);
            w0 = int(w);
            w1 = w0 + 1;
            w0 = mod(w0, float(sides));
            w1 = mod(w1, float(sides));
            m = mod(w, 1.0f);
            if (d > m)
            {
                w = w0;
            }
            else
            {
                w = w1;
            }
            basecolor = texture(sampler2DArray(mtl.textureHandle[0]), vec3(texcoords.xy, w));
            if (basecolor.a < ExtractMaterialAlphaCutoff(mtl)) discard;
        }
        if (mtl.textureHandle[1] != uvec2(0))
        {
            n = normalize(texture(sampler2DArray(mtl.textureHandle[1]), vec3(texcoords.xy, w)).rgb * 2.0f - 1.0f);
            mat3 nmat = mat3(tangent, bitangent, normal);
            n = nmat * n;
        }
    }

    MaterialInfo materialinfo;
    materialinfo.f0 = vec3(0.04f);
    materialinfo.f90 = vec3(1.0);
    materialinfo.specularWeight = 0.0;
    materialinfo.c_diff = basecolor.rgb;
    materialinfo.perceptualRoughness = 1.0f;

    vec3 specular = vec3(0);

    //if (dot(n, sundirection) > 0.0f) n *= -1.0f;

	// BSTF
    const float attenuation = 0.5f;
    vec3 cnv = normalize(CameraPosition - vertexWorldPosition.xyz);
	dFloat NdotV = dot(n, cnv);
    vec3 f_diffuse = vec3(0.0f);
    vec3 f_specular = vec3(0.0f);
    vec3 v = vertexWorldPosition.xyz;
	vec3 l = -sundirection; // Direction from surface point to light
	vec3 h = normalize(l + v); // Direction of the vector between l and v, called halfway vector
	float NdotL = clampedDot(n, l);
	float NdotH = clampedDot(n, h);
	float LdotH = clampedDot(l, h);
	float VdotH = clampedDot(v, h);
	if (NdotL > 0.0f || NdotV > 0.0f)
	{
		f_diffuse += suncolor * NdotL * BRDF_lambertian(materialinfo.f0, materialinfo.f90, materialinfo.c_diff, materialinfo.specularWeight, VdotH);
		//f_specular += specular.rgb * attenuation * NdotL * BRDF_specularGGX(materialinfo.f0, materialinfo.f90, materialinfo.alphaRoughness, materialinfo.specularWeight, VdotH, NdotL, NdotV, NdotH);
	}
    else
    {
        //outcolor = vec4(1,0,1,1);
        //return;
    }

    //Diffuse reflection
    vec3 ibldiffuse;
    //if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
    {
        if (IBLIntensity > 0.0f)
        {
            ibldiffuse += textureLod(DiffuseEnvironmentMap, n, 0.0f).rgb * IBLIntensity;
        }
        if (ibldiffuse.r + ibldiffuse.g + ibldiffuse.b > 0.0f)
        {
            f_diffuse += getIBLRadianceLambertian(Lut_GGX, ibldiffuse, n, v, materialinfo.perceptualRoughness, materialinfo.c_diff, materialinfo.f0, materialinfo.specularWeight);
        }
    }

    outcolor.rgb = f_diffuse + f_specular;
    outcolor.a = basecolor.a;

    //Camera distance fog
    //if ((entityflags & ENTITYFLAGS_NOFOG) == 0)
    ApplyDistanceFog(outcolor.rgb, vertexWorldPosition.xyz, CameraPosition);
}