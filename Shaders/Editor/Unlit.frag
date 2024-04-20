#version 450
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_separate_shader_objects : enable

#include "../Base/Fragment.glsl"
#include "../Utilities/PackSelectionState.glsl"

void main()
{
    Material material = materials[materialID];
    outColor[0] = material.diffuseColor * color;
    int textureID = GetMaterialTextureHandle(material, TEXTURE_DIFFUSE);
    if (textureID != -1) outColor[0] *= texture(texture2DSampler[textureID], GetMaterialTexCoords(material, texcoords, TEXTURE_DIFFUSE));

    //Camera distance fog
    if ((flags & RENDERNODE_NOFLAGS) == 0) ApplyDistanceFog(outColor[0].rgb, vertexWorldPosition.xyz, CameraPosition);
    
    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0)
    {
        outColor[0].rgb *= outColor[0].a;
        //outColor[0].a = 1.0f;
    }    
}