#include "../Utilities/ISO646.glsl"
#include "../Base/Fragment.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Base/Materials.glsl"
#include "../Base/UniformBlocks.glsl"
#include "../Khronos/material_info.glsl"
#include "../Khronos/ibl.glsl"
#include "../Khronos/brdf.glsl"
#include "../Khronos/tonemapping.glsl"
#include "../Khronos/punctual.glsl"
#include "../Base/EntityInfo.glsl"
#include "../Utilities/ReconstructPosition.glsl"
#include "../Utilities/Dither.glsl"
#include "../Editor/Grid.glsl"
#ifdef USE_IBL
#include "../Lighting/SSRTrace.glsl"
#endif

#ifdef LIGHTING
#include "Lighting.glsl"
#endif

int textureID;
MaterialInfo materialInfo;
Material material;
vec4 baseColor = vec4(1);

vec3 f_specular = vec3(0.0f);
vec3 f_diffuse = vec3(0.0f);
vec3 f_emissive = vec3(0.0f);
vec3 f_clearcoat = vec3(0.0f);
vec3 f_sheen = vec3(0.0f);
vec3 f_transmission = vec3(0.0f);
float albedoSheenScaling = 1.0f;

void main()
{
    u_EnvIntensity = IBLIntensity;
    material = materials[materialID];
    uint materialFlags = GetMaterialFlags(material);

    // The default index of refraction of 1.5 yields a dielectric normal incidence reflectance of 0.04.
    materialInfo.ior = 1.5f;//ExtractMaterialRefractionIndex(material);
    materialInfo.f0 = vec3(0.04f);//0.04 is default
    materialInfo.specularWeight = 1.0f;
    materialInfo.attenuationDistance = 0.0f;
    materialInfo.attenuationColor = vec3(1.0f);
    materialInfo.thickness = 10.0f;
    materialInfo.transmissionFactor = 1.0f;//GetMaterialTransmission(material);

	//--------------------------------------------------------------------------
    // Diffuse / albedo
    //--------------------------------------------------------------------------
    
    baseColor = material.diffuseColor * color;
    
    if (material.textureHandle[TEXTURE_DIFFUSE] != uvec2(0)) baseColor *= texture(sampler2D(material.textureHandle[TEXTURE_DIFFUSE]), texcoords.xy);
#ifdef ALPHA_DISCARD
    if (baseColor.a < ExtractMaterialAlphaCutoff(material)) discard;
#endif

    materialInfo.baseColor = baseColor.rgb;
    
    //--------------------------------------------------------------------------
    // Normal map
    //--------------------------------------------------------------------------

#ifdef DOUBLE_FLOAT
    dvec3 n = normal;
#else
    vec3 n = normal;
#endif
	if (material.textureHandle[TEXTURE_NORMAL] != uvec2(0))
	{
		vec4 nsample = texture(sampler2D(material.textureHandle[TEXTURE_NORMAL]), texcoords.xy);
        n = nsample.xyz * 2.0f - 1.0f;
        //Extract normal z
        if ((materialFlags & MATERIAL_EXTRACTNORMALMAPZ) != 0) n.z = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.y * n.y)));
        n = tangent.xyz * n.x + bitangent * n.y + normal * n.z;
	}
    n = normalize(n);
    
//outColor[0].rgb = n * 0.5 + 0.5;
//return;

// Used in lighting and transmission
#ifdef DOUBLE_FLOAT
    dvec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#else
    vec3 v = normalize(CameraPosition - vertexWorldPosition.xyz);
#endif
	dFloat NdotV = dot(n, v);

#ifdef MATERIAL_SPECULARGLOSSINESS
	
    //--------------------------------------------------------------------------
    // Specular glossiness
    //--------------------------------------------------------------------------
    
    materialInfo.metallic = 0;
	materialInfo.f0 = material.speculargloss.rgb;
    materialInfo.perceptualRoughness = 1.0f - material.speculargloss.a;
    if (material.textureHandle[TEXTURE_METALLICROUGHNESS] != uvec2(0))
    {
        vec4 sgSample = (texture(sampler2D(material.textureHandle[TEXTURE_METALLICROUGHNESS]), texcoords.xy));
        materialInfo.perceptualRoughness *= 1.0f - sgSample.a; // glossiness to roughness
        materialInfo.f0 *= sgSample.rgb; // specular
    }
    
    materialInfo.c_diff = materialInfo.baseColor.rgb * (1.0f - max(max(materialInfo.f0.r, materialInfo.f0.g), materialInfo.f0.b));
    
#endif

#ifdef MATERIAL_METALLICROUGHNESS

    //--------------------------------------------------------------------------
    // Metallic roughness
    //--------------------------------------------------------------------------

    materialInfo.metallic = material.metalnessRoughness.r;
    materialInfo.perceptualRoughness = material.metalnessRoughness.g;
    
    if (material.textureHandle[TEXTURE_METALLICROUGHNESS] != uvec2(0))
    {
        // Roughness is stored in the 'g' channel, metallic is stored in the 'b' channel.
        // This layout intentionally reserves the 'r' channel for (optional) occlusion map data
        vec4 mrSample = texture(sampler2D(material.textureHandle[TEXTURE_METALLICROUGHNESS]), texcoords.xy);
        materialInfo.metallic *= mrSample.b;
        materialInfo.perceptualRoughness *= mrSample.g;
    }

    materialInfo.perceptualRoughness = clamp(materialInfo.perceptualRoughness, 0.0f, 1.0f);
    materialInfo.metallic = clamp(materialInfo.metallic, 0.0f, 1.0f);    

    // Achromatic f0 based on IOR.
    materialInfo.c_diff = mix(materialInfo.baseColor.rgb,  vec3(0.0f), materialInfo.metallic);
    materialInfo.f0 = mix(materialInfo.f0, materialInfo.baseColor.rgb, materialInfo.metallic);
#endif

    //--------------------------------------------------------------------------
    // Miscellaneous stuff...
    //--------------------------------------------------------------------------
    
    // Roughness is authored as perceptual roughness; as is convention,
    // convert to material roughness by squaring the perceptual roughness.
    materialInfo.alphaRoughness = materialInfo.perceptualRoughness * materialInfo.perceptualRoughness;

    // Compute reflectance.
    float reflectance = max(max(materialInfo.f0.r, materialInfo.f0.g), materialInfo.f0.b);

    // Anything less than 2% is physically impossible and is instead considered to be shadowing. Compare to "Real-Time-Rendering" 4th editon on page 325.
    materialInfo.f90 = vec3(1.0f);

    //--------------------------------------------------------------------------
    // Lighting
    //--------------------------------------------------------------------------

    vec4 ibldiffuse = vec4(0.0f);
    vec4 iblspecular = vec4(0.0f);
	uint cameraflags = ExtractEntityFlags(CameraID);
	bool renderprobes = (RenderFlags & RENDERFLAGS_NO_IBL) == 0;

#ifndef USE_IBL
    renderprobes = false;
#endif

#ifdef LIGHTING
    if ((RenderFlags & RENDERFLAGS_NO_LIGHTING) == 0)
    {
        RenderLighting(material, materialInfo, vertexWorldPosition.xyz, n, v, NdotV, f_diffuse, f_specular, renderprobes, ibldiffuse, iblspecular);
        if (!renderprobes)
        {
            ibldiffuse = vec4(0.0f);
            iblspecular = vec4(0.0f);
            f_specular = vec3(0.0);// we don't want specular reflection in probe renders since it is view-dependent
        }
    }
    else
    {
        renderprobes = false;
        f_diffuse.rgb = materialInfo.c_diff * AmbientLight;
        f_specular = vec3(0.0f);// we don't want specular reflection in probe renders since it is view-dependent
    }    
#else
    f_diffuse.rgb = baseColor.rgb;
#endif

    //--------------------------------------------------------------------------
    // Ambient occlusion
    //--------------------------------------------------------------------------

    // Apply optional PBR terms for additional (optional) shading
	if (material.textureHandle[TEXTURE_AMBIENTOCCLUSION] != uvec2(0))
    {
        float ao = texture(sampler2D(material.textureHandle[TEXTURE_AMBIENTOCCLUSION]), texcoords.xy).r;
        f_diffuse *= ao;

        // apply ambient occlusion to all lighting that is not punctual
        f_specular *=ao;
        f_sheen *= ao;
        f_clearcoat *= ao;
    }

    //--------------------------------------------------------------------------
    // Calculate lighting contribution from image based lighting source (IBL)
    //--------------------------------------------------------------------------

#ifdef USE_IBL

    //Screen-space reflection, only when roughness < 1
    if ((RenderFlags & RENDERFLAGS_SSR) != 0 && ReflectionMapHandles.xy != uvec2(0) && ReflectionMapHandles.zw != uvec2(0))
    {
        if (materialInfo.perceptualRoughness < 1.0f)
        {
            /*{
                vec2 screencoord = gl_FragCoord.xy / BufferSize * 4.0f;
                if (screencoord.x < 1.0f && screencoord.y < 1.0f)
                {
                    float d = textureLod(sampler2D(ReflectionMapHandles.zw), screencoord, 0).r;
                    //d = DepthToPosition(d, CameraRange) / 2.0f;
                    outColor[0].rgb = vec3(d);
                    outColor[0].a = 1.0f;
                    //outColor[0] = textureLod(sampler2D(ReflectionMapHandles.xy), screencoord, 0);
                    return;
                }
            }*/
            vec2 screencoord = gl_FragCoord.xy / BufferSize;
            float ssrblend;
            vec4 ssr = SSRTrace(vertexWorldPosition.xyz, n, materialInfo.perceptualRoughness, sampler2D(ReflectionMapHandles.xy), sampler2D(ReflectionMapHandles.zw), ssrblend);            
            iblspecular = iblspecular * (1.0f - ssrblend) + ssr * ssrblend;
        }
    }

    vec3 prev_f_specular = f_specular;

    if (renderprobes)
    {
        int u_MipCount;
        float lod;

        //Specular reflection
        if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
        {            
            if (iblspecular.a < 1.0f && IBLIntensity > 0.0f)
            {
                //u_MipCount = textureQueryLevels(samplerCube(EnvironmentMap_Specular));
                u_MipCount = textureQueryLevels(SpecularEnvironmentMap);
                lod = materialInfo.perceptualRoughness * float(u_MipCount - 1);
                lod = min(lod, 5);
                //vec3 sky = textureLod(samplerCube(EnvironmentMap_Specular), reflect(-v,n), lod).rgb * (1.0f - iblspecular.a) * IBLIntensity;
                vec3 sky = textureLod(SpecularEnvironmentMap, reflect(-v,n), lod).rgb * (1.0f - iblspecular.a) * IBLIntensity;
                //const float maxbrightness = 16.0f;
                //sky.r = min(sky.r, maxbrightness);
                //sky.g = min(sky.g, maxbrightness);
                //sky.b = min(sky.b, maxbrightness);
                iblspecular.rgb += sky;
            }
            if (iblspecular.r + iblspecular.g + iblspecular.b > 0.0f)
            {
                f_specular += getIBLRadianceGGX(Lut_GGX, iblspecular.rgb, n, v, materialInfo.perceptualRoughness, materialInfo.f0, materialInfo.specularWeight);
            }
        }
        
        //Diffuse reflection
        if ((RenderFlags & RENDERFLAGS_NO_IBL) == 0)
        {
            if (ibldiffuse.a < 1.0f && IBLIntensity > 0.0f)
            {
                ibldiffuse.rgb += textureLod(DiffuseEnvironmentMap, n, 0.0f).rgb * (1.0f - ibldiffuse.a) * IBLIntensity;
            }
            if (ibldiffuse.r + ibldiffuse.g + ibldiffuse.b > 0.0f)
            {
                f_diffuse += getIBLRadianceLambertian(Lut_GGX, ibldiffuse.rgb, n, v, materialInfo.perceptualRoughness, materialInfo.c_diff, materialInfo.f0, materialInfo.specularWeight);
            }
        }

    }
#endif

    //--------------------------------------------------------------------------
    // Emission
    //--------------------------------------------------------------------------

    // Apply optional PBR terms for additional (optional) shading
    if ((RenderFlags & RENDERFLAGS_NO_MATERIAL_EMISSION) == 0)
    {
        f_emissive = material.emissiveColor.rgb;
        if (material.textureHandle[TEXTURE_EMISSION] != uvec2(0))
        {
            f_emissive *= texture(sampler2D(material.textureHandle[TEXTURE_EMISSION]), texcoords.xy).rgb;
        }
    }

    //--------------------------------------------------------------------------
    // Diffuse blend
    //--------------------------------------------------------------------------

    vec3 diffuse = f_diffuse;
    /*if (!Transparency)
    {
        //if ((materialFlags & MATERIAL_BLEND_TRANSMISSION) != 0)
        //{
        //    diffuse = mix(f_diffuse, f_transmission, materialInfo.transmissionFactor);
        //}
        //else
        if ((materialFlags & MATERIAL_BLEND_ALPHA) != 0)
        {
            diffuse = mix(f_transmission, f_diffuse, baseColor.a);
        }
        else
        {
            diffuse = f_diffuse;
        }
    }
    else
    {
        diffuse = f_diffuse;
    }*/

    //--------------------------------------------------------------------------
    // Final blend
    //--------------------------------------------------------------------------

    if ((RenderFlags & RENDERFLAGS_NO_SPECULAR) != 0) f_specular = vec3(0.0f);

    vec3 color = vec3(0.0f);
#ifdef MATERIAL_UNLIT
    color = baseColor.rgb;
#else
    color = diffuse + f_specular;
#ifdef MATERIAL_SHEEN
    color = f_sheen + color * albedoSheenScaling;
#endif
#ifdef MATERIAL_CLEARCOAT
    if (materialInfo.clearcoatFactor > 0.0f)
    {
        vec3 clearcoatFresnel = F_Schlick(materialInfo.clearcoatF0, materialInfo.clearcoatF90, clampedDot(materialInfo.clearcoatNormal, v));
        f_clearcoat *= materialInfo.clearcoatFactor;
        color = color * (1.0f - materialInfo.clearcoatFactor * clearcoatFresnel) + f_clearcoat;
    }
#endif
#endif

    color += f_emissive;

#ifdef DEFERRED_REFLECTIONCOLOR
    //baseColor.a = clamp(baseColor.a, 0.05f, 1.0f);
#endif

    //Camera distance fog
    if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(color.rgb, vertexWorldPosition.xyz, CameraPosition);

    outColor[0] = vec4(color.rgb, baseColor.a);

    int attachmentindex = 0;
    
    //Deferred normals
    if ((RenderFlags & RENDERFLAGS_OUTPUT_NORMALS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = n;// * 0.5f + 0.5f;
        outColor[attachmentindex].a = baseColor.a;
    }

    //Deferred metal / roughness
    if ((RenderFlags & RENDERFLAGS_OUTPUT_METALLICROUGHNESS) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].r = float(SpecularModel);
        outColor[attachmentindex].g = materialInfo.perceptualRoughness;
        outColor[attachmentindex].b = materialInfo.metallic;
        outColor[attachmentindex].a = baseColor.a;
#ifdef PREMULTIPLY_AlPHA
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
        {
            outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        }
#endif
    }

    //Deferred base color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ALBEDO) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = materialInfo.c_diff;
        outColor[attachmentindex].a = baseColor.a;
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
        //    outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }

    //Deferred Z-position
    if ((RenderFlags & RENDERFLAGS_OUTPUT_ZPOSITION) != 0)
    {
        ++attachmentindex;
        float d = PositionToDepth(vertexCameraPosition.z, CameraRange);
        outColor[attachmentindex] = vec4(d, d, d, 1.0f);
        //outColor[attachmentindex] = vec4(1.0f);
    }

    /*//Deferred specular color
    if ((RenderFlags & RENDERFLAGS_OUTPUT_SPECULAR) != 0)
    {
        ++attachmentindex;
        outColor[attachmentindex].rgb = materialInfo.f0;
        outColor[attachmentindex].a = baseColor.a;
        #ifdef PREMULTIPLY_AlPHA
        //if (Transparency)
        //{
         //   outColor[attachmentindex].rgb *= outColor[attachmentindex].a;
        //}
        #endif
    }
    */

    //Reflection color (no specular)
    if ((RenderFlags & RENDERFLAGS_SSR) != 0)
    {
        ++attachmentindex;
        vec3 reflection = diffuse + f_emissive;
        if ((entityflags & ENTITYFLAGS_NOFOG) == 0) ApplyDistanceFog(reflection, vertexWorldPosition.xyz, CameraPosition);
        outColor[attachmentindex].rgb = reflection;
        outColor[attachmentindex].a = clamp(baseColor.a, 0.0f, 1.0f);
        outColor[attachmentindex].r = min(2.0f, outColor[attachmentindex].r);
        outColor[attachmentindex].g = min(2.0f, outColor[attachmentindex].g);
        outColor[attachmentindex].b = min(2.0f, outColor[attachmentindex].b);
        if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) == 0) outColor[attachmentindex].a = 1.0f;
    }

    //Clamp alpha
    outColor[0].a = clamp(outColor[0].a, 0.0f, 1.0f);
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) == 0) outColor[0].a = 1.0f;

    //Editor grid
    if ((cameraflags & ENTITYFLAGS_SHOWGRID) != 0)
    {
        if ((entityflags & ENTITYFLAGS_SHOWGRID) != 0) outColor[0].rgb += WorldGrid(vertexWorldPosition.xyz, normal, d);
    }
    
    //Dither final pass
    if (renderprobes)
    {
        if ((RenderFlags & RENDERFLAGS_FINAL_PASS) != 0)
        {
            outColor[0].rgb += dither(ivec2(gl_FragCoord.x, gl_FragCoord.y));
        }
    }

    // Selection mask - This will display selected objects with a transparent red overlay
    //if ((entityflags & ENTITYFLAGS_SELECTED) != 0) outColor[0].rgb = outColor[0].rgb * 0.5f + vec3(0.5f, 0.0f, 0.0f);

    //Pre-multiply alpha
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) outColor[0].rgb *= outColor[0].a;
    
    //outColor[0].a = outColor[0].a * 0.5f + 0.5f;
    //if ((entityflags & ENTITYFLAGS_SELECTED) != 0) outColor[0].a = 0.5f - outColor[0].a;
}