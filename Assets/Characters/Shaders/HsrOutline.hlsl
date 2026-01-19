#ifndef HSR_OUTLINE
#define HSR_OUTLINE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define _OUTLINE_WIDTH_SCALE 0.0009

struct OutlineData
{
    float outlineWidth;
    float outlineZBias;
    // dynamic outline only below
    float outlineStandardCameraDistance;
    float outlineWidthRangeOffset;
};

struct OutlineAttributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float4 color : COLOR;
};

struct OutlineVaryings
{
    float2 uv : TEXCOORD0;
    float4 outlinePostionHCS : SV_POSITION;
};

float3 TransformOctahedronUVtoNormalTS(float2 oct, bool negative)
{
    if(!negative)
    {
        oct.xy = oct.xy*2.0-1.0;
    }
    float3 n = float3(oct.xy, 1.0 - abs(oct.x) - abs(oct.y));
    if (n.z < 0.0)
    {
        float2 t = float2(1.0 - abs(n.y), 1.0 - abs(n.x));
        n.xy = (oct.xy >= 0.0) ? t : -t;
    }
    return normalize(n);
}

float3 TransfromOctahedronUVtoNormalVS(float2 oct, float3x3 tnb, bool negative)
{
    float3 n = TransformOctahedronUVtoNormalTS(oct, negative);
    n = mul(n, tnb);
    n = TransformWorldToViewDir(n);
    return n;
}

float4 CalculateFixedWidthOutlinePostionHCS(OutlineAttributes input, OutlineData data)
{
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    float3 normalVS = TransfromOctahedronUVtoNormalVS(input.uv1, tnb, false);
    normalVS.z = -0.01;
    // calculate camera bias
    float3 cameraPostionWS = GetCameraPositionWS();
    float3 biasDirWS = normalize(vertexInput.positionWS - cameraPostionWS);
    float3 biasWS = biasDirWS * data.outlineZBias/1000;
    float3 biasPostionWS = vertexInput.positionWS + biasWS;
    float3 biasPositionVS = TransformWorldToView(biasPostionWS);
    // calculate outline position
    float3 outlinePostionVS = biasPositionVS + normalize(normalVS) * data.outlineWidth * _OUTLINE_WIDTH_SCALE * input.color.a;
    return TransformWViewToHClip(outlinePostionVS);
}

float4 CalculateFixedPixelOutlinePostionHCS(OutlineAttributes input, OutlineData data)
{
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    float3 normalVS = TransfromOctahedronUVtoNormalVS(input.uv1, tnb, false);
    normalVS.z = -0.01;
    // calculate camera bias
    float3 cameraPostionWS = GetCameraPositionWS();
    float3 biasDirWS = normalize(vertexInput.positionWS - cameraPostionWS);
    float3 biasWS = biasDirWS * data.outlineZBias/1000;
    float3 biasPostionWS = vertexInput.positionWS + biasWS;
    float4 biasPostionHCS = TransformWorldToHClip(biasPostionWS);
    // calculate outline position
    float3 normalWS = TransformViewToWorldDir(normalVS);
    float3 normalHCS = TransformWorldToHClipDir(normalWS);
    float2 outlineOffset = (data.outlineWidth * biasPostionHCS.w * input.color.a) / (_ScreenParams.xy / 2.0);
    float4 outlinePostionHCS = biasPostionHCS;
    outlinePostionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
    return outlinePostionHCS;
}

float4 CalculateDynamicWidthOutlinePostionHCS(OutlineAttributes input, OutlineData data)
{
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    float3 normalVS = TransfromOctahedronUVtoNormalVS(input.uv1, tnb, false);
    normalVS.z = -0.01;
    // calculate camera bias
    float3 cameraPostionWS = GetCameraPositionWS();
    float cameraDistance = length(vertexInput.positionWS - cameraPostionWS);
    float cameraDistanceScale = cameraDistance/data.outlineStandardCameraDistance;
    float3 biasDirWS = normalize(vertexInput.positionWS - cameraPostionWS);
    float3 biasWS = biasDirWS * data.outlineZBias/1000;
    float3 biasPostionWS = vertexInput.positionWS + biasWS;
    float3 biasPositionVS = TransformWorldToView(biasPostionWS);
    // calculate outline position
    float outlineWidth = data.outlineWidth*_OUTLINE_WIDTH_SCALE*input.color.a*cameraDistanceScale;
    float outlineMinWidth = (data.outlineWidth-data.outlineWidthRangeOffset)*_OUTLINE_WIDTH_SCALE*input.color.a;
    float outlineMaxWidth = (data.outlineWidth+data.outlineWidthRangeOffset)*_OUTLINE_WIDTH_SCALE*input.color.a;
    outlineWidth = clamp(outlineWidth, outlineMinWidth, outlineMaxWidth);
    float3 outlinePositionVS = biasPositionVS + normalize(normalVS) * outlineWidth;
    return TransformWViewToHClip(outlinePositionVS);
}

// OutlineVaryings OutlineVert(OutlineAttributes input)
// {
//     OutlineVaryings output;
//     // fill outline function;
//     output.uv = input.uv;
//     return output;
// }

// half4 OutlineFrag(OutlineVaryings input) : SV_Target
// {
//     #if _OUTLINE_OFF
//         clip(-1);
//         return 0;
//     #else
//         return _OutlineColor;
//     #endif
// }
#endif