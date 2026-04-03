---
name: soft-body-simulation
description: 软体仿真技能 - MuJoCo/Isaac Gym 软体物理、绳索/布料/软体抓取、仿真训练迁移
argument-hint: 软体仿真 OR soft body OR 绳索仿真 OR 布料仿真 OR MuJoCo
user-invocable: true
---

# 软体仿真技能

> 用于实现软体物理仿真，涵盖绳索、布料、软体抓取和仿真-现实迁移（Sim2Real）

---

## 何时使用

当需要以下帮助时使用此技能：
- 仿真绳索、布料、果冻等软体
- 软体机器人抓取和操作
- MuJoCo/Isaac Gym 软体环境配置
- Sim2Real 迁移（domain randomization）

---

## 快速参考

### 软体类型

```
软体仿真:
├── 绳索 (Rope/Cable) → 1D柔性，细长物体
├── 布料 (Cloth/Sheet) → 2D柔性，平坦软体
├── 颗粒 (Granular) → 沙子、粉末
├── 体积软体 (Volumetric) → 果冻、海绵
└── 混合刚软 (Hybrid) → 刚体+软体组合
```

### 仿真器支持

```bash
# MuJoCo（最推荐）
pip install mujoco

# Isaac Gym（GPU加速）
pip install isaacgymenvs

# PyBullet
pip install pybullet
```

---

## MuJoCo 绳索仿真

### 绳索建模

```python
import mujoco
import mujoco.viewer as viewer
import numpy as np


class RopeSimulator:
    """MuJoCo 绳索仿真"""

    def __init__(self, num_segments: int = 20, rope_length: float = 1.0):
        self.n = num_segments
        self.dt = 0.002

        # 创建模型
        self.model = self._build_model(num_segments, rope_length)
        self.data = mujoco.MjData(self.model)

        # 渲染器
        self.viewer = None

    def _build_model(self, n: int, length: float) -> mujoco.Model:
        """构建绳索 MuJoCo 模型"""
        segment_length = length / n

        # 球体几何体
        geom_radius = 0.01

        xml = f"""
        <mujoco model="rope">
          <option timestep="{self.dt}" iterations="50" tolerance="1e-10">
            <flag contact="enable" energy="enable"/>
          </option>

          <worldbody>
            <!-- 固定端（世界坐标） -->
            <light diffuse=".5 .5 .5" pos="0 0 3" dir="0 0 -1"/>

            <!-- 绳索段 -->
            <body name="seg0" pos="0 0 2">
              <freejoint/>
              <geom type="sphere" size="{geom_radius}" friction="0.5"/>
            </body>
        """

        # 添加剩余段
        for i in range(1, n):
            xml += f"""
            <body name="seg{i}" pos="{i * segment_length} 0 2">
              <freejoint/>
              <geom type="sphere" size="{geom_radius}" friction="0.5"/>
            </body>
            """

        # 使用 weld 约束连接相邻段
        for i in range(n - 1):
            xml += f"""
            <tendon>
              <fixed name="tendon{i}" stiffness="1000" damping="1">
                <joint joint="seg{i}_freejoint" coef1="1.0" coef2="-1.0"/>
              </fixed>
            </tendon>
            """

        xml += """
          </worldbody>
        </mujoco>
        """
        return mujoco.from_xml_string(xml)

    def simulate(self, num_steps: int = 1000):
        """运行仿真"""
        with viewer.launch_passive(self.model, self.data) as v:
            for _ in range(num_steps):
                mujoco.mj_step(self.model, self.data)
                v.sync()

    def apply_force(self, segment_id: int, force: np.ndarray):
        """对指定段施加力"""
        self.data.xfrc_applied[segment_id + 1, :3] = force

    def get_end_effector_position(self) -> np.ndarray:
        """获取末端位置"""
        return self.data.body('seg{}'.format(self.n - 1)).xpos.copy()


class RopeManipulator:
    """绳索操作控制器"""

    def __init__(self, rope_sim: RopeSimulator):
        self.rope = rope_sim
        self.Kp = 5.0
        self.Kd = 2.0

    def position_control(
        self,
        target: np.ndarray,
        max_segments_to_move: int = 5
    ) -> np.ndarray:
        """
        末端位置控制

        Returns: 各段控制力
        """
        current_end = self.rope.get_end_effector_position()
        error = target - current_end

        # 计算控制力
        desired_velocity = self.Kp * error
        current_velocity = self.rope.data.qvel[-3:]

        # 只对前 max_segments_to_move 个段施加控制
        forces = np.zeros(self.rope.n * 6)
        for i in range(max_segments_to_move):
            forces[i * 6:(i + 1) * 6] = (
                self.Kp * error - self.Kd * current_velocity
            ) / max_segments_to_move

        return forces


class CableRoutingEnv:
    """电缆布线环境"""

    def __init__(self):
        self.rope = RopeSimulator(num_segments=30, rope_length=1.5)
        self.obstacles = []  # [(position, radius)]

        # 奖励参数
        self.reach_threshold = 0.02
        self.collision_penalty = -1.0
        self.success_reward = 10.0

    def reset(self) -> np.ndarray:
        """重置环境"""
        mujoco.mj_resetModel(self.rope.model, self.rope.data)
        return self.rope.data.qpos.copy()

    def step(self, action: np.ndarray) -> tuple:
        """
        执行动作

        Args:
            action: 控制命令

        Returns:
            (next_state, reward, done, info)
        """
        # 应用动作
        for i in range(len(action)):
            self.rope.data.ctrl[i] = action[i]

        # 仿真一步
        mujoco.mj_step(self.rope.model, self.rope.data)

        # 计算奖励
        end_pos = self.rope.get_end_effector_position()
        goal_pos = np.array([0.5, 0.0, 1.0])

        dist_to_goal = np.linalg.norm(end_pos - goal_pos)
        reward = -dist_to_goal

        # 检查是否成功
        done = dist_to_goal < self.reach_threshold
        if done:
            reward += self.success_reward

        return self.rope.data.qpos.copy(), reward, done, {}

    def render(self):
        """渲染"""
        with viewer.launch_passive(self.rope.model, self.rope.data) as v:
            v.sync()
```

---

## MuJoCo 布料仿真

### 布料建模

```python
class ClothSimulator:
    """布料仿真"""

    def __init__(self, width: int = 10, height: int = 10, cloth_size: float = 0.5):
        self.width = width
        self.height = height
        self.size = cloth_size
        self.cell_size = cloth_size / width

        self.model = self._build_model(width, height, cloth_size)
        self.data = mujoco.MjData(self.model)

    def _build_model(self, w: int, h: int, size: float) -> mujoco.Model:
        """构建布料 MuJoCo 模型"""
        cell = size / w
        h = size / h

        # 生成格子顶点
        n = (w + 1) * (h + 1)
        points = []
        faces = []

        for i in range(h + 1):
            for j in range(w + 1):
                points.append([j * cell, i * h, 2.0])

        # 生成三角形面
        for i in range(h):
            for j in range(w):
                v0 = i * (w + 1) + j
                v1 = v0 + 1
                v2 = v0 + w + 1
                v3 = v2 + 1
                faces.extend([v0, v1, v2, v1, v3, v2])

        geom_ids = list(range(n))

        xml = f"""
        <mujoco model="cloth">
          <option timestep="0.001"/>

          <worldbody>
            <light diffuse=".7 .7 .7" pos="0 0 3"/>
            <body>
              <!-- 布料顶点 -->
              <geom type="mesh" vertex="{n}"
                    face="{len(faces)}"
                    pos="0 0 2"
                    friction="0.5"
                    density="100"
                    solref="0.005 1"
                    solimp="0.9 0.5 0.01"/>
            </body>

            <!-- 地面 -->
            <geom type="plane" pos="0 0 0" size="2 2"/>
          </worldbody>
        </mujoco>
        """
        return mujoco.from_xml_string(xml)


class ClothGraspEnv:
    """布料抓取环境"""

    def __init__(self):
        self.cloth = ClothSimulator(width=10, height=10, cloth_size=0.3)
        self.grasper_pos = np.array([0.15, 0.15, 0.5])
        self.grasp_closed = False

    def step(self, action: np.ndarray) -> tuple:
        """
        action: [delta_x, delta_y, delta_z, grasp]
        """
        # 解析动作
        delta = action[:3] * 0.1  # 缩放
        grasp = action[3]

        # 更新夹爪位置
        self.grasper_pos += delta

        # 抓取逻辑
        if grasp > 0 and not self.grasp_closed:
            # 执行抓取：抓起布料顶点
            self._execute_grasp()

        # 仿真
        mujoco.mj_step(self.cloth.model, self.cloth.data)

        # 计算奖励
        cloth_center = self.cloth.data.geom_xpos[0]  # 布料中心
        reward = -np.linalg.norm(self.grasper_pos[:2] - cloth_center[:2])

        done = False
        return self._get_obs(), reward, done, {}

    def _execute_grasp(self):
        """执行抓取"""
        # 找到夹爪下方的布料顶点
        closest_vert = self._find_closest_vert(self.grasper_pos)
        # 应用抓取力
        self.grasp_closed = True

    def _find_closest_vert(self, pos: np.ndarray) -> int:
        """找最近的布料顶点"""
        # 简化实现
        return 0

    def _get_obs(self) -> np.ndarray:
        return np.concatenate([
            self.grasper_pos,
            self.cloth.data.qpos.copy(),
        ])
```

---

## Isaac Gym 软体环境

### Isaac Gym 配置

```python
import isaacgym
import isaacgym.gymapi as gym_api
import isaacgym.gymutil as gymutil


class IsaacGymSoftBody:
    """Isaac Gym 软体环境"""

    def __init__(self, num_envs: int = 256):
        self.gym = gym_api.acquire_gym()
        self.num_envs = num_envs

        # 创建仿真
        sim_params = gym_api.SimParams()
        sim_params.dt = 1.0 / 60.0
        sim_params.substeps = 2
        sim_params.up_axis = gym_api.UP_AXIS_Z
        sim_params.gravity = gym_api.Vec3(0.0, 0.0, -9.81)

        self.sim = self.gym.create_sim(
            compute_device=0,
            graphics_device=0,
            type=gym_api.SIM_PHY_SIM,
            params=sim_params
        )

        # 创建环境
        self.envs = []
        self.actors = []

        for i in range(num_envs):
            env = self.gym.create_env(
                self.sim,
                lower=gym_api.Vec3(-0.5, -0.5, 0),
                upper=gym_api.Vec3(0.5, 0.5, 1.0)
            )
            self.envs.append(env)

            # 创建软体
            self._create_soft_body(env, i)

    def _create_soft_body(self, env, idx: int):
        """创建软体"""
        # 简化：使用弹性体
        actor = self.gym.create_actor(
            env,
            self._get_soft_body_asset(),
            gym_api.Transform(),
            "soft_{}".format(idx),
            idx
        )

        # 软体质感
        props = self.gym.get_actor_shape_properties(env, actor)
        props[0].compliance = 0.001  # 柔顺度
        props[0].friction = 0.5
        self.gym.set_actor_shape_properties(env, actor, props)

        self.actors.append(actor)

    def _get_soft_body_asset(self):
        """获取软体资产"""
        # 实际使用中加载 SDF 或 URDF
        pass

    def reset(self):
        """重置所有环境"""
        for env in self.envs:
            self.gym.reset_actor_states(env)

    def step(self, actions: np.ndarray):
        """批量执行"""
        for i, env in enumerate(self.envs):
            self.gym.set_actor_dof_actuation(env, self.actors[i], actions[i])
        self.gym.simulate(self.sim)
        self.gym.fetch_results(self.sim, True)
```

---

## Sim2Real 迁移

### Domain Randomization

```python
import numpy as np


class DomainRandomizer:
    """Sim2Real 域随机化"""

    def __init__(self):
        # 可随机化的参数范围
        self.param_ranges = {
            # 物理参数
            'gravity': (-10.0, -9.81),           # 重力加速度
            'friction': (0.3, 0.8),              # 摩擦系数
            'softness': (0.8, 1.2),              # 软体刚度

            # 视觉参数
            'light_intensity': (0.7, 1.3),        # 光照强度
            'camera_noise': (0.0, 0.05),          # 相机噪声

            # 控制器参数
            'Kp': (0.8, 1.2),                    # 增益随机化
            'Kd': (0.8, 1.2),
        }

    def randomize(self) -> dict:
        """随机采样参数"""
        params = {}
        for name, (low, high) in self.param_ranges.items():
            params[name] = np.random.uniform(low, high)
        return params

    def apply_to_sim(self, sim, params: dict):
        """应用到仿真器"""
        if 'gravity' in params:
            sim.params.gravity.z = params['gravity']
        if 'friction' in params:
            for geom in sim.model.geom_friction:
                geom[:2] = params['friction']


class AdaptiveController:
    """Sim2Real 自适应控制器"""

    def __init__(self, sim_model, real_model):
        self.sim = sim_model
        self.real = real_model

        # 在线适应
        self.error_history = []
        self.max_history = 100

    def adapt(
        self,
        sim_state: np.ndarray,
        real_state: np.ndarray,
        K: np.ndarray
    ) -> np.ndarray:
        """
        自适应调整控制器增益

        Returns: 调整后的增益
        """
        # 状态误差
        error = real_state - sim_state

        # 记录历史
        self.error_history.append(np.linalg.norm(error))
        if len(self.error_history) > self.max_history:
            self.error_history.pop(0)

        # 如果 sim 和 real 误差增大，调整增益
        recent_error = np.mean(self.error_history[-20:])

        if recent_error > 0.1:  # 阈值
            # 减小增益（降低 sim 依赖）
            K_adapted = K * 0.9
        else:
            K_adapted = K

        return K_adapted
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 绳索断裂/不稳定 | 子步长太大 | 减小 timestep，增加 iterations |
| 布料穿透自身 | 碰撞参数不当 | 减小 geom size，增加 solimp |
| 仿真太慢 | 粒子数太多 | 减少段数/顶点数 |
| 抓取滑落 | 摩擦力不足 | 增加 friction，或改用夹爪 |
| Sim2Real 迁移失败 | sim 太理想化 | 添加 domain randomization |

### 调试命令

```bash
# MuJoCo 可视化
python -m mujoco.viewer --model=rope.xml

# Isaac Gym 测试
python -m isaacgym.gymutil --help

# 导出仿真数据
python export_sim_data.py --output=cloth_trajectory.npz
```

---

## 相关技能

- `simulator/mujoco/mujoco-modeling` — MuJoCo 模型创建
- `manipulator/grasp-planning` — 抓取规划
- `manipulator/impedance-control` — 柔顺控制
- `simulator/isaaclab/rl-training` — RL 训练
- `robotics-learning/transfer-learning` — 迁移学习
