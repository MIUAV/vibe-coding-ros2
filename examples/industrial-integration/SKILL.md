---
name: industrial-integration
description: 工业机器人集成 — ROS2 与 PLC/Modbus/OPCUA 通信，IEC 任务调度，适用于工厂柔性制造和机器人协作生产线
argument-hint: 工业 OR industrial OR PLC OR Modbus OR OPCUA OR IEC OR 柔性制造 OR 生产线
user-invocable: true
---

# industrial-integration — 工业机器人集成 SKILL

## 任务描述

ROS2 机器人与工厂 PLC 系统集成，通过 Modbus/OPCUA 通信，实现协同生产。

## 引用技能

- `agents/skills/system-integration/` — 系统集成
- `agents/skills/ros2-debug/` — 调试

## 通信协议

| 协议 | 层次 | 速度 | 可靠性 |
|------|------|------|--------|
| Modbus RTU | 串口 | 低（115kbps）| 高 |
| Modbus TCP | 以太网 | 中 | 高 |
| OPCUA | 以太网 | 高 | 高 |
| EtherCAT | 以太网 | 极高（μs级）| 高 |

## 关键信号

| 信号 | 方向 | 类型 |
|------|------|------|
| 机器人状态 | → PLC | Bool（运行/停止/报警）|
| 生产指令 | ← PLC | Int（工件号/工序）|
| 位置确认 | → PLC | Bool（到位信号）|
| 速度数据 | → PLC | Real（实际速度）|
| 急停 | ↔ 双向 | Bool（安全）|

## 禁止

- ❌ 急停信号不经过 ROS2（必须直连 PLC）
- ❌ 通信超时 > 100ms 不处理（生产线节拍要求）
- ❌ 断网时不进入安全停止状态
