---
name: nav2-config
description: Nav2 (Navigation2) 参数速查 — DWB/MPPI控制器、规划器、代价地图、行为树的 50+ 参数中文解释与调节范围，4大典型调优场景
argument-hint: Nav2参数调节 OR navigation配置 OR DWB控制器 OR move_base参数 OR 机器人导航不走
user-invocable: true
---

# nav2-config — Nav2 参数知识库

## 目的

Nav2 (Navigation2) 有 100+ 参数，调节不好机器人就不会动。本技能提供：
1. 核心参数的中文解释和调节范围
2. 典型场景的调优指南
3. 常见故障的快速排查

## 参数速查表

### 🟢 控制器 (dwb_controller / mppi_controller)

| 参数 | 默认值 | 说明 | 调节范围 |
|------|--------|------|----------|
| `max_vel_x` | 0.5 m/s | 最大线速度 | 0.1 ~ 2.0 |
| `max_vel_theta` | 1.0 rad/s | 最大角速度 | 0.5 ~ 2.0 |
| `acc_lim_x` | 2.5 m/s² | 线加速度限制 | 0.1 ~ 5.0 |
| `acc_lim_theta` | 3.2 rad/s² | 角加速度限制 | 1.0 ~ 10.0 |
| `min_vel_x` | 0.0 m/s | 最小线速度（负=后退） | -0.5 ~ 0.0 |
| `vx_samples` | 20 | 线速度采样数（精度/速度权衡） | 5 ~ 50 |
| `vtheta_samples` | 20 | 角速度采样数 | 5 ~ 50 |

### 🟢 规划器 (nav2_planner)

| 参数 | 默认值 | 说明 | 调节范围 |
|------|--------|------|----------|
| `forward_prune_distance` | 1.0 m | 路径前方多少米后裁剪旧路径点 | 0.5 ~ 3.0 |
| `allow_unknown` | true | 是否允许穿越未探索区域 | — |
| `tolerance` | 0.5 m | 到目标点的容差 | 0.1 ~ 1.0 |

### 🟢 代价地图 (nav2_costmap_2d)

| 参数 | 默认值 | 说明 | 调节范围 |
|------|--------|------|----------|
| `inflation_radius` | 0.55 m | 障碍物膨胀半径 | 0.3 ~ 1.5 |
| `cost_scaling_factor` | 1.0 | 代价衰减系数（越大障碍物边沿越陡） | 0.5 ~ 5.0 |
| `observation_sources` | [scan] | 传感器数据源列表 | — |
| `map_resolution` | 0.05 m/格 | 地图分辨率 | 0.02 ~ 0.2 |

### 🟢 行为树 (bt_navigator)

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `bt_xml_filename` | — | 行为树 XML 文件路径 |
| `plugin_lib_names` | — | 行为树插件库列表 |

## 典型场景调优

### 场景1: 机器人走得慢，路径合理但速度提不上

检查项：
1. `max_vel_x` 是否设低了？
2. `acc_lim_x` 是否太小（启停缓慢）？
3. `inflation_radius` 是否太大（贴着墙走时减速）？

```yaml
# 推荐速度配置（室内配送机器人）
controller_server:
  ros__parameters:
    max_vel_x: 0.8          # 提高
    max_vel_theta: 1.5      # 提高
    acc_lim_x: 3.0          # 提高加速度
    acc_lim_theta: 3.2
    min_vel_x: -0.3         # 允许小幅后退
```

### 场景2: 机器人靠近障碍物时抖动

原因：`inflation_radius` + `cost_scaling_factor` 导致边界代价梯度太陡。

解决：
```yaml
# 减小抖动
costmap:
  ros__parameters:
    inflation_radius: 0.35    # 减小（更早减速）
    cost_scaling_factor: 2.5   # 提高（更陡的梯度）
```

### 场景3: 动态障碍物（人）绕行不及时

检查项：
1. `controller_server.footprint` 是否正确？
2. `observation_sources` 是否包含动态障碍检测传感器？

```yaml
# 动态障碍绕行配置
controller_server:
  ros__parameters:
    # 添加动态障碍容许
    max_agent_radius: 0.4     # 假设人体半径 40cm
    agent_penalty: 1000        # 碰到"代理"的惩罚
```

### 场景4: 路径规划成功但执行失败（"导航失败"）

原因：全局路径有但控制器无法跟踪（局部路径规划失败）。

检查：
```bash
# 查看控制器输出
ros2 topic echo /cmd_vel
# 应该看到非零速度命令

# 查看局部代价地图
ros2 run nav2_map_server map_saver_cli -f my_map
```

## 快速排查流程

```
导航失败?
├─ 路径规划失败（地图问题）
│  └─ 解决: 降低 tolerance, 检查 amcl pose
├─ 控制器跟踪失败（速度为零）
│  ├─ 检查 cmd_vel 是否有输出
│  ├─ inflation_radius 是否太小
│  └─ 检查 footprint 是否正确
└─ 行为树节点崩溃
   └─ 解决: 查看 bt_navigator 日志
```

## AI 生成 Nav2 配置时的强制规则

```yaml
# ❌ 禁止：无注释的原始参数
controller_server:
  ros__parameters:
    max_vel_x: 0.5  # 没人知道这是干嘛的

# ✅ 必须：带单位/说明的参数
controller_server:
  ros__parameters:
    max_vel_x: 0.5  # m/s — 室内配送机器人最大线速度
    inflation_radius: 0.55  # m — 障碍物膨胀半径（机器人半径 0.3m + 安全余量）
```

## 相关资源

- Nav2 官方文档: https://docs.nav2.org/
- Nav2 参数描述: https://github.com/ros-planning/navigation2/tree/main/nav2_bringup/params
