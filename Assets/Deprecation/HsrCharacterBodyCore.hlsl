#ifndef HSR_FORWARDLIT_PASS
#define HSR_FORWARDLIT_PASS
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_SdfLightMap);
SAMPLER(sampler_SdfLightMap);
TEXTURE2D(_RampMap_Warm);
SAMPLER(sampler_RampMap_Warm);
TEXTURE2D(_RampMap_Cool);
SAMPLER(sampler_RampMap_Cool);

CBUFFER_START(UnityPerMaterial)
    //贴图
    half4 _BaseMap_ST;
    half4 _SdfLightMap_ST;
    half4 _RampMap_Warm_ST;
    half4 _RampMap_Cool_ST;
    //基础参数
    half4 _BaseColor;
    half4 _ShadowColor;
    half4 _OutlineColor;
    half _Alpha;
    half _AlphaCutOff;
    float _SrcMode;
    float _DstMode;
    float _BlendOp;
    //漫反射
    float _DiffuseLightUpMinGary;
    float _DiffuseLightUpThresholdOffset;
    float _DiffuseLightUpThresholdSoftness;
    //高光
    float _Metallic;
    float _SpecularLightingIntensity;
    float _SpecularExponent;
    //环境光照
    float _IndirectLightingIntensity;
    float _FlattenNormal;
    float _AmbientOcclusionIntensity;
    float _IndirectLightingBaseColorMixing;
    //自发光
    half4 _EmissionColor;
    float _EmissionIntensity;
    float _EmissionBaseColorMixing;
    //描边
    float _OutlineWidth;
    float _OutlineZBias;
    float _OutlineWidthRangeOffset;
    float _OutlineCameraStandardDistance;
CBUFFER_END

#include "HsrForwardVert.hlsl"

half4 ForwardFrag(Varyings input) : SV_Target
{
    // 输入
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv); //采样颜色贴图
    half3 baseColor = baseMap.rgb * _BaseColor.rgb; //颜色贴图混合基础颜色
    half4 lightMap = SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, input.uv);
    half alpha = _Alpha;
    Light mainLight = GetMainLight();
    half3 mainLightColor = mainLight.color;
    float3 mainLightDir = mainLight.direction;

    // 间接光照
    half3 IndirectLightingResult = input.SH;
    IndirectLightingResult *= lerp(1, lightMap.r, _AmbientOcclusionIntensity); //光照图红通道记录环境光遮蔽（AO）信息
    IndirectLightingResult = lerp(IndirectLightingResult, baseColor, _IndirectLightingBaseColorMixing); //环境光颜色混合基础色

    // 漫反射
    half diffuseLightUp = 0;
    half3 diffuseLightingResult = 0;
    float2 rampUV = 0;
    half NoL = saturate(dot(input.normalWS, mainLightDir));
    NoL = min(NoL, 1-_DiffuseLightUpMinGary);
    half diffuseLightUpThreshold = 1-lightMap.g; 
    diffuseLightUp = smoothstep(diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset - _DiffuseLightUpThresholdSoftness, diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset + _DiffuseLightUpThresholdSoftness, NoL);
    half3 baseShadowColor = lerp(_ShadowColor.rgb, half3(1, 1, 1), diffuseLightUp);
    half3 rampColor = 0;
    rampUV.y = lightMap.a;
    rampUV.x = diffuseLightUp;
    #if _RAMPHUETYPE_WARM
        rampColor = SAMPLE_TEXTURE2D(_RampMap_Warm, sampler_RampMap_Warm, rampUV).rgb;
    #elif _RAMPHUETYPE_COOL
        rampColor = SAMPLE_TEXTURE2D(_RampMap_Cool, sampler_RampMap_Cool, rampUV).rgb;
    #endif
    diffuseLightingResult = mainLightColor * baseColor * baseShadowColor * rampColor;

    // 高光计算
    half3 specularColor = 0;
    half3 specularResult = 0;
    specularColor = lerp(mainLightColor.rgb, baseColor, _Metallic);
    specularColor = lerp(half3(0, 0, 0), specularColor, lightMap.b);
    specularResult = BlinnPhongSpecular(mainLightDir, input.viewDirWS, input.normalWS, specularColor, _SpecularExponent);

    // 自发光
    half3 emissionResult = 0;
    #if _EMISSION_ON
        half emission_area = 1;
        #if _EMISSIONTYPE_PARTLY
            emission_area = step(0.2, baseMap.a);
        #endif
        half3 emissionColor = lerp(_EmissionColor.rgb, baseColor, _EmissionBaseColorMixing); //与基础色混合
        emissionResult = lerp(half3(0, 0, 0), emissionColor, emission_area);
    #endif
    
    // 最终输出颜色
    half3 albedo = diffuseLightingResult + diffuseLightingResult*IndirectLightingResult * _IndirectLightingIntensity; //基础色
    albedo += specularResult * _SpecularLightingIntensity;
    albedo += emissionResult * _EmissionIntensity; //自发光
    half4 final = half4(albedo, alpha); // Forward Rendering Result
    // Alpha Cut Off
    clip(final.a - _AlphaCutOff);
    return final;
}

#include "HsrOutline.hlsl"
// OutlineVaryings OutlineVert(OutlineAttributes input)
// {
//     OutlineVaryings output;
//     output.outlinePositionHCS = TransformObjectToHClip(input.positionOS.xyz);
//     #if _OUTLINE_ON
//         OutlineData data;
//         data.outlineWidth = _OutlineWidth;
//         data.outlineZBias = _OutlineZBias;
//         data.outlineWidthRangeOffset = _OutlineWidthRangeOffset;
//         data.outlineStandardCameraDistance = _OutlineCameraStandardDistance;
//         #if _OUTLINETYPE_FIXED_WIDTH
//             output.outlinePositionHCS = CalculateFixedWidthOutlinePostionHCS(input, data);
//         #elif _OUTLINETYPE_FIXED_PIXEL
//             output.outlinePositionHCS = CalculateFixedPixelOutlinePostionHCS(input, data);
//         #elif _OUTLINETYPE_DYNAMIC_WIDTH
//             output.outlinePositionHCS = CalculateDynamicWidthOutlinePostionHCS(input, data);
//         #endif
//     #endif
//     output.uv = input.uv;
//     return output;
// }

// half4 OutlineFrag(OutlineVaryings input) : SV_Target
// {
//     half4 final = 0;
//     #if _OUTLINE_OFF
//         clip(-1);
//     #elif _OUTLINE_ON
//         final = _OutlineColor;
//         clip(final.a - _AlphaCutOff);
//     #endif
//     return final;
// }

Varyings DepthOnlyVert(OutlineAttributes input)
{
    Varyings output;
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    #if _OUTLINE_ON
        OutlineData data;
        data.outlineWidth = _OutlineWidth;
        data.outlineZBias = _OutlineZBias;
        data.outlineWidthRangeOffset = _OutlineWidthRangeOffset;
        data.outlineStandardCameraDistance = _OutlineCameraStandardDistance;
        #if _OUTLINETYPE_FIXED_WIDTH
            output.positionHCS = CalculateFixedWidthOutlinePostionHCS(input, data);
        #elif _OUTLINETYPE_FIXED_PIXEL
            output.positionHCS = CalculateFixedPixelOutlinePostionHCS(input, data);
        #elif _OUTLINETYPE_DYNAMIC_WIDTH
            output.positionHCS = CalculateDynamicWidthOutlinePostionHCS(input, data);
        #endif
    #endif
    output.uv = input.uv;
    return output;
}

half DepthOnlyFrag(Varyings input) : SV_Target
{
    clip(_Alpha-_AlphaCutOff);
    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionHCS);
    #endif
    return input.positionHCS.z;
}

void DepthNormalsFrag(
    Varyings input
    , out half4 outNormalWS : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
#endif
)
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    clip(_Alpha-_AlphaCutOff);
    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionHCS);
    #endif

    #if defined(_GBUFFER_NORMALS_OCT)
        float3 normalWS = normalize(input.normalWS);
        float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
        float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
        half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
        outNormalWS = half4(packedNormalWS, 0.0);
    #else
        float2 uv = input.uv;
        #if defined(_PARALLAXMAP)
            #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS = input.viewDirTS;
            #else
                half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
            #endif
            ApplyPerPixelDisplacement(viewDirTS, uv);
        #endif

        #if defined(_NORMALMAP) || defined(_DETAIL)
            float sgn = input.tangentWS.w;      // should be either +1 or -1
            float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
            float3 normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

            #if defined(_DETAIL)
                half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
                float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
                normalTS = ApplyDetailNormal(detailUv, normalTS, detailMask);
            #endif

            float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
        #else
            float3 normalWS = input.normalWS;
        #endif

        outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
    #endif

    #ifdef _WRITE_RENDERING_LAYERS
        uint renderingLayers = GetMeshRenderingLayer();
        outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}
#endif