---
name: soft-body-simulation
description: 软体仿真技能 - 有限元、质点弹簧、柔体仿真、Gazebo 软体插件
argument-hint: "软体仿真" / "soft body" / "FEM" / "spring-mass" / "deformable"
user-invocable: true
---

# 软体仿真技能

> 柔体和软体仿真

---

## 何时使用

当需要以下帮助时使用此技能：
- 有限元方法 (FEM)
- 质点弹簧模型
- 柔体仿真
- Gazebo 软体插件
- 变形控制

---

## 核心实现

### 质点弹簧模型

```python
import numpy as np

class MassSpringSystem:
    def __init__(self, num_particles, spring_stiffness=100, damping=0.9):
        self.num_particles = num_particles
        self.stiffness = spring_stiffness
        self.damping = damping
        
        # 状态
        self.positions = np.zeros((num_particles, 3))
        self.velocities = np.zeros((num_particles, 3))
        self.forces = np.zeros((num_particles, 3))
        
        # 弹簧连接
        self.springs = []  # [(i, j, rest_length), ...]
        
    def add_spring(self, i, j, rest_length=None):
        """添加弹簧"""
        if rest_length is None:
            rest_length = np.linalg.norm(
                self.positions[j] - self.positions[i])
        self.springs.append((i, j, rest_length))
        
    def compute_forces(self):
        """计算弹簧力"""
        self.forces = np.zeros_like(self.forces)
        
        for i, j, rest_length in self.springs:
            # 弹簧方向
            delta = self.positions[j] - self.positions[i]
            dist = np.linalg.norm(delta)
            
            if dist < 1e-6:
                continue
                
            direction = delta / dist
            
            # 弹簧力 (Hooke 定律)
            stretch = dist - rest_length
            f = self.stiffness * stretch
            
            # 阻尼力
            rel_vel = self.velocities[j] - self.velocities[i]
            f += self.damping * np.dot(rel_vel, direction)
            
            self.forces[i] += f * direction
            self.forces[j] -= f * direction
            
    def step(self, dt):
        """仿真一步"""
        self.compute_forces()
        
        # 积分 (Verlet)
        for i in range(self.num_particles):
            self.velocities[i] += self.forces[i] * dt
            self.positions[i] += self.velocities[i] * dt
```

### 有限元方法 (简化)

```python
class FEMSimulation:
    def __init__(self, mesh):
        self.mesh = mesh  # 三角形网格
        self.stiffness_matrix = None
        self.mass_matrix = None
        
    def assemble_stiffness_matrix(self, young_modulus, poisson_ratio):
        """组装刚度矩阵"""
        # 简化的 2D 平面应力刚度
        E = young_modulus
        nu = poisson_ratio
        
        D = E / (1 - nu**2) * np.array([
            [1, nu, 0],
            [nu, 1, 0],
            [0, 0, (1-nu)/2]
        ])
        
        # 遍历每个三角形单元
        for element in self.mesh.elements:
            # 计算单元刚度矩阵
            Ke = self.compute_element_stiffness(element, D)
            # 组装到全局刚度矩阵
            # ...
            
    def solve_static(self, boundary_conditions, loads):
        """求解静力学问题"""
        # K * u = F
        # 应用边界条件
        # 求解
        return self.displacements
```

### Gazebo 软体插件

```xml
<!-- Gazebo 软体插件 -->
<plugin name="gazebo_ros_bumper" filename="libgazebo_ros_bumper.so">
  <ros>
    <namespace>/robot</namespace>
    <remapping>bumper_states:=bumper_states</remapping>
  </ros>
  <updateRate>10</updateRate>
</plugin>

<!-- 柔性关节 -->
<joint name="soft_joint" type="revolute">
  <parent>link1</parent>
  <child>soft_link</child>
  <axis>
    <xyz>0 0 1</xyz>
    <limit>
      <effort>10</effort>
    </limit>
    <dynamics>
      <spring_reference>0</spring_reference>
      <spring_stiffness>5</spring_stiffness>
      <damping>0.5</damping>
    </dynamics>
  </axis>
</joint>
```
