#ifndef CARTOON_SPECIAL_EFFECT_HLSL
#define CARTOON_SPECIAL_EFFECT_HLSL

//自发光
half3 CalculateEmissionColor(half3 emissionColor, half3 baseColor, half baseColorMixing, half mask=1)
{
    half3 res = lerp(emissionColor, baseColor, baseColorMixing) * saturate(mask);
    return res;
}
//卡通鼻子描边(仅强度)
half CalculateNoseLine(half3 faceForwardDirWS, half3 viewDirWS, half noseLineThreshold, half noseLineSoftness)
{
    half fov = saturate(dot(faceForwardDirWS, viewDirWS));
    half softBinaryFov = smoothstep(noseLineThreshold-noseLineSoftness, noseLineThreshold+noseLineSoftness, fov);
    return softBinaryFov;
}
//附加卡通鼻子描边到渲染结果
half4 AttachNoseLineColor(half4 renderRes, half3 noseLineColor, half3 faceForwardDirWS, half3 viewDirWS, half noseLineThreshold, half noseLineSoftness, half mask=0)
{
    half noseLine = CalculateNoseLine(faceForwardDirWS, viewDirWS, noseLineThreshold, noseLineSoftness);
    half4 res = half4(lerp(renderRes.rgb, noseLineColor, noseLine * saturate(mask)), renderRes.a);
    return res;
}
half4 AttachNoseLineColor(half4 renderRes, half3 noseLineColor, half noseLine, half mask=0)
{
    half4 res = half4(lerp(renderRes.rgb, noseLineColor, noseLine * saturate(mask)), renderRes.a);
    return res;
}
#endif