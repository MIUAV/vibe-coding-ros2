# AGENTS — VibeCoding-ROS2 工作流

## 执行顺序（强制）

```
1. 读 i18n/zh-CN/AGENTS_CONCISE.md  ← 必须先读
2. 读 i18n/zh-CN/ANTI_PATTERNS.md   ← 必须二读
3. 读 skill-index.md     ← 找对应 SKILL.md
4. 读对应 SKILL.md       ← 获取实现细节
5. 写代码
6. 自检清单
7. 更新 ROS2_MEMORY.md
```

## 核心原则

### 接口先行

```
ROS2 开发顺序（不可颠倒）：
1. 定义 .msg / .srv / .action（或用标准类型）
2. 配置 CMakeLists.txt: rosidl_generate_interfaces
3. 配置 package.xml: rosidl 依赖
4. 写节点代码
5. 写 launch 文件
6. colcon build
7. 提醒用户 source install/setup.bash
```

### 文件结构规范

```
pkg_name/
├── package.xml          # 依赖声明
├── CMakeLists.txt       # 构建配置
├── src/                 # C++ 源码
├── msg/                 # .msg 定义
├── srv/                 # .srv 定义
├── action/              # .action 定义
├── launch/              # .launch.py
└── config/              # YAML 参数
```

### 禁止事项（详见 i18n/zh-CN/ANTI_PATTERNS.md）

- CMakeLists.txt 遗漏 find_package
- package.xml 遗漏 <depend>
- launch 文件缺少 LaunchDescription
- 不提醒 source install/setup.bash
- Python 混用 rclpy.init() 无关闭逻辑

## 内存约定

```
工作空间临时记忆文件: /tmp/vibe-ros2-memory.md
项目持久记忆文件: memory-bank/ROS2_MEMORY.md（每个项目根目录）

格式:
## 已实现模块
- pkg_name: [一句话描述]

## 待办
- [pkg_name/功能]: [描述]

## 已知问题
- [pkg]: [问题描述]

每次会话开始 → 读
每次完成功能 → 更新
```

## 发行版支持

| 发行版 | 推荐版本 |
|--------|----------|
| Humble | ✅ 首选 |
| Iron   | ✅ |
| Jazzy  | ✅ |
| Foxy   | ⚠️ |

## 快捷缩写

```
FP  = Frontmatter (SKILL.md 头部 YAML)
KB  = Knowledge Base (SKILL.md)
AP  = Anti-Patterns (i18n/zh-CN/ANTI_PATTERNS.md)
MEM = ROS2_MEMORY.md
```

## 质量自检（完成后必须）

```
□ package.xml: 所有 <depend> 已声明
□ CMakeLists.txt: find_package + ament_target_dependencies
□ CMakeLists.txt: install(TARGETS + ament_package
□ Launch: 有 LaunchDescription() 结构
□ C++: rclcpp::init + rclcpp::shutdown
□ Python: rclpy.shutdown() 或 Executor 正确关闭
□ 用户被提醒 source install/setup.bash
□ 代码已编译通过
```

## 工具快捷命令

```bash
# 创建 ROS2 包（代替手动写）
ros2 pkg create pkg_name --dependencies rclcpp std_msgs

# 创建接口
ros2 interface show sensor_msgs/msg/LaserScan

# 构建（开发推荐）
colcon build --symlink-install

# 快速测试
ros2 pkg list | grep pkg_name
ros2 pkg executables pkg_name
```

---

*完整指南见 i18n/zh-CN/AGENTS_CONCISE.md（精简版）和各 SKILL.md*
