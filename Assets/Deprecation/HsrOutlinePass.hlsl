#ifndef HSR_OUTLINE_PASS
#define HSR_OUTLINE_PASS
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
    float3 outlineNormal : TEXCOORD1;
    float4 color : COLOR;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 outlinePostionHCS : SV_POSITION;
};

float3 UnitOctahedronUVtoNormal(float2 oct, bool negative)
{
    if(!negative)
    {
        oct.xy = oct.xy*2.0-1.0;
    }
    float3 n = float3(oct.xy, 1.0 - abs(oct.x) - abs(oct.y));
    if (n.z < 0.0)
    {
        // 处理折叠区域
        float2 t = float2(1.0 - abs(n.y), 1.0 - abs(n.x));
        n.xy = (oct.xy >= 0.0) ? t : -t;
    }
    return normalize(n);
}

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
    normalTS = normalize(UnitOctahedronUVtoNormal(normalTS.xy, false));
    float3 normalWS = mul(normalTS, tnb);
    float3 normalVS = TransformWorldToViewDir(normalWS);
    normalVS.z = -0.01;
    float3 positionVS = TransformWorldToView(outlinePostionWS);

    #if _OUTLINE_ON
        //固定粗细描边模式
        #if _OUTLINETYPE_FIXED_WIDTH
            positionVS += normalize(normalVS) * _OutlineWidth * _OutlineWidthScale * input.color.a;
            output.outlinePostionHCS = TransformWViewToHClip(positionVS);
        //固定像素描边模式
        #elif _OUTLINETYPE_FIXED_PIXEL
            //float3 normalHCS = mul((float3x3)UNITY_MATRIX_VP, normalWS);
            float3 normalHCS = TransformWorldToHClipDir(normalWS);
            output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
            float2 outlineOffset = (_OutlineWidth * output.outlinePostionHCS.w * input.color.a) / (_ScreenParams.xy / 2.0);
            output.outlinePostionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
        //随相机距离自动调整的动态宽度描边模式
        #elif _OUTLINETYPE_DYNAMIC_WIDTH
            float outlineWidth = _OutlineWidth*_OutlineWidthScale*input.color.a;
            float cameraDistance = length(outlinePostionWS - cameraPostionWS);
            outlineWidth = clamp(outlineWidth*cameraDistance, _OutlineMinWidth*_OutlineWidthScale*input.color.a, _OutlineMaxWidth*_OutlineWidthScale*input.color.a);
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
        return _OutlineColor;
    #endif
}
#endif