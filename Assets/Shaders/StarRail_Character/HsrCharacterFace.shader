Shader "HsrCharacter/HsrCharacterFace"
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
        _NoseOutlineColor("Nose Outline Color", Color) = (0, 0, 0, 1)

        [Header(Alpha Blending Setting)]
        _Alpha ("Alpha", Range(0, 1)) = 1.0
        _AlphaCutOff ("Alpha Cut Off", Range(0, 1)) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode ("SrcMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode ("DstMode", float) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("BlendOp", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", float) = 0

        [Header(Shadow Setting)]
        [Toggle]_Cast_Shadows ("Cast Shadows", Float) = 1
        [Toggle]_Receive_Shadows ("Receive Shadows", Float) = 1
        _ShadowIntensity ("Shadow Intensity", Range(0, 1)) = 1.0
        _ShadowDepthBias( "Shadow Depth Bias", Range(-1, 1)) = 0.1
        _ShadowNormalBias( "Shadow Normal Bias", Range(-1, 1)) = 0.1

        [Header(Diffuse Lighting Setting)]
        _DiffuseLightUpMinGary("Diffuse Minimum Light-up Gary", Range(0, 1)) = 0
        _DiffuseLightUpThresholdOffset("Diffuse Light-up Threshold Offset", range(-1, 1)) = 0
        _DiffuseLightUpThresholdSoftness ("DiffuseLightUpThreshold Softness", range(0, 1)) = 0
        [KeywordEnum(Warm, Cool)]_RampHueType ("Using Rampmap Texture Hue Type", float) = 0
        // SDF辅助方位
        [HideInInspector]_HeadForwardVectorWS ("Head Forward Vector", vector) = (0, 0, 1)
        [HideInInspector]_HeadRightVectorWS ("Head Right Vector", vector) = (-1, 0, 0)
        [HideInInspector]_HeadUpVectorWS ("Head Up Vector", vector) = (0, 1, 0)

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
        // 鼻子描边
        [Header(Nose Outline Setting)]
        _NoseOutlineFoVExponent("Nose Outline VoF Exponent", float) = 10
        _NoseOutlineThreshold ("Nose Outline Threshold", range(0, 1)) = 0.125
        _NoseOutlineSoftness("Nose Outline Softness", range(0,1)) = 0.125
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
        #define _AREA_FACE
        ENDHLSL
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            Stencil
            {
                Ref 3
                WriteMask 3
                Comp Always
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
            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag
            #pragma multi_compile _ _RAMPHUETYPE_WARM _RAMPHUETYPE_COOL
            #pragma multi_compile _ _EMISSION_OFF _EMISSION_ON
            #pragma multi_compile _ _EMISSIONTYPE_PARTLY _EMISSIONTYPE_WHOLE
            #pragma multi_compile _ _RECEIVE_SHADOWS_ON
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
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            
            #include "HsrCharacterShaderCore.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "EyesMask"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Stencil
            {
                Ref 7
                WriteMask 7
                Comp Always
                Pass Replace
                Fail Keep
                ZFail Keep
            }
            Blend 0 SrcAlpha OneMinusSrcAlpha, [_SrcBlendAlpha] [_DstBlendAlpha]
            BlendOp[_BlendOp]
            Cull[_Cull]
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex ForwardVert
            #pragma fragment EyesMaskFrag
            #pragma multi_compile _ _RAMPHUETYPE_WARM _RAMPHUETYPE_COOL
            #pragma multi_compile _ _EMISSION_OFF _EMISSION_ON
            #pragma multi_compile _ _EMISSIONTYPE_PARTLY _EMISSIONTYPE_WHOLE
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
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            
            #include "HsrCharacterShaderCore.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "Outline"
            }
            Stencil
            {
                Ref 1
                WriteMask 1
                Comp Always
                Pass Replace
                Fail Keep
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
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "HsrCharacterShaderCore.hlsl"
            ENDHLSL
        }
                Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            ZWrite On
            ZTest LEqual   
            ColorMask R
            Cull Off 
            
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex OutlineVert
            #pragma fragment DepthOnlyFrag
            #pragma shader_feature_local _USEALPHACLIPPING
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "HsrCharacterShaderCore.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
            ZWrite On
            ZTest LEqual           
            ColorMask RGBA
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex ForwardVert
            #pragma fragment DepthNormalsFrag
            #pragma shader_feature_local _USEALPHACLIPPING
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "HsrCharacterShaderCore.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            ZWrite On
            ZTest LEqual    
            ColorMask 0
            Cull Off
            HLSLPROGRAM
            #pragma multi_compile _ _CAST_SHADOWS_ON
            #pragma target 2.0
            #pragma vertex ShadowCasterVert
            #pragma fragment ShadowCasterFrag
            #pragma shader_feature_local _USEALPHACLIPPING
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #define ToonShaderApplyShadowBiasFix
            #include "HsrCharacterShaderCore.hlsl"
            ENDHLSL
        }
    }
}
