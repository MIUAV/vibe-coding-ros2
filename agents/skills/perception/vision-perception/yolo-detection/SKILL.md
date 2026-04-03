---
name: yolo-detection
description: YOLO 目标检测 ROS2 部署技能 - YOLOv5/v8/v11 TensorRT/OpenVINO/RKNN 部署
argument-hint: "YOLO" / "目标检测" / "TensorRT" / "yolov8" / "object detection"
user-invocable: true
---

# YOLO 目标检测技能

> YOLO 系列目标检测网络的 ROS2 部署与优化

---

## 何时使用

当需要以下帮助时使用此技能：
- YOLOv5/v8/v11 模型部署
- TensorRT 加速推理
- ROS2 目标检测节点开发
- 多目标跟踪
- 边缘设备部署 (Jetson/RK3588)

---

## 核心实现

### ROS2 YOLO 节点 (C++)

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <vision_msgs/msg/detection2_d_array.hpp>
#include <cv_bridge/cv_bridge.hpp>
#include <opencv2/opencv.hpp>

class YOLONode : public rclcpp::Node {
public:
    YOLONode() : Node("yolo_node") {
        // 加载模型
        loadModel();
        
        // 订阅图像
        image_sub_ = this->create_subscription<sensor_msgs::msg::Image>(
            "/camera/image_raw", 10,
            std::bind(&YOLONode::imageCallback, this, std::placeholders::_1));
            
        // 发布检测结果
        det_pub_ = this->create_publisher<vision_msgs::msg::Detection2DArray>(
            "/detections", 10);
    }
    
private:
    void loadModel() {
        // TensorRT 引擎加载
        // 初始化推理引擎
    }
    
    void imageCallback(const sensor_msgs::msg::Image::SharedPtr msg) {
        cv::Mat image = cv_bridge::toCvShare(msg, "rgb8")->image;
        
        // 预处理
        auto input = preprocess(image);
        
        // 推理
        auto detections = infer(input);
        
        // 后处理
        auto results = postprocess(detections, image.size());
        
        // 发布结果
        publishResults(results);
    }
    
    cv::Mat preprocess(const cv::Mat& image) {
        cv::Mat resized;
        cv::resize(image, resized, cv::Size(640, 640));
        resized.convertTo(resized, CV_32FC3, 1.0/255.0);
        return resized;
    }
    
    std::vector<Detection> infer(const cv::Mat& input) {
        // TensorRT 推理
    }
    
    std::vector<Detection> postprocess(std::vector<float>& output, cv::Size original_size) {
        // NMS, 坐标转换
    }
    
    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr image_sub_;
    rclcpp::Publisher<vision_msgs::msg::Detection2DArray>::SharedPtr det_pub_;
    void* trt_context_;
};
```

### Python 部署版本

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from vision_msgs.msg import Detection2DArray, Detection2D
from cv_bridge import CvBridge
import torch
import numpy as np

class YOLONode(Node):
    def __init__(self):
        super().__init__('yolo_node')
        
        # 加载模型
        self.model = torch.hub.load('ultralytics/yolov8', 'yolov8n')
        self.bridge = CvBridge()
        
        # 订阅图像
        self.image_sub = self.create_subscription(
            Image, '/camera/image_raw', self.callback, 10)
            
        # 发布检测
        self.det_pub = self.create_publisher(Detection2DArray, '/detections', 10)
        
    def callback(self, msg):
        # 转换图像
        cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='rgb8')
        
        # 推理
        results = self.model(cv_image)
        
        # 发布结果
        self.publish_detections(results, msg.header.stamp)
        
    def publish_detections(self, results, stamp):
        det_array = Detection2DArray()
        det_array.header.stamp = stamp
        
        for box in results.boxes:
            det = Detection2D()
            det.bbox.center.position.x = float(box.xywh[0])
            det.bbox.center.position.y = float(box.xywh[1])
            det.bbox.size_x = float(box.xywh[2])
            det.bbox.size_y = float(box.xywh[3])
            det_array.detections.append(det)
            
        self.det_pub.publish(det_array)
```

### TensorRT 加速 (Python)

```python
import torch
import tensorrt as trt
import numpy as np

class TensorRTInference:
    def __init__(self, engine_path):
        self.logger = trt.Logger(trt.Logger.WARNING)
        self.runtime = trt.Runtime(self.logger)
        
        with open(engine_path, 'rb') as f:
            self.engine = self.runtime.deserialize_cuda_engine(f.read())
        self.context = self.engine.create_execution_context()
        
        self.buffers = {}
        for i in range(self.engine.num_io_tensors):
            name = self.engine.get_tensor_name(i)
            self.buffers[name] = self.allocate_buffer(name)
            
    def allocate_buffer(self, name):
        shape = self.context.get_tensor_shape(name)
        dtype = trt.nptype(self.engine.get_tensor_dtype(name))
        size = np.prod(shape)
        return torch.zeros(size, dtype=dtype, device='cuda')
        
    def infer(self, input_data):
        # 拷贝输入数据
        self.buffers['input'].copy_(torch.from_numpy(input_data).cuda())
        
        # 执行推理
        self.context.execute_v2(list(self.buffers.values()))
        
        # 拷贝输出
        output = self.buffers['output'].cpu().numpy()
        return output
```
