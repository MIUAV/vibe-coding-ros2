# Motion Control Task Context

## 控制范式
| 范式 | 说明 | 典型场景 |
|------|------|---------|
| PID 控制 | 最简单，最常用 | 位置/速度环 |
| MPC | 模型预测，最优控制 | 轨迹跟踪 |
| WBC | 全身协调控制 | 人形/冗余机械臂 |
| 阻抗控制 | 力控柔顺 | 接触任务 |
| 自适应控制 | 参数不确定系统 | |

## 控制频率要求
| 应用 | 周期 | 频率 |
|------|------|------|
| 机械臂关节控制 | 1ms | 1 kHz |
| 机械臂末端控制 | 10ms | 100 Hz |
| 移动机器人 | 20ms | 50 Hz |
| 无人机 | 2.5-5ms | 200-400 Hz |

## 关键依赖
```cpp
// 关节轨迹跟踪
#include <control_msgs/action/joint_trajectory.hpp>
#include <trajectory_msgs/msg/joint_trajectory_point.hpp>

// 力/位置混合
#include <geometry_msgs/msg/wrench_stamped.hpp>

// 欧拉角/四元数
#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>
```

## 逆运动学
```cpp
// KDL 逆运动学
#include <kdl/chainiksolvervel_pinv.hpp>
KDL::Chain chain;
KDL::JntArray q_out(6);
KDL::Frame F_out;
chain_ik.reset(new KDL::ChainIkSolverPos_LMA(chain));

// Cartesian 求解
int ret = chain_ik->CartToJnt(q_init, F_desired, q_out);
```

## 轨迹生成
```cpp
// 梯形速度曲线（TrapVelProfile）
KDL::VelocityProfile_Trap trap(max_vel, max_accel);
trap.SetProfileDuration(start_q, end_q, duration);

// S 曲线（无人机平滑轨迹）
trap.ChangeMaxVel(max_vel);
trap.ChangeMaxAcc(accel);
while (!trap.ProfileDone()) {
    trap.ProfilePos(); // 获取当前位置
}
```

## 生成器选择
- `ros2-control-node-generator.sh` — DiffDrive / JointTrajectory / ForcePosition
- `ros2-moveit-generator.sh` — cartesian / joint_space
- `ros2-rl-controller-generator.sh` — DDPG / PPO / SAC
