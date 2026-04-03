---
name: tensorrt-deployment
description: TensorRT 部署技能 - ONNX 转换、Engine 构建、INT8 量化、ROS2 加速推理
argument-hint: "TensorRT" / "ONNX" / "INT8" / "GPU加速" / "tensorrt deployment"
user-invocable: true
---

# TensorRT 部署技能

> NVIDIA Jetson/Desktop GPU 推理加速

---

## 何时使用

当需要以下帮助时使用此技能：
- ONNX 模型转 TensorRT
- FP16/INT8 量化
- Engine 优化
- Jetson 部署
- CUDA 流处理

---

## 核心实现

### ONNX 转 TensorRT

```python
import tensorrt as trt
import onnx

class TensorRTConverter:
    def __init__(self, logger_level=trt.Logger.WARNING):
        self.logger = trt.Logger(logger_level)
        self.builder = trt.Builder(self.logger)
        
    def convert_onnx_to_engine(self, onnx_path, engine_path, fp16=True, int8=False):
        """ONNX 转 TensorRT Engine"""
        network = self.builder.create_network(
            1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
            
        parser = trt.OnnxParser(network, self.logger)
        
        with open(onnx_path, 'rb') as f:
            parser.parse(f.read())
            
        config = self.builder.create_builder_config()
        
        if fp16:
            config.set_flag(trt.BuilderFlag.FP16)
            
        if int8:
            config.set_flag(trt.BuilderFlag.INT8)
            config.int8_calibrator = self.create_calibrator()
            
        # 构建 Engine
        engine = self.builder.build_serialized_network(network, config)
        
        with open(engine_path, 'wb') as f:
            f.write(engine)
            
        return engine
        
    def create_calibrator(self):
        """创建 INT8 校准器"""
        return INT8Calibrator()
```

### INT8 量化

```python
class INT8Calibrator(trt.IInt8Calibrator):
    def __init__(self, calibration_data, batch_size=8):
        self.calibration_data = calibration_data
        self.batch_size = batch_size
        self.cache_file = 'calibration.cache'
        
    def get_batch(self, names):
        """获取校准批次"""
        # 返回校准数据
        return self.calibration_data[:self.batch_size]
        
    def get_batch_size(self):
        return self.batch_size
        
    def read_calibration_cache(self):
        """读取缓存"""
        if os.path.exists(self.cache_file):
            with open(self.cache_file, 'rb') as f:
                return f.read()
                
    def write_calibration_cache(self, cache):
        """写入缓存"""
        with open(self.cache_file, 'wb') as f:
            f.write(cache)
```

### ROS2 TensorRT 节点

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.hpp>
#include <opencv2/opencv.hpp>
#include <cuda_runtime.h>

class TensorRTNode : public rclcpp::Node {
public:
    TensorRTNode() : Node("tensorrt_node") {
        // 加载 Engine
        loadEngine("/path/to/model.engine");
        
        // 分配 GPU 内存
        cudaMalloc(&device_input_, BATCH_SIZE * INPUT_SIZE);
        cudaMalloc(&device_output_, BATCH_SIZE * OUTPUT_SIZE);
        
        // 订阅
        sub_ = create_subscription<sensor_msgs::msg::Image>(
            "/image", 10,
            std::bind(&TensorRTNode::callback, this, std::placeholders::_1));
        pub_ = create_publisher<sensor_msgs::msg::Image>("/output", 10);
    }
    
private:
    void loadEngine(const std::string& engine_path) {
        std::ifstream file(engine_path, std::ios::binary);
        file.seekg(0, std::ios::end);
        size_t size = file.tellg();
        file.seekg(0, std::ios::beg);
        
        char* trt_model = new char[size];
        file.read(trt_model, size);
        file.close();
        
        runtime_ = nvinfer1::createInferRuntime(logger_);
        engine_ = runtime_->deserializeCudaEngine(trt_model, size);
        context_ = engine_->createExecutionContext();
    }
    
    void callback(const sensor_msgs::msg::Image::SharedPtr msg) {
        cv::Mat image = cv_bridge::toCvShare(msg)->image;
        
        // 预处理
        cv::Mat resized;
        cv::resize(image, resized, cv::Size(640, 640));
        float* input_data = preprocess(resized);
        
        // 拷贝到 GPU
        cudaMemcpy(device_input_, input_data, INPUT_SIZE * sizeof(float), 
                   cudaMemcpyHostToDevice);
        
        // 推理
        context_->executeV2(device_ptrs_);
        
        // 拷贝结果
        float output[BATCH_SIZE * OUTPUT_SIZE];
        cudaMemcpy(output, device_output_, OUTPUT_SIZE * sizeof(float),
                   cudaMemcpyDeviceToHost);
                   
        // 后处理
        auto results = postprocess(output);
        
        pub_->publish(results);
    }
    
    float* preprocess(const cv::Mat& image) {
        static float input[INPUT_SIZE];
        // 归一化
        return input;
    }
    
    void* device_input_;
    void* device_output_;
    void* device_ptrs_[2];
    nvinfer1::IRuntime* runtime_;
    nvinfer1::ICudaEngine* engine_;
    nvinfer1::IExecutionContext* context_;
};
```
