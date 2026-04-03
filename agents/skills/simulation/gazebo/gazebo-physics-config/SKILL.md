---
name: gazebo-physics-config
description: Gazebo 物理配置技能 - ODE/ Bullet/DART 物理引擎、接触参数、步长设置
argument-hint: Gazebo物理 OR physics OR ODE OR Bullet OR contact
user-invocable: true
---

# Gazebo 物理配置技能

> Gazebo 物理引擎配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 物理引擎选择
- ODE/Bullet/DART 配置
- 接触参数调整
- 实时因子
- 碰撞迭代

---

## 核心配置

### ODE 物理引擎

```xml
<!-- ODE 配置 -->
<physics name="ode_physics" type="ode">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
  
  <ode>
    <solver>
      <type>quick</type>
      <iters>50</iters>
      <sor>1.3</sor>      <!-- 超松弛 -->
    </solver>
    
    <constraints>
      <cfm>0</cfm>         <!-- 约束混合 -->
      <erp>0.2</erp>       <!-- 误差减少参数 -->
      <contact_max_correcting_vel>100</contact_max_correcting_vel>
      <contact_surface_layer>0.001</contact_surface_layer>
    </constraints>
  </ode>
</physics>
```

### Bullet 物理引擎

```xml
<!-- Bullet 配置 -->
<physics name="bullet_physics" type="bullet">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
  
  <bullet>
    <solver>
      <type>sequential_impulse</type>
      <num_threads>4</num_threads>
      <iters>100</iters>
      <warm_start>1</warm_start>
    </solver>
    
    <constraints>
      <cfm>0</cfm>
      <erp>0.2</erp>
      <contact_tolerance>0.001</contact_tolerance>
      <contact_surface_layer>0.0001</contact_surface_layer>
    </constraints>
  </bullet>
</physics>
```

### ROS2 物理参数动态调整

```python
import rclpy
from rclpy.node import Node
from gazebo_msgs.srv import SetPhysicsProperties

class PhysicsConfig(Node):
    def __init__(self):
        super().__init__('physics_config')
        
        self.client = self.create_client(
            SetPhysicsProperties, '/gazebo/set_physics_properties')
            
    def set_physics(self, max_step_size=0.001, real_time_factor=1.0):
        """设置物理参数"""
        request = SetPhysicsProperties.Request()
        request.max_step_size = max_step_size
        request.real_time_factor = real_time_factor
        request.real_time_update_rate = 1000
        
        # ODE 参数
        request.ode_config.solver_type = 1  # quick
        request.ode_config.iters = 50
        request.ode_config.cfm = 0.0
        request.ode_config.erp = 0.2
        
        self.client.call_async(request)
```
