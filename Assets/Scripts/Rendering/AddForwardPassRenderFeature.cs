using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;

[DisallowMultipleRendererFeature("Addtional Forward Passes")]
public class AddForwardPassRenderFeature : ScriptableRendererFeature
{
    [SerializeField] private List<string> m_AddtionalOpaquePassLightModeName = new List<string>();
    [SerializeField] private List<string> m_AddtionalTransparentPassLightModeName = new List<string>();
    private List<DrawObjectsPass> m_AddtionalOpaquePasses;
    private List<DrawObjectsPass> m_AddtionalTransparentPasses;
    private const string AddtionalOpaqueProfilerName = "DrawAddtionalOpaquePasses";
    private const string AddtionalTransparentProfilerName = "DrawAddtionalTransparentPasses";

    public override void Create()
    {
        m_AddtionalOpaquePasses = new List<DrawObjectsPass>();
        for(int i=0; i<m_AddtionalOpaquePassLightModeName.Count; i++)
        {
            m_AddtionalOpaquePasses.Add(new DrawObjectsPass(AddtionalOpaqueProfilerName, new ShaderTagId[]{new(m_AddtionalOpaquePassLightModeName[i])}, true, RenderPassEvent.AfterRenderingOpaques, RenderQueueRange.opaque, -1, new StencilState(), 0));
        }
        m_AddtionalTransparentPasses = new List<DrawObjectsPass>();
        for(int i=0; i<m_AddtionalTransparentPassLightModeName.Count; i++)
        {
            m_AddtionalTransparentPasses.Add(new DrawObjectsPass(AddtionalTransparentProfilerName, new ShaderTagId[]{new(m_AddtionalTransparentPassLightModeName[i])}, false, RenderPassEvent.AfterRenderingTransparents, RenderQueueRange.transparent, -1, new StencilState(), 0));
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        foreach(DrawObjectsPass p in m_AddtionalOpaquePasses)
        {
            renderer.EnqueuePass(p);
        }
        foreach(DrawObjectsPass p in m_AddtionalTransparentPasses)
        {
            renderer.EnqueuePass(p);
        }
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        base.SetupRenderPasses(renderer, in renderingData);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
    }
}

