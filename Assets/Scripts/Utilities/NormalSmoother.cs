using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Unity.Mathematics;

public class NormalSmoother : MonoBehaviour
{
    private Renderer[] allRenderers;
    public struct NormalWeight
    {
        public Vector3 normal;
        public float weight;
    }
    private void SmoothNormals(Mesh mesh)
    {
        Dictionary<Vector3, List<NormalWeight>> normalDict = new Dictionary<Vector3, List<NormalWeight>>();
        var triangles = mesh.triangles;
        var vertices = mesh.vertices;
        var normals = mesh.normals;
        var tangents = mesh.tangents;
        var smoothNormals = mesh.normals;
        var compressNormals = new Vector2[smoothNormals.Length];
        Debug.Log("开始遍历三角形顶点，并保存其所在三角形的法线和夹角");
        for (int i = 0; i <= triangles.Length - 3; i += 3)
        {
            int[] triangle = new int[] { triangles[i], triangles[i + 1], triangles[i + 2] };
            for (int j = 0; j < 3; j++)
            {
                int vertexIndex = triangle[j];
                Vector3 vertex = vertices[vertexIndex];
                if (!normalDict.ContainsKey(vertex))
                {
                    normalDict.Add(vertex, new List<NormalWeight>());
                }
                NormalWeight nw;
                Vector3 lineA = Vector3.zero;
                Vector3 lineB = Vector3.zero;
                if (j == 0)
                {
                    lineA = vertices[triangle[1]] - vertex;
                    lineB = vertices[triangle[2]] - vertex;
                }
                else if (j == 1)
                {
                    lineA = vertices[triangle[2]] - vertex;
                    lineB = vertices[triangle[0]] - vertex;
                }
                else
                {
                    lineA = vertices[triangle[0]] - vertex;
                    lineB = vertices[triangle[1]] - vertex;
                }
                lineA *= 10000f;
                lineB *= 10000f;
                nw.normal = Vector3.Cross(lineA, lineB).normalized;
                float angle = Mathf.Acos(Mathf.Max(Mathf.Min(Vector3.Dot(lineA, lineB) / (lineA.magnitude * lineB.magnitude), 1), -1));
                nw.weight = angle;
                normalDict[vertex].Add(nw);
            }
        }
        Debug.Log("开始计算每个顶点的平滑法线");
        for (int i = 0; i < vertices.Length; i++)
        {
            Vector3 vertex = vertices[i];
            List<NormalWeight> normalList = normalDict[vertex];
            Vector3 smoothNormal = Vector3.zero;
            float weightSum = 0;
            for (int j = 0; j < normalList.Count; j++)
            {
                NormalWeight nw = normalList[j];
                weightSum += nw.weight;
            }
            for (int j = 0; j < normalList.Count; j++)
            {
                NormalWeight nw = normalList[j];
                smoothNormal += nw.normal * nw.weight / weightSum;
            }
            smoothNormal = smoothNormal.normalized;
            smoothNormals[i] = smoothNormal;
            var normal = normals[i];
            var tangent = tangents[i];
            var binormal = (Vector3.Cross(normal, tangent) * tangent.w).normalized;
            var tbn = new Matrix4x4(tangent, binormal, normal, Vector3.zero);
            tbn = tbn.transpose;
            smoothNormals[i] = tbn.MultiplyVector(smoothNormals[i]).normalized;
            compressNormals[i] = OctahedronCompress(smoothNormals[i]);
        }
        mesh.SetUVs(1, compressNormals);
    }

    Vector2 OctahedronCompress(Vector3 sn)
    {
        Vector2 on = Vector2.zero;
        float L1 = math.abs(sn.x) + math.abs(sn.y) + math.abs(sn.z);
        sn/= L1;
        if (sn.z > 0)
        {
            on.x = sn.x;
            on.y = sn.y;
        }
        else
        {
            on.x = (1 - math.abs(sn.y)) * math.sign(sn.x);
            on.y = (1 - math.abs(sn.x)) * math.sign(sn.y);
        }
        on.x = (on.x+1.0f)/2.0f;
        on.y = (on.y+1.0f)/2.0f;
        return on;
    }
    void StartSmooth()
    {
        foreach (var item in GetComponentsInChildren<MeshFilter>())
        {
            SmoothNormals(item.sharedMesh);
        }
        foreach (var item in GetComponentsInChildren<SkinnedMeshRenderer>())
        {
            SmoothNormals(item.sharedMesh);
        }
    }

    // void Awake()
    // {
    //     StartSmooth();
    // }

#if UNITY_EDITOR
    [CustomEditor(typeof(NormalSmoother))]
    public class InspectorButtonExampleEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector(); // 绘制默认的Inspector GUI元素
            NormalSmoother myScript = (NormalSmoother)target;

            if (GUILayout.Button("平滑法线并保存到uv1"))
            {
                myScript.StartSmooth();
            }
        }
    }
#endif
}
