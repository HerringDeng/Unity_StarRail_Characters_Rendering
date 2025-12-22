#ifndef HSR_CalcFunc
#define HSR_CalcFunc
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
half3 BlinnPhongSpecular(half3 lightColor, float3 lightDirWS, float3 viewDirWS, float3 normalWS, half3 specularColor, float smoothness, float specularIntensity)
{
    float3 h = normalize(lightDirWS + viewDirWS);
    float3 h_dot_n = saturate(dot(h, normalWS));
    float3 modifier = pow(h_dot_n, smoothness);
    return lightColor * specularColor * modifier * specularIntensity;
}

//混合颜色
half3 MixColor(half3 a, half3 b, float intensity)
{
    half3 result = lerp(a, b, intensity);
    return result;
}
#endif