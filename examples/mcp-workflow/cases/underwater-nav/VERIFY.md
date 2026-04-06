# underwater-nav VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh underwater_nav
```

- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — Dead Reckoning

```python
class TestDR(unittest.TestCase):
    def test_velocity_integration(self):
        """速度积分应正确"""
        pass

    def test_drift_bounds(self):
        """DR 误差在给定时间内应有限"""
        pass
```

### 性能验证

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| DR 漂移率 | < 1% 距离 | USBL 对比 |
| 深度误差 | < 0.1m | 压力传感器标定 |
| 障碍物检测 | < 2s | 动态障碍物测试 |

---

## 验收清单

- [ ] DR 单元测试全绿
- [ ] 定位精度测试通过
- [ ] `colcon build` + `colcon test` 全部通过
