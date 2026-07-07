#ifndef HSR_CHARACTER_FORWARD_SHADER_HLSL
#define HSR_CHARACTER_FORWARD_SHADER_HLSL
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "HsrCharacterShaderProperties.hlsl"
#include "Assets/Shaders/CartoonOutlineCore/CartoonOutlineCore.hlsl"
#include "Assets/Shaders/Tools/NormalCompressionTools.hlsl"
#include "Assets/Shaders/Tools/ColorTools.hlsl"

Varyings Vert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 normalTS = UncompressOctahedronToNormalTS(input.uv2, false);
    float3x3 tnbWS = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    float3 cameraPositionWS = GetCameraPositionWS();
    float3 zBiasWS = normalize(vertexInput.positionWS - cameraPositionWS)*_OutlineZBias;
    float width = 0;
    if(_OutlineMode == 1)
    {
        width = _OutlineWidth;
    }
    else if(_OutlineMode == 2)
    {
        width = _DynamicOutlineWidth;
    }
    if(_Area == 2) // 脸颊、鼻子和嘴部描边修复, 该部分代码效果很好但部分参数比较Magic, 后续有时间再尝试重构
    {
        float3 viewDirWS = normalize(unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz);
        float fov = pow(max(0, dot(_FaceForwardDirWS, viewDirWS)), 0.8);
        width *= smoothstep(-0.02, 0, 1-fov-input.color.b);
        float rov = abs(dot(_FaceRightDirWS, viewDirWS));
        width = lerp(width, width*lerp(1, 0, step(0.93, rov)), step(0.2, input.color.g));
    }
    output.positionHCS = CalculatePixelOutlinePostionHCS(vertexInput.positionWS, normalTS, tnbWS, width, zBiasWS, input.color);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.uv = 0;
    output.normalWS = 0;
    output.viewDirWS = 0;
    output.SH = 0;
    output.shadowCoord = 0;
    return output;
}

half4 Frag(Varyings input) : SV_Target
{
    Light mainLight = GetMainLight();
    half4 final = half4(_OutlineColor.rgb*RGBtoGray(mainLight.color.rgb), _Alpha);
    clip(_Alpha - _CutOffThreshold);
    return final;
}
#endif