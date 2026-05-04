---
name: vla
description: 视觉语言动作模型 Vision-Language-Action 技能 - VLA 机器人控制、UniDiffuser、World Action Model
argument-hint: VLA OR Vision Language Action OR 视觉语言动作 OR 世界模型 OR world model OR robot control OR UniDiffuser
user-invocable: true
---

# VLA — Vision-Language-Action 技能

> 基于视觉-语言-动作统一建模的机器人控制技能（基于 MotuBrain / RT 系列 / UniDiffuser 架构）

---

## 何时使用

当需要以下帮助时使用此技能：
- VLA 机器人控制策略训练
- World Action Model / World Model 集成
- 视觉-语言-动作多模态策略学习
- 零样本机器人控制
- 跨实体（cross-embodiment）策略迁移
- ROS2 + VLA 实时控制流水线

---

## 核心概念

### VLA vs VLN 区别

| 维度 | VLN | VLA |
|------|-----|-----|
| 目标 | 到达位置 | 执行操作/完成任务 |
| 输出 | 离散步态（前进/左/右/停止） | 连续动作（关节角度/Twist） |
| 反馈 | 稀疏（到达/未到达） | 密集（任务完成度/奖励） |
| 典型模型 | HF-RCN, PREVALENT, VLNBERT | MOTOMAN, RT-1/2, MotuBrain, UniDiffuser |

### 主流 VLA 架构

| 架构 | 机构 | 关键特性 |
|------|------|----------|
| [MotuBrain](https://arxiv.org/abs/2604.27792) | MotuBrain Team | UniDiffuser + 三流 MoT，统一视频/动作/世界模型 |
| [RT-2](https://www.roboticsproceedings.org/robotics/v1/n08a08/) | Google Robotics | ViT + LLM = 视觉语言动作策略 |
| [UniDiffuser](https://arxiv.org/abs/2303.13853) | Tsinghua | 统一多模态扩散生成 |
| [ActMOD](https://arxiv.org/abs/2605.00663) | TENG + GOOD | Affordance Agent Harness，技能编排 |

---

## MotuBrain — World Action Model

> 来自 ICRA 2026 近期工作（arXiv:2604.27792），统一视频+动作联合建模

### 核心特性

```
输入: 视频帧 + 文本指令 + 历史动作
输出: 下一帧预测 + 动作预测
架构: UniDiffuser + 三流 Mixture-of-Transformers

支持:
  ✅ 策略学习 (policy learning)
  ✅ 世界建模 (world modeling)
  ✅ 视频生成 (video generation)
  ✅ 逆动力学 (inverse dynamics)
  ✅ 跨实体迁移 (cross-embodiment)
```

### 推理优化技术

```python
# 推理优化 — 50x 加速
OPTIMIZATIONS = {
    'step_reduction': '减少 diffusion 步数',
    'fp8_quantization': 'FP8 量化',
    'dit_caching': 'DiT KV cache',
    'v2a_style': 'Video-to-Action 动作专用推理',
    'chunked_execution': '实时分块闭环执行'
}
```

### ROS2 集成

```python
# rclpy VLA 执行节点
class VLAController(Node):
    def __init__(self):
        super().__init__('vla_controller')
        # 加载 MotuBrain（需适配 ROS2 关节接口）
        self.model = load_motubrain(checkpoint="motubrain-11hz.pt")
        self.joint_pub = self.create_publisher(
            JointCommand, '/arm_controller/joint_commands', 10)
        self.image_sub = self.create_subscription(
            Image, '/camera', self.on_image, 10)
        self.instruction_sub = self.create_subscription(
            String, '/task_instruction', self.on_instruction, 10)

    def on_image(self, msg):
        # 1. 视觉特征提取
        img_feat = self.clip_encode(msg)  # CLIP ViT-L/14@336px
        # 2. VLA 前向推理
        action = self.model.step(img_feat, self.instruction_emb, self.history)
        # 3. 关节命令发布
        self.joint_pub.publish(action)  # 11Hz 实时控制

    def on_instruction(self, msg):
        self.instruction_emb = self.clip_encode_text(msg.data)
```

---

## RT-2 风格视觉语言动作模型

### 架构

```
[图像] → ViT Encoder → [视觉 token 序列]
                              ↓
[文本指令] → LLM (PaLM/SETUPA) → [语言 token 序列]
                              ↓
              视觉 + 语言 token 序列
                              ↓
                    LLM decoder
                              ↓
               动作 token → 机器人关节命令
```

### ROS2 集成

```python
# RT-2 风格节点（伪代码）
class RT2Controller(Node):
    def __init__(self):
        self.vla_model = load_rt2_model("rt2_xavier.pt")
        self.actions = {}

    def callback(self, obs):
        # obs = {image, joint_state, instruction}
        action_tokens = self.vla_model.predict(
            image=obs['image'],
            text=obs['instruction']
        )
        # action_tokens → 关节命令
        cmd = self.tokens_to_joints(action_tokens)
        self.arm_pub.publish(cmd)
```

---

## UniDiffuser 多模态扩散

### 核心公式

```python
# UniDiffuser 统一生成
# p(x_v, x_a, x_t) — 联合建模视觉、动作、文本

class UniDiffuserVLA(nn.Module):
    def __init__(self, latent_dim=256):
        self.vae = ModalVAE()  # 视觉/动作/文本共用 VAE
        self.diffusion = UnifiedDiffusion()

    def forward(self, image, text, action=None, t=None):
        # 前向 diffusion 过程
        z = self.vae.encode(image, text, action)
        z_noisy = self.diffusion.add_noise(z, t)
        pred_z = self.diffusion.denoise(z_noisy, t, condition=(text,))
        return self.vae.decode_action(pred_z)
```

### 机器人控制场景应用

```python
# 动作条件生成
def generate_action(obs_image, instruction, n_steps=20):
    text_emb = clip_text_encoder(instruction)
    obs_emb = clip_image_encoder(obs_image)
    noisy_action = torch.randn(1, action_dim)

    for t in reversed(range(n_steps)):
        noise = noise_predictor(noisy_action, t, [obs_emb, text_emb])
        noisy_action = DDIM_step(noisy_action, noise, t)

    return decode_action(noisy_action)
```

---

## 跨实体（Cross Embodiment）策略

### MotuBrain 跨实体方案

```python
# 关键：共享动作表示
CROSS_EMBODIMENT_CONFIG = {
    'action_representation': '共享跨实体动作空间',
    'adaptation': '仅需 50-100 条目标机器人轨迹即可适应',
    'heterogeneous_data': '支持 video-only / task-agnostic / cross-embodiment 混合数据',
}

# 动作归一化
def normalize_action(action, robot_type):
    """将不同机器人的动作映射到统一表示"""
    if robot_type == 'franka':
        return action * FRANKA_ACTION_SCALE
    elif robot_type == 'xarm':
        return action * XARM_ACTION_SCALE
    elif robot_type == 'humanoid':
        return action * HUMANOID_ACTION_SCALE
```

---

## 数据集

| 数据集 | 规模 | 实体 |
|--------|------|------|
| [Open-X-Embodiment](https://arxiv.org/abs/2304.03799) | 1M+ 轨迹 | 22 种机器人 |
| [RoboTwin](https://roboTwin.github.io) | 灵巧手操作 | 双手机器人 |
| [BridgeData](https://github.com/google-research/bridge_data_v2) | 6K 轨迹 | 家庭操作 |
| [DROID](https://droid.grasp/) | 76K 轨迹 | 多种操作任务 |

---

## 常见问题

### 问题：VLA 推理延迟高

**解决方案**：
1. 使用 DiT caching + FP8 量化（参考 MotuBrain 优化）
2. Video-to-Action 专用模型（跳过视频生成）
3. Action chunking — 分块预测多步动作

### 问题：跨实体动作空间不一致

**解决方案**：
- 使用归一化动作表示（所有机器人映射到 [-1, 1]）
- 仅微调最后几层 transformer，而非全量参数

### 问题：指令遵循不稳定

**解决方案**：
- 文本 encoder 使用 CLIP 或 T5x
- 加入 instruction following auxiliary loss
- 对比学习强化文本-动作对齐

---

## 相关资源

- [MotuBrain Project](https://motubrain.github.io)
- [Open-X-Embodiment](https://robotics-transformer.github.io)
- [RoboTwin 2.0](https://roboTwin.github.io)
- [RT-2 Paper](https://www.roboticsproceedings.org/robotics/v1/n08a08/)
- [UniDiffuser](https://github.com/thudian/UniDiffuser)
- [Affordance Agent Harness](https://tenplusgood.github.io/a-harness-page/)

---

## 另见

- [robotics-learning](../robotics-learning/) - 强化学习/模仿学习
- [perception](../perception/) - 视觉感知
- [manipulation](../manipulator/) - 机器人操作
- [simulation](../simulator/) - 仿真环境
