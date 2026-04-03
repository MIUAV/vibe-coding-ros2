---
name: cross-machine-communication
description: 跨机器通信技能 - 网络配置、Discovery 加速、安全通信
argument-hint: "跨机器" / "网络" / "discovery" / "security" / "cross machine"
user-invocable: true
---

# 跨机器通信技能

> ROS2 跨机器通信配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 网络配置
- Discovery 加速
- 安全通信 (SROS2)
- NAT 穿越
- 带宽优化

---

## 核心实现

### 网络配置

```bash
# 机器 A (主机)
export ROS_DOMAIN_ID=42
export ROS_IP=192.168.1.100
export ROS_HOSTNAME=robot-a.local

# 机器 B (从机)
export ROS_DOMAIN_ID=42
export ROS_IP=192.168.1.101
export ROS_HOSTNAME=robot-b.local

# 测试连接
ping robot-a.local
ros2 topic list  # 应该能看到远程话题
```

### Discovery 加速

```python
# fast_discovery.py
from rclpy.node import Node

class FastDiscoveryNode(Node):
    def __init__(self):
        super().__init__('fast_discovery')
        
        # 减少 discovery 时间
        self.declare_parameter('fast_discovery', True)
        
        if self.get_parameter('fast_discovery').value:
            # 设置 DDS 快速发现
            self.set_parameters([
                rclpy.parameter.Parameter(
                    'enclave', '/robot/controller'
                )
            ])
```

### SROS2 安全通信

```bash
# 1. 创建安全文件夹
mkdir -p security_store

# 2. 创建权限文件
cat > security_store/permissions.xml << EOF
<permissions>
  <grant name="robot_grant">
    <subject_name>CN=robot</subject_name>
    <validity>
      <not_before>2024-01-01T00:00:00</not_before>
      <not_after>2029-12-31T23:59:59</not_after>
    </validity>
    <allow_rule>
      <actions>
        <action>READ</action>
        <action>WRITE</action>
      </actions>
      <topics>
        <topic>*/cmd_vel</topic>
        <topic>*/odom</topic>
      </topics>
    </allow_rule>
  </grant>
</permissions>
EOF

# 3. 启动带安全的节点
ros2 run demo_nodes_cpp talker --ros-args \
  --enclaves /robot/controller \
  --params-file security_store/permissions.yaml
```

### Discovery 服务器

```xml
<!-- fastrtps_discovery_server.xml -->
<?xml version="1.0"?>
<staticdiscovery>
  <participant>
    <name>discovery_server</name>
    <ID>0</ID>
    <externalunicastlocator address="192.168.1.100" port="53400"/>
  </participant>
</staticdiscovery>
```

```bash
# 启动 Discovery 服务器
ros2 run fastrtps_cmake_integration fastrtps_discovery_server -i 0

# 客户端配置
export FASTRTPS_DEFAULT_PROFILES_FILE=discovery_server.xml
```
