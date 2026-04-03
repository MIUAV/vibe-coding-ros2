---
name: px4-mc-tuning
description: PX4 多旋翼调参 - 姿态/位置PID参数调节、Autotune 自动调参、飞行性能优化
argument-hint: 多旋翼调参 OR px4 tuning OR PID调节 OR 自动调参
user-invocable: true
---

# PX4 多旋翼调参技能

> 用于调节和优化多旋翼飞行器的飞行参数

---

## 何时使用

当需要以下帮助时使用此技能：
- 手动调节 PID 参数
- 使用自动调参
- 优化飞行手感
- 解决飞行抖动问题

---

## 快速参考

### 调参流程

1. **基础配置** → 选择机型、配置电调
2. **传感器校准** → 完成所有传感器校准
3. **Radio 校准** → 确认遥控器正常
4. **飞行前检查** → 解锁测试、模式切换
5. **参数调节** → 使用 Autotune 或手动调节
6. **飞行测试** → 验证稳定性

---

## 自动调参 (Autotune)

### 启动自动调参

```
QGC → Vehicle Setup → Flight Modes → Autotune
```

### Autotune 步骤

1. **起飞** → 切换到 Position 模式
2. **选择轴** → 翻滚/俯仰/偏航
3. **执行调参** → 推动摇杆开始
4. **等待完成** → 自动测试各轴

### Autotune 参数

```bash
# 启用多旋翼自动调参
MC_AUTOTUNE_EN = 1

# 调参轴选择
MC_AUTOTUNE_AXES = 7  # 全部轴

# 安全参数
MC_AUTOTUNE_MIN_DZ   # 死区
```

---

## 手动调参

### 姿态控制器 (Attitude)

| 参数 | 说明 | 调整范围 |
|------|------|----------|
| `MC_ROLL_P` | 翻滚比例 | 4-8 |
| `MC_ROLL_I` | 翻滚积分 | 0.1-0.3 |
| `MC_ROLL_D` | 翻滚微分 | 0.0-0.2 |
| `MC_PITCH_P` | 俯仰比例 | 4-8 |
| `MC_PITCH_I` | 俯仰积分 | 0.1-0.3 |
| `MC_PITCH_D` | 俯仰微分 | 0.0-0.2 |
| `MC_YAW_P` | 偏航比例 | 4-8 |
| `MC_YAW_I` | 偏航积分 | 0.1-0.3 |

### 位置控制器 (Position)

| 参数 | 说明 | 调整范围 |
|------|------|----------|
| `MPC_XY_P` | 水平位置 P | 1-3 |
| `MPC_Z_P` | 高度位置 P | 1-3 |
| `MPC_XY_VEL_P` | 水平速度 P | 2-5 |
| `MPC_Z_VEL_P` | 垂直速度 P | 2-5 |

---

## 调参步骤

### 1. 基础参数

```bash
# 设置悬停油门
MPC_THR_HOVER    # 悬停油门值

# 设置最大速度
MPC_VEL_MANUAL   # 最大手动速度
MPC_XY_CRUISE    # 巡航速度

# 设置最大倾斜角
MC_ATT_RATE_MAX  # 最大旋转率
MPC_MAN_TILT_MAX # 最大倾斜角
```

### 2. 姿态调参

```bash
# 步骤1: 调节 P 值
# 从小到大，直到出现轻微振荡
MC_ROLL_P: 4 → 6 → 8

# 步骤2: 调节 I 值
# 增加以消除稳态误差
MC_ROLL_I: 0.1 → 0.2

# 步骤3: 调节 D 值
# 减少振荡和过冲
MC_ROLL_D: 0.05 → 0.1
```

### 3. 位置调参

```bash
# 水平位置
MPC_XY_P: 1.0 → 1.5 → 2.0

# 高度
MPC_Z_P: 1.0 → 1.5
```

---

## 常见问题及解决方案

### 飞行抖动

**原因**: P 值过高
**解决**: 减少 P 值，增加 D 值

```bash
# 减少 P
MC_ROLL_P: 8 → 6
# 增加 D
MC_ROLL_D: 0 → 0.05
```

### 漂移

**原因**: 积分不足
**解决**: 增加 I 值

```bash
MC_ROLL_I: 0.1 → 0.2
MC_PITCH_I: 0.1 → 0.2
```

### 响应迟缓

**原因**: P 值过低
**解决**: 增加 P 值

```bash
MC_ROLL_P: 4 → 6
```

### 过冲

**原因**: D 值过高或 P 值过高
**解决**: 减少 P 和 D

```bash
MC_ROLL_P: 8 → 6
MC_ROLL_D: 0.2 → 0.1
```

---

## 参数文件

### 调参后保存

```bash
# 保存参数到文件
param save /fs/microsd/mc_tuning.txt

# 在 QGC 中
# File → Load Parameters
```

### 恢复默认

```bash
# QGC 中点击 "Reset to default"
# 或
param load /fs/microsd/default_params.txt
```

---

## 飞行测试检查清单

- [ ] 起飞稳定
- [ ] 前进/后退无漂移
- [ ] 左转/右转正常
- [ ] 悬停稳定
- [ ] 位置模式正常
- [ ] 任务执行正常
- [ ] 降落平稳

---

## 安全设置

```bash
# 最大倾斜角
MPC_MAN_TILT_MAX: 45  # 度

# 最大上升/下降速度
MPC_UP_SPEED_FEED: 3  # m/s
MPC_DOWN_SPEED: 1.5

# 电池保护
BAT1_WARNING_PER: 20  # %
BAT1_CRITICAL_PER: 10 # %
```

---

## 相关文档

- [PX4 多旋翼配置](https://docs.px4.io/main/en/config_mc/)
- [Autotune 文档](https://docs.px4.io/main/en/config/autotune_mc.html)
- [参数参考](https://docs.px4.io/main/en/advanced_config/parameter_reference.html)