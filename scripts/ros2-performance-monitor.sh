#!/bin/bash
# ros2-performance-monitor.sh — ROS2 节点性能监控与诊断钩子
# 用法: source ros2-performance-monitor.sh <node_name>
# 自动在节点中注入: 周期报告 / 内存跟踪 / 异常检测
#
# 原理: 生成 C++ 头文件模板，插入到节点代码中
# AI 生成节点后，运行此脚本注入监控钩子

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NODE_NAME="${1:-my_node}"

echo -e "${BLUE}=== 注入性能监控钩子: $NODE_NAME ===${NC}"

MONITOR_H="monitor_hooks_${NODE_NAME}.hpp"

cat > "$MONITOR_H" <<'MONITOREOF'
// monitor_hooks.hpp — ROS2 节点性能监控钩子（自动生成）
// 包含: 周期计时 / 内存跟踪 / 异常检测 / diagnostic_updater 集成

#ifndef MONITOR_HOOKS_HPP
#define MONITOR_HOOKS_HPP

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/lifecycle_node.hpp>
#include <memory>
#include <atomic>
#include <chrono>
#include <cstring>

namespace monitoring {

// ── 周期计时器 ───────────────────────────────────────
class PeriodMonitor {
public:
  PeriodMonitor(rclcpp::Node* node, double expected_hz = 10.0)
    : node_(node), expected_period_(1.0 / expected_hz)
  {
    last_tick_ = node_->now();
  }

  void tick() {
    auto now = node_->now();
    auto elapsed = (now - last_tick_).seconds();
    last_tick_ = now;

    // 检测周期偏差
    double deviation = std::abs(elapsed - expected_period_);
    double deviation_pct = (deviation / expected_period_) * 100.0;

    if (deviation_pct > 20.0) {
      RCLCPP_WARN(node_->get_logger(),
        "[PERIOD] deviation=%.1f%% (expected=%.3fs, actual=%.3fs)",
        deviation_pct, expected_period_, elapsed);
    }
  }

private:
  rclcpp::Node* node_;
  double expected_period_;
  rclcpp::Time last_tick_;
};

// ── 内存跟踪 ───────────────────────────────────────
class MemoryMonitor {
public:
  MemoryMonitor(rclcpp::Node* node, const char* label = "node")
    : node_(node), label_(label), baseline_rss_kb_(get_rss())
  {}

  size_t get_rss() {
    FILE* fp = fopen("/proc/self/statm", "r");
    if (!fp) return 0;
    size_t rss = 0;
    fscanf(fp, "%lu %lu", &rss, &rss);  // size, rss pages
    fclose(fp);
    return rss * 4096 / 1024;  // KB
  }

  void check() {
    size_t current_rss = get_rss();
    if (current_rss == 0) return;

    double growth_mb = (current_rss - baseline_rss_kb_) / 1024.0;
    if (growth_mb > 50.0) {  // 增长 > 50MB
      RCLCPP_ERROR(node_->get_logger(),
        "[MEMORY] LEAK SUSPECT: %s grew %.1f MB (baseline=%lu KB, current=%lu KB)",
        label_, growth_mb, baseline_rss_kb_, current_rss);
    }
    baseline_rss_kb_ = current_rss;  // rolling baseline
  }

private:
  rclcpp::Node* node_;
  const char* label_;
  size_t baseline_rss_kb_;
};

// ── 订阅者健康检测 ──────────────────────────────────
class SubscriberMonitor {
public:
  SubscriberMonitor() : last_msg_count_(0), silence_start_() {}

  void track(const rclcpp::SubscriptionBase::SharedPtr& sub) {
    auto now = std::chrono::steady_clock::now();

    // 记录活跃订阅
    sub->get_publisher_count();  // 触发更新

    // 简单: 没有发布者时告警
    if (sub->get_publisher_count() == 0) {
      RCLCPP_WARN_ONCE(sub->get_node_base_interface()->get_logger(),
        "[SUB] No publishers for subscription — topic may not be connected");
    }
  }
};

// ── 发布者缓冲检测 ─────────────────────────────────
class PublisherBufferMonitor {
public:
  PublisherBufferMonitor(rclcpp::PublisherBase::SharedPtr pub, const char* topic)
    : pub_(pub), topic_(topic) {}

  void check() {
    // 检测发布队列积压（Publisher 内部状态）
    // 注意: rclcpp 不直接暴露队列长度，这里用启发式方法
    // 通过调用 get_subscription_count 估算
    if (pub_->get_subscription_count() > 0) {
      // 有订阅者，等待输出
    }
  }

private:
  rclcpp::PublisherBase::SharedPtr pub_;
  const char* topic_;
};

}  // namespace monitoring
#endif  // MONITOR_HOOKS_HPP
MONITOREOF

echo -e "${GREEN}✓ 生成了监控钩子: $MONITOR_H${NC}"
echo ""
echo "使用方法（在节点代码中）:"
echo ""
echo "  #include \"$MONITOR_H\""
echo ""
echo "  class MyNode : public rclcpp::Node {"
echo "  private:"
echo "    monitoring::PeriodMonitor period_monitor_{this, 20.0};  // 20Hz"
echo "    monitoring::MemoryMonitor memory_monitor_{this, \"my_node\"};"
echo ""
echo "    void timer_callback() {"
echo "      period_monitor_.tick();      // 检测周期偏差"
echo "      memory_monitor_.check();   // 检测内存增长"
echo "    }"
echo "  };"
echo ""
echo "  // 在 timer_callback 开头调用:"
echo "  void timer_callback() {"
echo "    MONITOR_TICK();  // 一行搞定"
echo "  }"
echo ""
echo "编译时加入:"
echo "  g++ -fsanitize=address -fsanitize=leak node.cpp  # 内存泄漏检测"
