#ifndef _PBR_LIGHTING
#define _PBR_LIGHTING

#include "../Khronos/functions.glsl"
#include "../Khronos/material_info.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/LightInfo.glsl"
#include "../Base/Lighting.glsl"
#include "../Khronos/ibl.glsl"
#include "../Math/FloatPrecision.glsl"
#include "../Utilities/ISO646.glsl"
#include "../Math/AABB.glsl"

void RenderLight(in uint lightIndex, in Material material, in MaterialInfo materialInfo, in vec3 position, in vec3 normal, in vec3 v, in float NdotV, inout vec3 f_diffuse, inout vec3 f_specular, inout vec4 probediffuse, inout vec4 probespecular)//, inout vec3 f_clearcoat, inout vec3 f_sheen, inout float albedoSheenScaling)
{
	float visibility = 0.0f;
	int ShadowSoftness = 4;
	const float minlight = 0.004f;
	vec3 lightDir, lightPosition;
	vec4 shadowCoord, color;
	vec4 specular;
	bool transparent = false;
	mat4 lightmatrix;
	uint flags, lightflags;
	int shadowMapID, lighttype, shadowcachemapID;
	float attenuation = 1.0f;
	dFloat d;
#ifdef DOUBLE_FLOAT
	dvec2 lightrange, coneangles, shadowrange;
#else
	vec2 lightrange, coneangles, shadowrange;
#endif
	ExtractEntityInfo(lightIndex, lightmatrix, color, flags);	
	ExtractLightInfo(lightIndex, shadowMapID, shadowcachemapID, lightrange, coneangles, shadowrange, lightflags);
	specular = color;

	const int falloffmode = ((lightflags & ENTITYFLAGS_LIGHT_LINEARFALLOFF) != 0) ? LIGHTFALLOFF_LINEAR : LIGHTFALLOFF_INVERSESQUARE;
	if ((lightflags & ENTITYFLAGS_LIGHT_STRIP) != 0) lighttype = LIGHT_STRIP; // This needs to come first because the flag is a combination of others
	else if ((lightflags & ENTITYFLAGS_LIGHT_BOX) != 0) lighttype = LIGHT_BOX;
	else if ((lightflags & ENTITYFLAGS_LIGHT_DIRECTIONAL) != 0) lighttype = LIGHT_DIRECTIONAL;
	else if ((lightflags & ENTITYFLAGS_LIGHT_SPOT) != 0) lighttype = LIGHT_SPOT;
	else if ((lightflags & ENTITYFLAGS_LIGHT_PROBE) != 0) lighttype = LIGHT_PROBE;
	else lighttype = LIGHT_POINT;

	switch (lighttype)
	{
	case LIGHT_SPOT:
		break;

	/*case LIGHT_PROBE:
		mat4 mat = ExtractEntityMatrix(lightIndex);
		vec3 localposition = (inverse(mat) * vec4(position.xyz, 1.0f)).xyz;
		vec3 localnormal = normalize(mat3(mat) * normal);
		float influence = 1.0f - max(abs(localposition.x), max(abs(localposition.y), abs(localposition.z))) * 2.0f;
		if (influence <= -0.001f) return;
		if (shadowMapID == -1) return;// this should never happen
		influence=1;
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = normalize(vec3(position - lightPosition));
#else
		lightDir = normalize(position - lightPosition);
#endif
		
		//Diffuse reflection
		float dinfluence = min(influence, 1.0f - probediffuse.a);

		AABB bounds;
		bounds.min = vec3(-0.5f);
		bounds.max = vec3(0.5f);
		AABBUpdate(bounds);
		float dist;
		if (!AABBIntersectsRay2(bounds, localposition + localnormal * 20.0f, -localnormal * 20.0f, dist))
		{
			f_diffuse = vec3(1,0,1);
			return;
		};

		vec4 probesample = texture(textureCubeSampler[shadowMapID], lightDir);
		color.rgb *= probesample.rgb * probesample.a * dinfluence;
		probediffuse.a += dinfluence * probesample.a;
		f_diffuse = color.rgb;
		return;

		//Specular reflection
		float sinfluence = min(influence, 1.0f - probespecular.a);
		probesample = texture(textureCubeSampler[shadowMapID], reflect(normal, v));
		specular.rgb *= probesample.rgb * probesample.a * sinfluence;
		probespecular.a += sinfluence * probesample.a;
		specular = vec4(0);

		break;*/
		
	case LIGHT_POINT:
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(position - lightPosition);
#else
		lightDir = position - lightPosition;
#endif
		d = dot(lightDir, lightDir);
		if (d > lightrange.y * lightrange.y) return;
		if (d > 0.0f)
		{
			d = sqrt(d);
			lightDir /= d;
			if (dot(lightDir, normal) > 0.0f) return;
			attenuation *= DistanceAttenuation(d, lightrange.y, falloffmode);
			if (attenuation <= minlight) return;
		}
		if (shadowMapID != -1)
		{
			shadowCoord.xyz = position - ExtractLightShadowRenderPosition(lightIndex);
#ifdef USE_VSM
			shadowCoord.w = abs(shadowCoord[ getMajorAxis(shadowCoord.xyz) ]);
			attenuation *= vsmLookup( textureCubeStorageSampler[shadowMapID], shadowCoord, shadowrange);
#else
			int majoraxis = getMajorAxis(shadowCoord.xyz);
			int face = majoraxis * 2;
			if (shadowCoord[majoraxis] < 0.0f) ++face;
			mat4 lightProjMat = ExtractCameraProjectionMatrix(lightIndex, face);
			shadowCoord.xyw = (lightProjMat * vec4(position, 1.0f)).xyz;
			shadowCoord.xy /= shadowCoord.w * 2.0f;
			shadowCoord.xy += 0.5f;
			shadowCoord.w = PositionToDepth(shadowCoord.w, lightrange);
			shadowCoord.z = face;
			attenuation *= shadowSample16x( textureCubeShadowSampler[shadowMapID], shadowCoord);
#endif
		}
		break;

	case LIGHT_BOX:
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		if (dot(lightDir, normal) > 0.0f) return;
		shadowCoord.xyz = (inverse(lightmatrix) * vec4(position, 1.0f)).xyz;
		shadowCoord.y *= -1.0f;
		shadowCoord.xy += 0.5f;
		if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f || shadowCoord.z < lightrange.x || shadowCoord.z > lightrange.y) return;
		if (shadowMapID != -1)
		{
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(lightIndex);
			shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
			shadowCoord.y *= -1.0f;
			shadowCoord.xy += 0.5f;
			attenuation *= shadowSample(texture2DShadowSampler[shadowMapID], shadowCoord.xyz).r;
		}
		break;

	case LIGHT_DIRECTIONAL:
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		if (dot(lightDir, normal) > 0.0f) return;
		vec3 camspacepos = (CameraInverseMatrix * vec4(position, 1.0)).xyz;
		mat4 shadowmat;
		visibility = 1.0f;
		if (camspacepos.z <= 80.0)
		{
			int index = 0;
			shadowmat = ExtractCameraProjectionMatrix(lightIndex, index);
			if (camspacepos.z > CameraRange.x + 10.0) index = 1;
			if (camspacepos.z > CameraRange.x + 20.0) index = 2;
			if (camspacepos.z > CameraRange.x + 40.0) index = 3;
			uint sublight = floatBitsToUint(shadowmat[0][index]);
			shadowmat = ExtractEntityMatrix(sublight);
			shadowCoord.xyz = (inverse(shadowmat) * vec4(position, 1.0)).xyz;
			shadowCoord.y *= -1.0f;
			shadowCoord.xy += 0.5f;
			shadowMapID = ExtractLightShadowMapIndex(sublight);
			float samp = shadowSample(texture2DShadowSampler[shadowMapID], shadowCoord.xyz).r;
			if (camspacepos.z > CameraRange.x + 60.0)
			{
				samp = 1.0f - (1.0f - samp) * (1.0 - (camspacepos.z - 60.0) / 20.0);
			}
			visibility = samp;
			attenuation *= samp;
		}
		break;
		
	default:
		return;
	}

	if (attenuation <= minlight) return;
	color *= attenuation;

	vec3 pointToLight = -lightDir;
	vec3 n = normal;

	// BSTF
	vec3 l = pointToLight; // Direction from surface point to light
	vec3 h = normalize(l + v); // Direction of the vector between l and v, called halfway vector
	float NdotL = clampedDot(n, l);
	float NdotH = clampedDot(n, h);
	float LdotH = clampedDot(l, h);
	float VdotH = clampedDot(v, h);
	if (NdotL > 0.0f || NdotV > 0.0f)
	{
		// Calculation of analytical light
		// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#acknowledgments AppendixB
		vec3 intensity = color.rgb;
#ifdef MATERIAL_IRIDESCENCE
		f_diffuse += color.rgb * NdotL *  BRDF_lambertianIridescence(materialInfo.f0, materialInfo.f90, iridescenceFresnel, materialInfo.iridescenceFactor, materialInfo.c_diff, materialInfo.specularWeight, VdotH);
		f_specular += specular.rgb * NdotL * BRDF_specularGGXIridescence(materialInfo.f0, materialInfo.f90, iridescenceFresnel, materialInfo.alphaRoughness, materialInfo.iridescenceFactor, materialInfo.specularWeight, VdotH, NdotL, NdotV, NdotH);
#else
		f_diffuse += color.rgb * NdotL * BRDF_lambertian(materialInfo.f0, materialInfo.f90, materialInfo.c_diff, materialInfo.specularWeight, VdotH);
		f_specular += specular.rgb * NdotL * BRDF_specularGGX(materialInfo.f0, materialInfo.f90, materialInfo.alphaRoughness, materialInfo.specularWeight, VdotH, NdotL, NdotV, NdotH);
#endif

#ifdef MATERIAL_SHEEN
		if (Lut_Sheen != -1 and (material.sheen.r > 0.0f or material.sheen.g > 0.0f or material.sheen.b > 0.0f))
		{
			f_sheen += color.rgb * getPunctualRadianceSheen(materialInfo.sheenColorFactor, materialInfo.sheenRoughnessFactor, NdotL, NdotV, NdotH);
				albedoSheenScaling = min(1.0f - max3(materialInfo.sheenColorFactor) * albedoSheenScalingLUT(texture2DSampler[Lut_Sheen], NdotV, materialInfo.sheenRoughnessFactor),
				1.0f - max3(materialInfo.sheenColorFactor) * albedoSheenScalingLUT(texture2DSampler[Lut_Sheen], NdotL, materialInfo.sheenRoughnessFactor));
		}
#endif

#ifdef MATERIAL_CLEARCOAT
		if (material.clearcoat.r > 0.0f)
		{
			f_clearcoat += color.rgb * getPunctualRadianceClearCoat(materialInfo.clearcoatNormal, v, l, h, VdotH, materialInfo.clearcoatF0, materialInfo.clearcoatF90, materialInfo.clearcoatRoughness);
		}
#endif
	}
}

float RenderLighting(in Material material, in MaterialInfo materialInfo, in vec3 position, in vec3 normal, in vec3 v, in float NdotV, inout vec3 f_diffuse, inout vec3 f_specular, inout vec2 probeinfluence)//, inout vec3 f_clearcoat, inout vec3 f_sheen, inout float albedoSheenScaling)
{
	uint n;
    uint lightIndex;
	uint countlights;
	float dirlightshadow = 1.0f;
	float skycolor = 0.0f;
	vec4 probediffuse = vec4(0.0f);
	vec4 probespecular = vec4(0.0f);

//if (LightGridOffset > 0)
//{
//f_diffuse = vec3(1,0,0);
//return;
//}

    // Cell lights (affects this cell only)
    uint lightlistpos = GetCellLightsReadPosition(vertexCameraPosition.xyz);
    if (lightlistpos != -1)
    {
		countlights = ReadLightGridValue(lightlistpos);
        for (n = 0; n < countlights; ++n)
        {
            ++lightlistpos;
            lightIndex = ReadLightGridValue(lightlistpos);
			RenderLight(lightIndex, material, materialInfo, vertexWorldPosition.xyz, normal, v, NdotV, f_diffuse, f_specular, probediffuse, probespecular);
			//, f_clearcoat, f_sheen, albedoSheenScaling);
        }
		++lightlistpos;
    }

   	// Global lights (affects all cells)
	if (dirlightshadow > 0.0f)
	{
    	lightlistpos = GetGlobalLightsReadPosition();
		countlights = ReadLightGridValue(lightlistpos);
    	if (countlights > 0) skycolor = 0.0f;
		for (n = 0; n < countlights; ++n)
    	{
        	++lightlistpos;
        	lightIndex = ReadLightGridValue(lightlistpos);
        	RenderLight(lightIndex, material, materialInfo, vertexWorldPosition.xyz, normal, v, NdotV, f_diffuse, f_specular, probediffuse, probespecular);//, f_clearcoat, f_sheen, albedoSheenScaling);		
    	}
	}
	
	probeinfluence.x = probediffuse.a;
	probeinfluence.y = probespecular.a;

	f_diffuse += AmbientLight * materialInfo.c_diff;
	return skycolor;
}
#endif