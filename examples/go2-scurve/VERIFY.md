# go2-scurve — 验证标准

## 成功标准（必须全部通过）

### 仿真验证

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 轨迹误差 | < 5cm（相对于目标 S-curve）| `ros2 topic echo /scurve/actual_trajectory` |
| 速度约束 | ≤ V_max = 1.5 m/s | `ros2 topic echo /leg/feet_velocities` |
| 加速度约束 | ≤ A_max = 3.0 m/s² | 计算 `d²p/dt²` |
| jerk 连续性 | 无突变（< 100 m/s³ 跳变）| 数值微分 |
| 地隙 | > 0.05m（无足端碰地）| `ros2 topic echo /leg/ground_clearance` |
| 控制频率 | ≥ 350Hz（400Hz 目标）| `ros2 topic hz /joint_commands` |
| 关节限位 | 全部在物理范围内 | `ros2 topic echo /joint_states` |

### 代码质量

| 检查项 | 标准 |
|--------|------|
| colcon build | 零错误 |
| 单元测试 | 通过率 100% |
| clang-tidy | 无 Error（Warning 可接受）|
| 依赖声明 | 所有外部依赖在 package.xml |

## 失败判定

满足以下任意条件则判定为**失败**：

- [ ] colcon build 有任何链接错误
- [ ] 仿真中关节角度超过限位
- [ ] jerk 出现 > 100 m/s³ 的跳变
- [ ] 实际轨迹误差 > 10cm
- [ ] 控制频率 < 300Hz（不稳定）

## 测试命令

```bash
# 1. 编译
colcon build --packages-select go2_scurve go2_scurve_msgs
source install/setup.bash

# 2. 启动仿真
ros2 launch go2_scurve scurve.launch.py

# 3. 运行验证脚本
bash scripts/validators/go2-scurve-verify.sh

# 4. 查看结果
cat /tmp/go2_scurve_verify_result.json
```

## 验证脚本要求

`scripts/validators/go2-scurve-verify.sh` 必须检查：

1. 轨迹误差（对比 /scurve/target 和 /scurve/actual）
2. 速度/加速度/jerk 约束
3. 关节限位
4. 控制频率稳定性
5. 仿真时钟同步（/clock）
