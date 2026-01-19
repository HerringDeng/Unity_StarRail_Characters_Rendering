#ifndef HSR_SHADER_FUNCTION
#define HSR_SHADER_FUNCTION
//半兰伯特
half LightingHalfLambert(half3 lightDirWS, half3 normalWS)
{
    half NdotL = saturate(dot(normalWS, lightDirWS));//范围 0.0 - 1.0
    half diffuseDark = pow(NdotL * 0.5 + 0.5, 2.0);
    return diffuseDark;
}

//去色函数
half3 desaturation(half3 color, half3 glayXfer = half3(0.3, 0.59, 0.11))
{
    return dot(color, glayXfer);
}

//blinn-phong高光
half3 BlinnPhongSpecular(float3 lightDirWS, float3 viewDirWS, float3 normalWS, half3 specularColor, float exponent)
{
    float3 h = normalize(lightDirWS + viewDirWS);
    float3 h_dot_n = saturate(dot(h, normalWS));
    float3 modifier = pow(h_dot_n, exponent);
    return specularColor * modifier;
}

//混合颜色
half3 MixColor(half3 a, half3 b, float intensity)
{
    half3 result = lerp(a, b, intensity);
    return result;
}

float3 UnitOctahedronUVtoNormal(float2 oct, bool negative)
{
    if(!negative)
    {
        oct.xy = oct.xy*2.0-1.0;
    }
    float3 n = float3(oct.xy, 1.0 - abs(oct.x) - abs(oct.y));
    if (n.z < 0.0)
    {
        // 处理折叠区域
        float2 t = float2(1.0 - abs(n.y), 1.0 - abs(n.x));
        n.xy = (oct.xy >= 0.0) ? t : -t;
    }
    return normalize(n);
}

#endif