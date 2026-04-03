# 图形化工具

> ROS2 图形化开发与调试工具

---

## 启动文件编辑器

### rxplot（Python3）

```bash
ros2 run rxplot <topic_name>
```

实时绘制数值话题，支持多条曲线叠加。

### rqt

```bash
rqt
```

GUI 框架，支持以下插件：

| 插件 | 命令 | 用途 |
|------|------|------|
| rqt_graph | `rqt_graph` | 计算图可视化 |
| rqt_console | `rqt_console` | 日志查看器 |
| rqt_logger_level | `rqt_logger_level` | 设置节点日志级别 |
| rqt_plot | `rqt_plot` | 数值曲线绘制 |
| rqt_image_view | `rqt_image_view` | 图像话题查看 |
| rqt_service_caller | `rqt_service_caller` | Service 调用器 |
| rqt_bag | `rqt_bag` | Bag 可视化播放器 |

### rqt_graph

```bash
# 显示所有节点和话题
rqt_graph

# 只显示发布者/订阅者（隐藏其他）
rqt_graph --hide-debug
```

### rviz2

```bash
rviz2
```

三维可视化工具，常用配置：

| 配置项 | 说明 |
|--------|------|
| Fixed Frame | `map` 或 `odom` |
| TF Display | 显示坐标系树 |
| LaserScan | 激光扫描点云 |
| PointCloud2 | 深度传感器点云 |
| Image | 相机图像 |
| Path | 路径规划结果 |

### foxglove

```bash
# 安装
sudo apt install ros-humble-foxglove Bridge

# 启动
ros2 launch foxglove_bridge foxglove_bridge_launch.xml

# 或使用 web 界面
# 访问 http://localhost:8765
```

专业可视化平台，支持自定义布局，比 rviz2 更现代：

- 多面板布局（数值曲线、图像、点云、地图）
- 数据录制与回放
- 自定义消息类型
- Web 端访问

### plotjuggler

```bash
sudo apt install ros-humble-plotjuggler-ros
ros2 run plotjuggler plotjuggler
```

强大的数值绘图工具：

- 支持 ROS2 bag 文件回放
- 多曲线对比
- 数据导出（CSV、JSON）
- 实时流订阅

## 工具链速查

| 场景 | 工具 |
|------|------|
| 节点通信图 | `rqt_graph` |
| 日志查看 | `rqt_console` |
| 参数动态调参 | `rqt_reconfigure` |
| 图像查看 | `rqt_image_view` / foxglove |
| 点云查看 | rviz2 / foxglove |
| 数值曲线 | `rxplot` / `rqt_plot` / plotjuggler |
| Bag 回放 | `rqt_bag` / foxglove / plotjuggler |
| TF 树查看 | `rviz2` + TF panel |
| 服务调用测试 | `rqt_service_caller` / CLI `ros2 service call` |

## 调试命令速查

```bash
# 列出所有话题及带宽/频率
ros2 topic list -v

# 查看话题内容
ros2 topic echo <topic_name>

# 测量话题频率
ros2 topic hz <topic_name>

# 列出所有节点
ros2 node list

# 查看节点信息
ros2 node info <node_name>

# 列出所有接口
ros2 interface list

# 查看消息类型详情
ros2 msg show <msg_type>
```
