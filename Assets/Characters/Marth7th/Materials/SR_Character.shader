Shader "Unlit/SR_Shader"
{
    Properties
    {
        [KeywordEnum(Body, Face, Hair)]_Area ("Material Area", float) = 0

        [Header(MainTextures_Setting)]
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _MainTex ("Main Texture", 2D) = "white" { }

        [Header(Aphla_Setting)]
        _Aphla ("Aphla", Range(0, 1)) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode ("SrcMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode ("DstMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("BlendOp", float) = 0

        [Header(LightTextures_Setting)]
        _LightTex ("Light Texture", 2D) = "while" { }

        [Header(EnvironmentLighting_Setting)]
        _EnvironmentIntensity ("Environment Intensity", Range(0, 1)) = 0
        _FlattenNormal ("Flatten Normal", Range(0, 1)) = 0
        [KeywordEnum(Off, On)]_AmbientOcclusion ("AmbientOcclusion(off/on)", float) = 0
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
        #pragma shader_feature_local _AMBIENTOCCLUSION_ON
        #pragma shader_feature_local _EMISSION_ON
        ENDHLSL

        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" }

        Pass
        {
            Blend[_SrcMode][_DstMode]
            BlendOp[_BlendOp]
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

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
            TEXTURE2D(_LightTex);
            SAMPLER(sampler_LightTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_ST;
                half4 _LightTex_ST;
                half4 _BaseColor;
                half _Aphla;
                float _SrcMode;
                float _DstMode;
                float _BlendOp;
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

            half4 Frag(Varyings input) : SV_Target
            {
                //颜色贴图
                half4 baseColor_withAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 baseColor = baseColor_withAlpha.rgb * _BaseColor.rgb;
                //透明度
                half alpha = _Aphla;
                //光照图
                half4 lightMap = SAMPLE_TEXTURE2D(_LightTex, sampler_LightTex, input.uv);
                //环境光
                half3 environmentColor = input.SH;
                #if _AMBIENTOCCLUSION_ON
                #if _AREA_BODY | _AREA_HAIR
                environmentColor *= lerp(1, lightMap.r, _AmbientOcclusionIntensity); //光照图红通道记录环境光遮蔽（AO）信息
                #endif
                #if _AREA_FACE

                #endif
                #endif
                environmentColor = lerp(environmentColor, baseColor, _EnvironmentMixBaseIntensity);
                environmentColor *= _EnvironmentIntensity;
                #if _AREA_FACE

                #endif
                //自发光
                half3 emission = 0;
                #if _EMISSION_ON
                    half emission_area = baseColor_withAlpha.a;
                    emission = lerp(_EmissionColor.rgb, baseColor, _EmissionMixBaseIntensity); //与基础色混合
                    emission = lerp(half3(0, 0, 0), emission, emission_area); //选择自发光区域
                #endif

                half3 albedo = 0;
                albedo += baseColor;
                //最终输出颜色
                half4 color = half4(baseColor, alpha); //基础色
                
                color.rgb = lerp(color.rgb, color.rgb + emission, _EmissionIntensity); //自发光

                // 测试输出
                color.rgb = environmentColor;
                return color;
            }
            ENDHLSL
        }
    }
}
