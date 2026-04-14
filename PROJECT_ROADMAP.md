# PROJECT_ROADMAP — Vibe-Coding-ROS2

> 项目路线图。当前版本 v0.4.0（2026-04-13 进行中）。

---

## 当前版本: v0.3.x ✅

### 已完成功能

**工具链（Toolchain）**
- `ros2-package-generator` — 标准包生成（cpp/python/mixed）+ `--verify` 标志
- `ros2-interface-generator` — msg/srv/action 接口包生成
- `ros2-msg-generator` — 交互式 CLI 向导生成 .msg 文件
- `ros2-srv-generator.sh` — 交互式 .srv/.action 向导
- `ros2-launch-generator` — launch.py 生成（lifecycle/normal/component）
- `ros2-cpp-node` — 7种节点类型（publisher/sub/lifecycle/service/action/timer/parameters）
- `ros2-tf2-broadcaster` — TF2 广播节点生成器
- `ros2-build-verify-loop` — 编译验证 + LLM 修复闭环（3次重试）
- `ros2-build-feedback` — 编译错误解释 + 修复建议
- `ros2-debug` — 8类 ROS2 错误自动诊断
- `ros2-format` — clang-format 格式化
- `ros2-cmake-fix` — CMake 依赖问题诊断
- `ros2-bag-tool` — Bag 日志分析
- `ros2-param-wizard` — 参数 YAML 生成

**测试模板**
- `test-templates/src/publisher_test.cpp` — gtest 发布者测试（atomic 线程安全）
- `test-templates/src/lifecycle_test.cpp` — gtest 生命周期测试（6个测试用例）
- `test-templates/src/service_test.cpp` — gtest 服务测试（并发线程安全）
- `test-templates/src/action_test.cpp` — gtest Action 测试

**CI/CD**
- `ros2-ci.yml` — Matrix build（humble/iron/jazzy）+ clang-format + ament_lint + coverage + concurrency

**文档**
- README 重构（痛点→解决→差异化 + 工具链架构图）
- CLAUDE.md 精简（58行，核心规则）
- CONTRIBUTING.md（SKILL.md 编写规范 + commit 格式）
- PROJECT_ROADMAP.md（本文件）

---

## v0.3.x 完成内容 ✅

### 🔧 工具链增强

| 功能 | 描述 | 优先级 |
|------|------|--------|
| `ros2-nav2-node-generator` | Nav2 compatible 节点模板 | ✅ ✅✅ |
| `ros2-simulator-generator` | Gazebo 仿真包生成器（5种机器人类型） | ✅ P3 |
| `ros2-diagnostics-generator` | 机器人健康诊断（general/mobile/manipulator/drone） | ✅ P3 |
| `ros2-slam-generator` | SLAM 配置包（2D/3D/IMU-fusion/visual/cartographer） | ✅ P3 |
| `ros2-multi-agent-generator` | 多机器人协调（编队/任务分配/蜂群/ORCA） | ✅ P3 |
| `ros2-control-node-generator` | ros2_control 硬件接口节点 | ✅ P2-2 |
| `ros2-moveit-generator` | MoveIt2 运动规划节点 | ✅ P2-3 |
| `ros2-safety-generator` | 机器人安全模块（碰撞检测/急停/地理围栏/HITL） | ✅ P0 |

### 📦 案例包

| 案例 | 状态 |
|------|------|
| wheeled-nav2 | ✅ PLAN+SKILL+VERIFY |
| drone-exploration | ✅ PLAN+SKILL+VERIFY |
| go2-scurve | ✅ PLAN+SKILL+VERIFY |
| manipulator-pickplace | ✅ PLAN+SKILL+VERIFY |
| multi-robot-swarm | ✅ PLAN+SKILL+VERIFY |
| underwater-nav | ✅ PLAN+SKILL+VERIFY |
| industrial-integration | ✅ PLAN+SKILL+VERIFY |
| aerial-photography | ✅ PLAN+SKILL+VERIFY |
| sensor-fusion-locate | ✅ PLAN+SKILL+VERIFY |
| biped-walk | ✅ PLAN+SKILL+VERIFY |
| lifecycle-node-demo | ✅ PLAN+SKILL+VERIFY |
| action-fibonacci-demo | ✅ PLAN+SKILL+VERIFY |

### 🧪 测试覆盖

- ✅ 所有 scripts/ 有 bash -n 语法验证
- ✅ C++ GoogleTest 模板（4个测试文件）
- ⚠️ CI 中无 ros2 bag integration test
- ⚠️ 无 lint 覆盖率统计

---

## v1.0 目标

**愿景：输入自然语言描述 → 输出可编译的 ROS2 包**

```
用户: "帮我生成一个订阅 /scan 激光雷达，检测到障碍物时停车的节点"
AI Agent:
  1. 调用 ros2-package-generator 创建包
  2. 调用 ros2-msg-generator 定义消息格式
  3. 生成节点代码
  4. 调用 ros2-build-verify-loop 验证
  5. 通过 → 完成
```

**里程碑：**
- 用户无需修改生成的代码即可编译运行
- CI/CD 通过率 > 95%
- 至少 3 个真实机器人项目使用本工具链开发

---

## v0.4.0 规划（2026-04-13 进行中）

### 目标：让 v1.0 愿景更近一步

**核心改进方向：** 工具链闭环 + 文档完整 + CI 达标

#### 📋 文档补全
- ✅ `QUICKREF.md` — ROS2 命令速查（235行，13个场景）
- ✅ `CHECKLIST.md` — 开发质量清单（82行，5类检查表）
- ✅ `SYSTEM.md` — AI Agent 强制规则（103行，零容忍规则）
- ✅ `README_EN.md` / `README_DE.md` — 英文/德文文档
- ✅ `agents/skills/README.md` — 180+ SKILL 完整索引重写

#### 🔧 工具链改进（P1）
- `ros2-orchestrate.sh` 增强：支持 YAML/JSON 描述文件输入
- Python 节点生成器：`ros2-python-node-generator.sh`
- 统一接口描述格式：`.ifd`（接口定义文件）→ 自动生成 msg/srv/action + C++ 绑定

#### 🧪 CI/CD 补完（P2）
- ros2 bag integration test（当前缺失）
- clang-tidy 覆盖率统计
- 多 ROS2 版本（Humble / Iron / Jazzy）矩阵测试强化
- 自动化生成器脚本测试框架

#### 🤖 AI 增强（P2）
- LLM 驱动的 CMake 错误自动修复（超出 ros2-cmake-fix 现有规则）
- 基于过往编译历史学习，预测高概率失败点
- 多轮对话上下文记忆（memory-bank 与 CLAUDE.md 深度整合）

#### 📖 示例案例完善（P3）
- `go2-scurve` 案例补充真实步态数据
- `multi-robot-swarm` 案例补充分布式通信配置
- 新增：`autonomous-delivery` 轮式 + 机械臂组合案例

---

## v0.3.1 更新（2026-04-10）

**AI Agent 开发文档增强**
- CLAUDE.md 完全重写（中文为主），增加工具决策树、依赖速查表、Agent 行为准则
- agents/memory-bank/ 新增：**20 个自动切换模板**
  - robot-type（7）：wheeled-vehicle / multi-rotor-uav / quadruped / manipulator / humanoid / underwater / multi-robot
  - task-type（7）：navigation / perception / motion-control / simulation / multi-agent / reinforcement-learning / slam-mapping
  - phase（6）：requirements / architecture / prototyping / implementation / integration / deployment
- 自动切换脚本：`templates/auto-switch.sh`
- 修复 AGENTS.md / README.md 中 agents/documents/ 旧引用 → agents/memory-bank/

## 版本历史

| 版本 | 日期 | 主要内容 |
|------|------|---------|
| v0.4.0 | 2026-04-13 | QUICKREF + CHECKLIST + SYSTEM.md + SKILL索引重写 + 英德文 README |
| v0.3.1 | 2026-04-10 | memory-bank 20 模板 + CLAUDE.md 重写 + 文档修复 |
| v0.3.0 | 2026-04-07 | P2 Nav2/MoveIt/ros2_control + P3 + 12案例 |
| v0.2.x | 2026-04-06 | 工具链完整 + CI升级 + README重构 |
| v0.1.x | 2026-04-05 | 初始版本：工具链 + CI + 案例文档化 |
| v0.0.x | 2026-03 | 实验阶段 |
