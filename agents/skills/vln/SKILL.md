---
name: vln
description: 视觉语言导航 Vision-Language Navigation 技能 - VLN 自然语言导航、HF-RCN/R罗汉导航智能体
argument-hint: VLN OR 视觉语言导航 OR vision language navigation OR 语言导航 OR 具身智能导航
user-invocable: true
---

# VLN — Vision-Language Navigation 技能

> 基于自然语言指令在未知环境中进行视觉导航的具身智能技能

---

## 何时使用

当需要以下帮助时使用此技能：
- 视觉语言导航智能体开发
- RoomNav / R2R / RxR 数据集训练
- HF-RCN / R罗汉等导航智能体实现
- VLN 与 ROS2 移动底盘集成
- 零样本/少样本视觉导航

---

## 核心概念

### VLN 任务定义

```
自然语言指令 + 起始视角 → → → 目标位置
"Go past the kitchen and turn left at the blue sofa"
   ↓                          ↓
 视觉观测                   到达成功
```

### VLN 关键指标

| 指标 | 含义 |
|------|------|
| Success Rate (SR) | 是否到达目标位置 |
| Success Rate weighted by Path Length (SPL) | 考虑路径效率的成功率 |
| NDW | 成功导航的距离加权分数 |
| CLS | 按指令分句的逐句成功率 |

### 主流数据集

| 数据集 | 类型 | 特点 |
|--------|------|------|
| [R2R](https://arxiv.org/abs/1804.00168) | 室内视觉导航 | Matterport3D Gibson |
| [RxR](https://arxiv.org/abs/2010.13082) | 室内导航（多语言） | Hindi/English/Tagalog |
| [RoomNav](https://arxiv.org/abs/2207.02574) | 室内语义导航 | GeoChat |
| [VDOT](https://arxiv.org/abs/2310.07568) | 开放世界视觉导航 | 野外环境 |

---

## R2R 数据集标准流程

### 1. 数据准备

```python
# r2r_agent.py
class R2REnv:
    def __init__(self, dataset_path):
        # R2R 数据集格式
        # instrucion: 自然语言指令
        # path: 专家轨迹 [viewpoints]
        # start_pose: 起始位置 (scanId, viewpointId, heading, pitch)
        # goal_viewpoint: 目标视角
```

### 2. 观测表示

```python
import numpy as np

def encode_observation(image, heading, feature_dim=2048):
    """标准 R2R 观测编码"""
    # ResNet/Matterport3D ResNet pretrained features
    # 或使用 CLIP ViT encoding
    return obs_encoding
```

### 3. 动作空间

```python
# 两类动作空间
ACTION_TYPES = {
    'discrete':  # {Forward, Left, Right, Stop}
    'continuous':  # 32个离散视角 + Stop
}

class NavigationPolicy(nn.Module):
    def forward(self, obs, history_emb):
        # 输入: 当前图像特征 + 历史上下文
        # 输出: 动作对数几率或连续旋转+停止
        logits = self.action_head(history_emb)
        return logits
```

---

## HF-RCN / R罗汉 导航智能体

### 架构概览

```
文本编码器（BERT/CLIP）
        ↓
历史指令上下文（LSTM/Transformer）
        ↓
双层视觉编码器（全景图 → 视角注意）
        ↓
动作预测头（Cross-Entropy / 模仿学习）
```

### 关键代码模板

```python
# agents/vln/hf_rcn/model.py
class HF_RCN(nn.Module):
    def __init__(self, vision_dim=2048, hidden_dim=512):
        self.text_encoder = ClipEncoder()
        self.panorama_encoder = PanoramaAttention(vision_dim, hidden_dim)
        self.history_gru = nn.GRU(hidden_dim, hidden_dim, batch_first=True)
        self.action_head = nn.Linear(hidden_dim, 4)  # {F,L,R,Stop}

    def forward(self, obs_images, instruction_tokens, history=None):
        # obs_images: 全景图像列表 [batch, 36, C, H, W]
        # instruction_tokens: [batch, seq_len]
        text_feat = self.text_encoder(instruction_tokens)
        vis_feat = self.panorama_encoder(obs_images)
        combined = torch.cat([text_feat, vis_feat], dim=-1)
        if history is not None:
            combined = combined + history
        logits = self.action_head(combined)
        return logits
```

### 训练配置

```yaml
# configs/vln/r2r_hf_rcn.yaml
training:
  optimizer: AdamW
  learning_rate: 1e-4
  batch_size: 24
  epochs: 200
  scheduler: StepLR(step_size=50, gamma=0.5)

  loss: CrossEntropyLoss  # 或 SeqKD（知识蒸馏）
  auxiliary:
    angular_loss: 0.1  # 预测视角方向辅助损失
    stopping_loss: 0.05
```

### ROS2 集成接口

```python
# rclpy VLN 执行节点
class VLNNavigator(Node):
    def __init__(self):
        super().__init__('vln_navigator')
        self.model = load_hf_rcn_model()
        self.cmd_pub = self.create_publisher(Twist, '/nav_cmd', 10)
        self.image_sub = self.create_subscription(
            Image, '/camera', self.on_image, 10)

    def on_image(self, msg):
        # 1. 编码当前观测
        obs = self.preprocess(msg)
        # 2. 推理动作
        action = self.model.predict(obs, self.instruction_emb)
        # 3. 转换为 ROS2 Twist
        cmd = self.action_to_twist(action)
        self.cmd_pub.publish(cmd)
```

---

## 零样本 / 少样本 VLN

### CLIP-Preterrain 方案

```python
# 使用预训练 CLIP 替代 Matterport3D ResNet
class CLIPVLN(nn.Module):
    def __init__(self):
        self.clip, _ = load("ViT-L/14@336px", device='cuda')
        self.projection = nn.Linear(768, 512)

    def encode_observation(self, image):
        with torch.no_grad():
            feat = self.clip.encode_image(image)
        return self.projection(feat)
```

### 跨域迁移

```python
# RxR → R2R 迁移
# RxR（多语言更长指令）→ R2R（英文短指令）
def adapt_instruction(instruction):
    # 提取关键导航意图
    keywords = extract_nav_keywords(instruction)
    return " ".join(keywords)  # 英文短指令
```

---

## 常见问题

### 问题：全景视角编码效率

**解决方案**：使用预计算特征 + 全视角缓存

```python
# 预计算所有视角特征（36个方向）
VIEWPOINT_CACHE = {}
def get_panorama_features(scan_id, viewpoint_id):
    key = f"{scan_id}_{viewpoint_id}"
    if key not in VIEWPOINT_CACHE:
        images = capture_36_direction(scan_id, viewpoint_id)
        VIEWPOINT_CACHE[key] = model.encode_batch(images)
    return VIEWPOINT_CACHE[key]
```

### 问题：长期历史依赖

**解决方案**：使用 Transformer cross-attention 或 GRU+LSTM

### 问题：稀疏奖励

**解决方案**：
- 预训练使用模仿学习（BC）+ 专家轨迹
- 在线使用 PPO / DAgger

---

## 相关资源

- [R2R 数据集](https://github.com/petergong97/r2r)
- [RxR 数据集](https://github.com/google-research/google-research/tree/master/rxr)
- [VLN-CE (Habitat-Matterport3D)](https://github.com/nickgkan/lysium)
- [Matterport3D 工具](https://github.com/Matterport/Matterport3DSDK)
- [HF-RCN 原版](https://github.com/TheAbhiKumar/HF-RCN)

---

## 另见

- [navigation](../navigation/) - ROS2 导航集成
- [perception](../perception/) - 视觉感知
- [robotics-learning](../robotics-learning/) - 模仿学习/强化学习
- [multi_rotor_uav](../../../robots/multi_rotor_uav/) - 无人机导航
