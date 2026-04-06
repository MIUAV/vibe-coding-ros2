# aerial-photography VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh aerial_photo
```

- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — 航点计算

```python
class TestWaypoint(unittest.TestCase):
    def test_waypoint_distance(self):
        """航点间距离计算正确"""
        pass

    def test_geo_fence(self):
        """飞行器不飞出电子围栏"""
        pass
```

### 验收清单

- [ ] 航点距离测试通过
- [ ] GPS 锁定验证
- [ ] `colcon build` + `colcon test` 全部通过
