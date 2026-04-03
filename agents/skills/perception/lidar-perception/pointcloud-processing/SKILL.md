---
name: pointcloud-processing
description: 点云处理技能 - PCL 滤波、降采样、特征提取、ROS2 PCL 节点开发
argument-hint: "PCL" / "点云处理" / "降采样" / "滤波" / "pointcloud"
user-invocable: true
---

# 点云处理技能

> PCL (Point Cloud Library) 点云处理 ROS2 实现

---

## 何时使用

当需要以下帮助时使用此技能：
- 点云滤波去噪
- 降采样加速
- 特征提取
- 分割与聚类
- ROS2 PCL 集成

---

## 核心实现

### ROS2 PCL 节点

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/point_cloud2.hpp>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <pcl_conversions/pcl_conversions.h>
#include <pcl/filters/passthrough.hpp>
#include <pcl/filters/voxel_grid.hpp>
#include <pcl/segmentation/extract_clusters.hpp>

class PCLProcessingNode : public rclcpp::Node {
public:
    PCLProcessingNode() : Node("pcl_processing_node") {
        // 订阅原始点云
        cloud_sub_ = this->create_subscription<sensor_msgs::msg::PointCloud2>(
            "/lidar_points", 10,
            std::bind(&PCLProcessingNode::cloudCallback, this, std::placeholders::_1));
            
        // 发布处理后点云
        filtered_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>(
            "/pcl/filtered", 10);
        clusters_pub_ = this->create_publisher<sensor_msgs::msg::PointCloud2>(
            "/pcl/clusters", 10);
            
        // 滤波器参数
        declare_parameter("voxel_leaf_size", 0.1);
        declare_parameter("x_min", -10.0);
        declare_parameter("x_max", 10.0);
        declare_parameter("y_min", -10.0);
        declare_parameter("y_max", 10.0);
        declare_parameter("z_min", -0.5);
        declare_parameter("z_max", 5.0);
    }
    
private:
    void cloudCallback(const sensor_msgs::msg::PointCloud2::SharedPtr msg) {
        // ROS2 msg -> PCL
        pcl::PointCloud<pcl::PointXYZ>::Ptr cloud(new pcl::PointCloud<pcl::PointXYZ>);
        pcl::fromROSMsg(*msg, *cloud);
        
        // 滤波处理
        auto filtered = this->applyFilters(cloud);
        
        // 聚类
        auto clusters = this->extractClusters(filtered);
        
        // 发布
        sensor_msgs::msg::PointCloud2 output;
        pcl::toROSMsg(*filtered, output);
        output.header = msg->header;
        filtered_pub_->publish(output);
    }
    
    pcl::PointCloud<pcl::PointXYZ>::Ptr applyFilters(
        pcl::PointCloud<pcl::PointXYZ>::Ptr cloud) {
        
        // 直通滤波
        pcl::PassThrough<pcl::PointXYZ> pass;
        pass.setInputCloud(cloud);
        pass.setFilterFieldName("x");
        pass.setFilterLimits(-10.0, 10.0);
        
        pcl::PointCloud<pcl::PointXYZ>::Ptr filtered(new pcl::PointCloud<pcl::PointXYZ>);
        pass.filter(*filtered);
        
        // 体素滤波
        pcl::VoxelGrid<pcl::PointXYZ> voxel;
        voxel.setInputCloud(filtered);
        voxel.setLeafSize(0.1, 0.1, 0.1);
        voxel.filter(*filtered);
        
        return filtered;
    }
    
    std::vector<pcl::PointCloud<pcl::PointXYZ>::Ptr> extractClusters(
        pcl::PointCloud<pcl::PointXYZ>::Ptr cloud) {
        
        // 创建 KD-Tree
        pcl::search::KdTree<pcl::PointXYZ>::Ptr tree(new pcl::search::KdTree<pcl::PointXYZ>);
        tree->setInputCloud(cloud);
        
        // 欧式聚类
        std::vector<pcl::PointIndices> cluster_indices;
        pcl::EuclideanClusterExtraction<pcl::PointXYZ> ec;
        ec.setClusterTolerance(0.5);
        ec.setMinClusterSize(10);
        ec.setMaxClusterSize(250);
        ec.setSearchMethod(tree);
        ec.setInputCloud(cloud);
        ec.extract(cluster_indices);
        
        std::vector<pcl::PointCloud<pcl::PointXYZ>::Ptr> clusters;
        for (auto& indices : cluster_indices) {
            pcl::PointCloud<pcl::PointXYZ>::Ptr cluster(new pcl::PointCloud<pcl::PointXYZ>);
            for (auto idx : indices.indices) {
                cluster->points.push_back(cloud->points[idx]);
            }
            clusters.push_back(cluster);
        }
        
        return clusters;
    }
    
    rclcpp::Subscription<sensor_msgs::msg::PointCloud2>::SharedPtr cloud_sub_;
    rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr filtered_pub_;
    rclcpp::Publisher<sensor_msgs::msg::PointCloud2>::SharedPtr clusters_pub_;
};
```

### Python PCL 实现

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2
import pcl
import pcl_msgs

class PCLProcessingNode(Node):
    def __init__(self):
        super().__init__('pcl_processing_node')
        
        self.cloud_sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.callback, 10)
        self.pub = self.create_publisher(PointCloud2, '/pcl/filtered', 10)
        
    def callback(self, msg):
        # PointCloud2 -> PCL
        cloud = self.pcl_from_ros(msg)
        
        # 降采样
        filtered = self.voxel_downsample(cloud, leaf_size=0.1)
        
        # 发布
        self.pub.publish(self.pcl_to_ros(filtered, msg.header))
        
    def voxel_downsample(self, cloud, leaf_size):
        sor = cloud.make_voxel_grid_filter()
        sor.set_leaf_size(leaf_size, leaf_size, leaf_size)
        return sor.filter()
        
    def pcl_from_ros(self, msg):
        # ROS msg to PCL
        return pcl.PointCloud_PointXYZ()
        
    def pcl_to_ros(self, cloud, header):
        # PCL to ROS msg
        return PointCloud2()
```
