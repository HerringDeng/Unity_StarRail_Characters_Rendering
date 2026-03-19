using System.Collections;
using System.Collections.Generic;
using JetBrains.Annotations;
using UnityEngine;
using UnityEngine.Rendering;

namespace GameRuntime.StateMachine
{
    public class MonoStateMachine : MonoBehaviour
    {
        [SerializeField]
        private IMachineState m_currentState;
        

        void Start()
        {
            
        }

        void Update()
        {
            m_currentState.OnUpdate();
        }

        void FixedUpdate()
        {
            m_currentState.OnFixedUpdate();
        }

        void LateUpdate()
        {
            m_currentState.OnLateUpdate();
        }
    }
}