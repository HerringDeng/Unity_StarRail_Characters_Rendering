Shader "Custom/HSR_Character_Shader"
{
    Properties
    {
        [KeywordEnum(Body, Face, Hair)]_Area ("Material Area", float) = 0

        [Header(BaseColor_Setting)]
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _MainTex ("Main Texture", 2D) = "white" { }
        _DarkColor ("Dark Color", Color) = (0, 0, 0, 1)

        [Header(Aphla_Setting)]
        _Aphla ("Aphla", Range(0, 1)) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode ("SrcMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode ("DstMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("BlendOp", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", float) = 0

        [Header(SDF_Setting)]
        _LightMapTex ("LightMap Texture", 2D) = "while" { }
        _MainLigthColorIntensity ("Main Light Color Intensity", range(0, 1)) = 0
        _NoLMaxThreshold("NoL Max Threshold Value", Range(0, 1)) = 1
        _RampDarkCenter ("Ramp Dark Center", range(-1, 1)) = 0
        _RampDarkSoftness ("Ramp Dark Softness", range(0, 1)) = 0
        [KeywordEnum(Warm, Cool)]_RampType ("Ramp Texture Type", float) = 0
        _RampTex_warm ("Ramp Texture Warm", 2D) = "while" { }
        _RampTex_cool ("Ramp Texture Cool", 2D) = "while" { }
        [HideInInspector]_HeadForwardVector ("Head Forward Vector", vector) = (0, 0, 1)
        [HideInInspector]_HeadRightVector ("Head Right Vector", vector) = (1, 0, 0)
        [HideInInspector]_HeadUpVector ("Head Up Vector", vector) = (0, 1, 0)
        [Header(EnvironmentLighting_Setting)]
        _EnvironmentIntensity ("Environment Intensity", Range(0, 1)) = 0
        _FlattenNormal ("Flatten Normal", Range(0, 1)) = 0
        //[KeywordEnum(Off, On)]_AmbientOcclusion ("AmbientOcclusion(off/on)", float) = 0
        _AmbientOcclusionIntensity ("Ambient Occlusion Intensity", Range(0, 1)) = 0
        _EnvironmentMixBaseIntensity ("Environment Mix Base Intentsity", Range(0, 1)) = 0

        [Header(Specular)]
        _SpecularIntensity("Specular Intensity", Range(0, 100)) = 1
        _SpecularSmoothness ("Smooth Specular Parameter", float) = 1
        
        [Header(Emission_Setting)]
        //[KeywordEnum(Off, All_Area, Base_on_MainMap_a)]_Emission ("Emission(off/on)", float) = 0
        [KeywordEnum(Off, On)]_Emission ("Emission(off/on)", float) = 0
        [Toggle]_UsingEmisionMap("Using Emision Map?", float) = 0
        _EmissionMapTex ("EmissionMap Texture", 2D) = "while" { }
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionMixBaseColorIntensity ("Emission Mix Base Intensity", Range(0, 1)) = 0
        _EmissionIntensity ("Emission Intensity", Range(0, 10)) = 0

        [Header(Outline)]
        [KeywordEnum(Off, Fix_Mode, Pixel_Mode, Dynamic_Mode)]_Outline ("Outline off/on", float) = 0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 0)
        _OutlineWidth ("Outline Width", float) = 0
        _OutlineZBias ("Outline Z Bias", float) = 0
        _DynamicOutlineMinWidth("Dynamic Outline Min Width", float) = 0
        _DynamicOutlineMaxWidth("Dynamic Outline Max Width", float) = 0

        [Header(Nose_Shadow)]
        _NoseShadowPow("Nose Shadow Pow", float) = 10
        _NoseShadowThreshold ("Nose Shadow Threshold", range(0, 1)) = 0
        _NoseShadowSoftness("Nose Shadow Softness", range(0,1)) = 0
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "UniversalMaterialType" = "ComplexLit"
            "Queue"="Geometry"
        }
        LOD 100
        
        HLSLINCLUDE
        #pragma shader_feature_local _ _AREA_BODY _AREA_FACE _AREA_HAIR
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
            }
            Blend[_SrcMode][_DstMode]
            BlendOp[_BlendOp]
            Cull[_Cull]
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile _ _RAMPTYPE_WARM _RAMPTYPE_COOL
            //#pragma shader_feature_local _ _EMISSION_OFF _EMISSION_ALL_AREA _EMISSION_BASE_ON_MAINMAP_A
            #pragma multi_compile _ _EMISSION_OFF _EMISSION_ON
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            
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
            //半兰伯特
            half LightingHalfLambert(half3 lightDirWS, half3 normalWS)
            {
                half NdotL = saturate(dot(normalWS, lightDirWS));//范围 0.0 - 1.0
                half diffuseDark = pow(NdotL * 0.5 + 0.5, 2.0);
                return diffuseDark;
            }
            //去色函数
            half3 desaturation(half3 color, half3 glayXfer = half3(0.3, 0.59, 0.11))
            {
                return dot(color, glayXfer);
            }
            //blinn-phong高光
            half3 BlinnPhongSpecular(half3 lightColor, float3 lightDirWS, float3 viewDirWS, float3 normalWS, half3 specularColor, float smoothness)
            {
                float3 h = normalize(lightDirWS + viewDirWS);
                float3 h_dot_n = saturate(dot(h, normalWS));
                float3 modifier = pow(h_dot_n, smoothness);
                return lightColor * specularColor * modifier * _SpecularIntensity;
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
                    specularResult = BlinnPhongSpecular(lightColor, lightDir, input.viewDirWS, input.normalWS, specularColor, _SpecularSmoothness);
                #elif _AREA_HAIR
                    float specularArea = lightMap.b;
                    specularColor = lerp(half3(0, 0, 0), lightColor, specularArea);
                    specularResult = lerp(half3(0, 0, 0),specularColor, diffuseDark) * _SpecularIntensity;
                #elif _AREA_FACE
                    float specularArea = baseMapColor_withAlpha.a;
                    specularColor = lerp(half3(0, 0, 0), lightColor, specularArea);
                    specularResult = lerp(half3(0, 0, 0), specularColor, 1-sdfThreshold) * _SpecularIntensity;
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
                    half3 cameraForward = TransformViewToWorld(half3(0,0,1));
                    float noseShadowValue = pow(saturate(dot(_HeadForwardVector, cameraForward)), _NoseShadowPow);
                    noseShadowValue = smoothstep(_NoseShadowThreshold-_NoseShadowSoftness, _NoseShadowThreshold+_NoseShadowSoftness, noseShadowValue);
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
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Cull Front
            HLSLPROGRAM
            #pragma target 2.0
            #pragma shader_feature_local _ _OUTLINE_OFF _OUTLINE_FIX_MODE _OUTLINE_PIXEL_MODE _OUTLINE_DYNAMIC_MODE
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

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
                float4 uv7 : TEXCOORD7;
            };
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 outlinePostionHCS : SV_POSITION;
            };
            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3 outlinePostionWS = vertexInput.positionWS;
                //固定粗细描边模式
                #if _OUTLINE_FIX_MODE
                    //相机射线方向偏移
                    float3 cameraPostionWS = GetCameraPositionWS();
                    float3 biasDir = normalize(outlinePostionWS-cameraPostionWS);
                    float biasScale = 1000;
                    outlinePostionWS += biasDir/biasScale * _OutlineZBias;
                    //法线
                    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
                    float3 normalTS = input.uv7.xyz;
                    float3 normalWS = mul(normalTS, tnb);
                    float3 positionVS = TransformWorldToView(outlinePostionWS);
                    float3 normalVS = TransformWorldToViewDir(normalWS);
                    float fixWidthScaling = 1100;
                    positionVS += normalize(normalVS) * _OutlineWidth/fixWidthScaling;
                    output.outlinePostionHCS = TransformWViewToHClip(positionVS);
                //固定像素描边模式
                #elif _OUTLINE_PIXEL_MODE
                    //相机射线方向偏移
                    float3 cameraPostionWS = GetCameraPositionWS();
                    float3 biasDir = normalize(outlinePostionWS-cameraPostionWS);
                    float biasScale = 1000;
                    outlinePostionWS += biasDir/biasScale * _OutlineZBias;
                    //法线
                    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
                    float3 normalTS = input.uv7.xyz;
                    float3 normalWS = mul(normalTS, tnb);
                    float3 positionVS = TransformWorldToView(outlinePostionWS);
                    float3 normalVS = TransformWorldToViewDir(normalWS);
                    //float3 normalHCS = mul((float3x3)UNITY_MATRIX_VP, normalWS);
                    float3 normalHCS = TransformWorldToHClipDir(normalWS);
                    output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
                    float2 outlineOffset =  (_OutlineWidth * output.outlinePostionHCS.w) / (_ScreenParams.xy / 2.0);
                    output.outlinePostionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
                //随相机距离自动调整的动态宽度描边模式
                #elif _OUTLINE_DYNAMIC_MODE
                    //相机射线方向偏移
                    float3 cameraPostionWS = GetCameraPositionWS();
                    float3 biasDir = normalize(outlinePostionWS-cameraPostionWS);
                    float biasScale = 1000;
                    outlinePostionWS += biasDir/biasScale * _OutlineZBias;
                    //法线
                    float3x3 tnb = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
                    float3 normalTS = input.uv7.xyz;
                    float3 normalWS = mul(normalTS, tnb);
                    float3 positionVS = TransformWorldToView(outlinePostionWS);
                    float3 normalVS = TransformWorldToViewDir(normalWS);
                    float fixWidthScaling = 1100;
                    float outlineWidth = _OutlineWidth/fixWidthScaling;
                    float cameraDistance = length(outlinePostionWS-cameraPostionWS);
                    outlineWidth = clamp(outlineWidth*cameraDistance, _DynamicOutlineMinWidth/fixWidthScaling, _DynamicOutlineMaxWidth/fixWidthScaling);
                    positionVS += normalize(normalVS) * outlineWidth;
                    output.outlinePostionHCS = TransformWViewToHClip(positionVS);
                #else
                    output.outlinePostionHCS = TransformWorldToHClip(outlinePostionWS);
                #endif
                output.uv = input.uv;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                #if _OUTLINE_OFF
                    clip(-1);
                    return 0;
                #else
                    #if _AREA_FACE
                        half4 lightMap = SAMPLE_TEXTURE2D(_LightMapTex, sampler_LightMapTex, input.uv);
                        half outlineArea = lightMap.r;
                        float clipPara = lerp(1, -1, outlineArea);
                        clip(clipPara);
                    #endif
                    return _OutlineColor;
                #endif
            }
            ENDHLSL
        }
    }
}
