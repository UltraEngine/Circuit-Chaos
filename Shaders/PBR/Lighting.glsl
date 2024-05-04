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
#include "../Math/Plane.glsl"

int RenderLight(in uint lightIndex, in Material material, in MaterialInfo materialInfo, in vec3 position, in vec3 normal, in vec3 v, in float NdotV, inout vec3 f_diffuse, inout vec3 f_specular, in bool renderprobes, inout vec4 probediffuse, inout vec4 probespecular)
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
	int lighttype, shadowMap2ID;
	uint shadowMapLayer;
	float attenuation = 1.0f;
	int shadowkernel;
	float cascadedistance;
	dFloat d;
#ifdef DOUBLE_FLOAT
	dvec2 lightrange, coneangles, shadowrange;
#else
	vec2 lightrange, coneangles, shadowrange;
#endif

	ExtractEntityInfo(lightIndex, lightmatrix, color, flags);	
	ExtractLightInfo(lightIndex, shadowMapLayer, shadowMap2ID, lightrange, coneangles, shadowrange, lightflags, shadowkernel, cascadedistance);
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
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(position - lightPosition);
#else
		lightDir = position - lightPosition;
#endif
		float dp = dot(lightDir, normal);
		if (dp > 0.0f) return lighttype;		
		float dist_ = length(lightDir);
		lightDir /= dist_;
		dp = dot((lightDir), (normal));

		mat4 camerainfomatrix = ExtractCameraInfoMatrix(lightIndex, 0);
		float zoom = camerainfomatrix[2].z;

		shadowCoord.xyz = (inverse(lightmatrix) * vec4(position, 1.0f)).xyz;
		shadowCoord.xy /= shadowCoord.z * 2.0f / zoom;
		shadowCoord.y *= -1.0f;
		shadowCoord.xy += 0.5f;
		if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f || shadowCoord.z < lightrange.x || shadowCoord.z > lightrange.y) return lighttype;
		vec3 spotvector = normalize(lightmatrix[2].xyz);
		float anglecos = dot(spotvector, lightDir);
		if (anglecos < coneangles.x) return lighttype;
		if (anglecos < coneangles.y) attenuation *= 1.0f - (abs(anglecos - coneangles.y)) / abs(coneangles.x - coneangles.y);
		attenuation *= DistanceAttenuation(dist_, lightrange.y, falloffmode);
		if (shadowMapLayer != 0 /*&& WorldShadowMapHandle != uvec2(0)*/)
		{
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(lightIndex);
			if (shadowrendermatrix != lightmatrix)
			{
				shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
				shadowCoord.xy /= shadowCoord.z * 2.0f / zoom;
				shadowCoord.y *= -1.0f;
				shadowCoord.xy += 0.5f;
			}
			shadowCoord.z *= 0.98f;
			shadowCoord.z = PositionToDepth(shadowCoord.z, shadowrange);
			shadowCoord.w = shadowCoord.z;
			shadowCoord.z = float(shadowMapLayer - 1);
			//attenuation *= shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
			attenuation *= shadowSample(ShadowmapAtlas, shadowCoord).r;
		}
		break;

	case LIGHT_PROBE:
		if (!renderprobes) return lighttype;
		
		const float padding = 0.01f;
		mat4 lightmat = ExtractEntityMatrix(lightIndex);
		mat4 mat = inverse(lightmat);
		mat3 nmat = mat3(mat);
		vec3 scale = vec3(length(lightmat[0].xyz), length(lightmat[1].xyz), length(lightmat[2].xyz));
		vec3 localposition = (mat * vec4(position.xyz, 1.0f)).xyz;
		if (abs(localposition.x) > 0.5f + padding / scale.x || abs(localposition.y) > 0.5f + padding / scale.y || abs(localposition.z) > 0.5f + padding / scale.z) return lighttype;
		vec3 localnormal = normalize(nmat * normal);
		vec3 influence3 = 1.0f - abs(localposition) * 2.0f;
		mat4 probeinfo = ExtractProbeInfo(lightIndex);

		influence3 = vec3(1.0f);
		for (int i = 0; i < 3; ++i)
		{
			float padding = probeinfo[int(localposition[i] < 0.0f)][i];
			if (padding <= 0.0f) continue;
			float edge = abs(localposition[i]) * 2.0f;
			padding = 2.0f * padding / scale[i];
			float startfade = 1.0f - padding;
			if (edge > startfade)
			{
				influence3[i] = 1.0f - (edge - startfade) / padding;
			}
		}
		
		float influence = influence3.x * influence3.y * influence3.z;
		influence = clamp(influence, 0.0f, 1.0f);
		lightPosition = lightmatrix[3].xyz;

		vec4 cubecoord;
		vec3 localviewdir = normalize(nmat * -v);
		vec4 probesample;
		int u_MipCount;
		float lod;
		vec3 orig;
		float dist;
		cubecoord.w = shadowMapLayer - 1;

		//Diffuse reflection
		if (lightIndex != CameraID)
		{
			orig = localposition + localnormal * 2.0f;
			dist = BoxIntersectsRay(vec3(-0.5f),  vec3(0.5f), orig, -localnormal);
			if (dist >= 0.0f)
			{
				cubecoord.xyz = orig - localnormal * dist;
				float dinfluence = min(influence, 1.0f - probediffuse.a);
				probesample = textureLod(ProbeDiffuseAtlas, cubecoord, 0.0f);
				probesample.rgb = min(probesample.rgb, 2.0f);
				probediffuse.rgb += probesample.rgb * probesample.a * dinfluence * color.rgb;
				probediffuse.a += dinfluence * probesample.a;// * min(color.a, 1.0f);
			}
		}

		//Specular reflection
		if (lightIndex != CameraID)
		{
			vec3 reflection = reflect(localviewdir, localnormal);
			orig = localposition + reflection * 2.0f;
			dist = BoxIntersectsRay(vec3(-0.5f),  vec3(0.5f), orig, -reflection);
			if (dist > 0.0f)
			{
				cubecoord.xyz = orig - reflection * dist;
				vec4 p = Plane(localposition, localnormal);
				//if (PlaneDistanceToPoint(p, cubecoord.xyz) > 0.0f)
				{
					float sinfluence = min(influence, 1.0f - probespecular.a);
					u_MipCount = textureQueryLevels(ProbeSpecularAtlas);
					lod = materialInfo.perceptualRoughness * float(u_MipCount - 1); 
					probesample = textureLod(ProbeSpecularAtlas, cubecoord, lod);
					probesample.rgb = min(probesample.rgb, 2.0f);
					probespecular.rgb += probesample.rgb * probesample.a * sinfluence * color.rgb;					
					probespecular.a += sinfluence * probesample.a;// * min(color.a, 1.0f);
				}
			}
		}

		return lighttype;
		break;

	case LIGHT_POINT:
		lightPosition = lightmatrix[3].xyz;
#ifdef DOUBLE_FLOAT
		lightDir = vec3(position - lightPosition);
#else
		lightDir = position - lightPosition;
#endif
		d = dot(lightDir, lightDir);
		if (d > lightrange.y * lightrange.y) return lighttype;
		if (d > 0.0f)
		{
			d = sqrt(d);
			lightDir /= d;
			if (dot(lightDir, normal) > 0.0f) return lighttype;
			attenuation *= DistanceAttenuation(d, lightrange.y, falloffmode);
			if (attenuation <= minlight) return lighttype;
		}
		if (shadowMapLayer != 0 /*&& WorldShadowMapHandle != uvec2(0)*/)
		{
			shadowCoord.xyz = position - ExtractLightShadowRenderPosition(lightIndex);
			int majoraxis = getMajorAxis(shadowCoord.xyz);
			int face = majoraxis * 2;
			if (shadowCoord[majoraxis] < 0.0f) ++face;
			mat4 lightProjMat = ExtractCameraProjectionMatrix(lightIndex, face);
			shadowCoord.xyw = (lightProjMat * vec4(position, 1.0f)).xyz;
			shadowCoord.xy /= shadowCoord.w * 2.0f;
			shadowCoord.xy += 0.5f;

			float dp = 1.0f - dot(normal, lightDir);
			float angle = radians(90.0f * dp);
			shadowCoord.w *= 0.99f;

			shadowCoord.w = PositionToDepth(shadowCoord.w, lightrange);
			shadowCoord.z = float(shadowMapLayer - 1 + face);
			//attenuation *= textureLod(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord, 0.0f).r;
			//attenuation *= shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;		
			attenuation *= shadowSample(ShadowmapAtlas, shadowCoord).r;	
		}
		break;
		
	case LIGHT_BOX:
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		if (dot(lightDir, normal) > 0.0f) return lighttype;
		shadowCoord.xyz = (inverse(lightmatrix) * vec4(position, 1.0f)).xyz;
		shadowCoord.y *= -1.0f;
		shadowCoord.xy /= coneangles;
		shadowCoord.xy += 0.5f;
		if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f || shadowCoord.z < shadowrange.x || shadowCoord.z > shadowrange.y) return lighttype;
		//f_diffuse = vec3(shadowCoord.z / (lightrange.y - lightrange.x));
		//return 1;
		if (shadowMapLayer != 0 /*&& WorldShadowMapHandle != uvec2(0)*/)
		{
			//shadowCoord.z -= shadowrange.x;
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(lightIndex);
			shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
			shadowCoord.y *= -1.0f;
			shadowCoord.xy /= coneangles;
			shadowCoord.xy += 0.5f;
			shadowCoord.w = (shadowCoord.z - shadowrange.x) / (shadowrange.y - shadowrange.x);
			shadowCoord.w -= 0.001f;
			shadowCoord.z = float(shadowMapLayer.x - 1);
			//attenuation *= shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
			attenuation *= shadowSample(ShadowmapAtlas, shadowCoord).r;
		}
		break;

	case LIGHT_DIRECTIONAL:
#ifdef DOUBLE_FLOAT
		lightDir = vec3(normalize(lightmatrix[2].xyz));
#else
		lightDir = normalize(lightmatrix[2].xyz);
#endif
		if (dot(lightDir, normal) > 0.0f) return lighttype;
		vec3 camspacepos = (CameraInverseMatrix * vec4(position, 1.0)).xyz;
		mat4 shadowmat;
		visibility = 1.0f;
		if (camspacepos.z <= cascadedistance * 8.0f)
		{
			int index = 0;
			shadowmat = ExtractCameraProjectionMatrix(lightIndex, index);
			if (camspacepos.z > cascadedistance) index = 1;
			if (camspacepos.z > cascadedistance * 2.0f) index = 2;
			if (camspacepos.z > cascadedistance * 4.0f) index = 3;
			uint sublight = floatBitsToUint(shadowmat[0][index]);
			mat4 shadowrendermatrix = ExtractLightShadowRenderMatrix(sublight);
			shadowCoord.xyz = (shadowrendermatrix * vec4(position, 1.0f)).xyz;
			shadowCoord.y *= -1.0f;
			ExtractLightInfo(sublight, coneangles, shadowkernel, shadowMapLayer);
			shadowCoord.xy /= coneangles;
			shadowCoord.xy += 0.5f;
			shadowrange = vec2(-500, 500);
			if (shadowCoord.x < 0.0f || shadowCoord.y < 0.0f || shadowCoord.x > 1.0f || shadowCoord.y > 1.0f) return lighttype;
			if (shadowMapLayer != 0 /*&& WorldShadowMapHandle != uvec2(0)*/)
			{
				shadowCoord.w = PositionToLinearDepth(shadowCoord.z, shadowrange);
				shadowCoord.w -= 0.00015f * float(index + 1);	
				shadowCoord.z = float(shadowMapLayer.x - 1);
				//float samp = shadowSample(sampler2DArrayShadow(WorldShadowMapHandle), shadowCoord).r;
				float samp = shadowSample(DirectionalShadowmapAtlas, shadowCoord).r;
				cascadedistance *= 8.0f;
				if (camspacepos.z > cascadedistance * 0.9f) samp = 1.0f - (1.0f - samp) * (1.0 - (camspacepos.z - cascadedistance * 0.9f) / (cascadedistance * 0.1f));
				visibility = samp;
				attenuation *= samp;
			}
		}
		break;
	
	default:
		return lighttype;
		break;
	}

	if (attenuation <= minlight) return lighttype;
	color *= attenuation;
	//specular * attenuation;

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
		f_diffuse += color.rgb * NdotL * BRDF_lambertian(materialInfo.f0, materialInfo.f90, materialInfo.c_diff, materialInfo.specularWeight, VdotH);
		f_specular += specular.rgb * attenuation * NdotL * BRDF_specularGGX(materialInfo.f0, materialInfo.f90, materialInfo.alphaRoughness, materialInfo.specularWeight, VdotH, NdotL, NdotV, NdotH);
	}
}

float RenderLighting(in Material material, in MaterialInfo materialInfo, in vec3 position, in vec3 normal, in vec3 v, in float NdotV, inout vec3 f_diffuse, inout vec3 f_specular, in bool renderprobes, inout vec4 ibldiffuse, inout vec4 iblspecular)
{
	uint n;
    uint lightIndex;
	uint countlights;
	float dirlightshadow = 1.0f;
	float skycolor = 0.0f;

	vec3 cameraspaceposition;
	mat4 cullmat = ExtractCameraCullingMatrix(CameraID);
	cameraspaceposition = (cullmat * vec4(position, 1.0f) ).xyz;

    // Cell lights (affects this cell only)
    int lightlistpos = int(GetCellLightsReadPosition(cameraspaceposition));
    if (lightlistpos != -1)
    {
		uint countlights = ReadLightGridValue(uint(lightlistpos));
		if (countlights > 0)
		{
			for (uint  n = 0; n < countlights; ++n)
			{
				++lightlistpos;
				lightIndex = ReadLightGridValue(uint(lightlistpos));
				RenderLight(lightIndex, material, materialInfo, position, normal, v, NdotV, f_diffuse, f_specular, renderprobes, ibldiffuse, iblspecular);
			}
		}
		++lightlistpos;
    }
	
   	// Global lights (affects all cells)
	if (dirlightshadow > 0.0f)
	{
    	lightlistpos = int(GetGlobalLightsReadPosition());
		uint countlights = ReadLightGridValue(uint(lightlistpos));
    	if (countlights > 0) skycolor = 0.0f;
		if (countlights > 0)
		{
			for (uint n = 0; n < countlights; ++n)
			{
				++lightlistpos;
				lightIndex = ReadLightGridValue(uint(lightlistpos));
				RenderLight(lightIndex, material, materialInfo, position, normal, v, NdotV, f_diffuse, f_specular, false, ibldiffuse, iblspecular);
			}
		}
	}

	//if (ibldiffuse.a < 1.0f) f_diffuse += AmbientLight * materialInfo.c_diff * (1.0f - ibldiffuse.a);
	f_diffuse += AmbientLight * materialInfo.c_diff;
	return skycolor;
}

#endif