# biped-walk SKILL — 双足步行控制指南

---

## 核心规则

1. **ZMP 必须在支撑多边形内**：稳定性第一
2. **步行周期固定**：单脚支撑 + 双脚支撑 = T_total
3. **质心（CoM）轨迹用五次多项式插值**：避免突变
4. **摆动腿高度 ≥ 0.1m**：防止脚拖地

---

## 知识库

### ZMP 计算

```python
def compute_zmp(foot_positions, cop_positions):
    """计算 ZMP 位置，判断是否在支撑多边形内"""
    # ZMP = Σ(Fi × ri) / Σ(Fi)
    # 如果 ZMP.x ∈ [min(foot.x), max(foot.x)] 且 ZMP.y ∈ [min(foot.y), max(foot.y)]
    # 则稳定
    pass
```

### 步态周期调度

```python
GAIT_PARAMS = {
    "step_length": 0.3,      # m
    "step_height": 0.15,     # m
    "period": 1.2,           # s
    "single_support": 0.8,   # s
    "double_support": 0.4,  # s
}
```

### CoM 轨迹（五次多项式）

```python
from scipy.interpolate import CubicHermite

def com_trajectory(start, end, t_total):
    """生成平滑 CoM 轨迹（五次多项式）"""
    t = np.linspace(0, t_total, 100)
    # 使用 hermite 插值确保位置、速度、加速度连续
    pass
```

---

## 快速启动

```bash
bash scripts/generators/ros2-package-generator.sh biped_walk python
# 编写步行控制节点
bash scripts/ros2-build-verify-loop.sh biped_walk
```
