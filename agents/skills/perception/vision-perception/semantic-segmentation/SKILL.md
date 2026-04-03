---
name: semantic-segmentation
description: 语义分割技能 - DeepLabV3、UNet、SegFormer ROS2 部署
argument-hint: 语义分割 OR DeepLabV3 OR UNet OR semantic segmentation OR 分割
user-invocable: true
---

# 语义分割技能

> 图像语义分割网络的 ROS2 部署

---

## 何时使用

当需要以下帮助时使用此技能：
- 语义分割模型部署
- 道路/场景分割
- 机器人抓取分割
- 医学图像分割
- 农业机器人分割

---

## 核心实现

### DeepLabV3 ROS2 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import torch
import torch.nn as nn
import numpy as np
import cv2

class DeepLabV3Node(Node):
    def __init__(self):
        super().__init__('deeplabv3_node')
        
        # 加载模型
        self.model = torch.load('/path/to/deeplabv3_model.pth')
        self.model.eval()
        self.model.cuda()
        
        self.bridge = CvBridge()
        
        # 调参
        self.declare_parameter('num_classes', 21)
        self.declare_parameter('confidence_threshold', 0.5)
        self.num_classes = self.get_parameter('num_classes').value
        
        self.image_sub = self.create_subscription(
            Image, '/camera/image_raw', self.callback, 10)
        self.mask_pub = self.create_publisher(Image, '/segmentation/mask', 10)
        self.color_pub = self.create_publisher(Image, '/segmentation/colored', 10)
        
        # 调色板
        self.palette = self.generate_palette()
        
    def callback(self, msg):
        cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='rgb8')
        
        # 预处理
        input_tensor = self.preprocess(cv_image)
        
        # 推理
        with torch.no_grad():
            output = self.model(input_tensor)
            mask = output.argmax(dim=1).squeeze().cpu().numpy()
            
        # 发布
        self.publish_mask(mask, msg.header.stamp)
        self.publish_colored(mask, msg.header.stamp)
        
    def preprocess(self, image):
        # 调整大小、归一化
        input_tensor = cv2.resize(image, (512, 512))
        input_tensor = torch.from_numpy(input_tensor).permute(2, 0, 1).float() / 255.0
        input_tensor = input_tensor.unsqueeze(0).cuda()
        return input_tensor
        
    def generate_palette(self):
        # Cityscapes 调色板
        return np.array([
            [128, 64, 128], [244, 35, 232], [70, 70, 70], [102, 102, 156],
            [190, 153, 153], [153, 153, 153], [250, 170, 30], [220, 220, 0],
            [107, 142, 35], [152, 251, 152], [0, 130, 180], [220, 20, 60],
            [255, 0, 0], [0, 0, 142], [0, 0, 70], [0, 60, 100],
            [0, 80, 100], [0, 0, 230], [119, 11, 32]
        ], dtype=np.uint8)
        
    def publish_mask(self, mask, stamp):
        mask_msg = self.bridge.cv2_to_imgmsg(mask.astype(np.uint8), encoding='mono8')
        mask_msg.header.stamp = stamp
        self.mask_pub.publish(mask_msg)
        
    def publish_colored(self, mask, stamp):
        colored = self.palette[mask]
        colored_msg = self.bridge.cv2_to_imgmsg(colored, encoding='rgb8')
        colored_msg.header.stamp = stamp
        self.color_pub.publish(colored_msg)
```

### UNet 实现

```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class DoubleConv(nn.Module):
    def __init__(self, in_ch, out_ch):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True)
        )
        
    def forward(self, x):
        return self.conv(x)

class UNet(nn.Module):
    def __init__(self, in_channels, out_channels):
        super().__init__()
        
        self.enc1 = DoubleConv(in_channels, 64)
        self.enc2 = DoubleConv(64, 128)
        self.enc3 = DoubleConv(128, 256)
        self.enc4 = DoubleConv(256, 512)
        
        self.pool = nn.MaxPool2d(2)
        self.up = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True)
        
        self.dec3 = DoubleConv(512 + 256, 256)
        self.dec2 = DoubleConv(256 + 128, 128)
        self.dec1 = DoubleConv(128 + 64, 64)
        
        self.out_conv = nn.Conv2d(64, out_channels, 1)
        
    def forward(self, x):
        # Encoder
        e1 = self.enc1(x)
        e2 = self.enc2(self.pool(e1))
        e3 = self.enc3(self.pool(e2))
        e4 = self.enc4(self.pool(e3))
        
        # Decoder
        d3 = self.dec3(torch.cat([self.up(e4), e3], dim=1))
        d2 = self.dec2(torch.cat([self.up(d3), e2], dim=1))
        d1 = self.dec1(torch.cat([self.up(d2), e1], dim=1))
        
        return self.out_conv(d1)
```
