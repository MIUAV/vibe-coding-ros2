---
name: nav2-config
description: Nav2配置知识库 - AMCL/DWB/Teb/Planners等50+参数的物理含义、调节范围、调试方法
argument-hint: Nav2配置 OR AMCL参数 OR DWB参数 OR Teb参数 OR 导航调参 OR nav2参数
user-invocable: true
---

# Nav2 配置知识库

> Nav2（Navigation2）是 ROS2 的标准导航栈。本技能覆盖核心组件的关键参数。

---

## 一、AMCL（自适应蒙特卡洛定位）

### 1.1 核心参数

```yaml
amcl:
  ros__parameters:
    # 传感器模型
    laser_model_type: 1           # 0=beam, 1=likelihood_field（推荐）
    laser_z_max: 0.5             # 最大激光射程（米）
    laser_z_rand: 0.05            # 随机噪声比例（0-1）

    # 运动模型
    odom_model_type: 1            # 0=diff, 1=omni, 2=diff-corrected
    odom_alpha1: 0.2             # 旋转时旋转噪声
    odom_alpha2: 0.2             # 旋转时平移噪声
    odom_alpha3: 0.2             # 平移时平移噪声
    oodom_alpha4: 0.2            # 平移时旋转噪声

    # 定位精度
    min_particles: 500            # 最少粒子数
    max_particles: 2000          # 最多粒子数
    transform_tolerance: 0.1     # TF 变换容差（秒）
```

### 1.2 参数调节指南

| 参数 | 太小 | 太大 | 推荐值 |
|------|------|------|--------|
| `min_particles` | 定位精度差 | 算力浪费 | 500-1000 |
| `max_particles` | 定位精度差 | 算力浪费 | 2000-5000 |
| `odom_alpha1-4` | 粒子快速收敛但容易发散 | 收敛慢但稳定 | 室内 0.1-0.3，室外 0.3-0.5 |
| `laser_z_rand` | 地图精确但噪声大 | 噪声被忽略，定位不稳定 | 0.01-0.1 |

---

## 二、DWB Controller（局部路径跟踪）

### 2.1 核心参数

```yaml
dwb_controller:
  ros__parameters:
    # 速度限制
    max_vel_x: 0.5              # 最大线速度 m/s
    max_vel_x_backwards: 0.2    # 最大后退速度
    max_vel_theta: 1.0           # 最大角速度 rad/s
    min_speed_theta: 0.1         # 最小旋转速度

    # 轨迹评估权重
    vx_scale: 1.0                # 线速度权重
    vtheta_scale: 1.0            # 角速度权重
    path_distance_bias: 1.0      # 路径跟随权重
    goal_distance_bias: 1.0      # 目标接近权重
    oscillation_reset_dist: 0.05 # 振荡检测距离

    # 障碍物
    sim_time: 1.0               # 轨迹预测时间（秒）
    obstacle_footprint: "[0.25, 0.25]"  # 机器人足迹
```

### 2.2 调节指南

| 参数 | 太小 | 太大 | 推荐场景 |
|------|------|------|----------|
| `max_vel_x` | 移动慢 | 碰撞风险 | 室内 0.3-0.5 |
| `path_distance_bias` | 机器人绕路多 | 贴近障碍物 | 开阔环境 2.0 |
| `goal_distance_bias` | 目标导向弱 | 路径不平滑 | 0.5-1.0 |
| `sim_time` | 响应快但震荡 | 计算量大 | 1.0-2.0 |

---

## 三、TEB Local Planner（时间弹性带）

### 3.1 核心参数

```yaml
teb_local_planner:
  ros__parameters:
    # 速度限制
    max_vel_x: 0.5
    max_vel_x_backwards: 0.2
    max_vel_theta: 1.0
    acceleration_limits: [0.5, 0.5, 1.5]

    # 避障
    min_obstacle_dist: 0.5       # 最小障碍物距离
    inflation_dist: 0.6          # 障碍物膨胀距离
    dynamic_obstacles_inflation_dist: 0.8

    # 时间优化
    dt_ref: 0.3                 # 时间分辨率
    dt_hysteresis: 0.1          # 时间滞后
    max_samples: 500             # 最大采样数

    # 轨迹优化
    no_inner_iterations: 5      # 内迭代
    no_outer_iterations: 3      # 外迭代
```

### 3.2 适用场景

| 场景 | 关键参数调整 |
|------|-------------|
| 复杂地形 | `min_obstacle_dist` 调大 0.6-0.8 |
| 高速运动 | `max_vel_x` 调大，`dt_ref` 调小 |
| 狭窄通道 | `inflation_dist` 调小 0.3 |

---

## 四、Global Planners

### NavFn（默认）

```yaml
Navfn:
  ros__parameters:
    allow_unknown: true         # 允许穿越未知区域
    planner_window_x: 0.0       # 规划窗口
    planner_window_y: 0.0
    default_tolerance: 0.0       # 目标容差
```

### Smac Planner 2D（推荐）

```yaml
smac_planner:
  ros__parameters:
    tolerance: 0.25             # 目标容差（米）
    downsample_costmap: 2       # 降采样倍数
    shortcut_padding: 0.2       # 允许绕路
    max_iterations: 100000     # 最大迭代（越大越精确）
    max_on_approach_iterations: 1000
```

---

## 五、Costmap2D 配置

### 5.1 全局 Costmap

```yaml
global_costmap:
  global_costmap:
    ros__parameters:
      update_frequency: 1.0      # 更新频率 Hz
      publish_frequency: 1.0
      width: 20.0               # 地图宽（米）
      height: 20.0
      resolution: 0.05          # 分辨率（米/像素）
      origin_x: 0.0
      origin_y: 0.0

      # 障碍物层
      obstacle_layer:
        enabled: true
        observation_sources: [scan]
        scan:
          topic: /scan
          sensor_frame: base_scan
          clearing: true
          marking: true

      # 膨胀层
      inflation:
        inflation_radius: 0.5   # 膨胀半径
        cost_scaling_factor: 1.0 # 代价缩放因子
```

### 5.2 局部 Costmap

```yaml
local_costmap:
  local_costmap:
    ros__parameters:
      update_frequency: 5.0      # 局部更新更频繁
      publish_frequency: 2.0
      width: 3.0                 # 只看机器人周围 3m
      height: 3.0
      resolution: 0.05
      rolling_window: true      # 窗口跟随机器人
```

### 5.3 调节指南

| 参数 | 太小 | 太大 | 推荐 |
|------|------|------|------|
| `inflation_radius` | 路径贴近障碍物 | 路径绕远 | 机器人半径 + 0.3m |
| `cost_scaling_factor` | 代价曲线平滑 | 代价曲线陡峭 | 1.0-2.0 |
| `resolution` | 计算量大 | 精度差 | 0.05（室内） |

---

## 六、Recovery 行为

```yaml
recovery:
  ros__parameters:
    # 旋转恢复
    rotate_recovery:
      enabled: true
      simulation_duration: 1.0
      simulation_time_step: 0.1
      max_rotational_vel: 1.0
      min_rotational_vel: 0.5
      rotational_acceleration: 2.0

    # 清除障碍恢复
    clear_costmap_recovery:
      enabled: true
      reset_distance: 3.0         # 清除机器人周围多少米
```

---

## 七、快速调参清单

### 新机器人首次部署

1. **AMCL**: `min/max_particles` 先用 500/2000
2. **DWB**: `max_vel_x` 设为预期速度的 50%
3. **Costmap**: `inflation_radius` = 机器人半径 + 0.3m
4. **Recovery**: 全部启用

### 定位漂移

- AMCL `odom_alpha1-4` 调大 20-30%
- AMCL `laser_z_rand` 调小 20%
- 全局 costmap `inflation_radius` 调大

### 路径不平滑

- DWB `path_distance_bias` 调大
- TEB `dt_ref` 调小（0.2）

### 碰撞后不恢复

- Recovery `rotate_recovery` enabled: true
- 全局 costmap `clearing: true`
