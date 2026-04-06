# sensor-fusion-locate VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh sensor_fusion
```

- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — EKF 核心

```python
class TestEKF(unittest.TestCase):
    def test_predict_preserves_state_dim(self):
        """预测步不改变状态维度"""
        X, P = ekf_init()
        Xp, Pp = ekf_predict(X, P, u=np.zeros(6), dt=0.01)
        self.assertEqual(X.shape, (8,))
        self.assertEqual(P.shape, (8, 8))

    def test_update_reduces_uncertainty(self):
        """修正步应减少状态不确定性（迹下降）"""
        pass
```

### 性能验证

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 定位精度 | < 0.05m | 与真值（RTK）对比 |
| EKF 更新频率 | ≥ 50Hz | `ros2 topic hz /ekf/pose` |
| IMU 延迟 | < 5ms | `ros2 topic delay /imu/data` |

---

## 验收清单

- [ ] EKF 单元测试全绿
- [ ] 定位精度测试通过（< 5cm）
- [ ] `colcon build` + `colcon test` 全部通过
