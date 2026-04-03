---
name: tl-cross-robot-transfer
description: 跨机器人知识迁移技能 - 形态无关特征、领域泛化、策略蒸馏
argument-hint: "跨机器人迁移" / "robot transfer" / "形态迁移" / "policy distillation"
user-invocable: true
---

# 跨机器人知识迁移技能

> 将一个机器人的技能迁移到不同形态的机器人

---

## 何时使用

当需要以下帮助时使用此技能：
- 不同机器人平台间迁移
- 仿真机器人到真实机器人
- 技能形态适应
- 知识蒸馏

---

## 核心方法

### 形态无关特征提取

```python
import torch
import torch.nn as nn

class MorphologyAgnosticFeature(nn.Module):
    def __init__(self, state_dim, hidden_dim=128):
        super().__init__()
        
        # 规范化状态输入
        self.normalizer = nn.LayerNorm(state_dim)
        
        # 形态无关特征提取
        self.feature_net = nn.Sequential(
            nn.Linear(state_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim)
        )
        
    def forward(self, state, morphology_encoding=None):
        # 归一化状态
        norm_state = self.normalizer(state)
        
        # 融合形态编码
        if morphology_encoding is not None:
            norm_state = torch.cat([norm_state, morphology_encoding], dim=-1)
            
        features = self.feature_net(norm_state)
        return features

class CrossRobotTransfer:
    def __init__(self, source_robot, target_robot):
        self.source = source_robot
        self.target = target_robot
        
        # 形态编码器
        self.morphology_encoder = MorphologyEncoder()
        
    def extract_morphology(self, robot):
        """提取机器人形态特征"""
        return torch.tensor([
            robot.dof,           # 自由度
            robot.link_count,    # 连杆数
            robot.weight,        # 重量
            robot.height,        # 高度
            robot.reach,         # 臂展
        ])
        
    def transfer_policy(self, policy, source_state, target_state):
        """迁移策略到目标机器人"""
        source_morph = self.extract_morphology(self.source)
        target_morph = self.extract_morphology(self.target)
        
        # 提取形态无关特征
        features = policy.extract_features(source_state, source_morph)
        
        # 调整到目标形态
        adapted_features = self.morphology_adapter(features, source_morph, target_morph)
        
        # 生成目标机器人策略
        target_policy = policy.generate_policy(adapted_features, target_morph)
        
        return target_policy
```

### 策略蒸馏

```python
class PolicyDistillation:
    def __init__(self, teacher_policy, student_policy, temperature=2.0):
        self.teacher = teacher_policy
        self.student = student_policy
        self.temperature = temperature
        
    def distill(self, states, optimizer, alpha=0.5):
        """
        知识蒸馏
        alpha: 教师信号的权重
        """
        with torch.no_grad():
            teacher_q = self.teacher(states)
            
        student_logits = self.student(states)
        
        # KL 散度损失
        soft_loss = nn.functional.kl_div(
            student_logits / self.temperature,
            teacher_q / self.temperature,
            reduction='batchmean'
        ) * (self.temperature ** 2)
        
        # 硬标签损失
        hard_loss = nn.functional.cross_entropy(student_logits, teacher_q.argmax(dim=-1))
        
        # 联合损失
        loss = alpha * hard_loss + (1 - alpha) * soft_loss
        
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        
        return loss.item()
```
