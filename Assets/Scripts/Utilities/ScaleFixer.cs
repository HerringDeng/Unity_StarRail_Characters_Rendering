using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Net.Sockets;
using Unity.VisualScripting;

public class ScaleFixer : MonoBehaviour
{
    void func()
    {
        Transform[] tl = this.GetComponentsInChildren<Transform>();
        foreach (Transform i in tl)
        {
            i.localScale = new Vector3(1, 1, 1);
        }
    }

#if UNITY_EDITOR
    [CustomEditor(typeof(ScaleFixer))]
    public class InspectorButtonExampleEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector(); // 绘制默认的Inspector GUI元素
            ScaleFixer myScript = (ScaleFixer)target;
            if (GUILayout.Button("平滑法线并保存到uv7"))
            {
                myScript.func();
            }
        }
    }
#endif
}
