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
        [KeywordEnum(No, UV1, UV2, UV3, UV4, UV5, UV6, UV7, VC)]_OutlineNormal_Channel("Outline Normal Channel", float) = 0
        [KeywordEnum(No, Oct)]_OutlineNormal_Compressed("Outline Normal Compressed", float) = 0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 0)
        _OutlineWidth ("Outline Width", float) = 0
        _OutlineZBias ("Outline Z Bias", float) = 0
        _DynamicOutlineMinWidth("Dynamic Outline Min Width", float) = 0
        _DynamicOutlineMaxWidth("Dynamic Outline Max Width", float) = 0

        [Header(Nose_Shadow)]
        _NoseShadowPow("Nose Shadow Pow", float) = 10
        _NoseShadowDarkness("Nose Shadow Darkness", range(0, 1)) = 0.6
        _NoseShadowGamma("Nose Shadow Gamma", float) = 16
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
            
            #include"HSR_ForwardLit_Shader.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Cull Front
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma shader_feature_local _ _OUTLINE_OFF _OUTLINE_FIXED_MODE _OUTLINE_PIXEL_MODE _OUTLINE_DYNAMIC_MODE
            #pragma shader_feature_local _ _OUTLINENORMAL_CHANNEL_NO, _OUTLINENORMAL_CHANNEL_UV1, _OUTLINENORMAL_CHANNEL_UV2, _OUTLINENORMAL_CHANNEL_UV3, _OUTLINENORMAL_CHANNEL_UV4, _OUTLINENORMAL_CHANNEL_UV5, _OUTLINENORMAL_CHANNEL_UV6, _OUTLINENORMAL_CHANNEL_UV7, _OUTLINENORMAL_CHANNEL_VC
            #pragma shader_feature_local _ _OUTLINENORMAL_COMPRESSED_NO _OUTLINENORMAL_COMPRESSED_OCT
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

            #include "HSR_Outline_Shader.hlsl"
            ENDHLSL
        }
    }
}
