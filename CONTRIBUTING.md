# Contributing to vibe-coding-ros2

> 如何贡献高质量代码和文档。

---

## SKILL.md 编写规范

每个 SKILL.md 必须包含：

### 必须包含的 4 个部分

```markdown
# SKILL — <topic>

<一句话描述这个 skill 解决的问题>

## Tools
- <tool 1>: <具体用途>
- <tool 2>: <具体用途>

## Usage
<使用场景描述>

## Tips
- <实战技巧 1>
- <实战技巧 2>
```

### 质量标准

| 要求 | 说明 |
|------|------|
| **≥1 个实战案例** | 必须包含具体的错误案例 + 修复前后对比 |
| **具体代码示例** | 至少一段可直接使用的代码 |
| **预期输出** | 命令的预期输出截取 |
| **中文 + 英文混写** | 概念用中文，技术术语用英文 |

### 禁止

- ❌ 纯概念描述，无具体代码
- ❌ 复制粘贴模板，无实战内容
- ❌ 链接外部文档代替正文

### 示例：合格 vs 不合格

**❌ 不合格（模板填充）：**
```markdown
# SKILL — ros2-cmake-guard

CMake 很重要。确保三行导出。

## Usage
按照规则写 CMakeLists.txt。
```

**✅ 合格（有实战案例）：**
```markdown
# SKILL — ros2-cmake-guard

CMake 导出三行缺失会导致链接错误。

## Tools
- `ament_export_dependencies`: 导出依赖
- `ament_target_dependencies`: 链接依赖

## Usage
在 CMakeLists.txt 末尾添加三行。

## Tips
- 三行必须同时存在，缺一不可
- 验证：`colcon build --packages-select PKG` 无 undefined reference

## Real Error Case
```
/usr/bin/ld: CMakeFiles/publisher.dir/src/publisher_node.cpp.o: 
undefined reference to `rclcpp::Publisher::publish(...)'
```
修复：在 CMakeLists.txt 末尾添加：
```cmake
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})
```
```

---

## 提交规范

### Commit Message 格式

```
<type>(<scope>): <简短描述>

<可选的详细说明>
```

**Type:** feat | fix | docs | refactor | test | chore

**Example:**
```
feat(scripts): add ros2-tf2-broadcaster.sh

Add TF2 broadcast node generator for robot URDF integration.
Includes quaternion setup and dynamic parameter updates.
```

### 脚本规范

- 所有 `*.sh` 必须 `bash -n` 通过
- 添加 `#!/bin/bash` shebang
- 使用 `set -e` 错误退出
- 定义颜色变量：`RED GREEN YELLOW BLUE NC`
- 对非零退出码使用 `|| true` 避免误退出

### 文档规范

- README 按痛点 → 解决 → 差异化结构组织
- 工具链文档用表格展示
- 代码块标注语言（bash/cpp/python）
