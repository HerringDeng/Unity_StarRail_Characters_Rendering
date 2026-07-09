using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.PackageManager;

[ExecuteInEditMode]
public class HsrCharacterRenderController : MonoBehaviour
{
    //----------
    //脸部SDF
    [Header("Face SDF")]
    public Transform headBone;
    private Vector3 faceForwardDirWS;
    private Vector3 faceRightDirWS;
    private Vector3 faceUpDirWS;
    [Space]
    //----------
    //描边
    [Header("Outline")]
    public float outlineWidth = 3;
    //----------
    //材质相关
    private MaterialPropertyBlock propertyBlock;
    [SerializeField]
    private Renderer[] renderers;
    void Start()
    {
        if(headBone==null)
        {
            Transform[] children = GetComponentsInChildren<Transform>();
            foreach(var i in children)
            {
                if(i.gameObject.name=="Head_M")
                {
                    headBone = i;
                    break;
                }
            }
        }
        renderers = GetComponentsInChildren<Renderer>(true);
        propertyBlock = new MaterialPropertyBlock();
    }

    void UpdateFaceDirection()
    {
        if(headBone != null)
        {   faceForwardDirWS = headBone.up;
            faceRightDirWS = -headBone.forward;
            faceUpDirWS = -headBone.right;
            Debug.DrawRay(headBone.position, faceForwardDirWS, Color.red);
            Debug.DrawRay(headBone.position, faceRightDirWS, Color.blue);
            Debug.DrawRay(headBone.position, faceUpDirWS, Color.green);
        }
    } 

    void SetPropertyIntoBlock()
    {
        foreach(var r in renderers)
        {
            r.GetPropertyBlock(propertyBlock);
            propertyBlock.SetVector("_FaceForwardDirWS", faceForwardDirWS);
            propertyBlock.SetVector("_FaceRightDirWS", faceRightDirWS);
            propertyBlock.SetVector("_FaceUpDirWS", faceUpDirWS);
            propertyBlock.SetFloat("_DynamicOutlineWidth", outlineWidth);
            r.SetPropertyBlock(propertyBlock);
        }
    }

    void Update()
    {
        UpdateFaceDirection();
        SetPropertyIntoBlock();
    }
#if UNITY_EDITOR
[CustomEditor(typeof(HsrCharacterRenderController))]
    public class InspectorButtonExampleEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector(); // 绘制默认的Inspector GUI元素
            HsrCharacterRenderController controller = (HsrCharacterRenderController)target;
            if (GUILayout.Button("初始化"))
            {
                controller.Start();
            }
        }
    }
#endif
}
