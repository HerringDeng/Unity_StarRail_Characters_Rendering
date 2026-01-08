#ifndef HSR_OUTLINE
#define HSR_OUTLINE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct OutlineAttributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float3 outlineNormal : TEXCOORD1;
};

struct OutlineVaryings
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

OutlineVaryings Vert(OutlineAttributes input)
{
    OutlineVaryings output;
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

half4 Frag(OutlineVaryings input) : SV_Target
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