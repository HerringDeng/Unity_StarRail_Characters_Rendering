using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Net.Sockets;
using Unity.VisualScripting;

public class DirectionTester : MonoBehaviour
{
    public GameObject testedObject;
    void func()
    {
        Transform transform = testedObject.GetComponent<Transform>();
        Debug.Log(transform.forward);
        Debug.Log(transform.up);
        Debug.Log(transform.right);
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(DirectionTester))]
    public class InspectorButtonExampleEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector(); // 绘制默认的Inspector GUI元素
            DirectionTester myScript = (DirectionTester)target;
            if (GUILayout.Button("显示头部骨骼方向"))
            {
                myScript.func();
            }
        }
    }
#endif
}
