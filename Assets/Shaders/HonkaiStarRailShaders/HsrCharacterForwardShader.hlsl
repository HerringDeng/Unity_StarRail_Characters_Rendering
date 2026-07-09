#ifndef HSR_CHARACTER_FORWARD_SHADER_HLSL
#define HSR_CHARACTER_FORWARD_SHADER_HLSL
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "HsrCharacterShaderProperties.hlsl"
#include "Assets/Shaders/CartoonRenderCore/CartoonForwardCore.hlsl"
#include "Assets/Shaders/CartoonRenderCore/CartoonSpecialEffect.hlsl"

Varyings Vert(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    output.viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);  // 区分透视相机和正交相机;
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.SH = SampleSH(float3(0,0,0));
    output.shadowCoord = GetShadowCoord(vertexInput);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

half4 Frag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    // 基本参数
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    half3 baseColor = baseMap.rgb * _Color;
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv);
    Light mainLight = GetMainLight(input.shadowCoord); // 区分透视相机和正交相机
    half3 mainLightColor = mainLight.color;
    float3 mainLightDirWS = mainLight.direction;
    half mainLightShadow = MainLightRealtimeShadow(input.shadowCoord);

    // 间接光照
    half3 environmentAlbedo=0;
#if _AREA_BODY||_AREA_HAIR
    environmentAlbedo = CalculateSphericalHarmonicsEnvironmentAlbedo(baseColor, input.SH, lightMap.r, _AmbientOcclusionUsage, _EnvironmentLightingBaseColorMixing)*_EnvironmentLightingIntensity;
#elif _AREA_FACE
    environmentAlbedo = CalculateSphericalHarmonicsEnvironmentAlbedo(baseColor, input.SH, 0, 0, _EnvironmentLightingBaseColorMixing)*_EnvironmentLightingIntensity;
#endif

    // 漫反射
    half diffuseValue = 0;
    float2 rampUV = 0;
    half shadow = 1;
    half shadowMask = 1;
#if _RECEIVESHADOWS_ON
    shadow = mainLightShadow;
#endif
#if _AREA_BODY||_AREA_HAIR
    float diffuseThreshold = lerp(10, 1-lightMap.g, step(0.2, lightMap.g));
    diffuseValue = CalculateCartoonDiffuseValueWithShadow(input.normalWS, mainLightDirWS, diffuseThreshold+_DiffuseThresholdOffset, _DiffuseThresholdSoftness, shadow);
    //diffuseValue = CalculateCartoonDiffuseValue(input.normalWS, mainLightDirWS, diffuseThreshold+_DiffuseThresholdOffset, _DiffuseThresholdSoftness);
    rampUV = float2(diffuseValue, lightMap.a);
#elif _AREA_FACE
    diffuseValue = CalculateSdfFaceDiffuseValueWithShadow(_LightMap, sampler_LightMap, input.uv, _FaceForwardDirWS, _FaceUpDirWS, _FaceRightDirWS, mainLightDirWS, _DiffuseThresholdOffset, _DiffuseThresholdSoftness, shadow);
    //diffuseValue = CalculateSdfFaceDiffuseValue(_LightMap, sampler_LightMap, input.uv, _FaceForwardDirWS, _FaceUpDirWS, _FaceRightDirWS, mainLightDirWS, _DiffuseThresholdOffset, _DiffuseThresholdSoftness);
    shadowMask = 1-step(0.2, lightMap.r);
    diffuseValue = lerp(1, diffuseValue, shadowMask);
    rampUV = float2(diffuseValue, 0.05);
#endif
    half3 coolRampColor = SAMPLE_TEXTURE2D(_RampMap_Cool, sampler_RampMap_Cool, rampUV).rgb;
    half3 warmRampColor = SAMPLE_TEXTURE2D(_RampMap_Warm, sampler_RampMap_Warm, rampUV).rgb;
    half3 rampColor = BlendCoolWarmRampMap(coolRampColor, warmRampColor, _RampMapTemperature);
    half3 diffuseAlbedo = CalculateRampCartoonDiffuseAlbedo(diffuseValue, baseColor, _ShadowColor, mainLightColor, rampColor);

    // 高光计算
    half3 specularAlbedo=0;
#if _AREA_BODY||_AREA_HAIR
    specularAlbedo = CalculateSpecularAlbedo(baseColor, mainLightColor, 1, input.normalWS, mainLightDirWS, input.viewDirWS, _SpecularSmoothness, lightMap.b)*_SpecularIntensity;
#elif _AREA_FACE
    specularAlbedo = 0;
#endif
#if _RECEIVESHADOWS_ON
    specularAlbedo *= mainLightShadow;
#endif

    // 自发光
    half3 emissionColor = CalculateEmissionColor(baseColor, _EmissionColor, _EmissionBaseColorMixing, 1)*_EmissionIntensity;
    half emissionMask = baseMap.a;
    half3 maskEmissionColor = CalculateEmissionColor(baseColor, _MaskEmissionColor, _MaskEmissionBaseColorMixing, emissionMask)*_MaskEmissionIntensity;

    // 深度纹理采样
    float4 positionSS = ComputeScreenPos(input.positionHCS);
    float2 screenUVs = positionSS.xy / positionSS.w;
    float rawDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUVs).r;
    float scene01Depth = Linear01Depth(rawDepth, _ZBufferParams);
    float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);

    // 输出
    half4 final = half4(0, 0, 0, _Alpha);
    final.rgb = environmentAlbedo + diffuseAlbedo + specularAlbedo + emissionColor + maskEmissionColor;
    // final.rgb = half3(1,1,1)*diffuseValue;
    // clip(final.a-_CutOffThreshold);
    return final;
}
#endif