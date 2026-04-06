# multi-robot-swarm VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh swarm_control
```

**通过条件：**
- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — ORCA 冲突避免

```python
import unittest
from swarm.orca import orca_velocity

class TestORCA(unittest.TestCase):
    def test_no_collision_two_robots(self):
        """两个机器人相向而行，应计算出安全分离速度"""
        r1_pos, r1_vel = [0, 0], [0.5, 0]
        r2_pos, r2_vel = [1, 0], [-0.5, 0]
        safe_vel = orca_velocity(r1_pos, r1_vel, [r2_pos], time_horizon=5.0)
        
        # 安全速度应使两机器人保持距离
        # 如果当前距离 < 2×安全距离，则 safe_vel 应有侧向分量
        pass

    def test_leader_follower_formation(self):
        """编队形状保持测试"""
        pass
```

### 集成测试 — 实际多机

```bash
# 模拟 3 台机器人（需 ROS2 测试框架）
ros2 launch swarm_control test_formation.launch.py num_robots:=3

# 验证：机器人间距始终 ≥ min_separation_distance
# 验证：到达目标后编队形状与设定一致
```

---

## 性能验证

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 通信延迟 | < 100ms | `ros2 topic delay` |
| 碰撞率 | 0 次 | 10 次编队测试 |
| 编队收敛时间 | < 5s | 计时器 |
| 领导人失联响应 | < 2s | 切断 Leader 观测 |

---

## 验收清单

- [ ] ORCA 单元测试全绿
- [ ] 编队形状保持测试通过
- [ ] Leader 失联后安全停止验证
- [ ] `colcon build` + `colcon test` 全部通过
- [ ] AI 生成代码无需手动修改即可运行
