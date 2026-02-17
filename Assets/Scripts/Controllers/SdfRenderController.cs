using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class SdfRenderController : MonoBehaviour
{
    public string headBoneName = "Head_M";
    private string lastHeadBoneName;
    [SerializeField]
    private Transform headBone;
    private Vector3 headForwardDirection;
    private Vector3 headUpDirection;
    private Vector3 headRightDirection;
    [SerializeField]
    private Renderer[] allRenderers;
    private int headForwardID = Shader.PropertyToID("_HeadForwardVectorWS");
    private int headRightID = Shader.PropertyToID("_HeadRightVectorWS");
    private int headUpID = Shader.PropertyToID("_HeadUpVectorWS");

    void Start()
    {
        Init();
    }

    private void Init()
    {
        UpdateHeadBone();
        allRenderers = GetComponentsInChildren<Renderer>(true);
    }

    private void UpdateHeadBone()
    {
        if(headBoneName != lastHeadBoneName)
        {
            lastHeadBoneName = headBoneName;
            var children = GetComponentsInChildren<Transform>();
            foreach(Transform t in children)
            {
                if(t.name == headBoneName)
                {
                    headBone = t;
                    break;
                }
            }
        }
    }

    private void CalculateDirection()
    {
        if(headBone != null)
        {   headForwardDirection = headBone.up;
            headUpDirection = -headBone.right;
            headRightDirection = -headBone.forward;
        }
    } 

    private void SentParametersToMaterials()
    {
        for(int i = 0; i < allRenderers.Length; i++)
        {
            Renderer r = allRenderers[i];
            foreach(Material mat in r.sharedMaterials)
            {
                if(mat.shader)
                {
                    mat.SetVector(headForwardID, headForwardDirection);
                    mat.SetVector(headRightID, headRightDirection);
                    mat.SetVector(headUpID, headUpDirection);
                }
            }
        }
    }

    void LateUpdate()
    {
        CalculateDirection();
        SentParametersToMaterials();
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(SdfRenderController))]
    public class InspectorButtonExampleEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector(); // 绘制默认的Inspector GUI元素
            SdfRenderController controller = (SdfRenderController)target;

            if (GUILayout.Button("初始化"))
            {
                controller.Init();
            }
        }
    }
#endif
}
