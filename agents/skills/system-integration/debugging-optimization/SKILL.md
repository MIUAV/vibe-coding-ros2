---
name: debugging-optimization
description: ROS2 调试与优化 — rqt/rviz 工具链、性能分析、内存泄漏检测、实时性优化
argument-hint: 调试 OR debugging OR rqt OR rviz OR 性能 OR profiling OR 内存泄漏 OR latency
user-invocable: true
---

# debugging-optimization — 调试与优化 SKILL

## 引用技能

- `agents/skills/ros2-debug/`
- `agents/skills/ros2-qos-checker/`

## 工具链

| 工具 | 用途 |
|------|------|
| `rqt_graph` | 节点关系图 |
| `rqt_console` | 日志查看 |
| `rqt_topic` | 话题监控 |
| `rqt_bag` | Bag 可视化 |
| `valgrind` | 内存泄漏 |
| `perf` | CPU profiling |

## 实时性优化

```cpp
// 实时线程优先级
struct sched_param sp;
sp.sched_priority = 50;
pthread_setschedparam(pthread_self(), SCHED_FIFO, &sp);
```

## 禁止

- ❌ 不做 profiling 就优化（盲目优化）
- ❌ 在主线程做耗时计算（阻塞控制循环）
