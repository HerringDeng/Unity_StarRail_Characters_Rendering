#ifndef HSR_CHARACTER_CORE
#define HSR_CHARACTER_CORE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "HsrOutline.hlsl"

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
    #if defined(_AREA_FACE)
        half4 _NoseOutlineColor;
    #endif
    half _Alpha;
    #if defined(_AREA_HAIR)
        half _FrontHairAlpha;
    #endif
    half _AlphaCutOff;
    float _SrcMode;
    float _DstMode;
    float _BlendOp;
    //阴影
    float _CastShadows;
    float _ReceiveShadows;
    float _ShadowIntensity;
    float _ShadowDepthBias;
    float _ShadowNormalBias;
    #if defined(_AREA_HAIR)
        float _HairFakeShadowHorizontalBias;
        float _HairFakeShadowVerticalBias;
        float _HairFakeShadowExtend;
    #endif
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
    // 脸部参数
    #if defined(_AREA_FACE)
        // SDF辅助方位
        float3 _HeadForwardVectorWS;
        float3 _HeadRightVectorWS;
        float3 _HeadUpVectorWS;
        //鼻子描边
        float _NoseOutlineFoVExponent;
        float _NoseOutlineThreshold;
        float _NoseOutlineSoftness;
    #endif
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    half4 color : COLOR;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD3;
    half3 SH : TEXCOORD4;
    float4 shadowCoord : TEXCOORD5;
    float4 positionHCS : SV_POSITION;
};

//blinn-phong高光
half3 BlinnPhongSpecular(float3 lightDirWS, float3 viewDirWS, float3 normalWS, half3 specularColor, float exponent)
{
    float3 h = normalize(lightDirWS + viewDirWS);
    float3 h_dot_n = saturate(dot(h, normalWS));
    float3 modifier = pow(h_dot_n, exponent);
    return specularColor * modifier;
}

float3 ApplySelfShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection, float2 selfShadowBias)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * selfShadowBias.y;
    // normal bias is negative since we want to apply an inset normal offset
    positionWS = positionWS - lightDirection * selfShadowBias.x;
    positionWS = positionWS - normalWS * scale;
    return positionWS;
}

#if defined(_AREA_HAIR)
Varyings HairFakeShadowVert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionHCS.x += _HairFakeShadowHorizontalBias;
    output.positionHCS.y += _HairFakeShadowVerticalBias;
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    float3 viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);  // 区分透视相机和正交相机
    output.viewDirWS = viewDirWS;
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    output.shadowCoord = GetShadowCoord(vertexInput);
    return output;
}

half4 HairFakeShadowFrag(Varyings input) : SV_Target
{
    return _ShadowColor;
}
#endif

Varyings ForwardVert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    float3 viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);  // 区分透视相机和正交相机
    output.viewDirWS = viewDirWS;
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    output.shadowCoord = GetShadowCoord(vertexInput);
    return output;
}

half4 ForwardFrag(Varyings input) : SV_Target
{
    // 输入
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv); //采样颜色贴图
    half3 baseColor = baseMap.rgb * _BaseColor.rgb; //颜色贴图混合基础颜色
    half4 lightMap = SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, input.uv);
    half alpha = _Alpha;
    half4 shadowCoord = input.shadowCoord;
    Light mainLight = GetMainLight(shadowCoord); // 区分透视相机和正交相机
    half3 mainLightColor = mainLight.color;
    float3 mainLightDir = mainLight.direction;

    // 间接光照
    half3 IndirectLightingResult = input.SH;
    IndirectLightingResult *= lerp(1, lightMap.r, _AmbientOcclusionIntensity); //光照图红通道记录环境光遮蔽（AO）信息
    IndirectLightingResult = lerp(IndirectLightingResult, baseColor, _IndirectLightingBaseColorMixing); //环境光颜色混合基础色

    // 漫反射
    half diffuseLightUp = 0;
    half3 diffuseLightingResult = 0;
    #if defined(_AREA_FACE)
        float3 flattenLightDir = normalize(mainLightDir - dot(mainLightDir, _HeadUpVectorWS) * _HeadUpVectorWS);
        float RoL = dot(_HeadRightVectorWS, flattenLightDir);
        float2 sdfUV = float2(-sign(RoL), 1) * input.uv;
        half diffuseLightUpThreshold = 1 - SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, sdfUV).a;
        half FoL = saturate(dot(_HeadForwardVectorWS, flattenLightDir));
        FoL = min(FoL, 1 - _DiffuseLightUpMinGary);
        diffuseLightUp = smoothstep(diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset -_DiffuseLightUpThresholdSoftness, diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset +_DiffuseLightUpThresholdSoftness, FoL);
        #if _RECEIVE_SHADOWS_ON
            half mainLightShadow = MainLightRealtimeShadow(shadowCoord);
            diffuseLightUp = lerp(diffuseLightUp, diffuseLightUp*mainLightShadow, _ShadowIntensity); 
        #endif
        diffuseLightUp = lerp(diffuseLightUp, 1, step(0.2, lightMap.r)); // 眼睛和嘴巴区域始终高亮
        half3 baseShadowColor = lerp(_ShadowColor.rgb, half3(1, 1, 1), diffuseLightUp);
        float2 rampUV = 0;
        rampUV.x = diffuseLightUp;
        rampUV.y = 0.05;
        half3 rampColor = 0;
        #if _RAMPHUETYPE_WARM
            rampColor = SAMPLE_TEXTURE2D(_RampMap_Warm, sampler_RampMap_Warm, rampUV).rgb;
        #endif
        #if _RAMPHUETYPE_COOL
            rampColor = SAMPLE_TEXTURE2D(_RampMap_Cool, sampler_RampMap_Cool, rampUV).rgb;
        #endif
    #else
        half NoL = saturate(dot(input.normalWS, mainLightDir));
        NoL = min(NoL, 1-_DiffuseLightUpMinGary);
        half diffuseLightUpThreshold = 1-lightMap.g; 
        diffuseLightUp = smoothstep(diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset - _DiffuseLightUpThresholdSoftness, diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset + _DiffuseLightUpThresholdSoftness, NoL);
        #if _RECEIVE_SHADOWS_ON
            half mainLightShadow = MainLightRealtimeShadow(shadowCoord);
            diffuseLightUp = lerp(diffuseLightUp, diffuseLightUp*mainLightShadow, _ShadowIntensity); 
        #endif
        half3 baseShadowColor = lerp(_ShadowColor.rgb, half3(1, 1, 1), diffuseLightUp);
        half3 rampColor = 0;
        float2 rampUV = 0;
        rampUV.y = lightMap.a;
        rampUV.x = diffuseLightUp;
        #if _RAMPHUETYPE_WARM
            rampColor = SAMPLE_TEXTURE2D(_RampMap_Warm, sampler_RampMap_Warm, rampUV).rgb;
        #elif _RAMPHUETYPE_COOL
            rampColor = SAMPLE_TEXTURE2D(_RampMap_Cool, sampler_RampMap_Cool, rampUV).rgb;
        #endif
    #endif
    diffuseLightingResult = mainLightColor * baseColor * baseShadowColor * rampColor;

    // 高光计算
    half3 specularColor = 0;
    half3 specularResult = 0;
    #if defined(_AREA_BODY)
        specularColor = lerp(mainLightColor.rgb, baseColor, _Metallic);
        specularColor = lerp(half3(0, 0, 0), specularColor, lightMap.b);
        specularResult = BlinnPhongSpecular(mainLightDir, input.viewDirWS, input.normalWS, specularColor, _SpecularExponent);
    #elif defined(_AREA_HAIR)
        specularColor = lerp(half3(0, 0, 0), baseColor, lightMap.b);
        specularResult = lerp(half3(0, 0, 0), specularColor, diffuseLightUp);
    #endif

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

    //鼻影
    #if defined(_AREA_FACE)
        half3 noseOutlineColor = _NoseOutlineColor.rgb;
        half FoV = pow(abs(dot(_HeadForwardVectorWS, input.viewDirWS)), _NoseOutlineFoVExponent);
        float noseOutlineIntensity = 1.0 + _NoseOutlineThreshold - lightMap.b;
        noseOutlineColor = lerp(half3(1,1,1),  _NoseOutlineColor.rgb, smoothstep(noseOutlineIntensity, noseOutlineIntensity+_NoseOutlineSoftness, FoV));
    #endif
    
    // 最终输出颜色
    half3 albedo = diffuseLightingResult + diffuseLightingResult*IndirectLightingResult * _IndirectLightingIntensity; //基础色
    albedo += specularResult * _SpecularLightingIntensity;
    albedo += emissionResult * _EmissionIntensity; //自发光
    #if defined(_AREA_FACE)
        albedo *= noseOutlineColor;
    #endif
    half4 final = half4(albedo, alpha);
    clip(final.a - _AlphaCutOff);
    return final;
}

#if defined(_AREA_FACE)
    half4 EyesMaskFrag(Varyings input) : SV_Target
    {
        half4 lightMap = SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, input.uv);
        float FoV = dot(_HeadForwardVectorWS, input.viewDirWS);
        if (lightMap.g < 0.2)
        {
            clip(-1);
            return 0;
        }
        else
        {
            clip(lerp(-1, 1, step(0, FoV)));
            half4 final = ForwardFrag(input);
            return final;
        }
    }
#endif

#if defined(_AREA_HAIR)
    half4 HairTransparentFrag(Varyings input) : SV_Target
    {
        half4 final = ForwardFrag(input);
        final.a = _FrontHairAlpha;
        return final;
    }
#endif

half4 GetFinalBaseColor(Varyings input)
{
    return half4((SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv)*_BaseColor).rgb, _Alpha);
}

void DoClipTestToTargetAlphaValue(half alpha) 
{
#if _UseAlphaClipping
    clip(alpha - _AlphaCutOff);
#endif
}

void AlphaClipAndLODTest(Varyings input)
{
    DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif
}

Varyings OutlineVert(Attributes input)
{
    Varyings output;
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    #if _OUTLINE_ON
        OutlineData data;
        data.outlineWidth = _OutlineWidth;
        #if defined(_AREA_FACE)
            VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
            float3 viewDirWS = normalize(GetWorldSpaceViewDir(vertexInput.positionWS));
            float FoV = pow(max(0, dot(_HeadForwardVectorWS, viewDirWS)), 0.8);
            data.outlineWidth *= smoothstep(-0.02, 0, 1 - FoV - input.color.b);
            if(input.color.g > 0.2)
            {
                float RoV = abs(dot(_HeadRightVectorWS, viewDirWS));
                data.outlineWidth *= lerp(1, 0, step(0.93, RoV));
            }
        #endif
        data.outlineZBias = _OutlineZBias;
        data.outlineWidthRangeOffset = _OutlineWidthRangeOffset;
        data.outlineStandardCameraDistance = _OutlineCameraStandardDistance;
        OutlineAttributes outlineInput;
        outlineInput.positionOS = input.positionOS;
        outlineInput.normalOS = input.normalOS;
        outlineInput.tangentOS = input.tangentOS;
        outlineInput.uv1 = input.uv1;
        outlineInput.color = input.color;
        #if _OUTLINETYPE_FIXED_WIDTH
            output.positionHCS = CalculateFixedWidthOutlinePostionHCS(outlineInput, data);
        #elif _OUTLINETYPE_FIXED_PIXEL
            output.positionHCS = CalculateFixedPixelOutlinePostionHCS(outlineInput, data);
        #elif _OUTLINETYPE_DYNAMIC_WIDTH
            output.positionHCS = CalculateDynamicWidthOutlinePostionHCS(outlineInput, data);
        #endif
    #endif
    output.uv = input.uv;
    output.positionWSAndFogFactor = 0;
    output.normalWS = 0;
    output.viewDirWS = 0;
    output.SH = 0;
    output.shadowCoord = 0;
    return output;
}

half4 OutlineFrag(Varyings input) : SV_Target
{
    half4 final = 0;
    #if _OUTLINE_OFF
        clip(-1);
    #elif _OUTLINE_ON
        final = _OutlineColor;
        clip(final.a - _AlphaCutOff);
    #endif
    return final;
}

half DepthOnlyFrag(Varyings input) : SV_Target
{
    AlphaClipAndLODTest(input);
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

    AlphaClipAndLODTest(input);

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

Varyings ShadowCasterVert(Attributes input)
{
    Varyings output;
    Light mainLight = GetMainLight();
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    float3 viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);  // 区分透视相机和正交相机
    output.viewDirWS = viewDirWS;
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    half3 positionWS_Biased = ApplySelfShadowBias(vertexInput.positionWS, vertexNormalInput.normalWS, mainLight.direction, float2(_ShadowDepthBias, _ShadowNormalBias));
    positionWS_Biased = ApplyShadowBias(positionWS_Biased, vertexNormalInput.normalWS, mainLight.direction);
    output.positionHCS = TransformWorldToHClip(positionWS_Biased);
    output.shadowCoord = GetShadowCoord(vertexInput);
    return output;
}

void ShadowCasterFrag(Varyings input)
{
    #if _CAST_SHADOWS_ON
        AlphaClipAndLODTest(input);
    #else
        clip(-1);
    #endif
}
#endif