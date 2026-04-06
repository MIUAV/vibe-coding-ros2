# industrial-integration SKILL — 工业机械臂 ROS2 集成指南

---

## 核心规则

1. **工业机械臂需要 explicit enable**：上电后必须发送 enable 指令才能运动
2. **E-Stop 必须监听**：安全回路断开心须立即停止所有运动
3. **速度缩放**：首次测试用 `max_velocity_scaling_factor ≤ 0.1`
4. **Modbus 寄存器映射**：IO 状态通过寄存器读写获取

---

## 知识库

### KUKA RSI 接口

```python
# RSI XML 指令示例（通过 UDP Socket 发送）
<Sen Struct="Esor">
  <AK A1="0.0" A2="0.0" ... A7="0.0"/>
  <IPOC>123456789</IPOC>
</Sen>

# 接收机器人状态
<Rob struct="埃Or">
  <A1 A2 ... A7/>
  <IPOC>123456790</IPOC>
</Rob>
```

### ros2_controllers 配置

```yaml
joint_trajectory_controller:
  type: joint_trajectory_controller/JointTrajectoryController
  joints:
    - joint_a1
    - joint_a2
    - joint_a3
    - joint_a4
    - joint_a5
    - joint_a6
    - joint_a7
```

### Modbus TCP IO

```python
from pyModbusTCP.client import ModbusClient

client = ModbusClient(host='192.168.1.10', port=502)
# 读取数字输入 DI[0]
di0 = client.read_discrete_inputs(0, 1)
# 写数字输出 DO[0]
client.write_single_coil(0, True)
```

---

## 快速启动

```bash
bash scripts/generators/ros2-package-generator.sh kuka_iiwa_control cpp
# 编写 RSI 接口节点
bash scripts/ros2-build-verify-loop.sh kuka_iiwa_control
```
