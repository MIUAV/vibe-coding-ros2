---
name: plugin-development
description: Gazebo 插件开发技能 - C++ 传感器插件、控制器、系统插件
argument-hint: gazebo插件开发 OR 编写传感器插件 OR 自定义控制器
user-invocable: true
---

# Gazebo Plugin Development Skill

> 用于开发 Gazebo Harmonic 插件

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建自定义传感器插件
- 编写控制器插件
- 开发系统插件
- 添加自定义物理行为

---

## 快速参考

### 插件基本结构

```cpp
#include <gz/sim/System.hh>
#include <gz/sim/Entity.hh>
#include <gz/sim/EntityComponentManager.hh>

class MyPlugin : public gz::sim::System,
                 public gz::sim::ISystemPreUpdate
{
  public: MyPlugin() = default;
  
  public: void PreUpdate(
      const gz::sim::UpdateInfo &_info,
      gz::sim::EntityComponentManager &_ecm) override
  {
    // 插件逻辑
  }
};

GZ_ADD_PLUGIN(MyPlugin, gz::sim::ISystemPreUpdate)
```

---

## 创建 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(gz_my_plugin)

# 找到 Gazebo
find_package(gz-logging7 REQUIRED COMPONENTS sim)
find_package(gz-math7 REQUIRED)
find_package(gz-plugin1 REQUIRED COMPONENTS loader)

# 创建共享库
add_library(my_plugin SHARED
  my_plugin.cc
)

# 链接库
target_link_libraries(my_plugin
  gz-sim7::gz-sim
  gz-plugin1::loader
  gz-logging7::gz-logging
)

# 安装
install(TARGETS my_plugin LIBRARY DESTINATION lib)
```

---

## 系统插件

### 基本系统插件

```cpp
#include <gz/sim/System.hh>
#include <gz/sim/EntityComponentManager.hh>
#include <gz/sim/Entity.hh>

namespace my_robot_plugin
{
  class MySystem : public gz::sim::System,
                   public gz::sim::ISystemPreUpdate,
                   public gz::sim::ISystemPostUpdate
  {
    public: void PreUpdate(
        const gz::sim::UpdateInfo &_info,
        gz::sim::EntityComponentManager &_ecm) override
    {
      // 更新前逻辑
    }
    
    public: void PostUpdate(
        const gz::sim::UpdateInfo &_info,
        gz::sim::EntityComponentManager &_ecm) override
    {
      // 更新后逻辑
    }
    
    private: double myParameter{1.0};
  };
}

GZ_ADD_PLUGIN(my_robot_plugin::MySystem,
              gz::sim::ISystemPreUpdate,
              gz::sim::ISystemPostUpdate)
```

### 控制器插件

```cpp
#include <gz/sim/System.hh>
#include <gz/sim/components/Joint.hh>
#include <gz/sim/components/JointPosition.hh>
#include <gz/sim/components/JointVelocity.hh>
#include <gz/sim/components/JointCommand.hh>

namespace robot_controller
{
  class JointController : public gz::sim::System,
                          public gz::sim::ISystemConfigure,
                          public gz::sim::ISystemPreUpdate
  {
    public: void Configure(
        const gz::sim::Entity &_entity,
        const std::shared_ptr<const sdf::Element> &_sdf,
        gz::sim::EntityComponentManager &_ecm,
        gz::sim::EventManager &_eventMgr) override
    {
      // 读取配置参数
      if (_sdf->HasElement("joint_name"))
      {
        this->jointName = _sdf->Get<std::string>("joint_name");
      }
      
      if (_sdf->HasElement("target_position"))
      {
        this->targetPosition = _sdf->Get<double>("target_position");
      }
    }
    
    public: void PreUpdate(
        const gz::sim::UpdateInfo &_info,
        gz::sim::EntityComponentManager &_ecm) override
    {
      // PD 控制器实现
      auto jointEntity = _ecm.EntityByName(this->jointName);
      if (jointEntity == gz::sim::kNullEntity)
        return;
        
      // 获取当前位置和速度
      auto posComp = _ecm.Component<gz::sim::components::JointPosition>(jointEntity);
      auto velComp = _ecm.Component<gz::sim::components::JointVelocity>(jointEntity);
      
      // 计算控制力
      double error = this->targetPosition - posComp->Data()[0];
      double control = this->kp * error - this->kd * velComp->Data()[0];
      
      // 应用控制
      auto cmdComp = _ecm.Component<gz::sim::components::JointCommand>(jointEntity);
      cmdComp->Data()[0] = control;
    }
    
    private: std::string jointName;
    private: double targetPosition{0.0};
    private: double kp{10.0};
    private: double kd{1.0};
  };
}

GZ_ADD_PLUGIN(robot_controller::JointController,
              gz::sim::ISystemConfigure,
              gz::sim::ISystemPreUpdate)
```

---

## 传感器插件

### 自定义传感器

```cpp
#include <gz/sim/Sensor.hh>
#include <gz/sim/SensorSystem.hh>
#include <gz/sim/EntityComponentManager.hh>

namespace custom_sensor
{
  class MySensor : public gz::sim::Sensor
  {
    public: MySensor() : Sensor() {}
    
    public: void Load(const gz::sim::Entity &_entity,
                      sdf::ElementPtr _sdf) override
    {
      Sensor::Load(_entity, _sdf);
      
      // 加载自定义参数
      if (_sdf->HasElement("my_param"))
      {
        this->myParam = _sdf->Get<double>("my_param");
      }
    }
    
    public: bool Update(
        const std::chrono::steady_clock::duration &_now) override
    {
      // 读取传感器数据
      // 生成输出数据
      
      this->pub.Publish(this->data);
      return true;
    }
    
    private: double myParam{1.0};
  };
}

// 注册传感器
GZ_ADD_PLUGIN(custom_sensor::MySensor,
              gz::sim::SensorSystem)
```

### 使用现有传感器系统

```cpp
#include <gz/sim/System.hh>

namespace example_plugins
{
  // 使用已有的 Ray Sensor 系统
  class LaserScannerPlugin : public gz::sim::System,
                              public gz::sim::ISystemConfigure
  {
    public: void Configure(
        const gz::sim::Entity &_entity,
        const std::shared_ptr<const sdf::Element> &_sdf,
        gz::sim::EntityComponentManager &_ecm,
        gz::sim::EventManager &_eventMgr) override
    {
      // 配置激光扫描器
      this->sensorEntity = _entity;
      
      // 订阅更新
      _ecm.CreateComponent(_entity, gz::sim::components::Sensor());
    }
    
    private: gz::sim::Entity sensorEntity;
  };
}

GZ_ADD_PLUGIN(example_plugins::LaserScannerPlugin,
              gz::sim::ISystemConfigure)
```

---

## 在模型中使用插件

```xml
<!-- robot.sdf -->
<model name="my_robot">
  <link name="base_link">
    <sensor name="my_sensor" type="custom">
      <my_param>1.5</my_param>
      <plugin filename="gz-custom-sensor-system" 
              name="custom_sensor::MySensor">
      </plugin>
    </sensor>
  </link>
  
  <plugin filename="gz-robot-controller-system" 
          name="robot_controller::JointController">
    <joint_name>arm_joint</joint_name>
    <target_position>0.5</target_position>
    <kp>10.0</kp>
    <kd>1.0</kd>
  </plugin>
</model>
```

---

## 实体组件系统 (ECS)

### 读取组件

```cpp
void ReadComponents(gz::sim::EntityComponentManager &_ecm, gz::sim::Entity entity)
{
  // 位置
  if (auto posComp = _ecm.Component<gz::sim::components::WorldPose>(entity))
  {
    gz::math::Pose3d pose = posComp->Data();
  }
  
  // 速度
  if (auto velComp = _ecm.Component<gz::sim::components::LinearVelocity>(entity))
  {
    gz::math::Vector3d vel = velComp->Data();
  }
  
  // 关节位置
  if (auto jointPos = _ecm.Component<gz::sim::components::JointPosition>(entity))
  {
    auto positions = jointPos->Data();
  }
}
```

### 创建组件

```cpp
void CreateComponents(gz::sim::EntityComponentManager &_ecm, gz::sim::Entity entity)
{
  // 创建自定义组件
  _ecm.CreateComponent(entity, gz::sim::components::WorldPose());
  
  // 创建带初始值的组件
  _ecm.CreateComponent(entity, 
      gz::sim::components::VelocityConfig(
          gz::math::Vector3d::Zero,
          gz::math::Vector3d::Zero
      ));
}
```

---

## 日志和调试

### 使用日志

```cpp
#include <gz/common/Console.hh>

void DebugLog()
{
  gzdbg << "Debug message" << std::endl;
  gzlog << "Info message" << std::endl;
  gzwarn << "Warning message" << std::endl;
  gzerr << "Error message" << std::endl;
}
```

---

## 构建和安装

```bash
# 构建
cd build
cmake ..
make -j$(nproc)

# 安装
sudo make install

# 设置环境
export GZ_SIM_SYSTEM_PLUGIN_PATH=/usr/local/lib:$GZ_SIM_SYSTEM_PLUGIN_PATH
```

---

## 常见问题

### 问题 1: 插件加载失败

**解决方案**：检查文件名和路径，确认插件路径设置正确

### 问题 2: 组件未找到

**解决方案**：确认组件已注册，使用正确的组件类型

---

## 相关资源

- [Gazebo Plugin Tutorial](https://gazebosim.org/docs/harmonic/plugins)
- [Gazebo API](https://gazebosim.org/api/sim/7/)

---

## 另见

- [robot-modeling](../robot-modeling/) - 机器人建模
- [sensor-integration](../sensor-integration/) - 传感器集成