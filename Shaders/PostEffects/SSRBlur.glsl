#include "../Base/CameraInfo.glsl"
#include "../Utilities/DepthFunctions.glsl"

vec4 SSRBlur(vec2 uv, sampler2D tex, sampler2D dtex, sampler2D ntex, float roughness, ivec2 delta)
{
    ivec2 ic = ivec2(uv * textureSize(tex, 0));
    ivec2 ic2 = ivec2(uv * textureSize(dtex, 0));

    vec3 normal = texelFetch(ntex, ic2, 0).rgb;
    float depth = texelFetch(dtex, ic2, 0).r;
    depth = DepthToPosition(depth, CameraRange);

    vec4 color = texelFetch(tex, ic, 0);
    float sumweights = 1.0f;
    float weight;

    int scale = int(float(textureSize(dtex, 0).y) / float(textureSize(tex, 0).y) + 0.5f);
    
    int maxrange = 16;
    int range = int(roughness * float(maxrange) + 0.5f);

    if (range > 0)
    {
        for (int i = -range; i <= range; ++i)
        {
            if (i == 0) continue;

            weight = 1;

            float d = texelFetch(dtex, ic2 + delta * i * scale, 0).r;
            if (d >= 1.0f) continue;
            d = DepthToPosition(d, CameraRange);
            float diff = abs(depth - d);
            if (diff > 0.5f) weight *= max(0.0f, 1.0f - (diff - 0.5f) / 0.5f);
            if (weight <= 0.0f) continue;

            vec3 n = texelFetch(ntex, ic2 + delta * i * scale, 0).rgb;
            weight *= dot(normal,n);
            if (weight <= 0.0f) continue;

            color += texelFetch(tex, ic + delta * i, 0) * weight;
            sumweights += weight;       
        }
    }
    return color / sumweights;
}