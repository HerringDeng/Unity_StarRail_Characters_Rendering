Shader "HonkaiStarRail_Rendering/HsrCharacterShader"
{
    Properties
    {
        [Header(Area Setting)]
        [KeywordEnum(Body, Hair, Face)]_Area ("Area Mask", Float) = 0
        [Header(Texture Setting)]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" { }
        _LightMap ("Light Map", 2D) = "white" { }
        _RampMap_Warm ("Ramp Map Warm", 2D) = "white" { }
        _RampMap_Cool ("Ramp Map Cool", 2D) = "white" { }
        [Header(Alpha Setting)]
        _Alpha ("Alpha", Range(0, 1)) = 1.0
        _CutOffThreshold ("Cut Off Threshold", Range(0, 1)) = 0
        [Header(Shadow Setting)]
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowUsage ("Shadow Usage", Range(0, 1)) = 1.0
        _ShadowDepthBias( "Shadow Depth Bias", Range(-1, 1)) = 0
        _ShadowNormalBias( "Shadow Normal Bias", Range(-1, 1)) = 0
        [Header(Diffuse Lighting Setting)]
        _DiffuseThresholdOffset("Diffuse Threshold Offset", Range(-1, 1)) = 0
        _DiffuseThresholdSoftness ("Diffuse Threshold Softness", Range(0, 1)) = 0
        _RampMapTemperature ("Ramp Map Temperature(Cool~Warm)", Range(0, 1)) = 0
        [HideInInspector][PerRendererData]_FaceForwardDirWS("Face Forward Direction", Vector) = (0, 0, 1)
        [HideInInspector][PerRendererData]_FaceRightDirWS("Face Right Direction", Vector) = (-1, 0, 0)
        [HideInInspector][PerRendererData]_FaceUpDirWS("Face Up Direction", Vector) = (0, 1, 0)
        [Header(Environment Lighting Setting)]
        _EnvironmentLightingIntensity ("Environment Lighting Intensity", Range(0, 1)) = 0
        _AmbientOcclusionUsage ("Ambient Occlusion Usage", Range(0, 1)) = 0
        _EnvironmentLightingBaseColorMixing ("Environment Lighting Base Color Mixing", Range(0, 1)) = 0
        [Header(Specular Lighting Setting)]
        _SpecularIntensity("Specular Intensity", Range(0, 100)) = 1
        _SpecularSmoothness ("Specular Smoothness", Range(0, 1)) = 0.5
        [Header(Emission Setting)]
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity ("Emission Intensity", Range(0, 100)) = 0
        _EmissionBaseColorMixing ("Base Color Emission Mixing", Range(0, 1)) = 0
        _MaskEmissionColor ("Mask Emission Color", Color) = (1, 1, 1, 1)
        _MaskEmissionIntensity ("Mask Emission Intensity", Range(0, 100)) = 0
        _MaskEmissionBaseColorMixing ("Mask Emission Base Color Mixing", Range(0, 1)) = 0
        [Header(Outline Setting)]
        [Enum(Fixed, 1, Dynamic, 2)]_OutlineMode("Outline Width Type", Integer) = 1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width(Unit: Pixel)", Float) = 0
        [HideInInspector][PerRendererData]_DynamicOutlineWidth("Dynamic Outline Width(Use by controller script)", Float) = 0
        _OutlineZBias ("Outline Z Bias", Float) = 0
        [Header(Stencil Setting)]
        [IntRange]_StencilValue ("Stencil Value", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPass ("Stencil Pass Operation", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilFail ("Stencil Fail Operation", Float) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilZFail ("Stencil ZFail Operation", Float) = 0
        [IntRange]_StencilWriteMask ("Stencil Write Mask", Range(0, 255)) = 255
        [IntRange]_StencilReadMask ("Stencil Read Mask", Range(0, 255)) = 255
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
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            // -------------------------------------
            // Alpha settings
            Blend One Zero
            BlendOp Add
            Cull Off
            ZWrite On
            ZTest LEqual
            // -------------------------------------
            // Stencil settings
            Stencil
            {
                Ref [_StencilValue]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPass]
                Fail [_StencilFail]
            }
            // -------------------------------------
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag
            // -------------------------------------
            // Custom keywords
            #pragma shader_feature _AREA_BODY _AREA_HAIR _AREA_FACE
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
            // -------------------------------------
            // Include Shader Core
            #include "HsrCharacterForwardShader.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "Outline"
            }
            Blend One Zero
            BlendOp Add
            Cull Front
            ZWrite On
            ZTest LEqual
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag
            // -------------------------------------
            // Custom keywords
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
            // -------------------------------------
            // Include Shader Core
            #include "HsrOutlineShader.hlsl"
            ENDHLSL
        }
    }
}
