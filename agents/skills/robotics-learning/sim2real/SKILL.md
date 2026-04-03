---
name: sim2real
description: Sim2Real 迁移技能 - 域随机化、域适应、系统识别、现实差距弥合、ROS2 部署
argument-hint: Sim2Real OR 域随机化 OR domain randomization OR sim-to-real OR 迁移
user-invocable: true
---

# Sim2Real 迁移技能

> 用于缩小仿真与现实之间差距的技能，涵盖域随机化、域适应、系统识别和现实部署

---

## 何时使用

当需要以下帮助时使用此技能：
- 在仿真中训练，在现实机器人上部署
- 配置域随机化参数
- 补偿物理参数差异
- 在线适应现实环境
- 减少 sim-to-real 迁移的性能下降

---

## 快速参考

### Sim2Real 挑战

```
现实差距主要来源:
├── 视觉差异 → 纹理、光照、噪声
├── 物理差异 → 摩擦、延迟、关节柔性
├── 传感器差异 → 噪声、漂移、校准
└── 控制差异 → 采样延迟、执行机构非线性
```

### 核心策略

```
1. 域随机化 (Domain Randomization)
   → 在仿真中随机化所有参数，强制策略对随机化鲁棒
   
2. 域适应 (Domain Adaptation)
   → 学习 domain-invariant 特征
   
3. 系统识别 (System Identification)
   → 精确测量现实机器人参数
   
4. 在线适应 (Online Adaptation)
   → 部署后持续调整策略
```

---

## 域随机化 (Domain Randomization)

### RGB 图像域随机化

```python
import numpy as np
from dataclasses import dataclass
from typing import Tuple, List
import cv2


@dataclass
class VisualRandomizationConfig:
    """视觉域随机化配置"""
    # 光照
    light_intensity_range: Tuple[float, float] = (0.5, 1.5)
    light_position_range: Tuple[float, float] = (-1.0, 1.0)

    # 纹理
    texture_noise_std: float = 0.02
    texture_patterns: List[str] = None  # 可选背景图案

    # 相机
    camera_noise_std: float = 0.01
    camera_resolution: Tuple[int, int] = (640, 480)
    distortion_k: Tuple[float, float] = (0.0, 0.01)

    # 物体颜色
    obj_color_hsv_range: Tuple = ((0, 150, 150), (180, 255, 255))


class VisualDomainRandomizer:
    """视觉域随机化"""

    def __init__(self, config: VisualRandomizationConfig):
        self.cfg = config

    def randomize_image(self, image: np.ndarray) -> np.ndarray:
        """对图像应用随机化"""
        img = image.copy()

        # 1. 亮度/对比度随机
        alpha = np.random.uniform(*self.cfg.light_intensity_range)
        img = cv2.convertScaleAbs(img, alpha=alpha, beta=0)

        # 2. 添加噪声
        noise = np.random.randn(*img.shape) * self.cfg.texture_noise_std * 255
        img = np.clip(img + noise, 0, 255).astype(np.uint8)

        # 3. 模糊（模拟对焦不准）
        if np.random.rand() < 0.2:
            ksize = np.random.choice([3, 5, 7])
            img = cv2.GaussianBlur(img, (ksize, ksize), 0)

        # 4. 模拟相机畸变
        if np.random.rand() < 0.3:
            k1, k2 = np.random.uniform(*self.cfg.distortion_k, 2)
            img = self._apply_distortion(img, k1, k2)

        return img

    def _apply_distortion(self, img, k1, k2) -> np.ndarray:
        """应用桶形/枕形畸变"""
        h, w = img.shape[:2]
        k = np.random.randn(6) * 0.001

        # 生成畸变映射
        map_x = np.zeros((h, w), dtype=np.float32)
        map_y = np.zeros((h, w), dtype=np.float32)

        cx, cy = w / 2, h / 2
        for y in range(h):
            for x in range(w):
                dx = (x - cx) / cx
                dy = (y - cy) / cy
                r2 = dx**2 + dy**2
                distortion = 1 + k1 * r2 + k2 * r2**2
                map_x[y, x] = cx + distortion * (x - cx)
                map_y[y, x] = cy + distortion * (y - cy)

        return cv2.remap(img, map_x, map_y, cv2.INTER_LINEAR)


class TextureRandomizer:
    """背景纹理随机化"""

    def __init__(self, texture_dir: str = None):
        self.textures = self._load_textures(texture_dir) if texture_dir else []

        # 默认图案
        self.default_patterns = [
            self._checkerboard,
            self._stripes,
            self._noise,
        ]

    def apply_random_texture(self, image: np.ndarray) -> np.ndarray:
        """应用随机背景纹理"""
        if not self.textures and not self.default_patterns:
            return image

        h, w = image.shape[:2]

        if self.textures and np.random.rand() < 0.3:
            # 使用真实纹理图像
            tex = np.random.choice(self.textures)
            tex = cv2.resize(tex, (w, h))
            return cv2.addWeighted(image, 0.7, tex, 0.3, 0)
        else:
            # 使用程序生成图案
            pattern = np.random.choice(self.default_patterns)
            bg = pattern(h, w)
            return cv2.addWeighted(image, 0.8, bg, 0.2, 0)

    def _checkerboard(self, h, w):
        size = np.random.randint(20, 80)
        board = np.indices((h, w))
        pattern = ((board[0] // size) + (board[1] // size)) % 2
        bg = (pattern * 255).astype(np.uint8)
        return cv2.cvtColor(bg, cv2.COLOR_GRAY2BGR)

    def _stripes(self, h, w):
        angle = np.random.uniform(0, 180)
        lines = h // np.random.randint(10, 50)
        bg = np.zeros((h, w), dtype=np.uint8)
        for i in range(0, h + w, lines):
            cv2.line(bg, (i, 0), (i - h, h), 255, 2)
        return cv2.cvtColor(bg, cv2.COLOR_GRAY2BGR)

    def _noise(self, h, w):
        bg = np.random.randint(100, 200, (h, w), dtype=np.uint8)
        return cv2.cvtColor(bg, cv2.COLOR_GRAY2BGR)
```

---

## 物理域随机化

### MuJoCo 物理参数随机化

```python
import numpy as np
import mujoco


class PhysicsDomainRandomizer:
    """物理域随机化"""

    def __init__(self, model: mujoco.Model):
        self.model = model

        # 参数范围（百分比）
        self.param_ranges = {
            # 摩擦系数
            'friction': (0.5, 1.5),         # 0.5x ~ 1.5x
            # 质量
            'mass': (0.8, 1.2),             # 0.8x ~ 1.2x
            # 关节阻尼
            'damping': (0.5, 2.0),           # 0.5x ~ 2.0x
            # 刚度
            'stiffness': (0.8, 1.2),       # 0.8x ~ 1.2x
            # 控制延迟 (模拟通信延迟)
            'control_delay': (0.0, 0.02),   # 0 ~ 20ms
            # 执行器增益
            'actuator_gain': (0.9, 1.1),   # ±10%
        }

    def randomize(self) -> dict:
        """随机采样物理参数，返回修改后的模型"""
        params = {}

        # 摩擦
        if 'friction' in self.param_ranges:
            r = self.param_ranges['friction']
            factor = np.random.uniform(*r)
            params['friction'] = factor
            for i in range(self.model.njnt):
                if self.model.jnt_type[i] == mujoco.mjtJoint.mjJNT_HINGE:
                    self.model.dof_frictionloss[i] *= factor

        # 质量
        if 'mass' in self.param_ranges:
            r = self.param_ranges['mass']
            factor = np.random.uniform(*r)
            params['mass'] = factor
            for i in range(self.model.nbody):
                self.model.body_mass[i] *= factor

        # 阻尼
        if 'damping' in self.param_ranges:
            r = self.param_ranges['damping']
            factor = np.random.uniform(*r)
            params['damping'] = factor
            for i in range(self.model.nv):
                self.model.dof_damping[i] *= factor

        # 执行器增益
        if 'actuator_gain' in self.param_ranges:
            r = self.param_ranges['actuator_gain']
            factor = np.random.uniform(*r)
            params['actuator_gain'] = factor
            for i in range(self.model.nu):
                self.model.actuator_gear[i] *= factor

        return params


class ControlDelaySimulator:
    """控制延迟模拟器"""

    def __init__(self, max_delay_ms: float = 20.0):
        self.max_delay = max_delay_ms / 1000.0  # 转换为秒
        self.delay_buffer = []
        self.last_apply_time = 0.0

    def apply_with_delay(
        self,
        command: np.ndarray,
        current_time: float
    ) -> np.ndarray:
        """
        延迟控制命令

        Args:
            command: 控制命令
            current_time: 当前时间戳

        Returns:
            延迟后的控制命令
        """
        delay = np.random.uniform(0, self.max_delay)
        apply_time = current_time + delay

        # 添加到缓冲区
        self.delay_buffer.append((apply_time, command))

        # 移除已过期（已应用）的条目
        self.delay_buffer = [
            (t, c) for t, c in self.delay_buffer if t <= current_time
        ]

        if not self.delay_buffer:
            return command

        # 返回最旧的命令（模拟 FIFO）
        return self.delay_buffer[0][1]
```

---

## 系统识别 (System Identification)

### 关节摩擦辨识

```python
import numpy as np
from scipy.optimize import minimize


class JointFrictionIdentifier:
    """
    关节摩擦辨识 (Coulomb + Viscous 模型)

    摩擦模型: tau_friction = F_c * sign(v) + F_v * v
    """

    def __init__(self):
        self.friction_params = None

    def collect_data(self, robot, duration: float = 10.0) -> tuple:
        """
        采集恒速测试数据

        Returns:
            (velocities, torques) - 速度和对应力矩
        """
        velocities = []
        torques = []

        # 以不同速度执行恒速运动，记录力矩
        test_speeds = [0.1, 0.2, 0.5, 1.0, 2.0]  # rad/s

        for v in test_speeds:
            robot.set_control_mode('velocity')
            robot.set_velocity_target(v)

            # 等待速度稳定
            time.sleep(2.0)

            # 记录稳态速度和力矩
            for _ in range(100):
                velocities.append(robot.get_velocity())
                torques.append(robot.get_torque())
                time.sleep(0.05)

        return np.array(velocities), np.array(torques)

    def fit_friction_model(
        self,
        velocities: np.ndarray,
        torques: np.ndarray
    ) -> dict:
        """
        拟合摩擦参数

        Args:
            velocities: 速度数据
            torques: 力矩数据

        Returns:
            {'Fc': Coulomb摩擦, 'Fv': 粘性摩擦}
        """
        def friction_model(v, Fc, Fv):
            return Fc * np.sign(v) + Fv * v

        def residual(params):
            Fc, Fv = params
            pred = friction_model(velocities, Fc, Fv)
            return np.sum((torques - pred)**2)

        # 初始猜测
        x0 = [0.5, 0.1]

        # 约束: 所有参数 > 0
        bounds = [(0.01, 5.0), (0.0, 2.0)]

        result = minimize(residual, x0, method='L-BFGS-B', bounds=bounds)
        Fc, Fv = result.x

        self.friction_params = {'Fc': Fc, 'Fv': Fv}
        return self.friction_params


class MotorParameterIdentifier:
    """电机参数辨识 (电流 → 力矩)"""

    def __init__(self):
        self.motor_params = None

    def step_response_analysis(
        self,
        current_commands: np.ndarray,
        position_responses: np.ndarray,
        dt: float
    ) -> dict:
        """
        阶跃响应分析辨识电机参数

        Returns:
            {'Kt': 力矩常数, 'Tm': 机械时间常数, 'Jm': 转动惯量}
        """
        # 简化一阶系统: tau = Kt * I
        # 机械: Jm * d_w/dt = tau - tau_load

        # 从响应曲线提取参数
        Kt_estimate = np.mean(torques / currents)  # 力矩常数

        # 机械时间常数（达到稳态 63% 的时间）
        tau = self._find_time_constant(position_responses, dt)

        self.motor_params = {
            'Kt': Kt_estimate,
            'Tm': tau,
        }
        return self.motor_params
```

---

## 在线适应 (Online Adaptation)

### 潜域适应

```python
import torch
import torch.nn as nn


class LatentDomainAdapter(nn.Module):
    """
    潜空间域适应器

    将现实观察映射到与仿真相同的潜空间
    """

    def __init__(self, state_dim: int, latent_dim: int = 64):
        super().__init__()
        self.state_dim = state_dim
        self.latent_dim = latent_dim

        # 编码器：现实观察 → 潜空间
        self.encoder = nn.Sequential(
            nn.Linear(state_dim, 128),
            nn.ReLU(),
            nn.Linear(128, latent_dim),
            nn.Tanh(),
        )

        # 域分类器：判断来自 sim 还是 real
        self.domain_classifier = nn.Sequential(
            nn.Linear(latent_dim, 32),
            nn.ReLU(),
            nn.Linear(32, 1),  # sigmoid
        )

        # 特征提取器
        self.feature_extractor = nn.Sequential(
            nn.Linear(latent_dim, 128),
            nn.ReLU(),
            nn.Linear(128, state_dim),
        )

    def forward(self, x):
        z = self.encoder(x)
        domain_pred = self.domain_classifier(z)
        return z, domain_pred


class RealTimeAdapter:
    """实时域适应器"""

    def __init__(self, sim_policy, adapter: nn.Module):
        self.sim_policy = sim_policy
        self.adapter = adapter
        self.adapter.eval()

        # 统计信息（EMA 跟踪）
        self.real_mean = None
        self.real_std = None
        self.alpha = 0.99  # EMA 平滑因子

    def adapt(
        self,
        real_observation: np.ndarray,
        action: np.ndarray,
        real_reward: float
    ) -> np.ndarray:
        """
        在线适应：基于现实反馈微调适配器

        Args:
            real_observation: 现实观察
            action: 策略输出的动作
            real_reward: 现实奖励

        Returns:
            调整后的动作
        """
        with torch.no_grad():
            obs_tensor = torch.FloatTensor(real_observation).unsqueeze(0)
            z_real, _ = self.adapter(obs_tensor)

            # 在线更新统计信息
            if self.real_mean is None:
                self.real_mean = real_observation.copy()
                self.real_std = np.ones_like(real_observation)
            else:
                self.real_mean = (
                    self.alpha * self.real_mean +
                    (1 - self.alpha) * real_observation
                )
                self.real_std = (
                    self.alpha * self.real_std +
                    (1 - self.alpha) * (real_observation**2)
                )
                self.real_std = np.sqrt(
                    np.maximum(self.real_std - self.real_mean**2, 1e-6)
                )

            # 归一化
            obs_norm = (real_observation - self.real_mean) / (self.real_std + 1e-8)

            # 用 sim_policy 推理
            sim_obs = torch.FloatTensor(obs_norm).unsqueeze(0)
            sim_action = self.sim_policy(sim_obs)

            return sim_action.numpy()[0]
```

---

## ROS2 Sim2Real 部署

### 仿真到现实的桥接节点

```python
#!/usr/bin/env python3
"""Sim2Real 部署节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, JointState
from std_msgs.msg import Float64MultiArray
import numpy as np
import torch


class Sim2RealDeploymentNode(Node):
    """
    将仿真中训练好的策略部署到现实机器人

    功能:
    1. 接收现实传感器数据
    2. 归一化到仿真域
    3. 策略推理
    4. 反归一化并发送控制命令
    """

    def __init__(self):
        super().__init__('sim2real_deployment')

        # 参数
        self.declare_parameter('policy_model_path', '/path/to/policy.pt')
        self.declare_parameter('obs_mean_path', '/path/to/obs_mean.npy')
        self.declare_parameter('obs_std_path', '/path/to/obs_std.npy')
        self.declare_parameter('action_max', 1.0)

        self.obs_mean = np.load(self.get_parameter('obs_mean_path').value)
        self.obs_std = np.load(self.get_parameter('obs_std_path').value)
        self.action_max = self.get_parameter('action_max').value

        # 加载策略
        self.policy = self._load_policy(
            self.get_parameter('policy_model_path').value
        )
        self.policy.eval()

        # 在线统计
        self.real_obs_buffer = []
        self.alpha = 0.99

        # 订阅
        self.joint_state_sub = self.create_subscription(
            JointState,
            '/joint_states',
            self.joint_callback,
            10
        )

        # 发布
        self.action_pub = self.create_publisher(
            Float64MultiArray,
            '/joint_effort_controller/commands',
            10
        )

        self.timer = self.create_timer(0.01, self.control_loop)  # 100Hz

        self.get_logger().info('Sim2Real Deployment Node ready')

    def joint_callback(self, msg: JointState):
        # 拼接观察
        obs = np.concatenate([
            msg.position[:6] if len(msg.position) >= 6 else msg.position,
            msg.velocity[:6] if len(msg.velocity) >= 6 else msg.velocity,
        ])
        self.real_obs_buffer.append(obs)

    def normalize_observation(self, obs: np.ndarray) -> np.ndarray:
        """归一化到仿真域"""
        return (obs - self.obs_mean) / (self.obs_std + 1e-8)

    def control_loop(self):
        if len(self.real_obs_buffer) == 0:
            return

        obs = self.real_obs_buffer[-1]

        # 在线适应：更新统计（域随机化反效果）
        self._update_online_stats(obs)

        # 归一化
        obs_norm = self.normalize_observation(obs)

        # 策略推理
        with torch.no_grad():
            obs_tensor = torch.FloatTensor(obs_norm).unsqueeze(0)
            action = self.policy(obs_tensor).numpy()[0]

        # 发布
        cmd = Float64MultiArray()
        cmd.data = action.tolist()
        self.action_pub.publish(cmd)

    def _update_online_stats(self, obs: np.ndarray):
        """渐进更新观测统计"""
        if not hasattr(self, 'running_mean'):
            self.running_mean = obs.copy()
            self.running_var = np.ones_like(obs)
            self.count = 1
            return

        self.count += 1
        delta = obs - self.running_mean
        self.running_mean += delta / self.count
        delta2 = obs - self.running_mean
        self.running_var += delta * delta2

        # 限制更新幅度
        adaptation_rate = 0.01
        self.obs_mean = (
            (1 - adaptation_rate) * self.obs_mean +
            adaptation_rate * obs
        )
        self.obs_std = (
            (1 - adaptation_rate) * self.obs_std +
            adaptation_rate * np.abs(obs - self.obs_mean) + 1e-6
        )

    def _load_policy(self, path: str):
        """加载策略网络"""
        # 简化示例，实际使用具体网络架构
        return torch.nn.Linear(12, 6)
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 现实表现远差于仿真 | 随机化不足 | 增大参数范围 |
| 策略完全失效 | 物理参数偏差太大 | 进行系统辨识 |
| 视觉策略不work | 相机参数差异 | 添加相机标定随机化 |
| 策略在现实震荡 | 控制延迟未被模拟 | 添加随机延迟 |
| 在线适应失败 | 统计更新太快 | 减小 adaptation_rate |

### 调试命令

```bash
# 录制现实部署数据
ros2 bag record /joint_states /joint_effort_controller/commands -o sim2real_data

# 分析 sim/real 差异
python analyze_domain_gap.py --sim_data=sim.npz --real_data=real.npz

# 在线绘制观察分布
ros2 run rqt_plot rqt_plot /normalized_observation/data
```

---

## 相关技能

- `robotics-learning/reinforcement-learning` — 强化学习基础
- `simulation/physics-simulation/soft-body-simulation` — 软体仿真
- `manipulator/impedance-control` — 柔顺控制
- `perception/edge-inference/tensorrt-deployment` — 边缘推理部署
- `robotics-learning/transfer-learning` — 迁移学习
