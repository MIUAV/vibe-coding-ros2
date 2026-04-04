# CRITICAL_ISSUES.md — 关键问题追踪

> 更新时间：2026-04-04 23:50

---

## 🔴 未解决

### ISSUE-001: MCP Server 连接验证
- **严重程度:** 高
- **描述:** ros-mcp-integration.sh 已实现但未在实际 ROS2 环境中验证
- **下一步:** 在真实 ROS2 Humble 环境中测试 `ros2 topic list` MCP 调用

---

## 🟡 进行中

### ISSUE-002: ament_auto vs 标准 CMake 混用
- **严重程度:** 中
- **描述:** ros2-package-generator.sh 生成的部分包用 ament_auto，部分用标准 CMake，依赖声明风格不统一
- **下一步:** 统一生成器输出，全部使用标准 ament_cmake（不依赖 ament_auto）

---

## ✅ 已解决

### ISSUE-003: QoS 静默失败
- **解决时间:** 2026-04-04 晚
- **解决方式:** 创建 `agents/skills/ros2-qos-checker/SKILL.md`，内置 QoS 选择规则

### ISSUE-004: Lifecycle 状态机错误
- **解决时间:** 2026-04-04 晚
- **解决方式:** `agents/skills/ros2-debug/SKILL.md` 中详细说明了 LifecycleNode 使用规范

### ISSUE-005: CMake 链接错误 (ament_export_dependencies)
- **解决时间:** 2026-04-04 晚
- **解决方式:** `scripts/ros2-build-feedback.sh` 自动检测并给出修复建议

### ISSUE-006: Nav2 参数调节无从下手
- **解决时间:** 2026-04-04 晚
- **解决方式:** `agents/skills/navigation/nav2-config/SKILL.md` 提供了参数速查表和典型场景

---

## 📋 已知限制

1. **ros2-package-generator 不支持 Python-only 包** — 需补充 `ament_python` 生成逻辑
2. **无 CI 验证** — 所有生成代码未经自动化编译测试
3. **中文文档质量参差不齐** — 部分文档由机器翻译，未验证准确性
