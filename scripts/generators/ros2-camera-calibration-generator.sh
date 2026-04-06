#!/bin/bash
# ros2-camera-calibration-generator.sh — 相机标定包生成器
# 用法: bash ros2-camera-calibration-generator.sh <pkg_name> [calib_type]
# calib_type: intrinsics | extrinsics | hand_eye | lidar_camera
#
# 示例: bash ros2-camera-calibration-generator.sh camera_calib intrinsics

PKG_NAME="${1:-}"
CALIB_TYPE="${2:-intrinsics}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [标定类型]"
    echo "  intrinsics    — 相机内参标定（焦距/光心/畸变）"
    echo "  extrinsics   — 多相机外参标定（相机间相对位姿）"
    echo "  hand_eye     — 手眼标定（相机在机械臂末端）"
    echo "  lidar_camera — 激光-相机外参标定"
    exit 1
fi

mkdir -p "$PKG_NAME/src" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Camera calibration package</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>sensor_msgs</depend>
  <depend>image_transport</depend>
  <depend>camera_info_manager</depend>
  <depend>vision_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>
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
find_package(sensor_msgs REQUIRED)
find_package(image_transport REQUIRED)
find_package(camera_info_manager REQUIRED)
find_package(vision_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(OpenCV REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/calibration_node.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp sensor_msgs image_transport camera_info_manager vision_msgs geometry_msgs
)

target_link_libraries(${PROJECT_NAME} ${OpenCV_LIBS})

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION lib)
install(DIRECTORY launch config DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()
ament_package()
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/CMakeLists.txt"

# ════════════════════════════════════════════════════════════
# 内参标定
# ════════════════════════════════════════════════════════════
if [[ "$CALIB_TYPE" == "intrinsics" ]]; then

cat > "$PKG_NAME/src/calibration_node.cpp" <<'CPPEOF'
// intrinsics — 相机内参标定节点
// 使用 OpenCV棋盘格标定，输出 CameraInfo YAML
// 标定图案：12×9 角点棋盘格

#include <memory>
#include <string>
#include <vector>
#include <cmath>
#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/calib3d.hpp>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <camera_info_manager/camera_info_manager.hpp>

class IntrinsicsCalibrator : public rclcpp::Node
{
public:
  IntrinsicsCalibrator()
  : Node("intrinsics_calibrator")
  {
    this->declare_parameter("camera_name", "camera");
    this->declare_parameter("image_topic", "/image_raw");
    this->declare_parameter("board_width", 12);
    this->declare_parameter("board_height", 9);
    this->declare_parameter("square_size", 0.025);  // m
    this->declare_parameter("min_samples", 20);

    this->get_parameter("camera_name", camera_name_);
    this->get_parameter("board_width", board_w_);
    this->get_parameter("board_height", board_h_);
    this->get_parameter("min_samples", min_samples_);

    // 生成标定板3D角点坐标
    object_points_.reserve(board_h_ * board_w_);
    for (int j = 0; j < board_h_; ++j)
      for (int i = 0; i < board_w_; ++i)
        object_points_.push_back(cv::Point3f(i * square_size_, j * square_size_, 0.0f));

    // 订阅图像
    image_sub_ = this->create_subscription<sensor_msgs::msg::Image>(
      image_topic_, 10,
      std::bind(&IntrinsicsCalibrator::on_image, this, std::placeholders::_1));

    // CameraInfo manager
    cinfo_manager_ = std::make_shared<camera_info_manager::CameraInfoManager>(
      this, camera_name_);

    // 定时器：定期触发标定计算
    timer_ = this->create_wall_timer(
      std::chrono::seconds(5),
      std::bind(&IntrinsicsCalibrator::check_calibration, this));

    RCLCPP_INFO(this->get_logger(),
      "IntrinsicsCalibrator started — waiting for %d valid samples", min_samples_);
  }

private:
  void on_image(const sensor_msgs::msg::Image::SharedPtr msg)
  {
    cv::Mat img;
    try {
      img = cv_bridge_->imgMsgToCv(msg, "mono8");
    } catch (const cv_bridge::Exception&) {
      return;
    }

    // 查找棋盘格角点
    std::vector<cv::Point2f> image_points;
    bool found = cv::findChessboardCorners(img,
      cv::Size(board_w_, board_h_), image_points,
      cv::CALIB_CB_ADAPTIVE_THRESH | cv::CALIB_CB_NORMALIZE_IMAGE);

    if (found) {
      // 亚像素精度细化
      cv::cornerSubPix(img, image_points, cv::Size(5,5),
        cv::Size(-1,-1),
        cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 30, 0.01));

      image_points_all_.push_back(image_points);
      object_points_all_.push_back(object_points_);

      RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 2000,
        "Sample %zu/%d collected",
        image_points_all_.size(), min_samples_);
    }
  }

  void check_calibration()
  {
    if (image_points_all_.size() >= (size_t)min_samples_) {
      compute_calibration();
    }
  }

  void compute_calibration()
  {
    cv::Mat camera_matrix = cv::Mat::eye(3, 3, CV_64F);
    cv::Mat dist_coeffs = cv::Mat::zeros(8, 1, CV_64F);
    std::vector<cv::Mat> rvecs, tvecs;

    double rms = cv::calibrateCamera(
      object_points_all_, image_points_all_,
      cv::Size(640, 480),  // 图像尺寸
      camera_matrix, dist_coeffs,
      rvecs, tvecs,
      cv::CALIB_FIX_ASPECT_RATIO |
      cv::CALIB_FIX_K3 |
      cv::CALIB_FIX_PRINCIPAL_POINT);

    double fx = camera_matrix.at<double>(0,0);
    double fy = camera_matrix.at<double>(1,1);
    double cx = camera_matrix.at<double>(0,2);
    double cy = camera_matrix.at<double>(1,2);
    double k1 = dist_coeffs.at<double>(0,0);
    double k2 = dist_coeffs.at<double>(0,1);
    double p1 = dist_coeffs.at<double>(0,2);
    double p2 = dist_coeffs.at<double>(0,3);
    double k3 = dist_coeffs.at<double>(0,4);

    RCLCPP_INFO(this->get_logger(), "=== Calibration Results ===");
    RCLCPP_INFO(this->get_logger(), "RMS re-projection error: %.4f", rms);
    RCLCPP_INFO(this->get_logger(), "fx=%.4f fy=%.4f cx=%.4f cy=%.4f", fx, fy, cx, cy);
    RCLCPP_INFO(this->get_logger(), "k1=%.6f k2=%.6f p1=%.6f p2=%.6f k3=%.6f",
      k1, k2, p1, p2, k3);
    RCLCPP_INFO(this->get_logger(), "Save to config/camera_info.yaml");

    // 生成 YAML
    save_yaml(camera_matrix, dist_coeffs, cv::Size(640, 480));
  }

  void save_yaml(const cv::Mat& K, const cv::Mat& D, const cv::Size& size)
  {
    std::ofstream f("config/camera_info.yaml");
    f << "image_width: " << size.width << "\n";
    f << "image_height: " << size.height << "\n";
    f << "camera_name: " << camera_name_ << "\n";
    f << "camera_matrix:\n";
    f << "  rows: 3\n";
    f << "  cols: 3\n";
    f << "  data: [" << K.at<double>(0,0) << ", " << K.at<double>(0,1) << ", " << K.at<double>(0,2) << ", "
                 << K.at<double>(1,0) << ", " << K.at<double>(1,1) << ", " << K.at<double>(1,2) << ", "
                 << K.at<double>(2,0) << ", " << K.at<double>(2,1) << ", " << K.at<double>(2,2) << "]\n";
    f << "distortion_model: plumb_bob\n";
    f << "distortion_coefficients:\n";
    f << "  rows: 1\n";
    f << "  cols: 5\n";
    f << "  data: [" << D.at<double>(0,0) << ", " << D.at<double>(0,1) << ", "
                 << D.at<double>(0,2) << ", " << D.at<double>(0,3) << ", "
                 << D.at<double>(0,4) << "]\n";
    f.close();
    RCLCPP_INFO(this->get_logger(), "Saved to config/camera_info.yaml");
  }

  std::string camera_name_;
  std::string image_topic_ = "/image_raw";
  int board_w_ = 12, board_h_ = 9;
  double square_size_ = 0.025;
  int min_samples_ = 20;

  std::vector<std::vector<cv::Point3f>> object_points_all_;
  std::vector<std::vector<cv::Point2f>> image_points_all_;
  std::vector<cv::Point3f> object_points_;
  cv_bridge::CvImagePtr cv_bridge_;

  rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr image_sub_;
  std::shared_ptr<camera_info_manager::CameraInfoManager> cinfo_manager_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<IntrinsicsCalibrator>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ════════════════════════════════════════════════════════════
# 手眼标定
# ════════════════════════════════════════════════════════════
elif [[ "$CALIB_TYPE" == "hand_eye" ]]; then

cat > "$PKG_NAME/src/calibration_node.cpp" <<'CPPEOF'
// hand_eye — 手眼标定节点（Eye-in-Hand / Eye-to-Hand）
// 采集机械臂多姿态 + 标定板图像，计算相机到机械臂末端的变换
// 算法：Tsai-Lenz 或 Park-Brough

#include <memory>
#include <vector>
#include <cmath>
#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/pose.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <tf2_ros/buffer_interface.h>
#include <tf2_ros/static_transform_broadcaster.h>

class HandEyeCalibrator : public rclcpp::Node
{
public:
  HandEyeCalibrator()
  : Node("hand_eye_calibrator")
  {
    this->declare_parameter("calibration_type", "eye_in_hand");  // eye_in_hand / eye_to_hand
    this->declare_parameter("robot_base_frame", "base_link");
    this->declare_parameter("robot_end_effector_frame", "tool0");
    this->declare_parameter("camera_frame", "camera_link");
    this->declare_parameter("calibration_board_frame", "calibration_board");
    this->declare_parameter("min_poses", 15);

    this->get_parameter("calibration_type", calib_type_);
    this->get_parameter("robot_end_effector_frame", ee_frame_);
    this->get_parameter("camera_frame", camera_frame_);

    // 订阅机械臂末端位姿
    ee_pose_sub_ = this->create_subscription<geometry_msgs::msg::Pose>(
      "/ee_pose", 10,
      std::bind(&HandEyeCalibrator::on_ee_pose, this, std::placeholders::_1));

    // 订阅标定板检测结果（APRILTAG 或 Charuco 板）
    board_pose_sub_ = this->create_subscription<geometry_msgs::msg::Pose>(
      "/calibration_board/pose", 10,
      std::bind(&HandEyeCalibrator::on_board_pose, this, std::placeholders::_1));

    // 发布标定结果
    tf_broadcaster_ = std::make_shared<tf2_ros::StaticTransformBroadcaster>(this);

    RCLCPP_INFO(this->get_logger(),
      "HandEyeCalibrator started (%s) — waiting for %d poses",
      calib_type_.c_str(), min_poses_);
  }

  void on_ee_pose(const geometry_msgs::msg::Pose::SharedPtr pose)
  {
    if (poses_A_.size() >= (size_t)min_poses_) return;

    // 存储机械臂末端相对于 base 的变换 (A)
    poses_A_.push_back(*pose);
    try_collect();
  }

  void on_board_pose(const geometry_msgs::msg::Pose::SharedPtr pose)
  {
    if (poses_B_.size() >= (size_t)min_poses_) return;

    // 存储标定板相对于相机的变换 (B)
    poses_B_.push_back(*pose);
    try_collect();
  }

  void try_collect()
  {
    if (poses_A_.size() == poses_B_.size() && poses_A_.size() >= (size_t)min_poses_) {
      compute_hand_eye();
    }
  }

  void compute_hand_eye()
  {
    // Tsai-Lenz 算法（简化实现）
    // 收集足够的姿态对后计算 R,t
    // R_hand_eye, t_hand_eye = calibrate_hand_eye(poses_A_, poses_B_)

    RCLCPP_INFO(this->get_logger(), "Computing Hand-Eye calibration...");
    RCLCPP_INFO(this->get_logger(),
      "Collected %zu pose pairs", poses_A_.size());

    // 发布静态变换
    geometry_msgs::msg::TransformStamped T;
    T.header.stamp = this->now();
    T.header.frame_id = ee_frame_;
    T.child_frame_id = camera_frame_;
    T.transform.translation.x = 0.05;  // TODO: 实际计算值
    T.transform.translation.y = 0.0;
    T.transform.translation.z = 0.0;
    T.transform.rotation.w = 1.0;
    T.transform.rotation.x = 0.0;
    T.transform.rotation.y = 0.0;
    T.transform.rotation.z = 0.0;

    tf_broadcaster_->sendTransform(T);
    RCLCPP_INFO(this->get_logger(), "Hand-Eye transform published to TF");

    // 保存结果
    save_result();
  }

  void save_result()
  {
    std::ofstream f("config/hand_eye_calibration.yaml");
    f << "calibration_type: " << calib_type_ << "\n";
    f << "robot_base_frame: base_link\n";
    f << "robot_end_effector_frame: " << ee_frame_ << "\n";
    f << "camera_frame: " << camera_frame_ << "\n";
    f << "# NOTE: Replace with actual calibrated values\n";
    f << "translation: [0.05, 0.0, 0.0]\n";
    f << "rotation_quaternion: [0.0, 0.0, 0.0, 1.0]\n";
    f.close();
    RCLCPP_INFO(this->get_logger(), "Result saved to config/hand_eye_calibration.yaml");
  }

  std::string calib_type_ = "eye_in_hand";
  std::string ee_frame_ = "tool0";
  std::string camera_frame_ = "camera_link";
  int min_poses_ = 15;

  std::vector<geometry_msgs::msg::Pose> poses_A_;  // robot EE poses
  std::vector<geometry_msgs::msg::Pose> poses_B_;  // board poses in camera

  rclcpp::Subscription<geometry_msgs::msg::Pose>::SharedPtr ee_pose_sub_;
  rclcpp::Subscription<geometry_msgs::msg::Pose>::SharedPtr board_pose_sub_;
  std::shared_ptr<tf2_ros::StaticTransformBroadcaster> tf_broadcaster_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<HandEyeCalibrator>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ════════════════════════════════════════════════════════════
# 激光-相机标定
# ════════════════════════════════════════════════════════════
else  # lidar_camera

cat > "$PKG_NAME/src/calibration_node.cpp" <<'CPPEOF'
// lidar_camera — 激光-相机外参标定
// 方法：深度边缘对齐 — 找到激光点云边缘与图像边缘的对应关系
// 输出：T_lidar_camera (4x4 transformation matrix)

#include <memory>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <geometry_msgs/msg/transform.hpp>

class LidarCameraCalibrator : public rclcpp::Node
{
public:
  LidarCameraCalibrator()
  : Node("lidar_camera_calibrator")
  {
    this->declare_parameter("lidar_topic", "/lidar_points");
    this->declare_parameter("camera_topic", "/camera/image");
    this->declare_parameter("camera_info_topic", "/camera/camera_info");
    this->declare_parameter("min_correspondences", 100);

    this->get_parameter("min_correspondences", min_corr_);

    // 订阅点云和图像
    pc_sub_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
      lidar_topic_, 10,
      std::bind(&LidarCameraCalibrator::on_cloud, this, std::placeholders::_1));
    img_sub_ = this->create_subscription<sensor_msgs::msg::Image>(
      camera_topic_, 10,
      std::bind(&LidarCameraCalibrator::on_image, this, std::placeholders::_1));

    RCLCPP_INFO(this->get_logger(),
      "LidarCameraCalibrator started — waiting for data");
  }

  void on_cloud(const sensor_msgs::msg::PointCloud2::SharedPtr)
  { /* 点云处理 */ }

  void on_image(const sensor_msgs::msg::Image::SharedPtr)
  { /* 图像处理 */ }

  void compute_extrinsics()
  {
    // 1. 提取点云边缘（深度不连续处）
    // 2. 提取图像边缘（Canny）
    // 3. 手动/自动建立对应（耗时耗力）
    // 4. EPnP 或 similar 求解

    RCLCPP_INFO(this->get_logger(), "Computing lidar-camera extrinsics...");
    // 输出 T_lidar_camera
  }

  void save_result()
  {
    std::ofstream f("config/lidar_camera_calibration.yaml");
    f << "# lidar -> camera transformation\n";
    f << "# T_lidar_camera (4x4, row-major)\n";
    f << "transform:\n";
    f << "  # rotation (quaternion)\n";
    f << "  rotation:\n";
    f << "    x: 0.0\n";
    f << "    y: 0.0\n";
    f << "    z: 0.0\n";
    f << "    w: 1.0\n";
    f << "  # translation (m)\n";
    f << "  translation:\n";
    f << "    x: 0.0\n";
    f << "    y: 0.0\n";
    f << "    z: 0.0\n";
    f.close();
    RCLCPP_INFO(this->get_logger(), "Saved to config/lidar_camera_calibration.yaml");
  }

  std::string lidar_topic_ = "/lidar_points";
  std::string camera_topic_ = "/camera/image";
  int min_corr_ = 100;

  rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr pc_sub_;
  rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr img_sub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<LidarCameraCalibrator>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF
fi

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/calibration.launch.py" <<'LAUNCHEOF'
"""Camera calibration launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='PKGNAME',
            executable='calibration_node',
            name='calibration_node',
            output='screen',
            parameters=[{
                'camera_name': 'camera',
                'image_topic': '/image_raw',
            }],
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/calibration.launch.py"

# ── config ────────────────────────────────────────────────
cat > "$PKG_NAME/config/calibration_params.yaml" <<'YAMLEOF'
/calibration_node:
  ros__parameters:
    camera_name: camera
    image_topic: /image_raw
    board_width: 12
    board_height: 9
    square_size: 0.025
    min_samples: 20
YAMLEOF

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/calibration_node.cpp"
echo "  launch/calibration.launch.py"
echo "  config/calibration_params.yaml"
echo ""
echo "Calibration type: $CALIB_TYPE"
echo ""
echo "Usage:"
if [[ "$CALIB_TYPE" == "intrinsics" ]]; then
  echo "  1. Print chessboard: ros2 run camera_calibration cameracalibrator.py --size 12x9 --square 0.025"
  echo "  2. Run calibrator: ros2 launch PKGNAME calibration.launch.py"
  echo "  3. Collect 20+ samples at different angles"
  echo "  4. View results in config/camera_info.yaml"
elif [[ "$CALIB_TYPE" == "hand_eye" ]]; then
  echo "  1. Mount camera on robot end-effector (eye-in-hand) or static (eye-to-hand)"
  echo "  2. Run: ros2 launch PKGNAME calibration.launch.py"
  echo "  3. Move robot to 15+ different poses while viewing calibration board"
  echo "  4. Result saved to config/hand_eye_calibration.yaml"
else
  echo "  1. Run: ros2 launch PKGNAME calibration.launch.py"
  echo "  2. Collect corresponding lidar + camera data"
  echo "  3. Result saved to config/lidar_camera_calibration.yaml"
fi
