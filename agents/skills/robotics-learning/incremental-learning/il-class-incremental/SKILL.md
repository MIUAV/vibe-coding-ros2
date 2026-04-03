---
name: il-class-incremental
description: 类别增量学习技能 - iCaRL、EEIL、LwF、蒸馏损失
argument-hint: "类别增量" / "class incremental" / "iCaRL" / "EEIL" / "LwF"
user-invocable: true
---

# 类别增量学习技能

> 逐步学习新类别而不遗忘旧类别的能力

---

## 何时使用

当需要以下帮助时使用此技能：
- 机器人识别新物体
- 增量式目标分类
- 知识蒸馏防止遗忘
- 样本回放分类

---

## 核心算法

### iCaRL (Incremental Classifier and Representation Learning)

```python
import torch
import torch.nn as nn
import numpy as np
from herding import HerdingSampler

class iCaRL:
    def __init__(self, backbone, num_classes_per_task=10, memory_size=2000):
        self.backbone = backbone
        self.num_classes_per_task = num_classes_per_task
        self.memory_size = memory_size
        self.exemplar_sets = []  # 每类的样本集
        self.class_means = {}
        self.old_network = None
        
    def increment_classes(self, num_new_classes):
        """增加新类别"""
        # 扩展分类器
        old_num_classes = self.backbone.fc.out_features
        new_num_classes = old_num_classes + num_new_classes
        
        # 保存旧网络用于蒸馏
        self.old_network = type(self.backbone)()
        self.old_network.load_state_dict(self.backbone.state_dict())
        
        # 扩展分类器
        new_fc = nn.Linear(self.backbone.fc.in_features, new_num_classes)
        new_fc.weight.data[:old_num_classes] = self.backbone.fc.weight.data
        self.backbone.fc = new_fc
        
    def construct_exemplar_set(self, dataset, class_idx, num_exemplars=20):
        """为类别构建样本集"""
        # 使用 herding 采样
        class_features = []
        for i, (inputs, labels) in enumerate(dataset):
            if labels == class_idx:
                features = self.backbone.feature_extract(inputs)
                class_features.append(features)
                
        class_features = torch.stack(class_features)
        mean_feature = class_features.mean(dim=0)
        
        # 贪心采样
        exemplar_set = []
        for _ in range(num_exemplars):
            min_dist = float('inf')
            best_idx = None
            
            for i, feat in enumerate(class_features):
                if i in [e[1] for e in exemplar_set]:
                    continue
                    
                dist = torch.norm(feat - mean_feature)
                if dist < min_dist:
                    min_dist = dist
                    best_idx = i
                    
            exemplar_set.append((class_features[best_idx], best_idx))
            
        self.exemplar_sets.append([dataset[i][0] for i in range(len(dataset)) if i in [e[1] for e in exemplar_set]])
        
    def classify(self, input_image):
        """分类新样本"""
        # 提取特征
        features = self.backbone.feature_extract(input_image)
        
        # 计算与类均值的距离
        distances = []
        for class_idx, mean in self.class_means.items():
            dist = torch.norm(features - mean)
            distances.append((dist.item(), class_idx))
            
        distances.sort()
        return distances[0][1]
        
    def update_representation(self, new_dataset, epochs=20):
        """更新表示学习"""
        # 知识蒸馏损失
        def distillation_loss(student_features, teacher_features, temperature=2.0):
            student_log_probs = torch.log_softmax(student_features / temperature, dim=-1)
            teacher_log_probs = torch.log_softmax(teacher_features / temperature, dim=-1)
            return nn.functional.kl_div(student_log_probs, teacher_log_probs, reduction='batchmean')
            
        optimizer = torch.optim.SGD(self.backbone.parameters(), lr=0.1)
        
        for epoch in range(epochs):
            for inputs, labels in new_dataset:
                optimizer.zero_grad()
                
                outputs = self.backbone(inputs)
                
                # 新类别分类损失
                new_mask = labels >= self.old_network.fc.out_features
                loss = nn.functional.cross_entropy(outputs[new_mask], labels[new_mask])
                
                # 旧类别蒸馏损失
                if self.old_network is not None and len(labels) > 0:
                    old_mask = labels < self.old_network.fc.out_features
                    with torch.no_grad():
                        old_outputs = self.old_network(inputs)
                    dist_loss = distillation_loss(outputs[old_mask], old_outputs[old_mask])
                    loss += 0.5 * dist_loss
                    
                loss.backward()
                optimizer.step()
```

### LwF (Learning without Forgetting)

```python
class LwF:
    def __init__(self, network, lambda_lwf=1.0):
        self.network = network
        self.lambda_lwf = lambda_lwf
        self.old_network = None
        
    def train_step(self, new_data, new_labels, old_data):
        """训练步骤"""
        # 保存旧网络
        if self.old_network is None:
            self.old_network = type(self.network)()
            self.old_network.load_state_dict(self.network.state_dict())
            
        optimizer = torch.optim.SGD(self.network.parameters(), lr=0.01)
        
        # 新数据前向传播
        new_outputs = self.network(new_data)
        
        # 旧网络在新数据上的输出 (知识蒸馏)
        with torch.no_grad():
            old_outputs = self.old_network(new_data)
            
        # 新类别损失
        task_loss = nn.functional.cross_entropy(new_outputs, new_labels)
        
        # 蒸馏损失
        distill_loss = nn.functional.kl_div(
            torch.log_softmax(new_outputs / 2.0, dim=-1),
            torch.log_softmax(old_outputs / 2.0, dim=-1),
            reduction='batchmean'
        ) * (2.0 ** 2)
        
        loss = task_loss + self.lambda_lwf * distill_loss
        
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
```
