# go2-scurve VERIFY — 验收标准

---

## 编译验证

```bash
cd /home/node/.openclaw/workspace/vibe-coding-ros2
bash scripts/ros2-build-verify-loop.sh go2_scurve
```

**通过条件：**
- [ ] `colcon build --packages-select go2_scurve` 无 error
- [ ] `ament_lint_auto` 检查通过
- [ ] `colcon test --packages-select go2_scurve` 全绿

---

## 功能验证

### Unit Test — S 曲线核心计算

```python
import unittest
import numpy as np
from scurve import compute_scurve_trajectory

class TestSCurve(unittest.TestCase):
    def test_velocity_profile(self):
        """速度曲线应平滑无突变"""
        start, goal = [0,0,0], [2,1,0]
        phases = compute_scurve_trajectory(start, goal, vmax=0.5, amax=0.2, jmax=1.0)
        
        # 检查：速度曲线是否连续
        # 检查：峰值速度是否 ≤ vmax
        # 检查：加加速度是否 ≤ jmax
        for p in phases:
            self.assertLessEqual(abs(p['j']), 1.0)

    def test_acceleration_smoothness(self):
        """加速度曲线应无突变"""
        # jerk (加加速度) 应在段间平滑过渡
        pass

    def test_step_height(self):
        """step_height 不应超过 0.2m"""
        # 在崎岖地形测试中验证
        pass
```

### 集成测试 — 步态周期匹配

```bash
ros2 run go2_scurve test_gait_sync
# 验证：步态频率 × 步长 ≥ 轨迹速度
```

---

## 性能验证

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 轨迹平滑度 | jerk < 1.0 m/s³ | `ros2 topic echo /go2/cmd_vel` 分析 |
| 定位精度 | 误差 < 0.1m | 与目标点对比 |
| 响应延迟 | < 50ms | `ros2 topic hz /cmd_vel` |
| 障碍物避障 | 距离 ≥ 0.3m | 动态障碍物测试 |

---

## 验收清单

- [ ] `scurve.py` 核心算法单元测试全绿
- [ ] 步态频率与轨迹速度匹配验证通过
- [ ] `colcon build` + `colcon test` 全部通过
- [ ] AI 生成的代码无需手动修改即可运行
- [ ] SKILL.md 知识可被 AI Agent 准确调用
