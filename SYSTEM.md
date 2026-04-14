# SYSTEM.md — AI Agent 强制规则

> 本文件是 AI Agent 的最高优先级指令。**违反即停止生成**，不输出任何代码直到规则满足。

---

## 🚨 零容忍规则（违反 = 立即停止）

### 规则 0：模板先行

**任何 ROS2 包生成，必须先用 `scripts/generators/ros2-package-generator.sh`**：

```bash
bash scripts/generators/ros2-package-generator.sh PKG_NAME cpp rclcpp,std_msgs
```

禁止凭空创建 CMakeLists.txt / package.xml。生成后在其基础上追加，不重写。

### 规则 1：CMake 三行导出（零例外）

所有 `ament_target_dependencies` 后**必须紧跟**：

```cmake
ament_export_dependencies(rclcpp std_msgs ...)   # 依赖树导出
ament_export_include_directories(include)          # 头文件路径（有include时）
ament_export_libraries(${PROJECT_NAME})            # 库链接
```

**没有例外。** 不写这三条 = 链接失败 = 代码不可用。

### 规则 2：LifecycleNode 生产规范

机器人控制类节点，**必须用** `rclcpp_lifecycle::LifecycleNode`：

```cpp
class RobotController : public rclcpp_lifecycle::LifecycleNode {
public:
    RobotController() : rclcpp_lifecycle::LifecycleNode("robot_controller") {}
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_configure(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Configuring");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    // on_activate / on_deactivate / on_cleanup / on_shutdown 同理
};
```

### 规则 3：QoS 组合强制检查

| 数据类型 | QoS 组合 | 错误后果 |
|---------|---------|---------|
| 控制命令（cmd_vel） | `QoS(10).reliable()` | 不通 = 机器人失控 |
| 传感器（camera/lidar） | `QoS(10).best_effort()` | 阻塞 = 数据积压 |
| 生命周期状态 | `QoS(10).transient_local()` | 新订阅者无数据 |

### 规则 4：文件创建顺序

```
package.xml → CMakeLists.txt → include/*.hpp → src/*.cpp → launch/*.py → test/*
```

顺序错 → 依赖缺失 → 编译失败。

---

## ⚙️ 工具链绑定

所有节点生成**必须**使用以下脚本，禁止手动创建：

| 任务 | 脚本 |
|------|------|
| 创建 ROS2 包 | `scripts/generators/ros2-package-generator.sh` |
| 创建 C++ 节点 | `scripts/generators/ros2-cpp-node.sh` |
| 创建 Lifecycle 节点 | `scripts/generators/ros2-cpp-node.sh lifecycle` |
| 创建 Nav2 节点 | `scripts/generators/ros2-nav2-node-generator.sh` |
| 创建 ros2_control 节点 | `scripts/generators/ros2-control-node-generator.sh` |
| 创建 MoveIt2 节点 | `scripts/generators/ros2-moveit-generator.sh` |
| 编译验证循环 | `scripts/ros2-build-verify-loop.sh` |
| 错误诊断 | `scripts/debugger/ros2-debug.sh` |

---

## 🔒 安全红线

- **不生成**裸指针管理的 ROS2 节点代码
- **不生成**未校验边界的数组索引操作
- **不生成**在 `on_configure` 之外做 `spin()` 的代码
- **不生成**超过 10Hz 的轮询循环（用 timer callback）

---

## 📋 AI 工作流

1. **读** `CLAUDE.md`（强制规则）→ 读 `SOUL.md`（项目哲学）
2. **查** `memory-bank/` 中相关模板（architecture-decisions / common-pitfalls）
3. **生成** 使用工具链脚本，不手写 CMakeLists.txt
4. **验证** 用 `ros2-build-verify-loop.sh` 闭环
5. **提交** 按 `CONTRIBUTING.md` commit 规范

---

*本文件内容优先级高于所有其他文档。AI 每次启动时重新加载。*
