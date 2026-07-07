using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HsrCharacterRenderController : MonoBehaviour
{
    public float outlineWidth = 3;
    private MaterialPropertyBlock propertyBlock;
    public SkinnedMeshRenderer myRenderer;
    void Start()
    {
        propertyBlock = new MaterialPropertyBlock();
    }

    void Update()
    {
        propertyBlock.SetFloat("_OutlineWidth", outlineWidth);
        myRenderer.SetPropertyBlock(propertyBlock);
    }
}
