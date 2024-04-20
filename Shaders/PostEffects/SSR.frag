#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_EXT_multiview : enable
#define MATERIAL_TRANSMISSION

//Includes
#include "../Base/TextureArrays.glsl"
#include "../Base/PushConstants.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/LightInfo.glsl"
#include "../Math/AABB.glsl"
#include "../Base/Lighting.glsl"
#include "../Math/Plane.glsl"
#include "../Utilities/ISO646.glsl"
#include "../Utilities/DepthFunctions.glsl"

//#define GBUFFER_MSAA
#include "SSRTrace.glsl"

//Inputs
layout(location = 0) in vec2 texCoords;

//Outputs
layout(location = 0) out vec4 outColor;

int PrevPassTextureID = PostEffectTexture0;
int DepthTextureID = PostEffectTexture1;
int NormalTextureID = PostEffectTexture2;
int MetallicRoughnessTextureID = PostEffectTexture3;
int BaseColorTextureID = PostEffectTexture4;
int TemporalSmoothingTextureID = PostEffectTexture5;

void main(void)
{
    outColor = vec4(0.0f);
#ifdef GBUFFER_MSAA
    vec4 metallicroughness = texture(texture2DMSSampler[MetallicRoughnessMSTextureID], texCoords, 0);
    vec3 fragposition;// = GetFragmentWorldPosition(texture2DMSSampler[DepthTextureID]);
    vec3 normal = texture(texture2DMSSampler[NormalTextureID],texCoords,0).rgb;
    vec3 basecolor = texture(texture2DMSSampler[BaseColorTextureID], texCoords, 0).rgb;
#else
    vec4 metallicroughness = texture(texture2DSampler[MetallicRoughnessTextureID], texCoords, 0);
    vec3 fragposition;// = GetFragmentWorldPosition(texture2DSampler[DepthTextureID]);
    vec3 normal = textureLod(texture2DSampler[NormalTextureID],texCoords,0).rgb;
	vec4 albedo = texture(texture2DSampler[BaseColorTextureID], texCoords, 0);
    vec3 basecolor = albedo.rgb;
#endif

	//Extract depth and reconstruct Z component of normal
	//float z = abs(normal.z / albedo.a); 
	//normal.z = sign(normal.z) * sqrt(1.0f - normal.x * normal.x - normal.y * normal.y);
    float roughness = metallicroughness.g;
	float metallic = metallicroughness.b;

	//Matrices
	//mat4 modelprojectionmatrix = ExtractCameraProjectionMatrix(CameraID, gl_ViewIndex);// projection matrix X camera matrix
    //mat4 projectionmatrix = modelprojectionmatrix * CameraMatrix;// isolate the projection matrix
	//mat4 inverseprojectionmatrix = inverse(projectionmatrix);
	//mat4 inversemodelprojectionmatrix = inverse(modelprojectionmatrix);

	/*//Construct gl_FragCoord equivalent
	vec4 fragpos;
	fragpos.xy = gl_FragCoord.xy / BufferSize * 2.0f - 1.0f;// convert to -1, 1 range
	fragpos.z = texelFetch(texture2DSampler[DepthTextureID], ivec2(gl_FragCoord.xy), 0).r;// get the depth at this coord
	//fragpos.z = (fragpos.z - 0.0f) / (1.0 - 0.0f);// not necessary
	fragpos.w = 1.0f;

	//Convert fragcoord to gl_Position equivalent
	vec4 glposition = fragpos;
	glposition.z = glposition.z * 2.0f - glposition.w;// opposite of gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5f;

	//Convert gl_Position equivalent to vertex position
	vec4 worldspaceposition = InverseCameraProjectionViewMatrix * glposition;
	worldspaceposition.xyz /= worldspaceposition.w;
	worldspaceposition.w = 1.0f;
	
	fragposition = worldspaceposition.xyz;*/

	vec2 texsize = textureSize(texture2DSampler[DepthTextureID], 0);
	vec3 screencoord;
	screencoord.xy = gl_FragCoord.xy / BufferSize;
	screencoord.z = texelFetch(texture2DSampler[DepthTextureID], ivec2(gl_FragCoord.xy / BufferSize * texsize), 0).r;// get the depth at this coord;
	if (screencoord.z >= 1.0f) return;
	fragposition = ScreenCoordToWorldPosition(screencoord);

    vec3 v = normalize(CameraPosition - fragposition);
    vec3 r = reflect(-v, normal);

    float speccutoff = 0.02;
    //vec3 color = getIBLRadianceGGX(texture2DSampler[Lut_GGX], vec3(1), normal, v, roughness, specularcolor, 1.0f);
    //if (color.r <= speccutoff and color.g <= speccutoff and color.b <= speccutoff) return;

    //Scene color
    //outColor = textureLod(texture2DSampler[IncomingDiffuseTextureID], gl_FragCoord.xy / BufferSize, 0);
	
	vec4 ssr = vec4(0);
	if (roughness < MAX_ROUGHNESS)
	{
#ifdef GBUFFER_MSAA
		int samples = textureSamples(texture2DMSSampler[DepthTextureID]);
		for (int n = 0; n < samples; ++n)
		{
			ssr += SSRTrace(fragposition, texCoords, texture2DSampler[PrevPassTextureID], texture2DMSSampler[DepthTextureID], texture2DMSSampler[NormalMSTextureID], texture2DSampler[NormalTextureID], texture2DMSSampler[MetallicRoughnessMSTextureID], texture2DMSSampler[SpecularColorMSTextureID], n);
		}
		ssr /= float(samples);
#else
		ssr = SSRTrace(fragposition, texCoords, texture2DSampler[PrevPassTextureID], texture2DSampler[DepthTextureID], texture2DSampler[NormalTextureID], texture2DSampler[MetallicRoughnessTextureID], texture2DSampler[BaseColorTextureID]);
#endif
		if (roughness < MAX_ROUGHNESS * 0.75f)
		{
			ssr *= 1.0f - clamp((roughness - MAX_ROUGHNESS * 0.75f) / (MAX_ROUGHNESS * 0.25f), 0.0f, 1.0f);
		}
	}
	outColor = ssr;

	//vec4 last = textureLod(texture2DSampler[TemporalSmoothingTextureID],texCoords,0);
	//outColor = outColor * 0.5f + last * 0.5f;
}