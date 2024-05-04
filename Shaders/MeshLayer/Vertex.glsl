#include "DrawElementsIndirectCommand.glsl"
#include "../Base/Lighting.glsl"

#define MESHLAYER_ALIGN_CENTER 0
#define MESHLAYER_ALIGN_VERTEX 1
#define MESHLAYER_ALIGN_ROTATE 2

//Uniforms
layout(binding = 0) uniform sampler2D elevationmap;
layout(binding = 1) uniform sampler2D normalmap;
layout(location = 15) uniform ivec2 resolution;
layout(location = 16) uniform vec2 spacing = vec2(2.0f);
layout(location = 17) uniform uint offset = 0;
//layout(location = 18) uniform int alignment = MESHLAYER_ALIGN_CENTER;

layout(std430, binding = 8) buffer IndirectDrawBlock { DrawElementsIndirectCommand drawcommands[]; };
layout(binding = 9) buffer DrawInstancesIDBlock { uint instanceids[]; };
layout(binding = 11) buffer MeshLayerNoiseBlock { mat4 meshlayeroffsets[]; };

#include "../Base/Vertex.glsl"
#include "../Base/CameraInfo.glsl"
#include "../Base/VertexLayout.glsl"
#include "../Base/Materials.glsl"

#ifdef IMPOSTER
layout(location = 29) flat out float cameraangle;
layout(location = 30) flat out vec3 suncolor;
layout(location = 31) flat out vec3 sundirection;
#endif

void main()
{
    vec4 p;
    p.xyz = VertexPositionDisplacement.xyz;
    p.w = 1.0f;

    int id = int(instanceids[gl_BaseInstanceARB + gl_InstanceID]);

    int y = id / resolution.x;
    int x = id - resolution.x * y;

    int noiseid = (y % 16) * 16 + (x % 16);
    mat4 noise = meshlayeroffsets[noiseid];

    uint alignment = drawcommands[gl_DrawID + offset].alignment;

    vec2 texcoord;

#ifdef IMPOSTER

    vec3 center;
    center.xz = vec2(x, y) * spacing;
    center.xz -= textureSize(elevationmap, 0) * 0.5f;
    center.y += textureLod(elevationmap, texcoord, 0).r;

    mat4 mat = noise;
    mat[3].xyz = center;

    vec4 relcampos = inverse(mat) * vec4(CameraPosition, 1.0f);
    vec2 d = -normalize(relcampos.xz);

    cameraangle = mod(degrees(atan(d.x, d.y)), 360.0f);
    
    mat3 rotationmat;
    rotationmat[2].xyz = vec3(d.x, 0, d.y);
    rotationmat[1].xyz = vec3(0,1,0);
    rotationmat[0].xyz = cross(rotationmat[2].xyz, rotationmat[1].xyz);

    p.xyz = rotationmat * p.xyz;

#endif

    if (alignment == MESHLAYER_ALIGN_ROTATE || alignment == MESHLAYER_ALIGN_CENTER)
    {
        vec2 center = vec2(x, y) * spacing;
        center += noise[3].xz;    
        texcoord = center / textureSize(elevationmap, 0);
       
        if (alignment == MESHLAYER_ALIGN_ROTATE)
        {
            vec2 ntexcoord = texcoord;

            vec3 n;
            n.xz = textureLod(normalmap, ntexcoord, 0).rg * 2.0f - 1.0f;
            n.y = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.z * n.z)));

            mat3 base;
            
            vec3 i, j, k;

            j = normalize(n);
            if (j.y > 0.99f)
            {
                i = vec3(1,0,0);
                j = vec3(0,1,0);
                k = vec3(0,0,1);
            }
            else
            {
                i = normalize(cross(j, vec3(0,1,0)));
                k = normalize(cross(i, j));
            }
			
            base[0].xyz = i;
            base[1].xyz = j;
            base[2].xyz = k;

            base *= mat3(noise);
            noise[0].xyz = base[0];
            noise[1].xyz = base[1];
            noise[2].xyz = base[2];
        }
    }

    p = noise * p;

    if (alignment == MESHLAYER_ALIGN_VERTEX)
    {
        texcoord = (vec2(x, y) * spacing + p.xz) / textureSize(elevationmap, 0);

#ifndef DEPTHRENDER
        vec3 n;
        n.xz = textureLod(normalmap, texcoord, 0).rg * 2.0f - 1.0f;
        n.y = sqrt(max(0.0f, 1.0f - (n.x * n.x + n.z * n.z)));
        normal = n;
#endif
    }

    p.xz -= textureSize(elevationmap, 0) * 0.5f;
    p.xz += vec2(x, y) * spacing;
    p.y += textureLod(elevationmap, texcoord, 0).r;

    vertexWorldPosition = p;
    flags = 0;

#ifdef WRITE_COLOR
    
    texCoords = VertexTexCoords;

    materialIndex = drawcommands[gl_DrawID + offset].materialID;

    #ifndef DEPTHRENDER
    
    if (alignment != MESHLAYER_ALIGN_VERTEX)
    {
        ExtractVertexNormalTangentBitangent(normal, tangent, bitangent);
        mat3 nmat = mat3(noise);
        //normal = vec3(0,1,0);

        //normal = normalize(nmat * normal);
        tangent = normalize(nmat * tangent);
        bitangent = normalize(nmat * bitangent);
    }

    #endif

#endif

    mat4 cameraProjectionMatrix = ExtractCameraProjectionMatrix(CameraID, 0);
    gl_Position = cameraProjectionMatrix * p;

#ifdef IMPOSTER

    tangent = normalize(noise[0].xyz);
    bitangent = normalize(noise[1].xyz);
    normal = normalize(noise[2].xyz);

    suncolor = vec3(0.0f);
    uint lightlistpos = int(GetGlobalLightsReadPosition());
    uint countlights = ReadLightGridValue(lightlistpos);
    if (countlights > 0)
    {
        ++lightlistpos;
        uint lightIndex = ReadLightGridValue(uint(lightlistpos));
        mat4 lightmatrix;
        vec4 lightcolor;
        uint lightflags;        
        ExtractEntityInfo(lightIndex, lightmatrix, lightcolor, lightflags);
        suncolor = lightcolor.rgb;
        sundirection = normalize(lightmatrix[2].xyz);
    }
#endif

    color = vec4(1.0f);
}