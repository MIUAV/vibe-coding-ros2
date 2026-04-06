# industrial-integration VERIFY — 验收标准

---

## 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh kuka_iiwa_control
```

- [ ] `colcon build` 无 error
- [ ] `colcon test` 全绿

---

## 功能验证

### Unit Test — RSI 协议

```python
class TestRSI(unittest.TestCase):
    def test_xml_format_valid(self):
        """RSI XML 格式应符合规范"""
        pass

    def test_ipoc_increment(self):
        """IPOC 应每次递增"""
        pass
```

### 性能验证

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 关节位置误差 | < 0.01rad | 与示教器对比 |
| 通信周期 | 4ms (±0.5ms) | 示波器/抓包 |
| E-Stop 响应 | < 10ms | 物理测试 |

---

## 验收清单

- [ ] RSI 单元测试全绿
- [ ] E-Stop 安全回路测试通过
- [ ] `colcon build` + `colcon test` 全部通过
