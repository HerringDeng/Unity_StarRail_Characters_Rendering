#ifndef HSR_FORWARD_SHADER
#define HSR_FORWARD_SHADER
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "HSR_CalcFunction.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_LightMapTex);
SAMPLER(sampler_LightMapTex);
TEXTURE2D(_RampTex_warm);
SAMPLER(sampler_RampTex_warm);
TEXTURE2D(_RampTex_cool);
SAMPLER(sampler_RampTex_cool);
TEXTURE2D(_EmissionMapTex);
SAMPLER(sampler_EmissionMapTex);

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
    float _NoseShadowThreshold;
    float _NoseShadowSoftness;
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    //float4 uv7 : TEXCOORD7;

};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD3;
    half3 SH : TEXCOORD4;
    //float4 uv7 : TEXCOORD5;
    float4 positionHCS : SV_POSITION;
};

Varyings Vert(Attributes input)
{
    Varyings output;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, ComputeFogFactor(vertexInput.positionCS.z));
    output.normalWS = vertexNormalInput.normalWS;
    output.viewDirWS = unity_OrthoParams.w == 0 ? GetCameraPositionWS() - vertexInput.positionWS : GetWorldToViewMatrix()[2].xyz;  // 区分透视相机和正交相机
    output.SH = SampleSH(lerp(vertexNormalInput.normalWS, float3(0, 0, 0), _FlattenNormal));
    //output.uv7 = input.uv7;
    return output;
}

half4 Frag(Varyings input) : SV_Target
{
    //颜色贴图
    half4 baseMapColor_withAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    half3 baseColor = baseMapColor_withAlpha.rgb * _BaseColor.rgb;
    //透明度
    half alpha = _Aphla;
    //光照图
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, input.uv);

    //环境光
    half3 environmentColor = input.SH;
    #if  _AREA_BODY | _AREA_HAIR
        environmentColor *= lerp(1, lightMap.r, _AmbientOcclusionIntensity); //光照图红通道记录环境光遮蔽（AO）信息
    #endif
    #if _AREA_FACE
        environmentColor *= lerp(1, lightMap.r, lerp(0, _AmbientOcclusionIntensity, step(0.2, lightMap.r)));
    #endif
    environmentColor = lerp(environmentColor, baseColor, _EnvironmentMixBaseIntensity); //环境光颜色混合基础色
    environmentColor *= _EnvironmentIntensity;
    //漫反射
    Light mainLight = GetMainLight();
    //光照颜色
    half3 lightColor = lerp(desaturation(mainLight.color), mainLight.color, _MainLigthColorIntensity) * mainLight.distanceAttenuation;
    //主光源方向
    float3 lightDir = mainLight.direction;
    half diffuseDark = 0;
    half3 diffuseColor = 0;
    half3 mixDarkColor = 0;
    float2 rampUV = 0;
    half3 rampColor = 0;
    // 身体和头发
    #if _AREA_BODY | _AREA_HAIR
        half NoL = saturate(dot(input.normalWS, lightDir));
        NoL = min(NoL, _NoLMaxThreshold);
        // 头发和身体的lightmap的g通道存储的灰度值表示二分阴影的明暗阈值，阈值越高则越容易被点亮（NoL较低时便能被判断为二分亮面），阈值越低则越难以被点亮（NoL较高时才能被判断为二分亮面）
        diffuseDark = smoothstep(1 - lightMap.g + _RampDarkCenter - _RampDarkSoftness, 1 - lightMap.g + _RampDarkCenter + _RampDarkSoftness, NoL);
        // 头发和身体的lightmap的a通道存储的灰度值对应rampmap中阴影色条的纵向uv值（uv_y），以选择该区域对应的rampmap色条（共8行）
        rampUV.y = lightMap.a;
    #endif
    // 脸部
    #if _AREA_FACE
        float3 headForward = _HeadForwardVector;
        float3 headRight = _HeadRightVector;
        float3 headUp = _HeadUpVector;
        float3 flattenLightDir = normalize(lightDir - dot(lightDir, headUp) * headUp);
        float flattenHoL = dot(flattenLightDir, headRight);
        float2 sdfUV = float2(-sign(flattenHoL), 1) * input.uv;
        // 脸部的lighmap的a通道存储脸部sdf光照阴影
        half faceMap_a = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, sdfUV).a;
        half sdfValue = faceMap_a + _RampDarkCenter;
        sdfValue = lerp(0, sdfValue, step(0.01, faceMap_a));
        // half sdfThreshold = 1-(dot(flattenLightDir, headForward) * 0.5 + 0.5);
        half sdfThreshold = 1 - (saturate(dot(flattenLightDir, headForward)));
        diffuseDark = smoothstep(sdfThreshold - _RampDarkSoftness, sdfThreshold + _RampDarkSoftness, sdfValue);
        diffuseDark = lerp(diffuseDark, 1, step(0.2, lightMap.r));
        rampUV.y = 0.08;
    #endif
    mixDarkColor = lerp(_DarkColor.rgb, half3(1, 1, 1), diffuseDark);
    // 将漫反射亮度作为rampmap的横向uv值（uv_x），uv_x越小则越暗，uv_x越大则越亮
    rampUV.x = diffuseDark;
    // 可选择暖色ramp和冷色ramp（在shader中选择）
    #if _RAMPTYPE_WARM
        rampColor = SAMPLE_TEXTURE2D(_RampTex_warm, sampler_RampTex_warm, rampUV).rgb;
    #endif
    #if _RAMPTYPE_COOL
        rampColor = SAMPLE_TEXTURE2D(_RampTex_cool, sampler_RampTex_cool, rampUV).rgb;
    #endif
    diffuseColor = lightColor * baseColor * mixDarkColor * rampColor;

    // 高光计算
    half3 specularColor = 0;
    half3 specularResult = 0;
    #if _AREA_BODY
        specularColor = lerp(specularColor, baseColor, lightMap.b);
        specularResult = BlinnPhongSpecular(lightColor, lightDir, input.viewDirWS, input.normalWS, specularColor, _SpecularSmoothness, _SpecularIntensity);
    #elif _AREA_HAIR
        float specularArea = lightMap.b;
        specularColor = lerp(half3(0, 0, 0), lightColor, specularArea);
        specularResult = lerp(half3(0, 0, 0), specularColor, diffuseDark) * _SpecularIntensity;
    #elif _AREA_FACE
        float specularArea = baseMapColor_withAlpha.a;
        specularColor = lerp(half3(0, 0, 0), lightColor, specularArea);
        specularResult = lerp(half3(0, 0, 0), specularColor, 1 - sdfThreshold) * _SpecularIntensity;
    #endif
    // 自发光
    half3 emission = 0;
    #if _EMISSION_ON
        half4 emissionMap = SAMPLE_TEXTURE2D(_EmissionMapTex, sampler_EmissionMapTex, input.uv);
        half emission_area = lerp(1, emissionMap.a, _UsingEmisionMap); //选择自发光区域
        half3 emissionColor = lerp(_EmissionColor.rgb, emissionMap.rgb, _UsingEmisionMap);
        emission = lerp(emissionColor, baseColor, _EmissionMixBaseColorIntensity); //与基础色混合
        emission = lerp(half3(0, 0, 0), emission, emission_area);
    #endif
    //鼻影
    half noseShadow = 0;
    #if _AREA_FACE
        half3 cameraForward = TransformViewToWorld(half3(0, 0, 1));
        float noseShadowValue = pow(saturate(dot(_HeadForwardVector, cameraForward)), _NoseShadowPow);
        noseShadowValue = smoothstep(_NoseShadowThreshold - _NoseShadowSoftness, _NoseShadowThreshold + _NoseShadowSoftness, noseShadowValue);
        noseShadow = noseShadowValue * lightMap.b;
    #endif
    
    // 最终输出颜色
    half3 albedo = 0; //基础色
    albedo = lerp(diffuseColor, environmentColor, _EnvironmentIntensity);
    albedo += specularResult;
    albedo += emission * _EmissionIntensity; //自发光
    #if _AREA_FACE
        albedo = lerp(albedo, _OutlineColor.rgb, lightMap.b);
    #endif
    // 测试输出
    half4 final_color = half4(albedo, alpha);
    return final_color;
}
#endif