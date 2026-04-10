# Toolchain Guide — 工具链使用记忆

## 工具链总览

```
生成包骨架 ──→ colcon build ──→ 错误诊断 ──→ 自动修复
(必选)           (自动)         (可选)
```

## 标准工作流

```bash
# 1. 生成包（自动创建 CMakeLists.txt + package.xml + 基础结构）
bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp <deps> [--verify]

# 2. 生成节点代码（选类型）
bash scripts/generators/ros2-cpp-node.sh <node_type> <pkg_name> <deps>
# node_type: publisher | subscriber | lifecycle | service | action | timer | parameters

# 3. 编译验证（3轮自动修复）
bash scripts/ros2-build-verify-loop.sh <pkg_name>

# 4. 如需启动文件
bash scripts/generators/ros2-launch-generator.sh <type> <pkg_name>
```

## 生成器脚本清单（scripts/generators/）

| 脚本 | 输入 | 输出 |
|------|------|------|
| `ros2-package-generator.sh` | pkg_name, language, deps | 完整包骨架 |
| `ros2-cpp-node.sh` | node_type, pkg_name, deps | C++ 节点代码 |
| `ros2-interface-generator.sh` | pkg_name, interface_type | msg/srv/action 包 |
| `ros2-msg-generator.sh` | — | 交互式 .msg 生成 |
| `ros2-srv-generator.sh` | — | 交互式 .srv 生成 |
| `ros2-launch-generator.sh` | launch_type, pkg_name | launch.py |
| `ros2-nav2-node-generator.sh` | node_type, pkg_name | Nav2 兼容节点 |
| `ros2-control-node-generator.sh` | controller_type, pkg_name | ros2_control 节点 |
| `ros2-moveit-generator.sh` | moveit_type, pkg_name | MoveIt2 节点 |
| `ros2-simulator-generator.sh` | robot_type, pkg_name | Gazebo 仿真包 |
| `ros2-slam-generator.sh` | slam_type, pkg_name | SLAM 配置包 |
| `ros2-diagnostics-generator.sh` | robot_type, pkg_name | 诊断节点 |
| `ros2-multi-agent-generator.sh` | coord_type, pkg_name | 多机协调包 |
| `ros2-behavior-tree-generator.sh` | bt_type, pkg_name | BT.xml |
| `ros2-rl-controller-generator.sh` | rl_algorithm, pkg_name | RL 控制器 |
| `ros2-camera-calibration-generator.sh` | calib_type | 标定配置 |
| `ros2-param-generator.sh` | param_type | YAML 参数文件 |
| `ros2-gazebo-world-generator.sh` | world_type | Gazebo world |
| `ros2-mission-generator.sh` | mission_type | Mission 脚本 |
| `ros2-data-logger.sh` | logger_type | 数据记录节点 |
| `ros2-safety-generator.sh` | safety_type | 安全模块 |
| `ros2-orchestrate.sh` | description | 完整项目编排 |

## 验证工具（scripts/）

| 脚本 | 用途 |
|------|------|
| `ros2-build-verify-loop.sh` | 编译 + 错误分析 + 自动修复（3轮） |
| `ros2-build-feedback.sh` | 解释编译错误 + 修复建议 |
| `ros2-debug.sh` | 8类运行时错误诊断 |
| `ros2-cmake-fix.sh` | CMake 依赖诊断 |
| `ros2-format.sh` | clang-format 格式检查 |
| `ros2-env-check.sh` | ROS2 环境诊断 |
| `ros2-monitor.sh` | 运行时监控 |
| `ros2-bag-tool.sh` | Bag 日志分析 |
| `ros2-param-wizard.sh` | 参数 YAML 生成 |
| `ros2-performance-monitor.sh` | 性能监控 |

## 翻译工作流（i18n/）

翻译脚本已移至 `i18n/translate-docs.sh`，翻译文件输出到 `i18n/` 目录。

```bash
# 环境变量
export DEEPL_API_KEY=your_key_here  # 或使用 Google Translate

# 翻译单个文件（从项目根目录运行）
bash i18n/translate-docs.sh README.md ja-JP --deepl

# 翻译整个目录
bash i18n/translate-docs.sh agents/memory-bank/ ko-KR --deepl

# 输出格式：i18n/<原文件名>.<语言代码>.<扩展名>
# → i18n/README.ja-JP.md
# → i18n/CLAUDE.ko-KR.md
```

## 自检命令速查

```bash
# 语法检查
bash -n scripts/generators/ros2-package-generator.sh

# 查看包依赖
rosdep check --from-paths src/ --ignore-src -r -y

# 查看 topic QoS
ros2 topic info /scan --verbose

# 查看节点状态
ros2 lifecycle get /my_node

# 列出可用 launch 文件
ros2 pkg executables <pkg_name>

# bag 信息
ros2 bag info <bag_file>

# TF 树
ros2 run tf2_tools view_frames
```

## 常见使用模式

### 生成 Nav2 包
```bash
bash scripts/generators/ros2-package-generator.sh my_nav cpp nav2_msgs,nav2_util --verify
bash scripts/generators/ros2-nav2-node-generator.sh lifecycle my_nav nav2_msgs
```

### 生成 MoveIt2 包
```bash
bash scripts/generators/ros2-package-generator.sh my_arm cpp moveit_ros_planning_interface --verify
bash scripts/generators/ros2-moveit-generator.sh move_group my_arm
```

### 生成 Gazebo 仿真包
```bash
bash scripts/generators/ros2-simulator-generator.sh manipulator my_sim
```

### 批量翻译文档
```bash
for lang in zh-CN ja-JP ko-KR; do
  bash i18n/translate-docs.sh README.md $lang --deepl
done
```
