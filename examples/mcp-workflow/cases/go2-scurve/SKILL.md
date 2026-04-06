# go2-scurve SKILL — 四足 S 曲线轨迹生成指南

---

## 核心规则

1. **包生成优先**：先用 `ros2-package-generator.sh` 创建包框架
2. **S 曲线必须 5 段**：T_acc → T_jerk → T_const → T_decel → T_settle
3. **步态频率匹配**：轨迹速度 ≤ 步态周期 × 占空比 × step_length
4. **冲击限制**：加加速度（jerk）突变是机器人抖动的根本原因

---

## 知识库

### S 曲线计算

```
import numpy as np

def compute_scurve_trajectory(start, goal, vmax, amax, jmax):
    """
    Compute S-curve trajectory with 5 phases.
    Returns: time_vector, position_vector, velocity_vector, acceleration_vector
    """
    distance = np.linalg.norm(np.array(goal) - np.array(start))
    
    # Phase 1: 恒加速 (T_acc)
    # Phase 2: 变加加速度 (T_jerk)  
    # Phase 3: 恒速 (T_const)
    # Phase 4: 变减加速度 (T_decel)
    # Phase 5: 恒减速 (T_settle)
    
    # 计算各段时间
    Tj = amax / jmax  # 加加速时间
    Ta = vmax / amax  # 加速段时间
    Tv = distance / vmax - Ta  # 匀速段时间
    
    phases = [
        {"name": "accel", "duration": Ta, "a": amax, "j": jmax},
        {"name": "coast", "duration": max(0, Tv), "a": 0.0, "j": 0},
        {"name": "decel", "duration": Ta, "a": -amax, "j": -jmax},
    ]
    return phases
```

### Go2 ROS2 接口

```python
# /cmd_vel 接收 Twist，映射到各关节
ros2 topic pub /go2/cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5, y: 0, z: 0}, angular: {x: 0, y: 0, z: 0.2}}"

# 状态反馈
ros2 topic echo /go2/joint_states
ros2 topic echo /go2/odom
```

### 步态选择矩阵

| 地形 | 推荐步态 | 频率 | 占空比 |
|------|---------|------|--------|
| 平地 | trot | 3.3 Hz | 50% |
| 不平整 | walk | 1.7 Hz | 70% |
| 楼梯 | 定制 | 2.0 Hz | 60% |
| 高速 | gallop | 5.0 Hz | 40% |

---

## 错误处理

| 错误 | 原因 | 解决 |
|------|------|------|
| `vmax too high` | 速度超过机器人极限 | 降低 vmax ≤ 1.0 m/s |
| `jerk discontinuity` | jerk 曲线不连续 | 确保加加速度在段间平滑过渡 |
| `step_height conflict` | 步高与地形碰撞 | 减小 step_height ≤ 0.2m |
| `编译失败：undefined reference to scurve` | 缺少 `colcon build` | 先编译包再运行 |

---

## 快速启动

```bash
# 1. 生成包
bash scripts/generators/ros2-package-generator.sh go2_scurve mixed

# 2. 编写 S 曲线核心（参考上方 Python 示例）
# 3. 编写步态周期调度器
# 4. 编译验证
bash scripts/ros2-build-verify-loop.sh go2_scurve
```
