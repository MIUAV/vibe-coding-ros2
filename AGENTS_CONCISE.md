# Vibe-Coding-ROS2 — 极简指令卡

> 任何 AI Agent 必须按此顺序执行，不得跳过任何步骤。

---

## 核心规则（不可违背）

### 接口先行（Interface First）

```
1. 定义 .msg / .srv / .action 文件（或确认使用标准类型）
2. 在 package.xml 中声明 rosidl_generate_interfaces
3. 生成节点代码
4. 编写 launch 文件
5. 编译验证
```

### 文件生成顺序（强制）

```
package.xml → CMakeLists.txt → msg/srv → 节点代码 → launch → 编译
```

### ROS2 发行版

| 发行版 | 支持状态 |
|--------|----------|
| Humble | ✅ 推荐 |
| Iron   | ✅ 支持 |
| Jazzy  | ✅ 支持 |
| Foxy   | ⚠️ 有限 |

---

## Anti-Patterns（禁止）

```
🚫 CMakeLists.txt 遗漏 find_package(rclcpp REQUIRED)
🚫 Python 节点混用 rclpy.init() + MultiThreadedExecutor 无关闭逻辑
🚫 假设 install/setup.bash 已被 source（每次都要提醒用户）
🚫 launch 文件缺少 launch_description = LaunchDescription([...])
🚫 未在 package.xml 声明 <depend> 就使用某个包
🚫 C++ 代码混用 rclcpp::Node 和 rclcpp::Node::SharedPtr
```

---

## 输出格式模板

### 接口定义（必须先生成）

```
## 接口设计
- 话题: [标准类型] → 用途
- 服务: MyService.srv → 内容：
---（服务定义）
---
- 动作: 无（或自定义）
```

### 节点代码

```cpp
// C++ 必须结构
#include <rclcpp/rclcpp.hpp>

class MyNode : public rclcpp::Node {
public:
  MyNode() : Node("my_node") {
    // 1. 发布/订阅
    // 2. 服务/动作
    // 3. 定时器或回调
  }
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MyNode>());
  rclcpp::shutdown();
  return 0;
}
```

### Launch 文件（必须结构）

```python
def generate_launch_description():
    return LaunchDescription([
        # Node(...)  必须用完整的 Node 参数
        # 不省略任何参数
    ])
```

---

## 缩写速查

```
msg = Message (接口定义)
srv = Service (请求/响应)
act = Action (异步目标/反馈/结果)
ws  = workspace
pkg = package
dep = dependency (package.xml 中的 depend)
KB  = Knowledge Base (skills/SKILL.md)
FP  = Frontmatter (SKILL.md 开头的 YAML 块)
```

---

## 内存约定（每次会话读写）

```
文件: /tmp/vibe-ros2-memory.md
格式:
## 已实现模块
- pkg_name: [功能简述]

## 待办
- [pkg_name]: [功能]

## 已知问题
- ...

每次开始: 读取
每次完成模块: 更新
```

---

## 质量自检清单

```
□ package.xml 有 <depend> 声明
□ CMakeLists.txt 有 find_package()
□ launch 有 LaunchDescription()
□ C++ 有 rclcpp::init/shutdown
□ Python 有 rclpy.shutdown() 逻辑
□ install/setup.bash 被提醒 source
□ 代码经过编译测试
```

---

*AGENTS_CONCISE.md — 精简版，如需完整指南见 AGENTS.md*
