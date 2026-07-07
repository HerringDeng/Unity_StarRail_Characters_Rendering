#ifndef NORMAL_COMPRESSION_TOOLS
#define NORMAL_COMPRESSION_TOOLS

float3 UncompressOctahedronToNormalTS(float2 oct, bool negativeUV)
{
    if(!negativeUV)
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

float3 UncompressOctahedronToNormalWS(float2 oct, float3x3 tnbWS, bool negativeUV)
{
    float3 n = UncompressOctahedronToNormalTS(oct, negativeUV);
    n = mul(n, tnbWS);
    return n;
}
#endif