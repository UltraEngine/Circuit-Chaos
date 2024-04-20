#version 450

// Uniforms
layout(location = 0) uniform sampler2DMS colorattachment0;
layout(location = 1) uniform sampler2DMS depthattachment;

// Outputs
layout(location = 0) out vec4 outColor;

void main()
{
    ivec2 coord = ivec2(gl_FragCoord.x, gl_FragCoord.y);
    int samples = textureSamples(colorattachment0);

    vec4 c = vec4(0.0f);    
    for (int n = 0; n < samples; ++n)
    {
        c += texelFetch(colorattachment0, coord, n);
    }
    outColor = c / float(samples);
    //outColor.r = 1.0f;
    //if (samples == 1) outColor.g =  1.0f;

    outColor = texelFetch(colorattachment0, coord, 0);

    gl_FragDepth = texelFetch(depthattachment, coord, 0).r;
}