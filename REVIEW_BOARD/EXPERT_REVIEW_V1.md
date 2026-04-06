# 专家评审报告 v1.0

> 评审等级：彭志辉级资深机器人专家
> 评审日期：2026-04-07
> 项目版本：v0.3.0
> 评审者：虚拟资深机器人专家（类彭志辉水平）

---

## 总评

**亮点：**
- 工具链覆盖面极广（22个生成器），覆盖ROS2开发全栈
- bash优先，移植性好，不依赖特定Python环境
- CI/CD真实编译，不是lint-only
- 文档结构清晰，CLAUDE.md核心规则提炼准确

**致命弱点（必须修复）：**
1. 生成代码是"壳"，无法控制真实机器人
2. 只有"生成"能力，没有"调参"能力
3. 案例只有文档，没有真实可运行代码

---

## 🔴 P0（立即修复）

### 1. 每个生成器必须指定目标硬件平台

**当前问题：**
生成的代码假设运行在Linux PC上，但真实机器人大量使用ARM Cortex-A、NVIDIA Jetson等嵌入式平台，这些平台可能没有 `/proc/stat` 等文件。

**修复方案：**
每个生成器增加 `--platform` 参数：

```bash
bash ros2-diagnostics-generator.sh my_diag general \
  --platform jetson_orin  # jetson_orin | raspberry_pi | pc | stm32 | esp32
```

| 平台 | /proc 存在 | CAN 总线 | GPIO | 特殊要求 |
|------|------------|---------|------|---------|
| PC (Linux) | ✅ | 可选 | ❌ | 无 |
| Jetson Orin | ✅ | ✅ JetsonHawk | ✅ | JetPack 5.x |
| Raspberry Pi | ✅ | 可选 | ✅ RPi.GPIO | - |
| STM32 | ❌ | ✅ CAN | ✅ | 需交叉编译 |
| ESP32 | ❌ | ❌ | ✅ I2C | FreeRTOS |

---

### 2. HITL（硬件在环）测试框架

**当前问题：**
生成的代码从未在真实硬件上测试过，不知道能否控制真实机器人。

**修复方案：**
```bash
# scripts/hitl-test-framework.sh
# 支持：
#   --platform jetson_orin
#   --hardware uart:/dev/ttyUSB0:115200
#   --test-type can_ros2_bridge
```

---

## 🟡 P1（本季度）

### 3. AutoTune 参数推荐

```bash
# 根据机器人参数自动估算初始参数值
bash scripts/autotune-params.sh \
  --robot mass=3.5 wheel_radius=0.08 wheelbase=0.4 \
  --scenario indoor_slow  # indoor_slow | outdoor_fast | rough_terrain
```

输出：
```
EKF process_noise_covariance:
  position: 0.05 → 0.08  (建议值，基于 mass=3.5kg)
  velocity: 0.10 → 0.15  (建议值，基于 wheel_radius=0.08m)
Nav2 max_speed: 1.0 → 0.5  (室内建议值)
```

---

### 4. 生成器依赖冲突检测

Nav2 + SLAM + MoveIt 同时使用时，参数冲突是最高频错误。

**解决方案：** `ros2-orchestrate.sh --check-deps` 在生成后自动检测：

```
冲突检测报告：
❌ map_frame 不一致: Nav2 用 "map", SLAM 用 "odom"
❌ odom_frame 不一致: ros2_control 用 "odom", EKF 用 "map"
❌ joint_names 不匹配: MoveIt 用 [j1,j2,j3], ros2_control 用 [joint1,joint2,joint3]
✅ 建议: 使用 --unify-frames 选项
```

---

### 5. 真实可运行的案例包

**问题：** `examples/` 只有markdown，没有真实可编译的代码包。

**修复：** 每个案例同时包含：
```
examples/wheeled-nav2/
├── PLAN.md          # 需求文档
├── SKILL.md         # 技能指南  
├── VERIFY.md        # 验收标准
└── src/
    ├── CMakeLists.txt
    ├── package.xml
    └── nodes/       # 真实可编译的代码
```

---

## 🟢 P2（下季度）

### 6. 性能基准测试

生成的代码在嵌入式平台上的实测数据：
- 内存占用（Jetson Nano vs Orin vs Raspberry Pi 4）
- CPU 使用率（单核 vs 多核）
- 延迟（sensor→actuator 闭环延迟）

### 7. 真机测试案例库

不只是文档，要包含：
- 运行视频/截图
- 硬件平台配置
- 实际参数调优记录
- 已知问题列表

---

## 已修复问题（v0.3.x → v0.4.x）

| 问题 | 修复方式 | 状态 |
|------|---------|------|
| 机器人安全模块缺失 | `ros2-safety-generator.sh` | ✅ 已实现 |
| 无碰撞检测生成器 | `safety_monitor_node.cpp` 含 CollisionDetector | ✅ 已实现 |
| 无紧急停止生成器 | `estop_hardware.cpp` 含 GPIO/CAN/Modbus 接口 | ✅ 已实现 |
| 无地理围栏生成器 | `GeoFence` 类 + YAML 配置 | ✅ 已实现 |
| 示例包被误删 | 需恢复 + 改为真实可编译代码 | ⚠️ 待修复 |

---

## 附录：彭志辉核心语录（项目相关）

> "机器人代码没有'差不多'——差0.01秒可能就是撞人与被撞的区别。"

> "你们工具生成的代码我敢让我学生用，但不敢让机器人真的跑起来。区别在这。"

> "SLAM参数调好了，机器人能自主导航；没调好，就是一个高级遥控车。"
