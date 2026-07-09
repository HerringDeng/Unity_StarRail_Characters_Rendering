#ifndef CARTOON_FORWARD_CORE_HLSL
#define CARTOON_FORWARD_CORE_HLSL
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/Shaders/Tools/ColorTools.hlsl"

//间接光照
//球谐环境光照
half3 CalculateSphericalHarmonicsEnvironmentAlbedo(half3 baseColor, half3 SH, half ambientOcclusion, float aoUsage, float baseColorMixing)
{
    half3 res = SH*lerp(1, ambientOcclusion, aoUsage);
    res = lerp(res, baseColor, baseColorMixing);
    return res;
}

//漫反射
//卡通风格漫反射光照(仅强度)
half CalculateCartoonDiffuseValue(half3 normalWS, half3 mainLightDirWS, half lightThreshold, half thresholdSoftness)
{
    half nol = saturate(dot(normalWS, mainLightDirWS));
    half softBinaryNol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, nol);
    return softBinaryNol;
}
half CalculateCartoonDiffuseValueWithShadow(half3 normalWS, half3 mainLightDirWS, half lightThreshold, half thresholdSoftness, half shadow)
{
    half nol = saturate(dot(normalWS, mainLightDirWS));
    nol = min(nol, shadow); 
    half softBinaryNol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, nol);
    return softBinaryNol;
}
//SDF脸部漫反射光照(仅强度)
half CalculateSdfFaceDiffuseValue(Texture2D sdfMap, SamplerState sdfMapSampler, half2 uv, half3 faceForwardDir, half3 faceUpDir, half3 faceRightDir, half3 mainLightDirWS, half lightThresholdOffset, half thresholdSoftness, bool leftDefault=true)
{
    if(leftDefault)
    {
        uv.x = -uv.x;
    }
    float3 flattenLightDir = normalize(mainLightDirWS - dot(mainLightDirWS, faceUpDir) * faceUpDir);
    float rol = dot(faceRightDir, flattenLightDir);
    float2 sdfUV = float2(sign(rol), 1) * uv;
    half lightThreshold = 1 - SAMPLE_TEXTURE2D(sdfMap, sdfMapSampler, sdfUV).a + lightThresholdOffset;
    half fol = saturate(dot(faceForwardDir, flattenLightDir));
    half softBinaryFol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, fol);
    return softBinaryFol;
}
half CalculateSdfFaceDiffuseValue(half4 sdfColor, half3 faceForwardDir, half3 faceUpDir, half3 mainLightDirWS, half lightThresholdOffset, half thresholdSoftness)
{
    float3 flattenLightDir = normalize(mainLightDirWS - dot(mainLightDirWS, faceUpDir) * faceUpDir);
    half lightThreshold = 1 - sdfColor.a + lightThresholdOffset;
    half fol = saturate(dot(faceForwardDir, flattenLightDir));
    half softBinaryFol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, fol);
    return softBinaryFol;
}
half CalculateSdfFaceDiffuseValueWithShadow(Texture2D sdfMap, SamplerState sdfMapSampler, half2 uv, half3 faceForwardDir, half3 faceUpDir, half3 faceRightDir, half3 mainLightDirWS, half lightThresholdOffset, half thresholdSoftness, half shadow, bool leftDefault=true)
{
    if(leftDefault)
    {
        uv.x = -uv.x;
    }
    float3 flattenLightDir = normalize(mainLightDirWS - dot(mainLightDirWS, faceUpDir) * faceUpDir);
    float rol = dot(faceRightDir, flattenLightDir);
    float2 sdfUV = float2(sign(rol), 1) * uv;
    half lightThreshold = 1 - SAMPLE_TEXTURE2D(sdfMap, sdfMapSampler, sdfUV).a + lightThresholdOffset;
    half fol = saturate(dot(faceForwardDir, flattenLightDir));
    fol = min(fol, shadow);
    half softBinaryFol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, fol);
    return softBinaryFol;
}
half CalculateSdfFaceDiffuseValueWithShadow(half4 sdfColor, half3 faceForwardDir, half3 faceUpDir, half3 mainLightDirWS, half lightThresholdOffset, half thresholdSoftness, half shadow)
{
    float3 flattenLightDir = normalize(mainLightDirWS - dot(mainLightDirWS, faceUpDir) * faceUpDir);
    half lightThreshold = 1 - sdfColor.a + lightThresholdOffset;
    half fol = saturate(dot(faceForwardDir, flattenLightDir));
    fol = min(fol, shadow);
    half softBinaryFol = smoothstep(lightThreshold-thresholdSoftness, lightThreshold+thresholdSoftness, fol);
    return softBinaryFol;
}
//附加主光源阴影
half AttachMainLightShadowToDiffuseValue(half diffuseValue, half mainLightShadow, float shadowUsage, float mask=1)
{
    half res = lerp(diffuseValue, mainLightShadow*diffuseValue, shadowUsage);
    res = lerp(diffuseValue, res, mask);
    return res;
}
//卡通风格漫反射光照
half3 CalculateCartoonDiffuseAlbedo(half diffuseValue, half3 baseColor, half3 darkColor, half3 mainLightColor)
{
    half3 res = baseColor*lerp(darkColor, half3(1, 1, 1), diffuseValue)*mainLightColor;
    return res;
}
//带Ramp阴影的卡通风格漫反射光照
half3 CalculateRampCartoonDiffuseAlbedo(half diffuseValue, half3 baseColor, half3 darkColor, half3 mainLightColor, Texture2D rampMap, SamplerState rampMapSampler, float2 rampUV)
{
    half3 rampColor = SAMPLE_TEXTURE2D(rampMap, rampMapSampler, rampUV).rgb;
    half3 res = CalculateCartoonDiffuseAlbedo(diffuseValue, baseColor, darkColor, mainLightColor) * rampColor;
    return res;
}
half3 CalculateRampCartoonDiffuseAlbedo(half diffuseValue, half3 baseColor, half3 darkColor, half3 mainLightColor, half3 rampColor)
{
    half3 res = CalculateCartoonDiffuseAlbedo(diffuseValue, baseColor, darkColor, mainLightColor) * rampColor;
    return res;
}
//混合冷暖RampMap
half3 BlendCoolWarmRampMap(half3 warmRampColor, half3 coolRampColor, half rampTemperature)
{
    half3 res = lerp(coolRampColor, warmRampColor, rampTemperature);
    return res;
}
//带Ramp阴影的SDF脸部卡通风格漫反射光照
half3 CalculateRampSdfFaceDiffuseAlbedo(half sdfDiffuseLighting, half3 baseColor, half3 darkColor, half3 mainLightColor, Texture2D rampMap, SamplerState rampMapSampler, float2 rampUV)
{
    half3 rampColor = SAMPLE_TEXTURE2D(rampMap, rampMapSampler, rampUV).rgb;
    half3 res = CalculateCartoonDiffuseAlbedo(sdfDiffuseLighting, baseColor, darkColor, mainLightColor) * rampColor;
    return res;
}
half3 CalculateRampSdfFaceDiffuseAlbedo(half sdfDiffuseLighting, half3 baseColor, half3 darkColor, half3 mainLightColor, half3 rampColor)
{
    half3 res = CalculateCartoonDiffuseAlbedo(sdfDiffuseLighting, baseColor, darkColor, mainLightColor) * rampColor;
    return res;
}

//高光
//Blinn-Phong高光(仅强度)
half CalculateBlinnPhongSpecular(half3 normalWS, half3 mainLightDirWS, half3 viewDirWS, float smoothness)
{
    float3 h = normalize(float3(mainLightDirWS) + float3(viewDirWS));
    half noh = half(saturate(dot(normalWS, h)));
    smoothness = exp2(10*smoothness+1);
    half res = pow(noh, smoothness);
    return res;
}
//Blinn-Phong高光
half3 CalculateSpecularAlbedo(half3 baseColor, half3 mainLightColor, half metallic, half3 normalWS, half3 mainLightDirWS, half3 viewDirWS, float smoothness, half mask=1)
{
    half specular = CalculateBlinnPhongSpecular(normalWS, mainLightDirWS, viewDirWS, smoothness);
    half3 specularColor = lerp(mainLightColor.rgb, RGBtoGray(mainLightColor.rgb)*baseColor, metallic);
    half3 res = specularColor * specular * saturate(mask);
    return res;
}
half3 CalculateSpecularAlbedo(half3 baseColor, half3 mainLightColor, half metallic, half specular, half mask=1)
{
    half3 specularColor = lerp(mainLightColor.rgb, RGBtoGray(mainLightColor.rgb)*baseColor, metallic);
    half3 res = specularColor * specular * saturate(mask);
    return res;
}
#endif