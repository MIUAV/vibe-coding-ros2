---
name: px4-multicopter-dev
description: PX4 软件在环仿真 (SITL) 环境设置与运行 - 支持 Gazebo、jMAVSim、SIH 仿真器
argument-hint: "PX4仿真" / "px4 sitl" / "启动仿真" / "仿真多旋翼"
user-invocable: true
---

# PX4 SITL 仿真技能

> 用于设置和运行 PX4 软件在环仿真环境

---

## 何时使用

当需要以下帮助时使用此技能：
- 在电脑上运行 PX4 仿真
- 测试飞行控制算法
- 验证无人机配置
- 调试自主飞行任务

---

## 快速参考

### 基础命令

```bash
# 克隆 PX4 源码
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd PX4-Autopilot

# 使用 Gazebo 启动 SITL (推荐)
make px4_sitl gz_x500

# 使用 jMAVSim 启动 SITL
make px4_sitl jmavsim

# 使用 SIH 启动 SITL (无依赖)
make px4_sitl_sih sihsim_quadx
```

### 仿真中控制无人机

```bash
# 在 PX4 控制台中起飞
commander takeoff

# 降落
commander land

# 切换模式
mode offboard
mode position

# 查看状态
status
```

---

## 支持的仿真器

| 仿真器 | 特点 | 适用场景 |
|--------|------|----------|
| **Gazebo** | 3D渲染、丰富传感器、ROS集成 | 视觉导航、避障、多机仿真 |
| **jMAVSim** | 轻量、快速启动 | 快速迭代、控制算法测试 |
| **SIH** | 无外部依赖、可在FC上运行 | 硬件集成测试、快速验证 |

---

## 多旋翼机型

```bash
# 四旋翼 (默认)
make px4_sitl gz_x500

# 六旋翼
make px4_sitl gz_x600

# 带光流的四旋翼
make px4_sitl gz_x500_opt_flow

# 带RTK GPS的四旋翼
make px4_sitl gz_x500_rtk
```

---

## 加速仿真

```bash
# 2倍速仿真
PX4_SIM_SPEED_FACTOR=2 make px4_sitl gz_x500

# 最多10倍速
PX4_SIM_SPEED_FACTOR=10 make px4_sitl gz_x500
```

---

## 连接到外部控制

### QGroundControl
仿真默认连接到 QGroundControl (UDP 端口 14550)

### MAVROS / MAVSDK
```bash
# 监听 offboard API 端口 (14540)
# 使用 MAVROS 连接
ros2 run mavros mavros_node _udp_port:=14540
```

---

## 常用配置

### 使用自定义机型
```bash
export PX4_SIM_MODEL=iris
make px4_sitl gz
```

### 添加环境变量
```bash
# 设置仿真速度
export PX4_SIM_SPEED_FACTOR=2

# 设置日志级别
export PX4_LOG_LEVEL=info

# 启动仿真
make px4_sitl gz_x500
```

---

## 故障排除

### Gazebo 启动失败
```bash
# 确保 Gazebo 已安装
which gz

# 使用 jMAVSim 作为替代
make px4_sitl jmavsim
```

### 端口被占用
```bash
# 检查端口
netstat -an | grep 14550

# 使用不同端口(需要修改配置)
```

### 构建失败
```bash
# 清理并更新子模块
make distclean
git submodule update --recursive

# 重新构建
make px4_sitl gz_x500
```

---

## 相关文档

- [PX4 仿真文档](https://docs.px4.io/main/en/simulation/)
- [Gazebo 仿真](https://docs.px4.io/main/en/sim_gazebo_gz/)
- [jMAVSim 仿真](https://docs.px4.io/main/en/sim_jmavsim/)
- [SIH 仿真](https://docs.px4.io/main/en/sim_sih/)