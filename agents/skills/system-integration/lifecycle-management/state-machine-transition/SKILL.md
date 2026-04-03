---
name: state-machine-transition
description: 状态机转换技能 - 状态机设计、转换逻辑、层级状态机、ROS2 状态机
argument-hint: "状态机" / "state machine" / "transition" / "hierarchical"
user-invocable: true
---

# 状态机转换技能

> 机器人状态机设计

---

## 何时使用

当需要以下帮助时使用此技能：
- 状态机建模
- 转换逻辑
- 层级状态机
- 状态机实现
- 故障处理

---

## 核心实现

### 状态机基类

```python
from enum import Enum
from typing import Callable, Dict, List
import time

class StateMachine:
    def __init__(self, initial_state):
        self.current_state = initial_state
        self.previous_state = None
        self.transitions: Dict[tuple, Callable] = {}
        self.state_enter_time = {}
        
    def add_transition(self, from_state, to_state, callback=None):
        """添加转换"""
        self.transitions[(from_state, to_state)] = callback
        
    def transition_to(self, new_state):
        """执行转换"""
        if (self.current_state, new_state) not in self.transitions:
            raise ValueError(f"Invalid transition: {self.current_state} -> {new_state}")
            
        # 执行转换回调
        callback = self.transitions[(self.current_state, new_state)]
        if callback:
            callback()
            
        # 更新状态
        self.previous_state = self.current_state
        self.current_state = new_state
        self.state_enter_time[new_state] = time.time()
```

### 机器人状态机

```python
class RobotState(Enum):
    INIT = 'init'
    IDLE = 'idle'
    NAVIGATING = 'navigating'
    MANIPULATING = 'manipulating'
    ERROR = 'error'
    SHUTDOWN = 'shutdown'

class RobotStateMachine(StateMachine):
    def __init__(self):
        super().__init__(RobotState.INIT)
        
        # 状态进入/退出回调
        self.on_enter_handlers = {}
        self.on_exit_handlers = {}
        
        # 定义转换
        self.setup_transitions()
        
    def setup_transitions(self):
        """设置所有转换"""
        # INIT -> IDLE
        self.add_transition(RobotState.INIT, RobotState.IDLE, self.on_init_complete)
        
        # IDLE -> NAVIGATING
        self.add_transition(RobotState.IDLE, RobotState.NAVIGATING, self.on_navigation_start)
        
        # NAVIGATING -> IDLE
        self.add_transition(RobotState.NAVIGATING, RobotState.IDLE, self.on_navigation_complete)
        
        # ANY -> ERROR
        self.add_transition(RobotState.NAVIGATING, RobotState.ERROR, self.on_error)
        self.add_transition(RobotState.MANIPULATING, RobotState.ERROR, self.on_error)
        
        # ERROR -> IDLE (恢复)
        self.add_transition(RobotState.ERROR, RobotState.IDLE, self.on_recovery)
        
    def on_init_complete(self):
        """初始化完成"""
        print("Initialization complete, ready for commands")
        
    def on_navigation_start(self):
        """开始导航"""
        print("Starting navigation")
        
    def on_navigation_complete(self):
        """导航完成"""
        print("Navigation complete")
```

### 层级状态机

```python
class HierarchicalState:
    def __init__(self, name):
        self.name = name
        self.substates = {}
        self.current_substate = None
        self.parent = None
        
    def add_substate(self, state, is_initial=False):
        """添加子状态"""
        state.parent = self
        self.substates[state.name] = state
        if is_initial:
            self.current_substate = state.name
            
    def handle_event(self, event):
        """处理事件"""
        if self.current_substate:
            return self.substates[self.current_substate].handle_event(event)
        return None
        
# 示例: 导航子状态机
class NavigatingState(HierarchicalState):
    def __init__(self):
        super().__init__('navigating')
        
        self.planning = SubState('planning')
        self.executing = SubState('executing')
        self.recovering = SubState('recovering')
        
        self.add_substate(self.planning, is_initial=True)
        self.add_substate(self.executing)
        self.add_substate(self.recovering)
```
