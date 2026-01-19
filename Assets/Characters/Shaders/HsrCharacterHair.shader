Shader "HsrCharacter/HsrCharacterHair"
{
    Properties
    {
        [Header(Texture Setting)]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" { }
        _SdfLightMap ("Light Map", 2D) = "while" { }
        _RampMap_Warm ("Ramp Map Warm", 2D) = "while" { }
        _RampMap_Cool ("Ramp Map Cool", 2D) = "while" { }

        [Header(Color Setting)]
        [MainColor] _BaseColor ("Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)

        [Header(Alpha Blending Setting)]
        _Alpha ("Alpha", Range(0, 1)) = 1.0
        _AlphaCutOff ("Alpha Cut Off", Range(0, 1)) = 0
        _FrontHairAlpha("Front Hair Alpha", Range(0, 1)) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode ("SrcMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode ("DstMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("BlendOp", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", float) = 0

        [Header(Diffuse Lighting Setting)]
        _DiffuseLightUpMinGary("Diffuse Minimum Light-up Gary", Range(0, 1)) = 0
        [HideInInspector]_DiffuseEyesMouthArea("Diffuse Eyes and Mouth Area will be Always Light-up", Range(0, 1)) = 0.2
        _DiffuseLightUpThresholdOffset("Diffuse Light-up Threshold Offset", range(-1, 1)) = 0
        _DiffuseLightUpThresholdSoftness ("DiffuseLightUpThreshold Softness", range(0, 1)) = 0
        [KeywordEnum(Warm, Cool)]_RampHueType ("Using Rampmap Texture Hue Type", float) = 0

        [Header(Environment Lighting Setting)]
        _IndirectLightingIntensity ("Indirect Lighting Intensity", Range(0, 1)) = 0
        [HideInInspector]_FlattenNormal ("Flatten Normal", Range(0, 1)) = 1
        _AmbientOcclusionIntensity ("Ambient Occlusion Intensity", Range(0, 1)) = 0
        _IndirectLightingBaseColorMixing ("Base Color Indirect Lighting Mixing", Range(0, 1)) = 0

        [Header(Specular Lighting Setting)]
        _Metallic("Metallic", Range(0, 1)) = 1
        _SpecularLightingIntensity("Specular Lighting Intensity", Range(0, 100)) = 1
        _SpecularExponent ("Specular Exponent", float) = 1
        
        [Header(Emission Setting)]
        [KeywordEnum(Off, On)]_Emission ("Emission Off/On)", float) = 0
        [KeywordEnum(Partly, Whole)]_EmissionType("Apply Emission Partly(BaseMap.a) or Whole", float) = 0
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity ("Emission Intensity", Range(0, 100)) = 0
        _EmissionBaseColorMixing ("Base Color Emission Mixing", Range(0, 1)) = 0

        [Header(Outline Setting)]
        [KeywordEnum(Off, On)]_Outline ("Outline Off/On", float) = 0
        [KeywordEnum(Fixed_Width, Fixed_Pixel, Dynamic_Width)]_OutlineType("Outline Width Control Type", float) = 0
        _OutlineWidth ("Outline Width or Pixel", float) = 0
        _OutlineZBias ("Outline Z Bias", float) = 0
        _OutlineWidthRangeOffset("Outline Width Range Offset(Dynamic Only)", float) = 0
        _OutlineCameraStandardDistance("Outline Camera Standard Distance(Dynamic Only)", float) = 0
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "UniversalMaterialType" = "ComplexLit"
        }
        LOD 100
        HLSLINCLUDE
        #pragma shader_feature_local _AREA_BODY _AREA_FACE _AREA_HAIR
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Stencil
            {
                Ref 3
                ReadMask 2
                WriteMask 1
                Comp NotEqual
                Pass Replace
                Fail Keep
            }
            Blend[_SrcMode][_DstMode]
            BlendOp[_BlendOp]
            Cull[_Cull]
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex ForwardVert // Vertex Shader
            #pragma fragment ForwardFrag // Fragment Shader
            #pragma multi_compile _RAMPHUETYPE_WARM _RAMPHUETYPE_COOL
            #pragma multi_compile _EMISSION_OFF _EMISSION_ON
            #pragma multi_compile _EMISSIONTYPE_PARTLY _EMISSIONTYPE_WHOLE
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
            
            #include"HsrCharacterHairCore.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            Stencil
            {
                Ref 7
                ReadMask 2
                WriteMask 5
                Comp Equal
                Pass Replace
                Fail Keep
            }
            Blend[_SrcMode][_DstMode]
            BlendOp[_BlendOp]
            Cull Off
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex ForwardVert // Vertex Shader
            #pragma fragment HairTransparentFrag // Fragment Shader
            #pragma multi_compile _RAMPHUETYPE_WARM _RAMPHUETYPE_COOL
            #pragma multi_compile _EMISSION_OFF _EMISSION_ON
            #pragma multi_compile _EMISSIONTYPE_PARTLY _EMISSIONTYPE_WHOLE
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
            
            #include"HsrCharacterHairCore.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
            }
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
                Fail Keep
                ZFail Keep
            }
            Cull Front
            ZWrite On
            ZTest LEqual
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag
            #pragma shader_feature_local _OUTLINE_OFF _OUTLINE_ON
            #pragma shader_feature_local _OUTLINETYPE_FIXED_WIDTH _OUTLINETYPE_FIXED_PIXEL _OUTLINETYPE_DYNAMIC_WIDTH
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

            #include "HsrCharacterHairCore.hlsl"
            ENDHLSL
        }
    }
}
