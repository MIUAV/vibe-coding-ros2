---
name: kinematics
description: 运动学技能 - 正逆运动学、雅可比矩阵、轨迹运动学、奇异姿态
argument-hint: "运动学" / "kinematics" / "逆运动学" / "雅可比" / "IK"
user-invocable: true
---

# 运动学技能

> 机器人运动学：正运动学、逆运动学、雅可比矩阵、奇异姿态分析

---

## 何时使用

- 求解机械臂末端位姿（正运动学）
- 已知末端位姿，求关节角度（逆运动学）
- 速度级逆运动学（雅可比矩阵）
- 奇异姿态检测与处理
- 冗余机械臂求解

---

## 正运动学（Forward Kinematics）

### DH 参数法（标准机械臂）

```cpp
// dh_kinematics.cpp — 标准 DH 参数正运动学
#include <Eigen/Dense>

struct DHParams {
  double a;   // 连杆长度
  double alpha; // 连杆偏角
  double d;    // 连杆偏移
  double theta; // 关节角
};

class ForwardKinematics {
public:
  // DH 参数 → 齐次变换矩阵
  Eigen::Matrix4d dh_to_transform(const DHParams& dh) {
    double ct = std::cos(dh.theta);
    double st = std::sin(dh.theta);
    double ca = std::cos(dh.alpha);
    double sa = std::sin(dh.alpha);

    Eigen::Matrix4d T;
    T << ct, -st*ca,  st*sa, dh.a*ct,
         st,  ct*ca, -ct*sa, dh.a*st,
        0.0,     sa,     ca,    dh.d,
        0.0,    0.0,    0.0,   1.0;
    return T;
  }

  // 计算末端执行器位姿
  Eigen::Matrix4d compute_pose(const std::vector<DHParams>& dh_chain) {
    Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
    for (const auto& dh : dh_chain) {
      T = T * dh_to_transform(dh);
    }
    return T;  // 4x4 齐次变换矩阵
  }
};
```

### 通用（已知 URDF）

```cpp
// urdf_kinematics.cpp — 从 URDF 计算正运动学
#include <kdl_parser/kdl_parser.hpp>
#include <kdl/chainfksolverpos_recursive.hpp>

class UrdfKinematics : public rclcpp::Node {
public:
  UrdfKinematics() : Node("urdf_kinematics") {
    // 从参数服务器加载 URDF
    this->declare_parameter("robot_description", "");
    std::string robot_desc;
    this->get_parameter("robot_description", robot_desc);

    KDL::Tree tree;
    if (!kdl_parser::treeFromString(robot_desc, tree)) {
      RCLCPP_ERROR(this->get_logger(), "Failed to parse URDF");
      return;
    }

    // 获取机械臂链（base → tip）
    tree.getChain("base_link", "tool0", kdl_chain_);

    // 创建正运动学求解器
    fk_solver_ = std::make_unique<KDL::ChainFkSolverPos_recursive>(kdl_chain_);

    RCLCPP_INFO(this->get_logger(), "FK solver initialized for %zu joints", kdl_chain_.getNrOfJoints());
  }

  // 计算正运动学
  KDL::Frame compute_fk(const std::vector<double>& q) {
    KDL::JntArray jnt_pos(kdl_chain_.getNrOfJoints());
    for (size_t i = 0; i < q.size(); ++i) jnt_pos(i) = q[i];

    KDL::Frame pose;
    fk_solver_->JntToCart(jnt_pos, pose);
    return pose;
  }

private:
  KDL::Chain kdl_chain_;
  std::unique_ptr<KDL::ChainFkSolverPos_recursive> fk_solver_;
};
```

---

## 逆运动学（Inverse Kinematics）

### 解析法（6DOF 机械臂）

```cpp
// analytical_ik.cpp — 6DOF 机械臂解析 IK
class AnalyticalIK {
public:
  // 工业 6DOF 机械臂（如 XArm）解析 IK
  // 返回 8 组解，取最近解
  std::vector<std::array<double, 6>> solve(const Eigen::Matrix4d& T) {
    std::vector<std::array<double, 6>> solutions;

    // 提取末端位姿
    Eigen::Vector3d p = T.block<3,1>(0,3);
    Eigen::Matrix3d R = T.block<3,3>(0,0);

    // 1. 求解 J1（基座旋转）
    double j1 = std::atan2(p(1), p(0));

    // 2. 求解 J2, J3（肩部和肘部）
    // ... 解析几何求解（见 MoveIt IKFast）

    solutions.push_back({j1, j2, j3, j4, j5, j6});
    return solutions;
  }

  // 选择最近解
  std::array<double, 6> choose_nearest(const std::vector<std::array<double,6>>& sols,
                                        const std::array<double,6>& q_current) {
    double min_dist = INFINITY;
    std::array<double,6> best;
    for (const auto& sol : sols) {
      double dist = 0;
      for (int i = 0; i < 6; ++i) dist += std::abs(sol[i] - q_current[i]);
      if (dist < min_dist) { min_dist = dist; best = sol; }
    }
    return best;
  }
};
```

### 数值法（KDL）

```cpp
// numerical_ik.cpp — KDL 数值 IK
#include <kdl/chainiksolverpos_lma.hpp>

class NumericalIK : public rclcpp::Node {
public:
  NumericalIK() : Node("numerical_ik") {
    // ... (加载 URDF 同上)

    ik_solver_ = std::make_unique<KDL::ChainIkSolverPos_LMA>(kdl_chain_);
  }

  std::vector<double> solve(const Eigen::Matrix4d& target_pose) {
    KDL::Frame frame;
    // Eigen → KDL
    frame.p = {target_pose(0,3), target_pose(1,3), target_pose(2,3)};
    frame.M = KDL::Rotation(target_pose(0,0), target_pose(1,0), target_pose(2,0),
                           target_pose(0,1), target_pose(1,1), target_pose(2,1),
                           target_pose(0,2), target_pose(1,2), target_pose(2,2));

    KDL::JntArray q_init(kdl_chain_.getNrOfJoints());
    KDL::JntArray q_out(kdl_chain_.getNrOfJoints());

    // 最大 100 次迭代，精度 1e-6m
    int ret = ik_solver_->CartToJnt(q_init, frame, q_out);

    if (ret >= 0) {
      std::vector<double> result;
      for (int i = 0; i < q_out.rows(); ++i) result.push_back(q_out(i));
      return result;
    }
    return {};  // IK 求解失败
  }

private:
  std::unique_ptr<KDL::ChainIkSolverPos_LMA> ik_solver_;
};
```

---

## 雅可比矩阵（Jacobian）

```cpp
// jacobian.cpp — 几何雅可比计算
class JacobianCalculator {
public:
  // 计算末端执行器的几何雅可比
  Eigen::MatrixXd compute_jacobian(const KDL::Chain& chain,
                                    const KDL::JntArray& q) {
    int nj = chain.getNrOfJoints();
    Eigen::MatrixXd J(6, nj);  // 6×n: linear(3) + angular(3)

    // 末端执行器位置
    KDL::Frame T_end;
    KDL::ChainFkSolverPos_recursive fk(chain);
    fk.JntToCart(q, T_end);
    Eigen::Vector3d p_end = {T_end.p.x(), T_end.p.y(), T_end.p.z()};

    for (int i = 0; i < nj; ++i) {
      // 关节轴（旋转关节 = 旋转轴；移动关节 = 移动方向）
      KDL::Vector axis = chain.getSegment(i).getSegment().Joint().JointAxis();

      // 雅可比列向量
      if (chain.getSegment(i).getSegment().Joint().getType() == KDL::Joint::RotAxis) {
        // 旋转关节
        J.block<3,1>(0,i) = axis.Cross(p_end - chain.getSegment(i).getSegment().pose(q).p);
        J.block<3,1>(3,i) = axis;
      } else {
        // 移动关节
        J.block<3,1>(0,i) = axis;
        J.block<3,1>(3,i) = Eigen::Vector3d::Zero();
      }
    }
    return J;
  }

  // 速度级逆运动学
  Eigen::VectorXd ik_velocity(const Eigen::MatrixXd& J,
                               const Eigen::::Vector6d& twist) {
    // 伪逆：q_dot = J^+ * twist
    // 阻尼最小二乘（DLS）
    double lambda = 0.01;  // 阻尼因子
    Eigen::MatrixXd J_inv = J.transpose() * (J * J.transpose() + lambda*lambda * Eigen::Matrix6d::Identity()).inverse();
    return J_inv * twist;
  }
};
```

---

## 奇异姿态检测

```cpp
// singularity.cpp — 奇异姿态检测与处理
class SingularityHandler {
public:
  // 计算可操作性度量（基于雅可比条件数）
  double manipulability(const Eigen::MatrixXd& J) {
    return std::sqrt((J * J.transpose()).determinant());
  }

  // 检测是否接近奇异姿态
  bool is_near_singularity(const Eigen::MatrixXd& J, double threshold = 0.01) {
    double m = manipulability(J);
    return m < threshold;
  }

  // 奇异姿态处理：阻尼
  Eigen::VectorXd damped_ik(const Eigen::MatrixXd& J,
                           const Eigen::Vector6d& desired_twist,
                           double lambda = 0.05) {
    Eigen::MatrixXd JJT = J * J.transpose();
    Eigen::MatrixXd J_damped = JJT + lambda * lambda * Eigen::Matrix6d::Identity();
    return J.transpose() * J_damped.inverse() * desired_twist;
  }
};
```

---

## 关节限位检查

```cpp
// joint_limits.cpp — 关节限位检查
struct JointLimits {
  std::vector<double> min;
  std::vector<double> max;
  std::vector<double> max_velocity;
  std::vector<double> max_acceleration;
};

bool check_limits(std::vector<double>& q,
                 const JointLimits& limits) {
  bool valid = true;
  for (size_t i = 0; i < q.size(); ++i) {
    if (i < limits.min.size()) {
      if (q[i] < limits.min[i]) { q[i] = limits.min[i]; valid = false; }
      if (q[i] > limits.max[i]) { q[i] = limits.max[i]; valid = false; }
    }
  }
  return valid;  // false = 被限位截断
}
```

---

## 性能指标

| 指标 | 目标 | 说明 |
|------|------|------|
| FK 求解时间 | < 1ms | 实时控制需要 |
| IK 求解时间（解析） | < 5ms | 6DOF 工业机械臂 |
| IK 求解时间（数值） | < 20ms | 冗余机械臂 |
| 奇异值阈值 | > 0.01 | manipulability |
| 关节限位余量 | > 5° | 避免物理限位 |
