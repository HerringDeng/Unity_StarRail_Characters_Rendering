Shader "Custom/SR_Character_Shader"
{
    Properties
    {
        [KeywordEnum(Body, Face, Hair)]_Area ("Material Area", float) = 0

        [Header(MainTextures_Setting)]
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _MainTex ("Main Texture", 2D) = "white" { }
        _DarkColor("Dark Color", Color) = (0, 0, 0, 1)

        [Header(Aphla_Setting)]
        _Aphla ("Aphla", Range(0, 1)) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode ("SrcMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode ("DstMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("BlendOp", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", float) = 0

        [Header(SDF_Setting)]
        _LightMapTex ("LightMap Texture", 2D) = "while" { }
        _MainLigthColorIntensity("Main Light Color Intensity", range(0, 1)) = 0
        _RampDarkCenter("Ramp Dark Center", range(-1, 1)) = 0
        _RampDarkSoftness("Ramp Dark Softness", range(0, 1)) = 0
        [KeywordEnum(Warm, Cool)]_RampType("Ramp Texture Type", float) = 0
        _RampTex_warm("Ramp Texture Warm", 2D) = "while" {}
        _RampTex_cool("Ramp Texture Cool", 2D) = "while" {}
        [HideInInspector]_HeadForwardVector("Head Forward Vector", vector) = (0, 0, 1)
        [HideInInspector]_HeadRightVector("Head Right Vector", vector) = (1, 0, 0)
        [HideInInspector]_HeadUpVector("Head Up Vector", vector) = (0, 1, 0)
        [Header(EnvironmentLighting_Setting)]
        _EnvironmentIntensity ("Environment Intensity", Range(0, 1)) = 0
        _FlattenNormal ("Flatten Normal", Range(0, 1)) = 0
        //[KeywordEnum(Off, On)]_AmbientOcclusion ("AmbientOcclusion(off/on)", float) = 0
        _AmbientOcclusionIntensity ("Ambient Occlusion Intensity", Range(0, 1)) = 0
        _EnvironmentMixBaseIntensity ("Environment Mix Base Intentsity", Range(0, 1)) = 0
        
        [Header(Emission_Setting)]
        [KeywordEnum(Off, On)]_Emission ("Emission(off/on)", float) = 0
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionMixBaseIntensity ("Emission Mix Base Intensity", Range(0, 1)) = 0
        _EmissionIntensity ("Emission Intensity", Range(0, 1)) = 0
    }
    SubShader
    {
        HLSLINCLUDE
        #pragma shader_feature_local _AREA_BODY
        #pragma shader_feature_local _AREA_FACE
        #pragma shader_feature_local _AREA_HAIR
        #pragma shader_feature_local _RAMPTYPE_WARM
        #pragma shader_feature_local _RAMPTYPE_COOL
        #pragma shader_feature_local _EMISSION_ON
        ENDHLSL

        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" }

        Pass
        {
            Blend[_SrcMode][_DstMode]
            BlendOp[_BlendOp]
            Cull[_Cull]
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

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

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_LightMapTex);
            SAMPLER(sampler_LightMapTex);
            TEXTURE2D(_RampTex_warm);
            SAMPLER(sampler_RampTex_warm);
            TEXTURE2D(_RampTex_cool);
            SAMPLER(sampler_RampTex_cool);

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
                float _RampDarkCenter;
                float _RampDarkSoftness;
                float3 _HeadForwardVector;
                float3 _HeadRightVector;
                float3 _HeadUpVector;

                float _EnvironmentIntensity;
                float _FlattenNormal;
                float _AmbientOcclusionIntensity;
                float _EnvironmentMixBaseIntensity;
                half4 _EmissionColor;
                float _EmissionMixBaseIntensity;
                float _EmissionIntensity;
            CBUFFER_END

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
                return output;
            }

            half LightingHalfLambert(half3 lightDirWS, half3 normalWS)
            {
                half NdotL = saturate(dot(normalWS, lightDirWS));//范围 0.0 - 1.0
                half diffuseDark = pow(NdotL * 0.5 + 0.5,2.0);
                return diffuseDark;
            }

            half3 desaturation(half3 color, half3 glayXfer = half3(0.3, 0.59, 0.11))
            {
                return dot(color, glayXfer);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                //颜色贴图
                half4 baseColor_withAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 baseColor = baseColor_withAlpha.rgb * _BaseColor.rgb;
                //透明度
                half alpha = _Aphla;
                //光照图
                half4 lightMap = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, input.uv);

                //环境光
                half3 environmentColor = input.SH;
                #if _AREA_BODY | _AREA_HAIR
                environmentColor *= lerp(1, lightMap.r, _AmbientOcclusionIntensity); //光照图红通道记录环境光遮蔽（AO）信息
                #endif
                #if _AREA_FACE
                environmentColor *= lerp(1, lightMap.r, lerp(0, _AmbientOcclusionIntensity, step(0.2, lightMap.r)));
                #endif
                environmentColor = lerp(environmentColor, baseColor, _EnvironmentMixBaseIntensity); //环境光颜色混合基础色
                environmentColor *= _EnvironmentIntensity;
                //漫反射
                Light mainLight = GetMainLight();
                half3 lightColor = lerp(desaturation(mainLight.color), mainLight.color, _MainLigthColorIntensity) * mainLight.distanceAttenuation;
                float3 lightDir = mainLight.direction;
                half diffuseDark = 0;
                half3 diffuseColor = 0;
                half3 mixDarkColor = 0;
                float2 rampUV = 0;
                half3 rampColor = 0;
                //身体和头发
                #if _AREA_BODY | _AREA_HAIR
                half NoL = saturate(dot(input.normalWS, lightDir));
                diffuseDark = smoothstep(1 - lightMap.g + _RampDarkCenter - _RampDarkSoftness, 1 - lightMap.g + _RampDarkCenter + _RampDarkSoftness, NoL);
                rampUV.y = lightMap.a;
                #endif
                //脸部
                #if _AREA_FACE
                float3 headForward = _HeadForwardVector;
                float3 headRight = _HeadRightVector;
                float3 headUp = _HeadUpVector;
                float3 flattenLightDir = normalize(lightDir-dot(lightDir, headUp)*headUp);
                float flattenNoL = dot(flattenLightDir, headRight);
                float2 sdfUV = float2(-sign(flattenNoL), 1) * input.uv;
                half faceMap_a = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, sdfUV).a;
                half sdfValue = faceMap_a +  _RampDarkCenter;
                sdfValue = lerp(0, sdfValue, step(0.01, faceMap_a));
                // half sdfThreshold = 1-(dot(flattenLightDir, headForward) * 0.5 + 0.5);
                half sdfThreshold = 1-(saturate(dot(flattenLightDir, headForward)));
                diffuseDark = smoothstep(sdfThreshold-_RampDarkSoftness, sdfThreshold+_RampDarkSoftness, sdfValue);
                diffuseDark = lerp(diffuseDark, 1, step(0.2, lightMap.r));
                rampUV.y = 0.08;
                #endif
                mixDarkColor = lerp(_DarkColor.rgb, half3(1, 1, 1), diffuseDark);
                rampUV.x = diffuseDark;
                #if _RAMPTYPE_WARM
                rampColor = SAMPLE_TEXTURE2D(_RampTex_warm, sampler_RampTex_warm, rampUV).rgb;
                #endif
                #if _RAMPTYPE_COOL
                rampColor = SAMPLE_TEXTURE2D(_RampTex_cool, sampler_RampTex_cool, rampUV).rgb;
                #endif
                diffuseColor = lightColor * baseColor * mixDarkColor * rampColor;
                
                //自发光
                half3 emission = 0;
                #if _EMISSION_ON
                    half emission_area = baseColor_withAlpha.a;
                    emission = lerp(_EmissionColor.rgb, baseColor, _EmissionMixBaseIntensity); //与基础色混合
                    emission = lerp(half3(0, 0, 0), emission, emission_area); //选择自发光区域
                #endif

                //最终输出颜色
                half3 albedo = 0; //基础色
                albedo = lerp(diffuseColor, environmentColor, _EnvironmentIntensity);
                albedo += emission * _EmissionIntensity; //自发光
                // 测试输出
                half4 final_color = half4(half3(1, 1, 1)*albedo, _Aphla);
                return final_color;
            }
            ENDHLSL
        }
    }
}
