# ros2-tf2 — TF2 坐标变换示例

> 演示 TF2 静态/动态广播、TF 树可视化。

## TF2 树

```
world
  └── base_link  (动态移动)
        ├── laser_frame (静态: base_link 前方 0.2m 上方)
        └── camera_link (静态: base_link 左侧 0.15m)
```

## 编译

```bash
colcon build --packages-select ros2_tf2
source install/setup.bash
```

## 运行

```bash
ros2 run ros2_tf2 tf2_broadcaster
```

## 调试

```bash
# 可视化 TF 树
ros2 run tf2_ros view_frames

# 查看 TF 变换
ros2 topic echo /tf_static     # 静态变换
ros2 topic echo /tf             # 动态变换

# 手动查询变换
ros2 run tf2_ros tf2_echo world base_link
```

## 关键代码

```cpp
// 静态广播（只发一次）
tf2_ros::StaticTransformBroadcaster broadcaster(node);
broadcaster.sendTransform(static_transforms);

// 动态广播（定时）
tf2_ros::TransformBroadcaster broadcaster(node);
broadcaster.sendTransform(dynamic_transform);

// 查询变换
tf2_ros::Buffer buffer;
tf2_ros::TransformListener listener(buffer);
auto transform = buffer.lookupTransform("target", "source", tf2::TimePointZero);
```
