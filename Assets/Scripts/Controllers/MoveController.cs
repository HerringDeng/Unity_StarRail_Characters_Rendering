using UnityEngine;

public class MoveController : MonoBehaviour
{
    // 输入
    public Vector2 moveInput;
    public int jumpInput;
    // 组件
    public Transform myTransform;
    public Animator myAnimator;
    public Rigidbody myRigidbody;
    public Collider footCollider;
    // 移动
    public float maximumMoveSpeed;
    public Vector2 currMoveSpeed
    {
        get;
        private set;
    }
    // 跳跃
    public float jumpUpAcceleration;
    public float jumpDownAcceleration;
    public int maximumJumpCount;
    public float currJumpSpeed
    {
        get;
        private set;
    }
    public int currJumpCount
    {
        get;
        private set;
    }
    public void Move(Vector2 _direction)
    {
        currMoveSpeed = _direction*maximumMoveSpeed;
        if(!myAnimator.applyRootMotion)
        {
            myRigidbody.velocity = new Vector3(currMoveSpeed.x, myRigidbody.velocity.y, currMoveSpeed.y);
        }
    }
    public void Jump()
    {
        if(currJumpCount < maximumJumpCount)
        {
            currJumpCount++;
            currJumpSpeed = jumpUpAcceleration;
            myRigidbody.velocity = new Vector3(myRigidbody.velocity.x, currJumpSpeed, myRigidbody.velocity.z);
        }
        Debug.Log("Jump Count: " + currJumpCount);
    }
    public void ResetJumpCount()
    {
        currJumpCount = 0;
    }
    void Start()
    {
        if(myTransform == null)
        {
            myTransform = transform;
        }
        if(myAnimator == null)
        {
            myAnimator = GetComponent<Animator>();
        }
        if(myRigidbody == null)
        {
            myRigidbody = GetComponent<Rigidbody>();
        }
    }

    void InputSimulatior()
    {
        moveInput = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical"));
        jumpInput = Input.GetButtonDown("Jump") ? 1 : 0;
    }

    void Update()
    {
        InputSimulatior();
        Move(moveInput);
        if(jumpInput == 1)
        {
            Jump();
        }
    }

    void OnCollisionEnter(Collision collision)
    {
        if(collision.gameObject.layer == LayerMask.NameToLayer("Ground"))
        {
            ResetJumpCount();
        }
    }
}
