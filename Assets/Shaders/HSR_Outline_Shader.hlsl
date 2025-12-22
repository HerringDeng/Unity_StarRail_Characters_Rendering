#ifndef HSR_OUTLINE_SHADER
#define HSR_OUTLINE_SHADER
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_LightMapTex);
SAMPLER(sampler_LightMapTex);
TEXTURE2D(_RampTex_warm);
SAMPLER(sampler_RampTex_warm);
TEXTURE2D(_RampTex_cool);
SAMPLER(sampler_RampTex_cool);

CBUFFER_START(UnityPerMaterial)
    half4 _MainTex_ST;
    half4 _LightTex_ST;
    half4 _BaseColor;
    half4 _DarkColor;
    half4 _RampTex_warm_ST;
    half4 _RampTex_cool_ST;

    half _Aphla;
    float _SrcMode;
    float _DstMode;
    float _BlendOp;
    
    float _MainLigthColorIntensity;
    float _NoLMaxThreshold;
    float _RampDarkCenter;
    float _RampDarkSoftness;
    float3 _HeadForwardVector;
    float3 _HeadRightVector;
    float3 _HeadUpVector;
    //高光
    float _SpecularIntensity;
    float _SpecularSmoothness;
    //环境光照
    float _EnvironmentIntensity;
    float _FlattenNormal;
    float _AmbientOcclusionIntensity;
    float _EnvironmentMixBaseIntensity;
    //自发光
    float _UsingEmisionMap;
    half4 _EmissionColor;
    float _EmissionMixBaseColorIntensity;
    float _EmissionIntensity;
    //描边
    half4 _OutlineColor;
    float _OutlineWidth;
    float _OutlineZBias;
    float _DynamicOutlineMinWidth;
    float _DynamicOutlineMaxWidth;
    //鼻影
    float _NoseShadowPow;
    float _NoseShadowDarkness;
    float _NoseShadowGamma;
    float _NoseShadowThreshold;
    float _NoseShadowSoftness;
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float4 uv7 : TEXCOORD7;
};
struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 outlinePostionHCS : SV_POSITION;
};
Varyings Vert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 outlinePostionWS = vertexInput.positionWS;
    //固定粗细描边模式
    #if _OUTLINE_FIXED_MODE
        //相机射线方向偏移
        float3 cameraPostionWS = GetCameraPositionWS();
        float3 biasDir = normalize(outlinePostionWS - cameraPostionWS);
        float biasScale = 1000;
        outlinePostionWS += biasDir / biasScale * _OutlineZBias;
        //法线
        float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
        float3 normalTS = input.uv7.xyz;
        float3 normalWS = mul(normalTS, tnb);
        float3 positionVS = TransformWorldToView(outlinePostionWS);
        float3 normalVS = TransformWorldToViewDir(normalWS);
        float fixWidthScaling = 1100;
        positionVS += normalize(normalVS) * _OutlineWidth / fixWidthScaling;
        output.outlinePostionHCS = TransformWViewToHClip(positionVS);
        //固定像素描边模式
    #elif _OUTLINE_PIXEL_MODE
        //相机射线方向偏移
        float3 cameraPostionWS = GetCameraPositionWS();
        float3 biasDir = normalize(outlinePostionWS - cameraPostionWS);
        float biasScale = 1000;
        outlinePostionWS += biasDir / biasScale * _OutlineZBias;
        //法线
        float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
        float3 normalTS = input.uv7.xyz;
        float3 normalWS = mul(normalTS, tnb);
        float3 positionVS = TransformWorldToView(outlinePostionWS);
        float3 normalVS = TransformWorldToViewDir(normalWS);
        //float3 normalHCS = mul((float3x3)UNITY_MATRIX_VP, normalWS);
        float3 normalHCS = TransformWorldToHClipDir(normalWS);
        output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
        float2 outlineOffset = (_OutlineWidth * output.outlinePostionHCS.w) / (_ScreenParams.xy / 2.0);
        output.outlinePostionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
        //随相机距离自动调整的动态宽度描边模式
    #elif _OUTLINE_DYNAMIC_MODE
        //相机射线方向偏移
        float3 cameraPostionWS = GetCameraPositionWS();
        float3 biasDir = normalize(outlinePostionWS - cameraPostionWS);
        float biasScale = 1000;
        outlinePostionWS += biasDir / biasScale * _OutlineZBias;
        //法线
        float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
        float3 normalTS = input.uv7.xyz;
        float3 normalWS = mul(normalTS, tnb);
        float3 positionVS = TransformWorldToView(outlinePostionWS);
        float3 normalVS = TransformWorldToViewDir(normalWS);
        float fixWidthScaling = 1100;
        float outlineWidth = _OutlineWidth / fixWidthScaling;
        float cameraDistance = length(outlinePostionWS - cameraPostionWS);
        outlineWidth = clamp(outlineWidth * cameraDistance, _DynamicOutlineMinWidth / fixWidthScaling, _DynamicOutlineMaxWidth / fixWidthScaling);
        positionVS += normalize(normalVS) * outlineWidth;
        output.outlinePostionHCS = TransformWViewToHClip(positionVS);
    #else
        output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
    #endif
    output.uv = input.uv;
    return output;
}

half4 Frag(Varyings input) : SV_Target
{
    #if _OUTLINE_OFF
        clip(-1);
        return 0;
    #else
        #if _AREA_FACE
            half4 lightMap = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, input.uv);
            half outlineArea = lightMap.r;
            float clipPara = lerp(1, -1, outlineArea);
            clip(clipPara);
        #endif
        return _OutlineColor;
    #endif
}
#endif