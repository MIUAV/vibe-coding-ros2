---
name: coppeliasim
description: CoppeliaSim 机器人仿真开发技能 - 远程 API、视觉脚本、碰撞检测、ROS/ROS2 集成
argument-hint: coppeliasim仿真 OR coppelia机器人 OR 远程API OR 视觉脚本
user-invocable: true
---

# CoppeliaSim Robot Simulation Skill

> 用于 CoppeliaSim 机器人仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 CoppeliaSim
- 使用远程 API 控制仿真
- 创建视觉脚本
- 配置传感器和碰撞检测
- 集成 ROS/ROS2

---

## 快速参考

### 安装 CoppeliaSim

```bash
# 下载 CoppeliaSim
# https://www.coppeliarobotics.com/downloads

# 解压
tar -xzvf CoppeliaSim_*.tgz

# 运行
cd CoppeliaSim
./coppeliaSim.sh
```

### 基本使用

```lua
-- Lua 脚本
sim = require('sim')

function sysCall_init()
    -- 初始化
end

function sysCall_actuation()
    -- 每帧执行
end
```

---

## 项目结构

```
my_project/
├── scenes/
│   └── robot.ttm                 # 场景文件
├── models/
│   └── my_robot.ttm              # 模型文件
├── scripts/
│   └── control.lua               # 控制脚本
├── remoteApiBindings/
│   └── (Python/C++ 远程 API)
└── textures/
    └── (纹理文件)
```

---

## 远程 API

### Python 客户端

```python
import sim

# 连接
sim.simxStart('127.0.0.1', 19997, True, True, 5000, 5)

# 获取句柄
_, robot_handle = sim.simxGetObjectHandle('Robot', sim.simxServiceCall)

# 设置位置
sim.simxSetObjectPosition(robot_handle, -1, [0, 0, 0.5], sim.simxCallMode)

# 获取位置
_, pos = sim.simxGetObjectPosition(robot_handle, -1, sim.simxCallMode)

# 设置关节位置
_, joint_handle = sim.simxGetObjectHandle('RevoluteJoint', sim.simxServiceCall)
sim.simxSetJointTargetPosition(joint_handle, 1.57, sim.simxCallMode)

# 断开
sim.simxFinish(-1)
```

### C++ 客户端

```cpp
#include "simLib.h"

int main() {
    // 启动
    simxInt clientID = simxStart("127.0.0.1", 19997, true, true, 2000, 5);
    
    if (clientID != -1) {
        // 获取句柄
        simxInt handle;
        simxGetObjectHandle(clientID, "Robot", &handle, simx_opmode_blocking);
        
        // 设置位置
        simxFloat pos[3] = {0, 0, 0.5};
        simxSetObjectPosition(clientID, handle, -1, pos, simx_opmode_blocking);
        
        // 停止
        simxFinish(clientID);
    }
    
    return 0;
}
```

---

## Lua 脚本

### 基础脚本结构

```lua
-- sysCall_init: 初始化 (执行一次)
function sysCall_init()
    -- 获取对象句柄
    robot_handle = sim.getObjectHandle('Robot')
    left_motor = sim.getObjectHandle('LeftMotor')
    right_motor = sim.getObjectHandle('RightMotor')
    
    -- 获取传感器
    proximity = sim.getObjectHandle('Proximity')
    sim.readProximitySensor(proximity)
end

-- sysCall_actuation: 每帧执行
function sysCall_actuation()
    -- 设置电机速度
    sim.setJointTargetVelocity(left_motor, 2.0)
    sim.setJointTargetVelocity(right_motor, 2.0)
end

-- sysCall_sensing: 每帧 sensing 阶段执行
function sysCall_sensing()
    -- 读取传感器
    local result, data = sim.readProximitySensor(proximity)
    if result == 1 then
        print("Detection!")
    end
end

-- sysCall_cleanup: 清理
function sysCall_cleanup()
    -- 停止电机
    sim.setJointTargetVelocity(left_motor, 0)
    sim.setJointTargetVelocity(right_motor, 0)
end
```

### 差速驱动

```lua
function sysCall_init()
    -- 句柄
    robot = sim.getObjectHandle('Robot')
    left_motor = sim.getObjectHandle('LeftMotor')
    right_motor = sim.getObjectHandle('RightMotor')
    
    -- 参数
    wheel_radius = 0.1
    axle_width = 0.3
end

function sysCall_actuation()
    -- cmd_vel 订阅
    local cmd = sim.getStringSignal('cmd_vel')
    if cmd then
        local vel = sim.unpackFloatTable(cmd, 2)
        local linear = vel[1]
        local angular = vel[2]
        
        -- 差速计算
        local left_vel = (linear - angular * axle_width / 2) / wheel_radius
        local right_vel = (linear + angular * axle_width / 2) / wheel_radius
        
        sim.setJointTargetVelocity(left_motor, left_vel)
        sim.setJointTargetVelocity(right_motor, right_vel)
    end
end
```

---

## 传感器

### 距离传感器

```lua
-- 红外/激光距离传感器
proximity = sim.getObjectHandle('ProximitySensor')

function sysCall_sensing()
    local result, distance, data = sim.readProximitySensor(proximity)
    
    if result == 1 then
        print("Distance:", distance)
    end
end
```

### 视觉传感器

```lua
-- 摄像头
camera = sim.getObjectHandle('Camera')

function sysCall_sensing()
    local image = sim.getVisionSensorImage(camera)
    -- 处理图像
end
```

### 力传感器

```lua
-- 力/力矩传感器
force_sensor = sim.getObjectHandle('ForceSensor')

function sysCall_sensing()
    local result, force, torque = sim.readForceSensor(force_sensor)
    
    if result == 1 then
        print("Force:", force[1], force[2], force[3])
        print("Torque:", torque[1], torque[2], torque[3])
    end
end
```

### 编码器

```lua
-- 关节编码器
joint = sim.getObjectHandle('RevoluteJoint')

function sysCall_sensing()
    local position = sim.getJointPosition(joint)
    local velocity = sim.getJointVelocity(joint)
    
    print("Position:", position, "Velocity:", velocity)
end
```

---

## 碰撞检测

```lua
-- 碰撞检测
collision = sim.getObjectHandle('Collision')

function sysCall_sensing()
    local result, data = sim.checkCollision(collision)
    
    if result then
        print("Collision detected!")
    end
end
```

### 自定义碰撞

```lua
function checkCollisionWithObstacle()
    local robot = sim.getObjectHandle('Robot')
    local obstacle = sim.getObjectHandle('Obstacle')
    
    local result = sim.checkCollision(robot, obstacle)
    return result
end
```

---

## ROS2 集成

### 安装 ROS2 接口

```bash
# 克隆仓库
cd ~/ros2_ws/src
git clone https://github.com/CoppeliaRobotics/sim_ros2_interface.git

# 构建
colcon build --packages-select sim_ros2_interface
```

### 使用 ROS2 插件

```lua
-- 在 CoppeliaSim 中启用 ROS2 插件
function sysCall_init()
    -- 初始化 ROS2 节点
    simROS2.init()
    
    -- 创建订阅
    cmd_sub = simROS2.subscribe('/cmd_vel', 'geometry_msgs/msg/Twist', 'cmd_callback')
    
    -- 创建发布
    odom_pub = simROS2.advertise('/odom', 'nav_msgs/msg/Odometry')
    image_pub = simROS2.advertise('/camera', 'sensor_msgs/msg/Image')
end

function cmd_callback(msg)
    -- 处理命令
    linear = msg.linear.x
    angular = msg.angular.z
end

function sysCall_sensing()
    -- 发布里程计
    local odom = {}
    odom.pose = getPose()
    simROS2.publish(odom_pub, odom)
end
```

### 自定义 ROS2 桥接

```python
# ros2_bridge.py
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
import sim

class CoppeliaBridge(Node):
    def __init__(self):
        super().__init__('coppelia_bridge')
        
        # 初始化 CoppeliaSim
        sim.simxStart('127.0.0.1', 19997, True, True, 5000, 5)
        
        # 订阅
        self.create_subscription(Twist, '/cmd_vel', self.cmd_vel_callback, 10)
        
        # 发布
        self.odom_pub = self.create_publisher(Odometry, '/odom', 10)
        
    def cmd_vel_callback(self, msg):
        # 发送到 CoppeliaSim
        data = [msg.linear.x, msg.angular.z]
        sim.simxSetStringSignal('cmd_vel', sim.packFloatTable(data), sim.simx_opmode_blocking)
        
    def timer_callback(self):
        # 获取里程计
        _, pos = sim.simxGetObjectPosition(robot, -1, sim.simx_opmode_blocking)
        _, vel = sim.simxGetObjectVelocity(robot, sim.simx_opmode_blocking)
        
        # 发布
        odom = Odometry()
        odom.pose.pose.position.x = pos[0]
        self.odom_pub.publish(odom)
```

---

## 动力学

### 设置质量

```lua
-- 设置质量
sim.setObjectFloatParameter(object, sim.objfloatparam_mass, 1.0)
```

### 设置摩擦

```lua
-- 设置摩擦系数
sim.setObjectFloatParameter(object, sim.objfloatparam_friction1, 1.0)
sim.setObjectFloatParameter(object, sim.objfloatparam_friction2, 1.0)
```

### 物理引擎

```lua
-- 物理引擎参数
sim.setPhysicsEngineParameter(sim.bullet_global_cfm, 0.001)
sim.setPhysicsEngineParameter(sim.bullet_global_erp, 0.2)
```

---

## 轨迹规划

### 逆运动学

```lua
-- 使用 IK
ik_group = sim.getIKGroupHandle('IK_Group')

function computeIK(target_pos, target_ori)
    -- 设置目标
    sim.setObjectPosition(ik_target, -1, target_pos)
    sim.setObjectOrientation(ik_target, -1, target_ori)
    
    -- 求解
    sim.handleIKGroup(ik_group)
    
    -- 获取结果
    return sim.getObjectPosition(robot_tip)
end
```

---

## 常见问题

### 问题 1: 远程 API 无法连接

**解决方案**：
- 检查端口 (默认 19997)
- 确认 CoppeliaSim 正在运行
- 检查防火墙设置

### 问题 2: 脚本不执行

**解决方案**：
- 确保脚本附加到对象
- 检查脚本类型 (child 或 simulation)
- 查看脚本错误日志

### 问题 3: 物理不稳定

**解决方案**：
- 减小时间步
- 增加 solver iterations
- 检查质量设置

---

## 相关资源

- [CoppeliaSim 文档](https://manual.coppeliarobotics.com/)
- [Remote API](https://manual.coppeliarobotics.com/en/remoteApi.htm)
- [ROS Interface](https://github.com/CoppeliaRobotics/sim_ros2_interface)

---

## 另见

- [lua-scripts](./lua-scripts/) - Lua 脚本
- [remote-api](./remote-api/) - 远程 API
- [webots](../webots/) - Webots 仿真
- [pybullet](../pybullet/) - PyBullet 仿真