#!/bin/bash
# ros2-rl-controller-generator.sh — ROS2 强化学习控制器生成器
# 用法: bash ros2-rl-controller-generator.sh <pkg_name> [rl_type]
# rl_type: ddpg | ppo | sac | td3
#
# 示例: bash ros2-rl-controller-generator.sh rl_dog ddpg

PKG_NAME="${1:-}"
RL_TYPE="${2:-ddpg}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [RL算法]"
    echo "  ddpg — Deep Deterministic Policy Gradient（连续控制）"
    echo "  ppo  — Proximal Policy Optimization（连续/离散）"
    echo "  sac  — Soft Actor-Critic（最大熵 RL）"
    echo "  td3  — Twin Delayed DDPG（双 Critic）"
    exit 1
fi

mkdir -p "$PKG_NAME/src" "$PKG_NAME/scripts" "$PKG_NAME/models" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Deep Reinforcement Learning controller for ROS2</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>nav_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>std_msgs</depend>
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ── CMakeLists.txt ────────────────────────────────────────
cat > "$PKG_NAME/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(PKGNAME)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/rl_controller.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp nav_msgs geometry_msgs
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION lib)
install(DIRECTORY scripts models launch config DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()
ament_package()
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/CMakeLists.txt"

# ════════════════════════════════════════════════════════════
# C++ RL Controller 节点
# ════════════════════════════════════════════════════════════

cat > "$PKG_NAME/src/rl_controller.cpp" <<'CPPEOF'
// rl_controller — ROS2 强化学习控制器节点
// 架构：
//   1. 接收传感器观测 (observation)
//   2. 输入 RL 推理模块（Python sidecar 或 C++ ONNX）
//   3. 输出动作到 /cmd_vel 或关节控制器
// 支持：模拟（Gazebo）或真机

#include <memory>
#include <vector>
#include <cmath>
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>
#include <std_msgs/msg/float32_multi_array.hpp>

using CallbackReturn = rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn;

class RLControllerNode : public rclcpp_lifecycle::LifecycleNode
{
public:
  RLControllerNode()
  : LifecycleNode("rl_controller")
  {
    // ── 参数声明 ─────────────────────────────────────
    this->declare_parameter("algorithm", "ddpg");
    this->declare_parameter("model_path", "models/policy.onnx");
    this->declare_parameter("action_topic", "/cmd_vel");
    this->declare_parameter("observation_topics",
      std::vector<std::string>{"/odom", "/scan"});
    this->declare_parameter("max_linear_vel", 0.5);    // m/s
    this->declare_parameter("max_angular_vel", 1.0);  // rad/s
    this->declare_parameter("inference_mode", "onnx");  // onnx / python / mock
    this->declare_parameter("python_inference_script",
      "scripts/inference_server.py");

    this->get_parameter("algorithm", algorithm_);
    this->get_parameter("action_topic", action_topic_);

    RCLCPP_INFO(this->get_logger(), "RL Controller (%s) initialized", algorithm_.c_str());
  }

  // ── on_configure: 订阅观测，发布动作 ────────────
  CallbackReturn on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[RL] Configuring...");

    // 观测订阅
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
      "/odom", 10,
      [this](nav_msgs::msg::Odometry::SharedPtr msg) {
        odom_buf_ = *msg;
        odom_fresh_ = true;
      });

    scan_sub_ = this->subscribe<sensor_msgs::msg::LaserScan>(
      "/scan", 10,
      [this](sensor_msgs::msg::LaserScan::SharedPtr msg) {
        scan_buf_ = *msg;
        scan_fresh_ = true;
      });

    // 动作发布
    action_pub_ = this->create_publisher<geometry_msgs::msg::Twist>(action_topic_, 10);

    // 推理服务客户端（Python sidecar 通信）
    if (inference_mode_ == "python") {
      inference_client_ = this->create_client<std_srvs::srv::Trigger>(
        "/rl_inference");
    }

    RCLCPP_INFO(get_logger(), "[RL] Configured — action_topic=%s", action_topic_.c_str());
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[RL] Activating...");
    action_pub_->on_activate();
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[RL] Deactivating...");
    action_pub_->on_deactivate();
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_cleanup(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[RL] Cleaning up...");
    odom_sub_.reset();
    scan_sub_.reset();
    action_pub_.reset();
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_shutdown(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[RL] Shutting down...");
    return CallbackReturn::SUCCESS;
  }

  // ── 推理 ───────────────────────────────────────────
  geometry_msgs::msg::Twist compute_action()
  {
    geometry_msgs::msg::Twist action;

    if (inference_mode_ == "mock") {
      // Mock：随机动作（测试用）
      action.linear.x = max_linear_vel_ * (2.0 * (rand() / RAND_MAX) - 1.0);
      action.angular.z = max_angular_vel_ * (2.0 * (rand() / RAND_MAX) - 1.0);
      return action;
    }

    if (inference_mode_ == "onnx") {
      // ONNX Runtime 推理（需 linking onnxruntime）
      return inference_onnx();
    }

    if (inference_mode_ == "python") {
      // Python sidecar RPC
      return inference_python();
    }

    return action;
  }

  geometry_msgs::msg::Twist inference_onnx()
  {
    // TODO: ONNX Runtime C++ API
    // std::vector<float> obs = build_observation();
    // auto output = session_->Run(Ort::RunOptions{}, "actions", &obs);
    geometry_msgs::msg::Twist action;
    action.linear.x = 0.3;
    action.angular.z = 0.1;
    return action;
  }

  geometry_msgs::msg::Twist inference_python()
  {
    geometry_msgs::msg::Twist action;
    // 请求 Python 推理服务
    // auto req = std::make_shared<std_srvs::srv::Trigger::Request>();
    // auto future = inference_client_->async_send_request(req);
    // action = future.get()->response;  // 简化
    action.linear.x = 0.3;
    action.angular.z = 0.1;
    return action;
  }

  // ── 观测构建 ────────────────────────────────────────
  std::vector<float> build_observation()
  {
    std::vector<float> obs;

    if (odom_fresh_) {
      // 位置 + 速度
      obs.push_back(odom_buf_.pose.pose.position.x);
      obs.push_back(odom_buf_.pose.pose.position.y);
      obs.push_back(odom_buf_.twist.twist.linear.x);
      obs.push_back(odom_buf_.twist.twist.angular.z);
      odom_fresh_ = false;
    }

    if (scan_fresh_) {
      // 激光扫描（降采样到 32 beams）
      int step = std::max(1, (int)(scan_buf_.ranges.size() / 32));
      for (size_t i = 0; i < scan_buf_.ranges.size(); i += step) {
        float r = scan_buf_.ranges[i];
        if (std::isinf(r) || std::isnan(r)) r = scan_buf_.range_max;
        obs.push_back(r);
      }
      scan_fresh_ = false;
    }

    return obs;
  }

private:
  std::string algorithm_;
  std::string action_topic_;
  std::string inference_mode_;
  std::string model_path_;
  double max_linear_vel_ = 0.5;
  double max_angular_vel_ = 1.0;

  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr scan_sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr action_pub_;
  rclcpp::Client<std_srvs::srv::Trigger>::SharedPtr inference_client_;

  nav_msgs::msg::Odometry odom_buf_;
  sensor_msgs::msg::LaserScan scan_buf_;
  bool odom_fresh_ = false, scan_fresh_ = false;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<RLControllerNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ── Python 推理服务器（sidecar）───────────────────────────
cat > "$PKG_NAME/scripts/inference_server.py" <<'PYEOF'
#!/usr/bin/env python3
"""
RL Inference Server — Python sidecar for RL controller
Receives observation via ROS2 service, returns action
Supports: Stable-Baselines3 models, ONNX exported models
"""
import rclpy
from rclpy.node import Node
from std_srvs.srv import Trigger
import numpy as np

# 实际使用时导入 stable_baselines3 或 onnxruntime
# from stable_baselines3 import DDPG, PPO, SAC


class RLInferenceNode(Node):
    def __init__(self):
        super().__init__('rl_inference_server')
        self.declare_parameter('model_path', 'models/policy.onnx')
        self.declare_parameter('algorithm', 'ddpg')
        self.model = None
        self.load_model()
        self.srv = self.create_service(Trigger, '/rl_inference', self.inference_callback)
        self.get_logger().info('RL Inference server ready')

    def load_model(self):
        # TODO: load Stable-Baselines3 or ONNX model
        # self.model = DDPG.load(self.get_parameter("model_path").value)
        self.get_logger().info('Model loaded (mock mode)')

    def inference_callback(self, request, response):
        # TODO: decode observation from request
        # obs = np.array([...])  # from request
        # action, _states = self.model.predict(obs)
        # response.message = action.tolist()
        response.success = True
        response.message = '[0.3, 0.1]'  # mock action
        return response


def main(args=None):
    rclpy.init(args=args)
    node = RLInferenceNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

# ── RL Training 脚本 ─────────────────────────────────────
cat > "$PKG_NAME/scripts/train.py" <<'PYEOF'
#!/usr/bin/env python3
"""
RL Training Script — 训练强化学习策略
用法: python3 train.py --algo ddpg --env IsaacGym-Env-v0
"""
import argparse
import gym
import numpy as np
from stable_baselines3 import DDPG, PPO, SAC, TD3
from stable_baselines3.common.noise import NormalActionNoise


def train(env_id, algo, total_timesteps=100000):
    env = gym.make(env_id)

    if algo == 'ddpg':
        model = DDPG('MlpPolicy', env, verbose=1)
    elif algo == 'ppo':
        model = PPO('MlpPolicy', env, verbose=1)
    elif algo == 'sac':
        model = SAC('MlpPolicy', env, verbose=1)
    elif algo == 'td3':
        model = TD3('MlpPolicy', env, verbose=1)
    else:
        raise ValueError(f"Unknown algo: {algo}")

    model.learn(total_timesteps=total_timesteps)
    model.save(f'models/{algo}_{env_id}')
    print(f'Model saved: models/{algo}_{env_id}')
    return model


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--algo', default='ddpg',
                        choices=['ddpg', 'ppo', 'sac', 'td3'])
    parser.add_argument('--env', default='HalfCheetah-v4')
    parser.add_argument('--steps', type=int, default=100000)
    args = parser.parse_args()
    train(args.env, args.algo, args.steps)
PYEOF

# ── config ────────────────────────────────────────────────
cat > "$PKG_NAME/config/rl_params.yaml" <<'YAMLEOF'
/rl_controller:
  ros__parameters:
    algorithm: ddpg
    model_path: "models/policy.onnx"
    inference_mode: mock   # mock / onnx / python
    action_topic: "/cmd_vel"
    max_linear_vel: 0.5
    max_angular_vel: 1.0
    observation_topics:
      - "/odom"
      - "/scan"
YAMLEOF

# ── launch ────────────────────────────────────────────────
cat > "$PKG_NAME/launch/rl.launch.py" <<'LAUNCHEOF'
"""RL Controller launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        # Python inference sidecar (if using python mode)
        Node(package='PKGNAME',
             executable='scripts/inference_server.py',
             name='rl_inference_server',
             output='screen'),
        # C++ RL controller
        Node(package='PKGNAME',
             executable='rl_controller',
             name='rl_controller',
             output='screen',
             parameters=['config/rl_params.yaml']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/rl.launch.py"

# ── Model export script ───────────────────────────────────
cat > "$PKG_NAME/scripts/export_onnx.py" <<'PYEOF'
#!/usr/bin/env python3
"""
Export Stable-Baselines3 model to ONNX for C++ inference
Usage: python3 export_onnx.py --algo ddpg --env Humanoid-v4
"""
import argparse
import numpy as np
# from stable_baselines3 import DDPG, PPO, SAC, TD3
# import torch


def export_to_onnx(algo_name, env_id, output_path):
    # Load model
    # model = DDPG.load(f'models/{algo_name}_{env_id}')

    # Export to ONNX
    # Example for Stable-Baselines3:
    # obs = np.zeros((1, model.observation_space.shape[0]), dtype=np.float32)
    # torch.onnx.export(
    #     model.policy,
    #     torch.from_numpy(obs),
    #     output_path,
    #     input_names=['observation'],
    #     output_names=['action'],
    #     dynamic_axes={'observation': {0: 'batch'}, 'action': {0: 'batch'}}
    # )
    print(f'Would export {algo_name} to {output_path}')
    print('Requires: stable-baselines3, torch, onnxruntime')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--algo', default='ddpg')
    parser.add_argument('--env', default='Humanoid-v4')
    parser.add_argument('--output', default='models/policy.onnx')
    args = parser.parse_args()
    export_to_onnx(args.algo, args.env, args.output)
PYEOF

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/rl_controller.cpp"
echo "  scripts/inference_server.py"
echo "  scripts/train.py"
echo "  scripts/export_onnx.py"
echo "  config/rl_params.yaml"
echo "  launch/rl.launch.py"
echo ""
echo "Algorithm: $RL_TYPE"
echo ""
echo "Dependencies to install:"
echo "  pip install stable-baselines3 gym torch onnxruntime onnx"
echo ""
echo "Next steps:"
echo "  1. Train: python3 scripts/train.py --algo $RL_TYPE --env YourEnv-v0"
echo "  2. Export: python3 scripts/export_onnx.py --algo $RL_TYPE --output models/policy.onnx"
echo "  3. Build: colcon build --packages-select $PKG_NAME"
echo "  4. Run:   ros2 launch $PKG_NAME rl.launch.py"
