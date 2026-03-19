using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GameRuntime.StateMachine
{
    public interface IMachineState
    {
        void OnEnter();
        void OnUpdate();
        void OnFixedUpdate();
        void OnLateUpdate();
        void OnExit();
    }
}