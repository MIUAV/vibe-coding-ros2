# Anti-Patterns — AI 常见错误清单

> 这些是 AI 在 ROS2 开发中最常犯的错误，用 `🚫 禁止` 标记，每次生成代码时必须检查。

---

## CMakeLists.txt

```
🚫 遗漏 find_package(rclcpp REQUIRED)
   → 必须先 find_package 所有依赖

🚫 遗漏 ament_target_dependencies()
   → add_library 后必须链接触参

🚫 遗漏 install(TARGETS ...)
   → 编译成功但无法安装运行

🚫 遗漏 ament_package()
   → 包无法被 rosdep 识别

🚫 混淆 ament_cmake 和 ament_python
   → C++ 包必须用 ament_cmake

🚫 用 add_executable 代替 add_library
   → 库才能被其他包链接
```

---

## package.xml

```
🚫 遗漏 <depend> 就使用某个包
   → 编译报错 "package 'xxx' not found"

🚫 遗漏 rosidl_default_generators (消息包)
   → 消息无法生成

🚫 用 build_depend 但遗漏 exec_depend
   → 运行时找不到.so

🚫 用 Format 2 但未声明 <export>
   → 下游包无法找到依赖

🚫 遗漏 <buildtool_depend>ament_cmake
   → 无法编译
```

---

## Python 节点

```
🚫 混用 rclpy.init() + MultiThreadedExecutor 无关闭逻辑
   → Ctrl+C 无法停止

🚫 在构造函数中创建订阅不用 SharedPtr
   → 内存泄漏
   ✅ sub_ = create_subscription<...>(..., [this](...) { ... });

🚫 不 source install/setup.bash 就运行
   → "package not found"

🚫 Python 节点忘记 `if __name__ == '__main__':`
   → 模块被 import 时直接执行

🚫 混用 rclpy 和 rclcpp
   → 两者不能在同一进程混用
```

---

## C++ 节点

```
🚫 混用 rclcpp::Node 和 rclcpp::Node::SharedPtr
   → 类型不匹配

🚫 在回调函数中执行耗时操作
   → 阻塞主循环
   ✅ 用多线程 executor 或将耗时操作移到 timer

🚫 遗漏 rclcpp::init() / rclcpp::shutdown()
   → 资源未正确初始化/清理

🚫 SharedPtr 循环引用
   → 内存泄漏
   ✅ 用 weak_ptr 打破循环
```

---

## Launch 文件

```
🚫 缺少 launch_description = LaunchDescription([...])
   → launchd 启动失败

🚫 Node 参数不完整
   → 必须包含: package, executable, name, output

🚫 省略 remappings 或 parameters
   → 默认值可能不符合预期

🚫 在 launch.py 中执行 os.system("source ...")
   → 不生效
   ✅ 在终端中 source 后再启动 launch

🚫 多个包写在同一个 launch 文件但未配置 namespace
   → 话题名冲突
```

---

## 消息/服务/动作

```
🚫 .msg 文件中有多余空格
   → 生成失败

🚫 .srv 定义不区分 --- 分隔符前后
   → 编译器混淆

🚫 动作的 result 和 feedback 类型设为空
   → action server 崩溃
```

---

## 命名规范

```
🚫 包名带下划线 _ (ROS2 不允许)
   ✅ 用 my_robot_control 而不是 my_robot_control

🚫 话题名用驼峰命名
   ✅ /cmd_vel (snake_case)

🚫 变量名与 ROS2 关键字冲突
   → class, public, private 等

🚫 命名空间硬编码
   → 用参数或 launch 配置替代
```

---

## 编译与运行

```
🚫 不运行 colcon build 就 source
   → 包不存在

🚫 用 colcon build 而非 --symlink-install 开发
   → 每次改代码都要重新编译

🚫 安装依赖后不更新 ROS_DOMAIN_ID
   → 跨机器通信失败

🚫 修改代码后不重新编译
   → 运行的还是旧代码
```

---

## 快速检查命令

```bash
# CMakeLists.txt 检查
grep -c "find_package" CMakeLists.txt
grep -c "ament_target_dependencies" CMakeLists.txt
grep -c "install(TARGETS" CMakeLists.txt
grep -c "ament_package" CMakeLists.txt

# package.xml 检查
grep -c "<depend>" package.xml

# Python 检查
grep -c "rclpy.shutdown" my_node.py
grep -c "if __name__" my_node.py

# Launch 检查
grep -c "LaunchDescription" my.launch.py
```

---

*ANTI_PATTERNS.md — 每次生成代码前必读*
