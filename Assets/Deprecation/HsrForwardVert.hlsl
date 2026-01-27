#ifndef HSR_FORWARD_VERT
#define HSR_FORWARD_VERT
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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

Varyings ForwardVert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    output.viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);  // 区分透视相机和正交相机
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    return output;
}

#endif