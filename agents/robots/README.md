# 机器人类型 VibeCoding 指南

> 本目录包含针对不同机器人形态的专项 VibeCoding 开发指南

---

## 目录结构

```
robots/
├── README.md                    # 本文档 (索引)
├── common/                      # 共性特性
│   └── ros2_robot_common.md     # 所有ROS2机器人的共性原则
├── humanoid/                    # 人形机器人
│   └── humanoid_guide.md         # 人形机器人专有指南
├── quadruped/                   # 四足机器人
│   └── quadruped_guide.md       # 四足机器人专有指南
├── manipulator/                 # 机械臂
│   └── manipulator_guide.md      # 机械臂专有指南
├── wheeled_vehicle/             # 轮式底盘
│   └── wheeled_vehicle_guide.md # 轮式底盘专有指南
└── multi_rotor_uav/             # 多旋翼无人机
    └── uav_guide.md             # 无人机专有指南
```

---

## 机器人类型概览

| 类型 | 形态特点 | 主要应用场景 | 关键挑战 |
|------|----------|--------------|----------|
| **人形机器人** | 双足平衡、多关节 | 服务、协作、制造 | 平衡控制、双足导航 |
| **四足机器人** | 四足运动、地形适应 | 巡检、救援、军事 | 足式导航、崎岖地形 |
| **机械臂** | 多自由度、精度操作 | 装配、搬运、医疗 | 运动规划、力控操作 |
| **轮式底盘** | 轮式移动、负载能力 | 物流、清洁、巡检 | 自主导航、避障 |
| **多旋翼无人机** | 空中飞行、机动灵活 | 航拍、巡检、农业 | 3D导航、飞行安全 |

---

## 文档内容结构

每个机器人指南包含以下四大核心模块：

### 1. 感知 (Perception)

该机器人形态的专用传感器配置和感知算法：

```
├── 传感器选型与配置
├── 感知算法实现
├── 传感器融合策略
└── VibeCoding 提示词模板
```

### 2. 定位 (Localization)

适合该机器人形态的定位技术：

```
├── 定位方案选型
├── SLAM / 里程计算法
├── 多传感器融合
└── VibeCoding 提示词模板
```

### 3. 导航 (Navigation)

针对该形态的导航系统：

```
├── 路径规划算法
├── 运动控制策略
├── 避障与安全机制
└── VibeCoding 提示词模板
```

### 4. 技能规划 (Skill Planning)

该形态特有的技能定义和编排：

```
├── 技能分类体系
├── 技能描述模板
├── 技能编排逻辑
└── VibeCoding 提示词模板
```

---

## 快速导航

### 人形机器人

适用于:
- 双足仿生机器人
- 上肢仿生机器人
- 全尺寸人形机器人
- 小型人形机器人

**核心模块**: 平衡控制、双足运动、灵巧操作、人体姿态估计

📖 [阅读人形机器人指南](./humanoid/humanoid_guide.md)

---

### 四足机器人

适用于:
- Spot (Boston Dynamics)
- Anymal (ANYbotics)
- Laikago / Aliengo (宇树)
- 定制四足机器人

**核心模块**: 足式运动、地形感知、动态避障、负载运输

📖 [阅读四足机器人指南](./quadruped/quadruped_guide.md)

---

### 机械臂

适用于:
- 协作机械臂 (Franka Panda, UR)
- 工业机械臂 (ABB, KUKA, Fanuc)
- 轻量型机械臂 (Kinova, Kinect)
- 移动操作臂 (移动+臂)

**核心模块**: 逆运动学、轨迹规划、力控、视觉伺服

📖 [阅读机械臂指南](./manipulator/manipulator_guide.md)

---

### 轮式底盘

适用于:
- 室内移动机器人
- 园区配送车
- 自动导引车 (AGV)
- 自动驾驶汽车

**核心模块**: 里程计融合、车道保持、自主泊车、路径跟踪

📖 [阅读轮式底盘指南](./wheeled_vehicle/wheeled_vehicle_guide.md)

---

### 多旋翼无人机

适用于:
- 四旋翼 / 六旋翼 / 八旋翼
- VTOL 垂直起降
- 巡检无人机
- 农业无人机

**核心模块**: 3D 导航、飞行控制、目标跟踪、编队飞行

📖 [阅读无人机指南](./multi_rotor_uav/uav_guide.md)

---

## 共性特性

所有 ROS2 机器人的共性原则和技术栈：

📖 [阅读 ROS2 机器人共性指南](./common/ros2_robot_common.md)

---

## 使用建议

### 1. 新项目启动

```
1. 阅读 robots/common/ros2_robot_common.md (共性原则)
2. 选择对应机器人形态的指南
3. 按照文档结构逐步实现各模块
4. 参考 prompts/ 中的提示词模板
```

### 2. 技能开发

```
1. 确定机器人类型和任务需求
2. 选择合适的技能分类
3. 参考技能描述模板定义新技能
4. 使用行为树/状态机编排技能
5. 在仿真环境中验证
```

### 3. VibeCoding 工作流

```
1. 生成项目上下文 (context generation)
2. 定义技能接口 (interface design)
3. 实现核心算法 (implementation)
4. 集成测试验证 (integration testing)
5. 优化性能调优 (optimization)
```

---

## 相关资源

- **主文档**: [../README.md](../README.md)
- **方法论**: [../documents/Methodology_and_Principles/](../documents/Methodology_and_Principles/)
- **技能索引**: [../skills/README.md](../skills/README.md)
- **提示词库**: [../prompts/](../prompts/)
- **记忆银行**: [../memory-bank/](../memory-bank/)

---

## 贡献指南

添加新的机器人类型指南时：

1. 在 `robots/` 下创建新目录
2. 按照本文档结构编写 `*_guide.md`
3. 更新本索引文件的目录结构
4. 确保包含四大核心模块:
   - 感知 (Perception)
   - 定位 (Localization)
   - 导航 (Navigation)
   - 技能规划 (Skill Planning)

---

*最后更新: 2025*
