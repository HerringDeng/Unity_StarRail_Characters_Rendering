#ifndef HSR_CHARACTER_SHADER_PROPERTIES_HLSL
#define HSR_CHARACTER_SHADER_PROPERTIES_HLSL

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap);
SAMPLER(sampler_LightMap);
TEXTURE2D(_RampMap_Warm);
SAMPLER(sampler_RampMap_Warm);
TEXTURE2D(_RampMap_Cool);
SAMPLER(sampler_RampMap_Cool);

CBUFFER_START(UnityPerMaterial)
    //区域
    float _Area;
    //颜色
    half4 _Color;
    //贴图
    half4 _BaseMap_ST;
    half4 _LightMap_ST;
    half4 _RampMap_Warm_ST;
    half4 _RampMap_Cool_ST;
    //透明度
    half _Alpha;
    half _CutOffThreshold;
    //阴影
    half3 _ShadowColor;
    float _ShadowUsage;
    float _ShadowDepthBias;
    float _ShadowNormalBias;
    //漫反射
    float _DiffuseThresholdOffset;
    float _DiffuseThresholdSoftness;
    float _RampMapTemperature;
    float3 _FaceForwardDirWS;
    float3 _FaceRightDirWS;
    float3 _FaceUpDirWS;
    //高光
    float _SpecularIntensity;
    float _SpecularSmoothness;
    //环境光照
    float _EnvironmentLightingIntensity;
    float _AmbientOcclusionUsage;
    float _EnvironmentLightingBaseColorMixing;
    //自发光
    half3 _EmissionColor;
    float _EmissionIntensity;
    float _EmissionBaseColorMixing;
    half3 _MaskEmissionColor;
    float _MaskEmissionIntensity;
    float _MaskEmissionBaseColorMixing;
    //描边
    int _OutlineMode;
    half3 _OutlineColor;
    float _OutlineWidth;
    float _DynamicOutlineWidth;
    float _OutlineZBias;
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1; //《Honkai:StarRail》的“独眼”角色使用uv1控制眼睛不透过头发
    float2 uv2 : TEXCOORD2; //uv2存储八面体压缩后的描边法线
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float3 viewDirWS : TEXCOORD4;
    half3 SH : TEXCOORD5;
    float4 shadowCoord : TEXCOORD6;
    float4 positionHCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
#endif