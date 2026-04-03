---
name: managed-node-design
description: 托管节点设计技能 - LifecycleNode、状态回调、Configure/Activate、ROS2 生命周期
argument-hint: "LifecycleNode" / "managed" / "configure" / "activate" / "deactivate"
user-invocable: true
---

# 托管节点设计技能

> ROS2 生命周期托管节点

---

## 何时使用

当需要以下帮助时使用此技能：
- LifecycleNode 使用
- 状态回调处理
- Configure/Activate
- 托管节点 launch
- 生命周期服务

---

## 核心实现

### LifecycleNode

```python
import rclpy
from rclpy.lifecycle import LifecycleNode
from rclpy.lifecycle import publisher_factory
from rclpy.lifecycle import TransitionCallbackReturn

class ManagedSensorNode(LifecycleNode):
    def __init__(self):
        super().__init__('managed_sensor_node')
        
        # 声明参数
        self.declare_parameter('device', '/dev/video0')
        self.declare_parameter('frame_rate', 30)
        
        # 状态
        self.sensor_initialized = False
        
    def on_configure(self, state):
        """配置状态回调"""
        self.get_logger().info('Configuring...')
        
        # 获取参数
        device = self.get_parameter('device').value
        
        # 初始化传感器
        try:
            self.init_sensor(device)
            self.sensor_initialized = True
            return TransitionCallbackReturn.SUCCESS
        except Exception as e:
            self.get_logger().error(f'Configure failed: {e}')
            return TransitionCallbackReturn.FAILURE
            
    def on_activate(self, state):
        """激活状态回调"""
        self.get_logger().info('Activating...')
        
        if not self.sensor_initialized:
            self.get_logger().error('Cannot activate without configuration')
            return TransitionCallbackReturn.FAILURE
            
        # 启用发布者
        self.publisher = self.create_publisher(Image, '/image', 10)
        
        # 启动定时器
        self.timer = self.create_timer(0.033, self.capture_callback)
        
        return TransitionCallbackReturn.SUCCESS
        
    def on_deactivate(self, state):
        """停用状态回调"""
        self.get_logger().info('Deactivating...')
        
        # 停止定时器
        self.timer.cancel()
        
        # 销毁发布者
        self.destroy_publisher(self.publisher)
        
        return TransitionCallbackReturn.SUCCESS
        
    def on_cleanup(self, state):
        """清理状态回调"""
        self.get_logger().info('Cleaning up...')
        
        # 关闭传感器
        self.close_sensor()
        self.sensor_initialized = False
        
        return TransitionCallbackReturn.SUCCESS
        
    def on_shutdown(self, state):
        """关闭状态回调"""
        self.get_logger().info('Shutting down...')
        return TransitionCallbackReturn.SUCCESS
        
    def init_sensor(self, device):
        """初始化传感器"""
        pass
        
    def capture_callback(self):
        """采集回调"""
        pass
```

### 生命周期 Launch

```python
# launch/lifecycle.launch.py
from launch import LaunchDescription
from launch_ros.actions import LifecycleNode
from launch_ros.actions import TimerAction

def generate_launch_description():
    sensor_node = LifecycleNode(
        package='robot_driver',
        executable='sensor_node',
        name='sensor_node',
        parameters=[{'device': '/dev/video0'}],
        output='screen'
    )
    
    # 启动管理器
    lifecycle_manager = TimerAction(
        period=2.0,
        actions=[
            # 按顺序激活
            # 1. 配置
            lifecycle_node.set_state(lifecycle_state.CONFIGURE),
            # 2. 激活
            lifecycle_node.set_state(lifecycle_state.ACTIVATE),
        ]
    )
    
    return LaunchDescription([
        sensor_node,
        lifecycle_manager
    ])
```

### 生命周期客户端

```python
# lifecycle_client.py
import rclpy
from rclpy.node import Node
from lifecycle_msgs.srv import ChangeState, GetState
from lifecycle_msgs.msg import Transition

class LifecycleClient(Node):
    def __init__(self):
        super().__init__('lifecycle_client')
        
        self.get_state_client = self.create_client(
            GetState, '/sensor_node/get_state')
        self.change_state_client = self.create_client(
            ChangeState, '/sensor_node/change_state')
            
    def get_state(self):
        """获取当前状态"""
        request = GetState.Request()
        future = self.get_state_client.call_async(request)
        rclpy.spin_until_future_complete(self, future)
        return future.result().current_state.label
        
    def change_state(self, transition_label):
        """改变状态"""
        # 转换标签到 ID
        transition_id = {
            'configure': Transition.TRANSITION_CONFIGURE,
            'activate': Transition.TRANSITION_ACTIVATE,
            'deactivate': Transition.TRANSITION_DEACTIVATE,
            'cleanup': Transition.TRANSITION_CLEANUP,
            'shutdown': Transition.TRANSITION_SHUTDOWN
        }[transition_label]
        
        request = ChangeState.Request()
        request.transition.id = transition_id
        future = self.change_state_client.call_async(request)
        rclpy.spin_until_future_complete(self, future)
        return future.result().success
```
