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
    half4 _NoseOutlineColor;
    half _Alpha;
    float _SrcMode;
    float _DstMode;
    float _BlendOp;
    //漫反射
    float _DiffuseLightUpMinGary;
    float _DiffuseEyesMouthArea;
    float _DiffuseLightUpThresholdOffset;
    float _DiffuseLightUpThresholdSoftness;
    // SDF辅助方位
    float3 _HeadForwardVector;
    float3 _HeadRightVector;
    float3 _HeadUpVector;
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
    float _OutlineWidthScale;
    float _OutlineMinWidth;
    float _OutlineMaxWidth;
    float _OutlineZBias;
    //鼻子描边
    float _NoseOutlineVofExponent;
    float _NoseOutlineThreshold;
    float _NoseOutlineSoftness;
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD3;
    half3 SH : TEXCOORD4;
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

Varyings Vert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    output.viewDirWS = unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz;  // 区分透视相机和正交相机
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    return output;
}

half4 Frag(Varyings input) : SV_Target
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
    #if _AREA_BODY | _AREA_HAIR
        half NoL = saturate(dot(input.normalWS, mainLightDir));
        NoL = min(NoL, 1-_DiffuseLightUpMinGary);
        half diffuseLightUpThreshold = 1-lightMap.g; 
        diffuseLightUp = smoothstep(diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset - _DiffuseLightUpThresholdSoftness, diffuseLightUpThreshold + _DiffuseLightUpThresholdOffset + _DiffuseLightUpThresholdSoftness, NoL);
        rampUV.y = lightMap.a;
    #elif _AREA_FACE
        float3 flattenLightDir = normalize(mainLightDir - dot(mainLightDir, _HeadUpVector) * _HeadUpVector);
        float RoL = dot(_HeadRightVector, flattenLightDir);
        float2 sdfUV = float2(-sign(RoL), 1) * input.uv;
        half diffuseLightUpThreshold = 1-SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, sdfUV).a;
        half FoL = saturate(dot(_HeadForwardVector, flattenLightDir));
        FoL = min(FoL, 1-_DiffuseLightUpMinGary);
        diffuseLightUp = smoothstep(diffuseLightUpThreshold+_DiffuseLightUpThresholdOffset-_DiffuseLightUpThresholdSoftness, diffuseLightUpThreshold+_DiffuseLightUpThresholdOffset+_DiffuseLightUpThresholdSoftness, FoL);
        diffuseLightUp = lerp(diffuseLightUp, 1, step(_DiffuseEyesMouthArea, lightMap.r));
        rampUV.y = 0.08;
    #endif
    half3 baseShadowColor = lerp(_ShadowColor.rgb, half3(1, 1, 1), diffuseLightUp);
    rampUV.x = diffuseLightUp;
    half3 rampColor = 0;
    #if _RAMPHUETYPE_WARM
        rampColor = SAMPLE_TEXTURE2D(_RampMap_Warm, sampler_RampMap_Warm, rampUV).rgb;
    #endif
    #if _RAMPHUETYPE_COOL
        rampColor = SAMPLE_TEXTURE2D(_RampMap_Cool, sampler_RampMap_Cool, rampUV).rgb;
    #endif
    diffuseLightingResult = mainLightColor * baseColor * baseShadowColor * rampColor;

    // 高光计算
    half3 specularColor = 0;
    half3 specularResult = 0;
    #if _AREA_BODY  
        specularColor = lerp(mainLightColor.rgb, baseColor, _Metallic);
        specularColor = lerp(half3(0, 0, 0), specularColor, lightMap.b);
        specularResult = BlinnPhongSpecular(mainLightDir, input.viewDirWS, input.normalWS, specularColor, _SpecularExponent);
    #elif _AREA_HAIR //非真实高光
        
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
    half noseOutlineIntensity = 0;
    half3 noseOutlineColor = _NoseOutlineColor.rgb;
    #if _AREA_FACE
        half3 cameraForward = TransformViewToWorld(half3(0, 0, 1));
        half VoF = saturate(dot(_HeadForwardVector, cameraForward));
        VoF = pow(VoF, _NoseOutlineVofExponent);
        noseOutlineIntensity = VoF * lightMap.b;
        noseOutlineIntensity = smoothstep(_NoseOutlineThreshold-_NoseOutlineSoftness, _NoseOutlineThreshold+_NoseOutlineSoftness, noseOutlineIntensity);
    #endif
    
    // 最终输出颜色
    half3 albedo = diffuseLightingResult + diffuseLightingResult*IndirectLightingResult * _IndirectLightingIntensity; //基础色
    albedo += specularResult * _SpecularLightingIntensity;
    albedo += emissionResult * _EmissionIntensity; //自发光
    #if _AREA_FACE
        albedo = lerp(albedo, noseOutlineColor, noseOutlineIntensity);
    #endif
    // 测试输出
    half4 final_color = half4(albedo, alpha);
    return final_color;
}
#endif