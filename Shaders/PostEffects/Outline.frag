#version 450
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable

#define UNIFORMSTARTINDEX 1

//#include "../Base/PushConstants.glsl"
#include "../Base/CameraInfo.glsl"
//#include "../Base/TextureArrays.glsl"
#include "../Utilities/Dither.glsl"
#include "../Utilities/DepthFunctions.glsl"

layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 20, binding = 0) uniform sampler2DMS DepthBuffer;
//layout(location = 21) uniform ivec4 DrawViewport;
layout(location = 22) uniform vec4 BackgroundColor = vec4(0.0f);
layout(location = 23) uniform vec4 EdgeColor = vec4(1.0f);
layout(location = 24) uniform int Thickness = 3; // should be an odd number

void main()
{
    vec2 BufferSize = vec2(DrawViewport.z, DrawViewport.w);
    vec2 texCoords = gl_FragCoord.xy / BufferSize;
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    outColor = BackgroundColor;

    int count = textureSamples(DepthBuffer);
    
    vec4 c;
    bool sel;
    const int m = max(0, (Thickness - 1) / 2);
    float depth;

    outColor = vec4(0.0f);

    for (int n = 0; n < count; ++n)
    {
        bool done = false;
        depth = texelFetch(DepthBuffer, coord, n).r;

        //Handle selected objects
        if (depth < 1.0f)
        {
            vec2 pixelsize = vec2(1.0f) / BufferSize;

            if (coord.x < m || coord.x > DrawViewport.z - 1 - m || coord.y < m || coord.y > DrawViewport.w - 1 - m)
            {
                outColor += EdgeColor;
                continue;
            }

            for (int x = -m; x <= m; ++x)
            {
                for (int y = -m; y <= m; ++y)
                {
                    if (x == 0 && y == 0) continue;
                    float neighbor = texelFetch(DepthBuffer, coord + ivec2(x, y), n).r;
                    if (neighbor == 1.0f)
                    {
                        outColor += EdgeColor;
                        done = true;
                        break;
                    }
                }                
                if (done) break;
            }
        }
    }

    outColor /= float(count);
}
