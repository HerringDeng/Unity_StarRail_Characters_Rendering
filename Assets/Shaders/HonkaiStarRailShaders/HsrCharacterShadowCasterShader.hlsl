#ifndef HSR_CHARACTER_FORWARD_SHADER_HLSL
#define HSR_CHARACTER_FORWARD_SHADER_HLSL
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "HsrCharacterShaderProperties.hlsl"

float3 ApplyLocalShadowBias(float3 positionWS, float3 normalWS, float3 lightDirectionWS, float2 shadowBias)
{
    float invNdotL = 1.0 - saturate(dot(lightDirectionWS, normalWS));
    float scale = invNdotL * shadowBias.y;
    // normal bias is negative since we want to apply an inset normal offset
    positionWS = positionWS + lightDirectionWS * shadowBias.x;
    positionWS = positionWS + normalWS * scale;
    return positionWS;
}

Varyings Vert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionWSAndFogFactor = 0;
    output.normalWS = 0;
    output.viewDirWS = 0;
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.SH = 0;
    output.shadowCoord = 0;
    half3 mainLightDirWS = GetMainLight().direction;
    float3 positionWS = ApplyLocalShadowBias(vertexInput.positionWS, vertexNormalInput.normalWS, mainLightDirWS, float2(_ShadowDepthBias, _ShadowNormalBias));
    positionWS = ApplyShadowBias(positionWS, vertexNormalInput.normalWS, mainLightDirWS);
    output.positionHCS = TransformWorldToHClip(positionWS);
    return output;
}

half4 Frag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    #if defined(_ALPHATEST_ON)
        Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    #endif

    #if defined(LOD_FADE_CROSSFADE)
        LODFadeCrossFade(input.positionCS);
    #endif
    return 0;
}
#endif