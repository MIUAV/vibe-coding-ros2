# underwater-nav SKILL — 水下导航指南

---

## 核心规则

1. **无 GPS**：水下只能用 DVL + IMU + USBL 融合定位
2. **深度优先**：深度计数据最可靠（压力传感器），作为高度基准
3. **声呐数据低频**：声呐图像处理频率低（< 5Hz），导航决策需预留提前量
4. **水声通信延迟**：USBL 定位延迟可达 2-5s，不可用于实时控制

---

## 知识库

### DVL 数据格式

```python
# /dvl/data (DVL)
# velocity in body frame: [vx, vy, vz] m/s
# altitude: 距离海底高度 m
# 速度积分 → 位置估计（Dead Reckoning）
def dead_reckoning(vx, vy, vz, heading, dt):
    dx = (vx * np.cos(heading) - vy * np.sin(heading)) * dt
    dy = (vx * np.sin(heading) + vy * np.cos(heading)) * dt
    return dx, dy
```

### 深度传感器

```python
# /depth (Depthometer)
# z = -50.0 → 水下 50m（正深度）
```

### 水声定位（USBL）

```python
# /usbl/position (UsblFix)
# lat, lon → 转换到局部坐标系（NED）
# USBL 更新频率：0.1-0.5 Hz（极低）
# 用于周期性修正 DR 累积误差
```

---

## 快速启动

```bash
bash scripts/generators/ros2-package-generator.sh underwater_nav cpp
bash scripts/ros2-build-verify-loop.sh underwater_nav
```
