#ifndef HSR_OUTLINE_PASS
#define HSR_OUTLINE_PASS
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "HsrRenderFunction.hlsl"

TEXTURE2D(_SdfLightMap);
SAMPLER(sampler_SdfLightMap);
CBUFFER_START(UnityPerMaterial)
    //贴图
    half4 _BaseMap_ST;
    half4 _SdfLightMap_ST;
    half4 _RampMap_Warm_ST;
    half4 _RampMap_Cool_ST;
    //基础参数
    half4 _BaseColor;
    half4 _ShadowColor;
    half4 _SpecularColor;
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
#ifdef _OUTLINENORMALCHANNEL_UV1
    struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
        float3 outlineNormal : TEXCOORD1;
    };
#elif _OUTLINENORMALCHANNEL_UV7
    struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
        float3 outlineNormal : TEXCOORD7;
    };
#elif _OUTLINENORMALCHANNEL_VC
    struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
        float3 outlineNormal : COLOR;
    };
#else
    struct Attributes
    {
        float3 positionOS : POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 uv : TEXCOORD0;
        float3 outlineNormal : NORMAL;
    };
#endif

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
    float3 cameraPostionWS = GetCameraPositionWS();
    float3 biasDir = normalize(outlinePostionWS - cameraPostionWS);
    float biasScale = 1000;
    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    //相机射线方向偏移
    outlinePostionWS += biasDir / biasScale * _OutlineZBias;
    //法线
    float3 normalTS = input.outlineNormal.xyz;
    #if _OUTLINENORMALCOMPRESSION_OCT
        normalTS = normalize(unit_octahedron_to_vector(normalTS.xy*2-1));
    #endif
    float3 normalWS = mul(normalTS, tnb);
    float3 positionVS = TransformWorldToView(outlinePostionWS);
    float3 normalVS = TransformWorldToViewDir(normalWS);
    #if _OUTLINE_ON
        //固定粗细描边模式
        #if _OUTLINETYPE_FIXED_WIDTH
            positionVS += normalize(normalVS) * _OutlineWidth * _OutlineWidthScale;
            output.outlinePostionHCS = TransformWViewToHClip(positionVS);
        //固定像素描边模式
        #elif _OUTLINETYPE_FIXED_PIXEL
            //float3 normalHCS = mul((float3x3)UNITY_MATRIX_VP, normalWS);
            float3 normalHCS = TransformWorldToHClipDir(normalWS);
            output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
            float2 outlineOffset = (_OutlineWidth * output.outlinePostionHCS.w) / (_ScreenParams.xy / 2.0);
            output.outlinePostionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
        //随相机距离自动调整的动态宽度描边模式
        #elif _OUTLINETYPE_DYNAMIC_WIDTH
            float outlineWidth = _OutlineWidth*_OutlineWidthScale;
            float cameraDistance = length(outlinePostionWS - cameraPostionWS);
            outlineWidth = clamp(outlineWidth*cameraDistance, _OutlineMinWidth*_OutlineWidthScale, _OutlineMaxWidth*_OutlineWidthScale);
            positionVS += normalize(normalVS) * outlineWidth;
            output.outlinePostionHCS = TransformWViewToHClip(positionVS);
        #endif
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
            half4 lightMap = SAMPLE_TEXTURE2D(_SdfLightMap, sampler_SdfLightMap, input.uv);
            half outlineArea = lightMap.r;
            clip(lerp(1, -1, outlineArea));
        #endif
        return _OutlineColor;
    #endif
}
#endif