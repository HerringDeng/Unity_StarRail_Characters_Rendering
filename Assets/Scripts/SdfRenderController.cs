using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode]
public class SdfRenderController : MonoBehaviour
{
    public Transform headCenter;
    public Transform headForward;
    public Transform headRight;
    private Renderer[] allRenderers;
    private int headForwardID = Shader.PropertyToID("_HeadForwardVectorWS");
    private int headRightID = Shader.PropertyToID("_HeadRightVectorWS");
    private int headUpID = Shader.PropertyToID("_HeadUpVectorWS");

    void LateUpdate()
    {
        if(allRenderers == null)
        {
            allRenderers = GetComponentsInChildren<Renderer>(true);
        }
        for(int i = 0; i < allRenderers.Length; i++)
        {
            Renderer r = allRenderers[i];
            foreach(Material mat in r.sharedMaterials)
            {
                if(mat.shader)
                {
                    Vector3 currHeadForwardVector = headForward.position-headCenter.position;
                    Vector3 currHeadRightVector = headRight.position-headCenter.position;

                    mat.SetVector(headForwardID, currHeadForwardVector.normalized);
                    mat.SetVector(headRightID, currHeadRightVector.normalized);
                    mat.SetVector(headUpID, Vector3.Cross(currHeadForwardVector, currHeadRightVector).normalized);
                }
            }
        }
    }
}
