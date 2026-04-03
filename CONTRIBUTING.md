# 如何为 vibe-coding-ros2 贡献代码

> 感谢你贡献！本项目欢迎所有形式的改进：文档、Skill、代码、测试。

---

## 贡献类型

| 类型 | 说明 | 难度 |
|------|------|------|
| 🐛 Bug 修复 | 修复现有代码的错误 | ⭐ |
| 📄 文档改进 | 修正错别字、完善说明 | ⭐ |
| 🎯 新增 Skill | 在 agents/skills/ 下添加新 SKILL.md | ⭐⭐ |
| 🔧 脚本改进 | 改进 scripts/ 下的工具 | ⭐⭐ |
| 📦 示例代码 | 在 examples/ 下添加新示例 | ⭐⭐ |
| 🔬 测试 | 添加 ROS2 编译测试或单元测试 | ⭐⭐⭐ |
| 🏗️ 重构 | 大规模代码重构（需先讨论） | ⭐⭐⭐⭐ |

---

## 开发流程

### 1. Fork + Clone

```bash
# Fork: https://github.com/MIUAV/vibe-coding-ros2/fork

# Clone 你的 Fork
git clone https://github.com/<你的用户名>/vibe-coding-ros2.git
cd vibe-coding-ros2

# 添加上游仓库
git remote add upstream https://github.com/MIUAV/vibe-coding-ros2.git
```

### 2. 创建分支

```bash
# 从 latest 创建功能分支
git checkout -b feat/my-new-skill

# 命名规范:
#   feat/<skill-name>        新增 Skill
#   fix/<issue-number>        Bug 修复
#   docs/<description>        文档改进
#   script/<tool-name>        脚本工具
#   example/<example-name>     新示例
```

### 3. 开发

```bash
# 3.1 运行初始化（生成 .gitignore 等本地配置）
./init-agent.sh

# 3.2 开发你的内容
# ...

# 3.3 验证（如果修改了脚本）
bash scripts/check_ros2_package.sh <pkg_dir>
bash scripts/validators/ros2-node-validator.sh src/my_node.cpp
bash scripts/mcp/mcp-agent-orchestrator.sh <case> --agent claude  # 可选

# 3.4 提交
git add .
git commit -m "feat: add my new skill"
```

### 4. 提交 Pull Request

```bash
# 推送分支
git push origin feat/my-new-skill

# 在 GitHub 上创建 PR:
# https://github.com/MIUAV/vibe-coding-ros2/compare
```

### 5. PR 模板

```markdown
## 描述
简要说明你的改动。

## 改动类型
- [ ] 新增 Skill（agents/skills/...）
- [ ] 改进现有 Skill
- [ ] 新增/改进脚本
- [ ] 新增示例
- [ ] 文档修正

## 关联的 Issue（如果有）
Closes #XXX

## 自检清单
- [ ] 新 Skill 有 Frontmatter（name/description/argument-hint/user-invocable）
- [ ] 代码示例可以编译（colcon build --packages-select <pkg>）
- [ ] 遵循 ANTI_PATTERNS.md 规范
- [ ] AGENTS_CONCISE.md 自检通过
```

---

## Skill 贡献规范

### 文件结构

```
agents/skills/
└── <robot_type>/
    └── <domain>/
        └── SKILL.md          ← 每个 Skill 一个目录
```

### Frontmatter 必须字段

```yaml
---
name: skill-name                    # 小写+连字符，唯一
description: 技能描述               # 一句话描述功能
argument-hint: "触发词1" / "触发词2"  # AI 触发关键词
user-invocable: true              # true=用户可直接调用
---

# Skill 内容...
```

### Frontmatter 可选字段

```yaml
---
name: skill-name
description: 技能描述
argument-hint: "触发词"
user-invocable: true
status: draft  # draft | verified | concept
version: "1.0"  # 版本号
author: GitHub用户名
tags: ["ros2", "navigation"]  # 标签
---
```

### Skill 内容规范

1. **何时使用**：明确什么场景触发这个 Skill
2. **快速参考**：常用命令/代码片段
3. **详细说明**：核心概念 + 代码示例
4. **质量自检**：完成后的检查清单
5. **常见问题**：FAQ 格式

### 代码示例规范

```cpp
// ✅ 正确：完整的可编译代码
#include <rclcpp/rclcpp.hpp>

class MyNode : public rclcpp::Node {
public:
  MyNode() : Node("my_node") {
    pub_ = this->create_publisher<std_msgs::msg::String>("/topic", 10);
  }
private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;  // SharedPtr
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MyNode>());
  rclcpp::shutdown();
  return 0;
}
```

```cpp
// ❌ 错误：裸指针、占位符、不完整的片段
class MyNode : public rclcpp::Node {
  rclcpp::Publisher<...>* pub_;  // 裸指针！
};
// TODO: 完成实现
```

### Skill 自检

- [ ] Frontmatter 字段完整（name/description/argument-hint）
- [ ] 代码示例 > 20 行或包含完整可运行的逻辑
- [ ] 包含"何时使用"说明
- [ ] 包含质量自检清单
- [ ] 遵循 ANTI_PATTERNS.md（C++: SharedPtr / QoS / Lifecycle）

---

## 脚本贡献规范

### 必须满足

```bash
#!/bin/bash
# 文件头注释
set -euo pipefail  # 必须有错误处理

# 函数定义
my_function() {
  local arg="${1:-}"
  # ...
}
```

### 测试你的脚本

```bash
# 语法检查
bash -n my_script.sh

# ShellCheck（如果安装了）
shellcheck my_script.sh

# 实际运行
bash my_script.sh <test_args>
```

---

## 示例代码规范

每个示例必须：
1. 包含 `package.xml` + `CMakeLists.txt`
2. 可通过 `colcon build --packages-select <pkg>` 编译
3. 包含 `launch/` 文件
4. 代码注释解释"为什么这样做"（不只是"做了什么"）

```bash
# 验证示例可编译
colcon build --packages-select <example_pkg>
```

---

## 分支策略

```
latest      ← 主要开发分支，稳定
  ↑
  │  feat/my-skill   ← 功能分支
  │  fix/bug-123     ← 修复分支
  │  docs/readme      ← 文档分支
  │
  └─ (合并后删除分支)
```

**规则**：
- 所有 PR 合并到 `latest`
- 分支命名：`feat/` `fix/` `docs/` `script/` `example/`
- 合并后删除源分支

---

## Commit Message 规范

```bash
# 格式
<类型>: <简短描述>

# 类型
feat     新增功能
fix      Bug 修复
docs     文档
refactor 重构（不改变功能）
perf     性能改进
test     测试
chore    维护（依赖、CI 等）

# 示例
feat: add slam SKILL.md with GMapping and Cartographer
fix: ros2-node-validator.sh missing set -e
docs: improve ANTI_PATTERNS QoS section
```

---

## 发现问题？

- 🐛 Bug → https://github.com/MIUAV/vibe-coding-ros2/issues/new?template=bug_report.md
- 💡 功能建议 → https://github.com/MIUAV/vibe-coding-ros2/issues/new?template=feature_request.md
- ❓ 提问 → https://github.com/MIUAV/vibe-coding-ros2/discussions

---

## 快速检查清单

```bash
# 提交前运行
bash scripts/check_ros2_package.sh <your_pkg>
bash scripts/validators/ros2-node-validator.sh <your_node.cpp>

# 确保 .gitignore 生效（init-agent.sh 生成本地文件）
./init-agent.sh --local
```

---

*感谢每一份贡献！*
