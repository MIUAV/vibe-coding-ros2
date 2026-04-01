---
name: px4-airframe
description: PX4 机架配置与电机映射 - 多旋翼机型选择、电调校准、输出通道配置
argument-hint: "机架配置" / "px4 airframe" / "电机配置" / "电调校准"
user-invocable: true
---

# PX4 机架配置技能

> 用于配置多旋翼机架类型和电机/电调设置

---

## 何时使用

当需要以下帮助时使用此技能：
- 选择和配置机架类型
- 配置电机顺序和转向
- 校准电调
- 配置舵机输出

---

## 快速参考

### 机型分类

| 机型 | 电机数 | 描述 |
|------|--------|------|
| **四旋翼 (+)** | 4 | 标准四旋翼 |
| **四旋翼 (x)** | 4 | X 布局 |
| **六旋翼** | 6 | 六旋翼 |
| **八旋翼** | 8 | 八旋翼 |

### 常用机架代码

```bash
# 四旋翼 X 布局 (默认)
make px4_sitl gz_x500

# 四旋翼 + 布局
make px4_sitl gz_x500

# 六旋翼
make px4_sitl gz_x600

# 通用多旋翼
make px4_sitl gz_quad
```

---

## 配置步骤

### 1. 选择机型

```
QGC → Vehicle Setup → Airframe
→ 选择 "Multicopter"
→ 选择具体型号
→ 应用并重启
```

### 2. 电机映射

```
QGC → Vehicle Setup → Actuators
→ 配置电机输出
→ 设置电机顺序
→ 设置转向
```

---

## 电机输出顺序

### 四旋翼 X 布局

```
      2
      |
4 ----+---- 1
      |
      3

电机 1: CW (顺时针)
电机 2: CCW (逆时针)
电机 3: CCW
电机 4: CW
```

### 四旋翼 + 布局

```
1 -------- 2
    |
    |
    |
3 -------- 4

电机 1: CCW (前右)
电机 2: CW (后右)
电机 3: CW (后左)
电机 4: CCW (前左)
```

### 六旋翼

```
    2
  /   \
6       1
  \   /
    3
  /   \
5       4
  \   /
```

---

## 电调校准

### 方法一：QGC 自动校准

```
QGC → Vehicle Setup → Motors
→ 点击 "Calibrate"
→ 按照提示操作
```

### 方法二：手动校准

1. **断开电池**
2. **进入校准模式**
   - 按住电调校准按钮
   - 连接电池
   - 等待蜂鸣器
3. **发送最大油门**
4. **等待确认音**
5. **发送最小油门**
6. **等待确认音**
7. **校准完成**

---

## 电机参数

### 电机参数配置

```bash
# 电机输出限制
MOT_SPIN_MIN     # 最小转速
MOT_SPIN_MAX     # 最大转速

# 电调类型
MOT_1_TYPE      # PWM/DShot
```

### DShot 配置

```bash
# 启用 DShot
DSHOT_ESC_TYPE = 1  # DShot150/300/600

# 输出配置
PWM_MAIN_DIS1 = DShot
PWM_MAIN_DIS2 = DShot
```

---

## 机架参考

### 标准多旋翼

| 机型 | Airframe | 描述 |
|------|----------|------|
| Generic x500 | 4001 | 通用 X500 |
| Holybro x500 | 4011 | Holybro x500 |
| DJI F450 | 4015 | DJI Flame Wheel |
| DJI F550 | 4016 | DJI Flame Wheel 550 |
| QAV250 | 4050 | 竞速无人机 |
| QAV-R 5" | 4051 | 5寸竞速 |

### 六旋翼/八旋翼

| 机型 | Airframe | 描述 |
|------|----------|------|
| Hex x600 | 6001 | 通用六旋翼 |
| Hex x720 | 6002 | 六旋翼 720mm |
| Octo x800 | 7001 | 通用八旋翼 |

---

## 高级配置

### 电机混控器

```bash
# 查看混控器
mixer status

# 加载自定义混控器
mixer load /dev/pwm-output0 /fs/microsd/mixer.txt
```

### 通道配置

```bash
# PWM 输出范围
PWM_MIN         # 最小 PWM (1000)
PWM_MAX         # 最大 PWM (2000)
PWM_DISARMED    # 停机 PWM (1000)
```

---

## 故障排除

### 电机不转

1. 检查电调供电
2. 检查 PWM 信号线
3. 检查安全开关
4. 确认已解锁

### 转向错误

```bash
# 在 QGC 中调整
QGC → Actuators → Motor Direction
→ 反转对应电机
```

### 电机震动

1. 检查螺旋桨平衡
2. 检查电机安装
3. 检查电调设置

---

## 相关文档

- [PX4 机架参考](https://docs.px4.io/main/en/airframes/airframe_reference.html)
- [电调校准](https://docs.px4.io/main/en/advanced_config/esc_calibration.html)
- [执行器配置](https://docs.px4.io/main/en/config/actuators.html)