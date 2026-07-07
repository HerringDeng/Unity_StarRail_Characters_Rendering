#ifndef CARTOON_OUTLINE_TOOLS
#define CARTOON_OUTLINE_TOOLS

float4 CalculateWidthOutlinePostionHCS(float3 positionWS, float3 normalWS, float width, float3 zBiasWS, half4 color)
{
    float3 normalVS = TransformWorldToView(normalWS);
    float3 zBiasPositionVS = TransformWorldToView(positionWS + zBiasWS);
    zBiasPositionVS += normalVS * width * color.a;
    return TransformWViewToHClip(zBiasPositionVS);
}

float4 CalculateWidthOutlinePostionHCS(float3 positionWS, float3 normalTS, float3x3 tnbWS, float width, float3 zBiasWS, half4 color)
{
    float3 normalWS = mul(normalTS, tnbWS);
    return CalculateWidthOutlinePostionHCS(positionWS, normalWS, width, zBiasWS, color);
}

float4 CalculatePixelOutlinePostionHCS(float3 positionWS, float3 normalWS, float pixel, float3 zBiasWS, half4 color)
{
    float4 zBiasPositionHCS = TransformWorldToHClip(positionWS + zBiasWS);
    float3 normalHCS = TransformWorldToHClipDir(normalWS);
    float2 pixelOffset = zBiasPositionHCS.w * pixel / (_ScreenParams.xy/2.0);
    zBiasPositionHCS.xy += normalize(normalHCS.xy) * pixelOffset * color.a;
    return zBiasPositionHCS;
}

float4 CalculatePixelOutlinePostionHCS(float3 positionWS, float3 normalTS, float3x3 tnbWS, float pixel, float3 zBiasWS, half4 color)
{
    float3 normalWS = mul(normalTS, tnbWS);
    return CalculatePixelOutlinePostionHCS(positionWS, normalWS, pixel, zBiasWS, color);
}
#endif