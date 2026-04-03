---
name: ros2-distributed-communication
description: ROS2 分布式通讯技能 - DDS/RMW 配置、多机器通讯、网络优化、跨域配置
user-invocable: true
argument-hint: "分布式通讯" / "dds" / "rmw" / "多机器" / "跨域" / "network"
---

# ROS2 Distributed Communication Skill

> ROS2 DDS/RMW 分布式通讯完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 多机器机器人通讯
- DDS 中间件配置
- 网络优化和 QoS
- 跨域通讯配置
- 通讯诊断和调试

---

## 快速参考

### RMW 实现

| 实现 | 包 | 特性 |
|------|-----|------|
| CycloneDDS | rclcpp | 高性能，默认 |
| FastRTPS | fastrtps | 低延迟 |
| Connext | rti-connext | 企业级(收费) |

### 架构

```
┌─────────────┐      ┌─────────────┐
│   Node A    │      │   Node B    │
│  (机器 A)   │      │  (机器 B)   │
└──────┬──────┘      └──────┬──────┘
       │                   │
       └────────┬──────────┘
                │
         ┌──────┴──────┐
         │   RMW      │
         │ (DDS层)    │
         └──────┬──────┘
                │
         ┌──────┴──────┐
         │ Network     │
         │ (UDP/TCP)   │
         └─────────────┘
```

---

## RMW 配置

### 切换中间件

```bash
# 使用 FastRTPS
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# 使用 CycloneDDS
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# 使用 Connext (如已安装)
export RMW_IMPLEMENTATION=rmw_connext_cpp

# 验证
ros2 doctor -r
```

### 运行时切换

```cpp
// 代码中切换
rclcpp::init(argc, argv, 
    rclcpp::InitOptions::from_raw_arguments(
        "--rmw", "rmw_fastrtps_cpp"));
```

---

## 多机器通讯

### 网络发现配置

```xml
<!-- fastrtps.xml -->
<?xml version="1.0" ?>
<profiles>
    <participant name="participant_name">
        <rtps>
            <discoveryProtocol>SIMPLE</discoveryProtocol>
            <discoveryServers>
                <RemoteServer prefix="uuid">
                    <metatrafficUnicastLocatorList>
                        <locator>
                            <udpv4>
                                <address>192.168.1.100</address>
                                <port>11811</port>
                            </udpv4>
                        </locator>
                    </metatrafficUnicastLocatorList>
                </RemoteServer>
            </discoveryServers>
        </rtps>
    </participant>
</profiles>
```

### 设置环境变量

```bash
# 机器 A (服务器)
export ROS_LOCALHOST_ONLY=0
export RMW_FASTRTPS_DEFAULT_PROFILES_FILE=/path/to/fastrtps.xml
export FASTRTPS_DEFAULT_PROFILE=file:///path/to/fastrtps.xml

# 或者使用域 ID
export ROS_DOMAIN_ID=42
```

### 通讯测试

```bash
# 机器 A
ros2 run demo_nodes_cpp listener

# 机器 B
ros2 run demo_nodes_cpp talker

# 查看话题
ros2 topic list
```

---

## QoS 网络配置

### 可靠传输配置

```cpp
// 高可靠性配置
rclcpp::QoS reliable_qos(10);
reliable_qos.reliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE)
           .durability(RMW_QOS_POLICY_DURABILITY_VOLATILE);

auto sub = node->create_subscription<MyMsg>(
    "/topic", reliable_qos, callback);
```

### 跨域配置

```xml
<!-- cyclonedds.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<cyclonedds xmlns="https://cdds.io/config" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="https://cdds.io/config 
            https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
    <domain id="0">
        <discovery>
            <ParticipantIndex>auto</ParticipantIndex>
            <MaxAutoParticipantIndex>50</MaxAutoParticipantIndex>
        </discovery>
        <internal>
            <NetworkInterfaceAddress>auto</NetworkInterfaceAddress>
        </internal>
    </domain>
    <domain id="1">
        <discovery>
            <ParticipantIndex>auto</ParticipantIndex>
        </discovery>
    </domain>
</cyclonedds>
```

---

## 性能优化

### 网络绑定

```xml
<!-- 指定网络接口 -->
<profiles>
    <participant name="participant_name">
        <rtps>
            <transport>
                <sendSocketBufferSize>
                    <size>1048576</size>
                </sendSocketBufferSize>
                <receiveSocketBufferSize>
                    <size>1048576</size>
                </receiveSocketBufferSize>
            </transport>
            <metatrafficUnicastLocatorList>
                <locator>
                    <udpv4>
                        <address>192.168.1.10</address>
                        <port>7400</port>
                    </udpv4>
                </locator>
            </metatrafficUnicastLocatorList>
        </rtps>
    </participant>
</profiles>
```

### 缓冲区配置

```cpp
// 增加队列深度处理高吞吐
rclcpp::QoS high_throughput_qos(100);  // 深度100
high_throughput_qos.best_effort()
                   .durability_volatile();

auto pub = node->create_publisher<sensor_msgs::msg::PointCloud2>(
    "/points", high_throughput_qos);
```

---

## 跨域通讯 (Domain)

### 域 ID 配置

```bash
# 使用不同域隔离通讯
export ROS_DOMAIN_ID=0    # 主系统
export ROS_DOMAIN_ID=1    # 测试系统
export ROS_DOMAIN_ID=2    # 开发系统
```

### 域过滤

```xml
<!-- 只订阅特定域的数据 -->
<dataReader name="my_reader">
    <topic>
        <name>robot/chassis</name>
        <dataType>MyType</dataType>
        <domainId>0</domainId>
    </topic>
</dataReader>
```

---

## 常见问题排查

### 节点不可见

```bash
# 检查网络
ping other_machine

# 检查域 ID
echo $ROS_DOMAIN_ID

# 查看 ROS 诊断
ros2 doctor

# 列出所有节点
ros2 node list

# 查看节点信息
ros2 node info /talker
```

### 话题不通

```bash
# 检查话题列表
ros2 topic list

# 查看话题类型
ros2 topic type /chatter

# 手动发布测试
ros2 topic pub /chatter std_msgs/msg/String "data: test"

# 查看实时数据
ros2 topic echo /chatter

# 诊断工具
ros2 daemon start
ros2 doctor --report
```

---

## 命令行工具

```bash
# 查看当前 RMW
ros2 pkg list | grep rmw

# 查看话题通讯
ros2 topic hz /chatter
ros2 topic bw /chatter

# 网络诊断
ros2 network_scanner

# 启用日志调试
export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}] [{name}]: {message}"
export RCUTILS_LOGGING_BUFFER_OUTPUT_STRING=0

# RMW 调试
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export FASTRTPS_DEFAULT_PROFILE=file://fastrtps_debug.xml
```

---

## 最佳实践

1. **统一域 ID**: 多机器使用相同 ROS_DOMAIN_ID
2. **QoS 匹配**: 确保发布/订阅 QoS 兼容
3. **网络优化**: 使用有线网络，低延迟关键数据
4. **监控**: 定期检查话题带宽和延迟
5. **隔离**: 不同系统使用不同域 ID