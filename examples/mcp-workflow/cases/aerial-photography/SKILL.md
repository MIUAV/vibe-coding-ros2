# aerial-photography SKILL — 航拍无人机控制指南

---

## 核心规则

1. **飞行前检查**：电池 ≥ 80%、GPS 锁定、磁罗盘校准
2. **电子围栏**：Geo-fence 必须设置，防止飞出安全区域
3. **MAVLink 消息频率**：heartbeat ≥ 1Hz，GPS ≥ 5Hz
4. **返航高度**：RTH 高度必须高于周边最高障碍物

---

## 知识库

### MAVLink 关键消息

```bash
# 订阅无人机状态
ros2 topic echo /mavros/state
# 订阅 GPS
ros2 topic echo /mavros/global_position/global
# 发送航点
ros2 topic pub /mavros/mission/push waypoint
```

### 飞行模式

```python
FLIGHT_MODES = {
    "manual":     "MANUAL",
    "stabilize":  "STABILIZE", 
    "loiter":     "LOITER",
    "rtl":        "RTL",     # Return to Launch
    "auto":       "AUTO",
    "guided":     "GUIDED",
}
```

### 相机触发

```python
# 通过 MAVLink COMMAND_LONG 触发相机
# command=MAV_CMD_DO_DIGICAM_CONTROL
# param5=1 (单次拍摄)
```

---

## 快速启动

```bash
bash scripts/generators/ros2-package-generator.sh aerial_photo python
bash scripts/ros2-build-verify-loop.sh aerial_photo
```
