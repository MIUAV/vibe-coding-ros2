#!/usr/bin/env python3
"""
py_subscriber — ROS2 Python 订阅者节点示例

功能: 订阅 /chatter 话题并打印消息

对应规范 (ANTI_PATTERNS.md):
  ✅ rclpy.init() / rclpy.shutdown() 完整生命周期
  ✅ 使用 try/finally 保证 shutdown
  ✅ 回调中不能有阻塞操作
  ✅ QoS 说明注释
  ✅ if __name__ == '__main__' 保护

编译: colcon build --packages-select py_subscriber --symlink-install
运行: ros2 run py_subscriber py_subscriber
"""

import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class MinimalSubscriber(Node):
    """订阅者节点类"""

    def __init__(self) -> None:
        # ── 1. 节点名 ──────────────────────────────
        super().__init__('py_subscriber')

        # ── 2. 创建订阅者 ──────────────────────────
        # QoS: reliable + depth=10（与发布者匹配才能通信）
        # 如果发布者用 best_effort，订阅者也必须用 best_effort
        # 否则静默通信失败（不报错但收不到数据）
        self.sub = self.create_subscription(
            String,
            '/chatter',
            self.subscriber_callback,
            10  # QoS depth
        )

        self.get_logger().info('Subscriber started, listening on /chatter')

    def subscriber_callback(self, msg: String) -> None:
        """
        回调函数 — 必须轻量，不能有阻塞操作
        🚫 禁止: time.sleep() / 耗时计算 / 同步 I/O
        ✅ 正确: 仅处理消息，立即返回
        """
        self.get_logger().info(f'Heard: "{msg.data}"')


def main(args=None):
    """主入口 — 必须有 rclpy.shutdown() 保证清理"""

    # ── 初始化 ───────────────────────────────────
    rclpy.init(args=args)

    try:
        # ── spin node ─────────────────────────────
        subscriber = MinimalSubscriber()

        # spin_until_future_complete: 阻塞直到节点被 shutdown
        rclpy.spin(subscriber)

    finally:
        # ── 必须保证 shutdown ──────────────────────
        # 🚫 禁止: 不调用 rclpy.shutdown()
        # 导致: 节点无法正常退出，资源泄漏
        rclpy.shutdown()


if __name__ == '__main__':
    main()
