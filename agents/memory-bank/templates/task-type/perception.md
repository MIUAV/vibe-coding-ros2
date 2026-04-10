# Perception Task Context

## 感知流水线
```
传感器原始数据 → 预处理 → 特征提取 → 感知算法 → 输出
     ↓
camera/radar/lidar → 去噪/同步 → 分割/检测 → 目标跟踪/定位
```

## 感知算法速查
| 任务 | 算法 | ROS2 包 |
|------|------|---------|
| 2D 目标检测 | YOLO v5/v8 | `yolov8_ros`, `ros2_yolov8` |
| 3D 目标检测 | PointPillars / PointNet++ | `ros2_pointpillars` |
| 语义分割 | DeepLabV3 / UNet | `deeplab_ros` |
| 深度估计 | Monodepth2 / MiDaS | `depthai_ros` |
| 激光雷达检测 | Euclidean Cluster | `pointcloud_to_laserscan` |
| 传感器融合 | Autoware FF | `autoware_sensing` |

## 点云处理（PCL）
```cpp
#include <pcl/point_types.h>
#include <pcl/filters/voxel_grid.h>
#include <pcl/segmentation/extract_clusters.h>

// 降采样
pcl::VoxelGrid<pcl::PointXYZ> vg;
vg.setInputCloud/cloud);
vg.setLeafSize(0.1f, 0.1f, 0.1f);
vg.filter(*filtered);

// 欧式聚类
pcl::EuclideanClusterExtraction<pcl::PointXYZ> ec;
ec.setClusterTolerance(0.5);
ec.setMinClusterSize(10);
ec.setMaxClusterSize(250);
ec.extract(cloud_clusters);
```

## 图像处理（OpenCV + cv_bridge）
```cpp
#include <cv_bridge/cv_bridge.h>
#include <opencv4/opencv2/dnn.hpp>

// ROS2 → OpenCV
auto cv_img = cv_bridge::toCvCopy(msg, "bgr8");

// DNN 推理
cv::dnn::Net net = cv::dnn::readNet("/model.onnx");
net.setInput(blob);
cv::Mat outputs = net.forward();

// NMS 后处理
std::vector<int> indices;
cv::dnn::NMSBoxes(boxes, scores, 0.5f, 0.4f, indices);
```

## 推理加速平台
| 平台 | 框架 | 说明 |
|------|------|------|
| NVIDIA Jetson | TensorRT | INT8 量化 |
| Intel NUC | OpenVINO | FP16/FP32 |
| RK3588 | RKNN | INT8 量化 |
| 通用 | ONNX Runtime | 跨平台 |

## 传感器时间同步
```cpp
#include <message_filters/subscriber.h>
#include <message_filters/synchronizer.h>
#include <message_filters/sync_policies/approximate_time.h>

using SyncPolicy = message_filters::sync_policies::ApproximateTime<Image, PointCloud2>;
message_filters::Synchronizer<SyncPolicy> sync(SyncPolicy(10), img_sub, pc_sub);
sync.registerCallback(&callback);
```
