---
name: robot-integration
description: Unreal Engine 机器人集成技能 - 导入机器人模型、物理设置、控制接口
argument-hint: Unreal机器人 OR 导入模型 OR 物理设置
user-invocable: true
---

# Unreal Engine Robot Integration Skill

> 用于在 Unreal Engine 中集成机器人

---

## 何时使用

当需要以下帮助时使用此技能：
- 导入机器人模型
- 配置物理属性
- 添加控制接口
- 设置传感器

---

## 快速参考

### 导入模型

```
1. File -> Import Into Level
2. 选择 FBX/USD 文件
3. 设置导入选项
4. 点击 Import
```

---

## 机器人配置

### 物理约束

```cpp
// 设置物理约束
UPhysicsConstraintComponent* constraint = NewObject<UPhysicsConstraintComponent>();
constraint->SetConstrainedComponents(
    base_mesh, NAME_None,
    wheel_mesh, NAME_None
);
constraint->SetAngularSwing1Limit(ACM_Free, 0);
constraint->SetLinearXLimit(LCM_Free, 0);
```

---

## 常见问题

### 问题 1: 物理不稳定

**解决方案**：增加阻尼，降低模拟步长

---

## 另见

- [project-setup](../project-setup/) - 项目设置
- [ros2-integration](../ros2-integration/) - ROS2 集成