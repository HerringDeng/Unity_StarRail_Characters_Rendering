using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Unity.VisualScripting;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    private Transform cameraTransform;
    private bool isCursorLock = true;
    public float moveSpeed;
    public Transform viewFollowTarget;
    public float followSpeed;
    void Start()
    {
        cameraTransform = GetComponent<Transform>();
    }

    // LateUpdate is called once per frame after all Update calls
    void LateUpdate()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            isCursorLock = !isCursorLock;
        }
        if (Input.GetKey(KeyCode.W))
        {
            cameraTransform.position += cameraTransform.forward * moveSpeed*Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S))
        {
            cameraTransform.position -= cameraTransform.forward * moveSpeed*Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A))
        {
            cameraTransform.position -= cameraTransform.right.normalized * moveSpeed*Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.D))
        {
            cameraTransform.position += cameraTransform.right.normalized * moveSpeed*Time.deltaTime;
        }
        Vector3 targetDirection = viewFollowTarget.position - cameraTransform.position;
        Vector3 newDirection = Vector3.RotateTowards(transform.forward, targetDirection, followSpeed*Time.deltaTime, 0.0f);
        Debug.DrawRay(transform.position, newDirection, Color.red);
        cameraTransform.rotation = Quaternion.LookRotation(newDirection);
    }
}
