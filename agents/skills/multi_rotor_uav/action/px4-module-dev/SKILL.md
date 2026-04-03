---
name: px4-module-dev
description: PX4 模块/应用程序开发 - 创建自定义飞控模块、订阅 uORB 话题、发布数据
argument-hint: "开发PX4模块" / "px4 module" / "创建应用" / "uORB编程"
user-invocable: true
---

# PX4 模块开发技能

> 用于在 PX4 飞控上开发自定义模块和应用程序

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建新的 PX4 应用程序
- 订阅/发布 uORB 话题
- 访问传感器数据
- 实现自定义控制算法

---

## 快速参考

### 模块结构

```cpp
#include <px4_platform_common/px4_config.h>
#include <px4_platform_common/tasks.h>
#include <px4_platform_common/module.h>
#include <px4_platform_common/module_params.h>
#include <drivers/drv_hrt.h>
#include <uORB/uORB.h>
#include <uORB/topics/sensor_bias.h>
#include <uORB/topics/vehicle_attitude.h>

class MyModule : public ModuleBase<MyModule> {
public:
    MyModule();

    /** @return The name of the module. */
    static const char *get_name() { return "my_module"; }

    /** @return The default priority. */
    static constexpr int default_priority() { return 100; }

private:
    bool init() override;
    void run() override;
    void parameters_updated() override;
};
```

---

## uORB 消息

### 订阅话题

```cpp
// 声明订阅
orb_advert_t _attitude_sub;
int _attitude_sub_fd;

// 初始化
_attitude_sub = orb_subscribe(ORB_ID(vehicle_attitude));
orb_set_interval(_attitude_sub, 10);  // 10ms 间隔

// 检查更新
bool updated;
orb_check(_attitude_sub, &updated);

if (updated) {
    orb_copy(ORB_ID(vehicle_attitude), _attitude_sub, &_attitude);
}
```

### 发布话题

```cpp
// 声明发布者
orb_advert_t _pub;

// 初始化
_pub = orb_advertise(ORB_ID(vehicle_attitude), nullptr);

// 发布数据
_attitude.timestamp = hrt_absolute_time();
_attitude.q[0] = 1.0f;
orb_publish(ORB_ID(vehicle_attitude), _pub, &_attitude);
```

---

## 常用话题参考

### 传感器话题

| 话题 | 说明 |
|------|------|
| `sensor_accel` | 加速度计 |
| `sensor_gyro` | 陀螺仪 |
| `sensor_mag` | 磁罗盘 |
| `sensor_baro` | 气压计 |
| `sensor_gps` | GPS 数据 |
| `sensor_optical_flow` | 光流 |

### 状态话题

| 话题 | 说明 |
|------|------|
| `vehicle_attitude` | 姿态 (四元数) |
| `vehicle_local_position` | 局部位置 |
| `vehicle_global_position` | 全局位置 |
| `vehicle_odometry` | 里程计 |
| `vehicle_status` | 飞控状态 |

### 控制话题

| 话题 | 说明 |
|------|------|
| `actuator_controls` | 执行器控制 |
| `vehicle_command` | 车辆命令 |
| `offboard_control_mode` | Offboard 模式 |

---

## 模块参数

### 定义参数

```cpp
// 参数结构体
struct ParamHandle {
    float param1;
    int32_t param2;
    bool param3;
};

// 声明参数
param_t _param_handle1;
param_t _param_handle2;

// 初始化
_param_handle1 = param_find("MY_PARAM1");
_param_handle2 = param_find("MY_PARAM2");

// 更新参数
void parameters_updated() {
    param_get(_param_handle1, &(_params.param1));
    param_get(_param_handle2, &(_params.param2));
}
```

### 参数文件 (module.yaml)

```yaml
module_name: my_module
module_args: []

parameters:
  - name: param1
    type: float
    default: 1.0
    description: "First parameter"
  - name: param2
    type: int32
    default: 10
    description: "Second parameter"
```

---

## 模块注册

### 在 module_tables 中注册

```cpp
// src/modules/modules_main.cpp
#ifdef CONFIG_MODULES
#include "my_module/MyModule.hpp"
#endif

// 添加到模块列表
#ifdef CONFIG_MODULES
    ...,
    MyModule::init_class,
#endif
```

---

## 编译和测试

### 编译模块

```bash
# 开发 SITL
make px4_sitl gz_x500

# 单独编译模块
make px4_fmu-v5_default
```

### 测试运行

```bash
# 在 SITL 控制台
my_module start

# 查看状态
my_module status

# 停止
my_module stop
```

---

## 最佳实践

### 代码规范

1. **使用 `ModuleBase` 模板类**
2. **实现所有纯虚方法**
3. **正确处理参数更新**
4. **定期检查退出标志**

### 资源管理

```cpp
void run() override {
    while (!should_exit()) {
        // 主循环
        
        // 适当休眠
        px4_usleep(10000);  // 10ms
    }
}

void stop() override {
    _should_exit = true;
}
```

---

## 常见模式

### 发布者-订阅者

```cpp
class MyModule : public ModuleBase<MyModule> {
    // 订阅
    orb_advert_t _sub;
    
    // 发布
    orb_advert_t _pub;
    
    void run() override {
        _sub = orb_subscribe(ORB_ID(sensor_data));
        _pub = orb_advertise(ORB_ID(output_data), nullptr);
        
        while (!should_exit()) {
            // 检查更新
            bool updated;
            orb_check(_sub, &updated);
            
            if (updated) {
                orb_copy(ORB_ID(sensor_data), _sub, &data);
                // 处理并发布
                orb_publish(ORB_ID(output_data), _pub, &output);
            }
            
            px4_usleep(1000);
        }
    }
};
```

### 定时器模式

```cpp
// 使用定时器代替轮询
void run() override {
    // 每 10ms 回调
    px4_pollfd_struct_t fds[1];
    fds[0].fd = _sub;
    fds[0].events = POLLIN;
    
    while (!should_exit()) {
        int ret = px4_poll(fds, 1, 10);
        
        if (ret > 0) {
            // 处理数据
        }
    }
}
```

---

## 相关文档

- [PX4 模块开发](https://docs.px4.io/main/en/modules/module_template.html)
- [uORB 文档](https://docs.px4.io/main/en/middleware/uorb.html)
- [开发者指南](https://docs.px4.io/main/en/development/development.html)