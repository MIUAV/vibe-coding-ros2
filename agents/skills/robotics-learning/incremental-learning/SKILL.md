---
name: incremental-learning
description: 增量学习技能 — 类别增量、任务增量、表示学习，新类别无需重新训练全量数据，适用于机器人在线学习
argument-hint: 增量学习 OR incremental learning OR class IL OR task IL OR 在线学习
user-invocable: true
---

# incremental-learning — 增量学习 SKILL

## 引用技能

- `agents/skills/perception/edge-inference/`
- `agents/skills/ros2-debug/`

## 增量学习策略

| 方法 | 说明 |
|------|------|
| Rehearsal | 保留旧样本子集 + 新样本联合训练 |
| Regularization | 蒸馏损失 + 新任务损失 |
| Parameter Isolation | 固定旧任务参数，只更新新参数 |

## 知识蒸馏

```python
# 旧模型 → 新模型蒸馏
loss = alpha * CE(logits_new, labels) + (1-alpha) * KL(logits_new, logits_old)
```

## ROS2 集成

```python
class IncrementalLearner(Node):
    def __init__(self):
        super().__init__('incremental_learner')
        self.model = load_model()
        self.sub = self.create_subscription(Detection, '/detections', self.update)

    def update(self, msg):
        # 增量更新
        self.model.incremental_fit(msg.boxes, msg.labels)
```

## 禁止

- ❌ 不做知识蒸馏直接训练（灾难性遗忘）
- ❌ 增量更新不验证旧类别准确率
