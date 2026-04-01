# ROS2 开发常用提示词模板

> 用户可直接复制使用的高频提示词

---

## 1. 创建项目上下文

```
请帮我创建一个 ROS2 项目上下文文档。
信息如下：
- 项目名称：巡检机器人
- 目标平台：Jetson OrinNX
- ROS2 版本：Humble
- 核心功能：图像检测 + 激光雷达导航
- 开发语言：C++

请按照 vibe-coding-ros2 的模板生成完整的上下文文档。
```

---

## 2. 创建功能包

```
请帮我创建一个 ROS2 功能包。

包名：image_processor
语言：C++
核心依赖：rclcpp, sensor_msgs, cv_bridge, image_transport
功能：接收原始图像，进行预处理后输出

请生成完整的包结构，包括：
1. CMakeLists.txt
2. package.xml
3. 基础节点代码
4. Launch 文件
5. 参数文件
```

---

## 3. 添加新节点

```
请在现有的 my_robot 包中添加一个新节点。

节点名：patrol_node
功能：实现巡检状态机
- 订阅 /cmd_vel 接收运动指令
- 发布 /odom 里程计数据
- 接收 /patrol/path 路径数据
- 状态机：IDLE -> PATROLLING -> RETURNING

请生成完整的节点代码和状态机实现。
```

---

## 4. 调试 Topic 问题

```
我的 /camera/image_raw 话题没有数据。

已尝试：
1. ros2 topic list 显示话题存在
2. 相机驱动节点正在运行
3. ros2 doctor 无明显错误

请帮我分析可能的原因，并给出调试步骤。
```

---

## 5. 配置交叉编译

```
请帮我配置 ARM64 交叉编译环境。

目标平台：Jetson OrinNX
现有工具：
- x86_64 开发机
- Linux_for_Tegra/rootfs 已解压
- ros:humble 镜像

请生成：
1. aarch64.toolchain.cmake 文件
2. Dockerfile.arm64_cross
3. colcon build 编译命令
```

---

## 6. 创建 Launch 文件

```
请帮我创建一个 Launch 文件。

要求：
- 启动 image_processor 节点
- 启动 camera_driver 节点
- camera_driver 的输出 remap 到 image_processor 的输入
- 从 config/params.yaml 加载参数
- 设置节点名称空间为 /robot1

请生成 Python 格式的 launch 文件。
```

---

## 7. 定义自定义消息

```
请帮我定义一个自定义消息。

消息用途：目标检测结果
包含字段：
- Header (时间戳和坐标系)
- uint8 检测类型 (PERSON=0, CAR=1, OBSTACLE=2)
- uint8 数量
- float32[] 置信度数组
- geometry_msgs/Box[] 边界框数组

请生成 .msg 文件和对应的 CMakeLists.txt 配置。
```

---

## 8. 优化性能

```
我的图像处理节点延迟太高 (100ms+)，请帮我优化。

当前实现：
- 订阅 /camera/image_raw (1920x1080 @ 30Hz)
- OpenCV 处理 (缩放 + 格式转换)
- 发布处理后的图像

请给出：
1. 可能的性能瓶颈分析
2. 优化方案 (多线程/流水线/零拷贝)
3. 优化后的代码示例
```

---

## 9. 部署到 OrinNX

```
请帮我创建一个部署脚本。

信息：
- 目标机 IP：192.168.1.110
- 用户名：ubuntu
- 编译产物在 ./install 目录
- 需要部署到 /opt/ros_ws/

请生成：
1. 打包命令
2. 传输命令
3. 远程安装命令
4. 验证命令
```

---

## 10. 代码审查

```
请帮我审查以下代码的 ROS2 最佳实践。

文件：src/detection_node.cpp
语言：C++

关注点：
1. 内存管理 (是否有泄漏)
2. 线程安全 (多线程访问)
3. QoS 配置 (是否合理)
4. 错误处理 (是否有遗漏)
5. 日志规范 (是否适当)

请给出审查报告和改进建议。
```
