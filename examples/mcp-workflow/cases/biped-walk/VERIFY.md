# biped-walk VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh biped_walk
```

- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — ZMP 稳定性

```python
class TestZMP(unittest.TestCase):
    def test_zmp_inside_support_polygon(self):
        """ZMP 必须在支撑多边形内"""
        pass

    def test_com_continuity(self):
        """CoM 位置、速度、加速度连续"""
        pass
```

### 验收清单

- [ ] ZMP 单元测试全绿
- [ ] 步行周期测试（1.2s ± 0.05s）
- [ ] 步长验证（0.3m ± 0.02m）
- [ ] `colcon build` + `colcon test` 全部通过
