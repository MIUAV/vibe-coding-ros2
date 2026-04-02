---
name: project-setup
description: Unreal Engine 项目设置技能 - 项目创建、插件安装、渲染配置
argument-hint: "Unreal Engine项目" / "项目配置" / "渲染设置"
user-invocable: true
---

# Unreal Engine Project Setup Skill

> 用于配置 Unreal Engine 机器人仿真项目

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建新项目
- 安装机器人插件
- 配置渲染参数
- 设置物理引擎

---

## 快速参考

### 安装

```bash
# 从 Epic Games Launcher 安装
# 或从源码编译
git clone https://github.com/EpicGames/UnrealEngine.git
cd UnrealEngine
./Setup.sh
./Build.sh
```

---

## 项目配置

### 创建项目

```
1. 启动 Unreal Engine
2. 选择 "Games" -> "Blank"
3. 选择平台 (Windows/Linux)
4. 选择质量级别 (Scalable/High)
5. 命名并创建项目
```

### 插件

```json
// Project/Plugins 添加
{
    "Name": "Robotics",
    "Enabled": true
}
```

---

## 常见问题

### 问题 1: 编译错误

**解决方案**：安装 Visual Studio Build Tools

---

## 另见

- [robot-integration](../robot-integration/) - 机器人集成
- [ros2-integration](../ros2-integration/) - ROS2 集成