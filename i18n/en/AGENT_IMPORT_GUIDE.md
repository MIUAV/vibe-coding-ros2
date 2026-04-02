# AI Agent Import Guide for VibeCoding Skills

> This tutorial provides detailed instructions on how to properly load and use Skills and Prompts from the vibe-coding-ros2 project for AI agents, enabling efficient ROS2 development workflows.

---

## 0. One-Click Initialization (Recommended)

Run this command at repository root:

```bash
./init-agent.sh --target all
```

Optional targets:
- `--target all`: initialize both VS Code Copilot and Cursor
- `--target copilot`: initialize VS Code Copilot only
- `--target cursor`: initialize Cursor only

The script auto-generates:
- `.github/copilot-instructions.md` (Copilot workspace instructions)
- `.cursor/rules/vibe-coding-ros2.mdc` (Cursor always-on rule)
- `.vscode/mcp.json` and `.cursor/mcp.json` (MCP config templates)
- `agents/generated/skill-index.md` (full skill index)
- `agents/generated/context-index.md` (principles/prompts/guides index)
- `agents/generated/agent-bootstrap.md` (single bootstrap entry)

---

## 1. Project Resources Overview

### 1.1 Skills

Skills are modular capability definitions organized in a **taxonomy system**:

> Note: The skill set is growing quickly. Treat the static tree as illustrative only. Always use `agents/generated/skill-index.md` (full list) and `agents/generated/skill-routing.md` (routing/disambiguation) as the source of truth.

#### Skill Taxonomy Dimensions

| Dimension | Description |
|-----------|-------------|
| **Robot Type** | multi_rotor_uav / quadruped / humanoid / manipulator / wheeled_vehicle |
| **Function Domain** | perception / localization / navigation / motion-control / skill-planning / action |
| **Common Skills** | ros2 basics, cross-compilation, debugging, etc. |

#### Skill Directory Structure

```
agents/skills/
├── common/                    # Common ROS2 development skills
│   ├── ros2-package-generator/      # Package generator
│   ├── ros2-debugging/               # Debugging skills
│   ├── arm64-cross-compile/         # ARM64 cross-compilation
│   ├── ros2-action-communication/   # Action communication
│   ├── ros2-component/              # Component development
│   ├── ros2-topic-communication/     # Topic communication
│   └── ... (more communication, lifecycle skills)
│
├── edge-platforms/            # Edge computing platforms
│   ├── rockchip-rknn/               # Rockchip RKNN
│   │   ├── rknn-model-conversion/  # Model conversion
│   │   ├── rknn-inference-runtime/ # Inference runtime
│   │   ├── rknn-camera-driver/      # Camera driver
│   │   └── rknn-npu-profiling/      # NPU profiling
│   ├── nvidia-cuda/                 # CUDA programming
│   │   ├── cuda-programming/        # Programming basics
│   │   ├── cuda-optimization/       # Performance optimization
│   │   ├── cuda-libraries/          # Acceleration libraries
│   │   └── cuda-profiling/          # Performance profiling
│   ├── nvidia-jetpack/              # Jetson development
│   │   ├── jetpack-setup/           # Environment setup
│   │   ├── deepstream/              # Video analytics
│   │   ├── tensorrt/                # Inference optimization
│   │   └── ros2-integration/        # ROS2 integration
│   └── digiwheel-sunrise/           # DiGiWheel Sunrise
│       ├── sunrise-sdk/             # SDK development
│       ├── sunrise-toolchain/       # Cross-compilation
│       ├── sunrise-perception/      # Vision perception
│       └── sunrise-robotics/        # Robotics applications
│
├── multi_rotor_uav/           # Multi-rotor UAV (PX4)
│   ├── perception/            # Perception
│   │   ├── px4-sensor-config/       # Sensor configuration
│   │   └── px4-vision-nav/          # Vision navigation
│   ├── localization/          # Localization
│   │   └── px4-multicopter-dev/    # Multicopter development
│   ├── navigation/            # Navigation
│   │   ├── px4-debug-logging/      # Debug logging
│   │   ├── px4-flight-mode/        # Flight mode
│   │   └── px4-mc-tuning/          # Multicopter tuning
│   ├── skill-planning/        # Skill planning
│   │   └── px4-ros2/                # PX4-ROS2 integration
│   └── action/                # Action
│       ├── px4-firmware-build/     # Firmware build
│       ├── px4-airframe/            # Airframe config
│       ├── px4-dev-env/              # Dev environment
│       ├── px4-module-dev/          # Module development
│       └── px4-mavlink/             # MAVLink communication
│
├── quadruped/                 # Quadruped robots
│   ├── perception/            # Perception
│   ├── localization/          # Localization
│   ├── navigation/            # Navigation
│   ├── motion-control/        # Motion control
│   ├── skill-planning/        # Skill planning
│   ├── deeprobotics-quadruped/     # Deeprobotics quadruped
│   └── unitree-quadruped/          # Unitree quadruped
│
├── humanoid/                  # Humanoid robots
│   ├── perception/            # Perception
│   ├── localization/          # Localization
│   ├── navigation/            # Navigation
│   └── skill-planning/        # Skill planning
│
├── manipulator/               # Manipulators
│   ├── perception/            # Perception
│   ├── localization/          # Localization
│   ├── motion-control/        # Motion control
│   └── skill-planning/        # Skill planning
│
└── wheeled_vehicle/           # Wheeled vehicles
    ├── perception/            # Perception
│   ├── localization/          # Localization
│   ├── navigation/            # Navigation
│   └── action/                # Action
```

#### Trigger Phrase Examples

| Skill | Trigger Phrases |
|-------|-----------------|
| ros2-package-generator | "Create ROS2 package" / "Generate ROS2 package" |
| ros2-debugging | "Debug ROS2" / "ROS2 troubleshooting" |
| arm64-cross-compile | "Cross compile ARM" / "ARM64 compilation" |
| px4-ros2 | "PX4 ROS2 integration" / "UAV development" |
| rknn-model-conversion | "RKNN model conversion" / "Rockchip AI deployment" |
| cuda-optimization | "CUDA optimization" / "GPU acceleration" |
| tensorrt | "TensorRT optimization" / "Jetson inference" |

### 1.2 Prompts

Prompts are predefined instruction templates that help AI understand task context:

```
agents/prompts/
├── coding_prompts/         # Coding task prompts
│   ├── (1,1)_ros2_project_context_generation.md
│   ├── (2,1)_ros2_package_creation.md
│   └── (3,1)_ros2_node_implementation.md
├── system_prompts/         # System-level prompts
│   └── ros2-developer-system.md
└── user_prompts/           # User prompt templates
    └── ros2-common-prompts.md
```

### 1.3 Memory Bank

Context documents that maintain project long-term memory:

```
agents/memory-bank/
├── project-context.md      # Project context
├── implementation-plan.md  # Implementation plan
└── progress.md             # Progress tracking
```

### 1.4 Robot Guides

Development guides for different robot types:

```
agents/robots/
├── multi_rotor_uav/        # Multi-rotor UAV guide
├── quadruped/             # Quadruped robot guide
├── humanoid/              # Humanoid robot guide
├── manipulator/           # Manipulator guide
└── wheeled_vehicle/      # Wheeled vehicle guide
```

### 1.5 Edge Platform Knowledge

Development knowledge for different edge computing platforms:

```
agents/skills/edge-platforms/
├── rockchip-rknn/          # Rockchip RKNN
├── nvidia-cuda/            # NVIDIA CUDA
├── nvidia-jetpack/         # NVIDIA JetPack
└── digiwheel-sunrise/     # DiGiWheel Sunrise
```

---

## 2. AI Tool Loading Methods

### 2.1 Skill Location Rules

Since skills are organized in a **taxonomy system**, AI needs to locate the correct skill based on user requirements:

#### Location Steps

1. **Identify Robot Type**: Determine if it's UAV, quadruped, humanoid, manipulator, or wheeled vehicle from the requirement
2. **Determine Function Domain**: Judge whether it belongs to perception, localization, navigation, motion control, or skill planning
3. **Match Specific Skill**: Locate the specific SKILL.md file based on the above dimensions

#### Example

```
User Request: "Help me develop UAV object tracking functionality"
Location:
  1. Robot Type: multi_rotor_uav (Multi-rotor UAV)
  2. Function Domain: perception
  3. Specific Skill: px4-vision-nav
  4. Skill File: agents/skills/multi_rotor_uav/perception/px4-vision-nav/SKILL.md
```

### 2.2 VS Code Copilot / GitHub Copilot

**Loading skills**:
```
@skills/multi_rotor_uav/perception/px4-vision-nav develop UAV vision navigation
```

**Loading edge platform skills**:
```
@skills/edge-platforms/rockchip-rknn/rknn-model-conversion convert YOLO model
@skills/edge-platforms/nvidia-jetpack/tensorrt optimize inference engine
```

**Loading prompts**:
```
Please read agents/prompts/coding_prompts/(2,1)_ros2_package_creation.md
Help me create a ROS2 package named image_processor
```

### 2.3 Cursor

**Using slash commands**:
```
/ros2-create-pkg    # Create ROS2 package
/ros2-debug        # Debug ROS2
/ros2-cross-compile # Cross-compile
/px4-vision-nav    # UAV vision navigation
/rknn-convert      # RKNN model conversion
```

**Loading prompt files**:
```
Read agents/prompts/system_prompts/ros2-developer-system.md
Then help me develop nodes according to the system prompt
```

### 2.4 Claude CLI / Codex CLI

**Via file path reference**:
```bash
# In conversation, reference skill files directly
cat agents/skills/multi_rotor_uav/perception/px4-vision-nav/SKILL.md

# Let AI learn the skill format - edge platforms
cat agents/skills/edge-platforms/rockchip-rknn/rknn-model-conversion/SKILL.md

# Let AI locate skills by taxonomy
Please read agents/skills/README.md to understand skill taxonomy
Then help me develop quadruped gait control
```

---

## 3. Agent Proper Loading Flow

### 3.1 First Interaction Prompt

When the agent handles a task for the first time, use this prompt:

```
Hello! I'm the vibe-coding-ros2 project assistant.

Before starting development, please understand the project resource structure:

1. Skills location: agents/skills/
   - common/        : Common ROS2 development skills
   - edge-platforms/: Edge computing platforms (RKNN, CUDA, JetPack, Sunrise)
   - multi_rotor_uav/: Multi-rotor UAV (PX4)
   - quadruped/     : Quadruped robots
   - humanoid/      : Humanoid robots
   - manipulator/   : Manipulators
   - wheeled_vehicle/: Wheeled vehicles

2. Prompt templates location: agents/prompts/
3. Robot guides location: agents/robots/
4. Memory bank location: agents/memory-bank/

Please read the following key files to understand the project's skill taxonomy system:
- agents/skills/README.md
- agents/prompts/system_prompts/ros2-developer-system.md

After reading, I will tell you my development requirements, and please provide help according to project standards.
```

### 3.2 Task Distribution Prompt

Before each task, guide the agent to locate the correct skill based on the taxonomy:

```
Please load the following resources, then start the task:

1. Robot Type: [multi_rotor_uav / quadruped / humanoid / manipulator / wheeled_vehicle / edge-platforms]
2. Function Domain: [perception / localization / navigation / motion-control / skill-planning / action / common]
3. Specific Skill: [locate the specific SKILL.md based on above dimensions]
4. Prompts: [select relevant prompt]
5. Context: [select relevant memory-bank or robot guide]

Location Examples:
- UAV Vision → multi_rotor_uav/perception/px4-vision-nav
- Quadruped Gait → quadruped/motion-control
- Jetson Inference → edge-platforms/nvidia-jetpack/tensorrt

After loading, please confirm you understand:
- The skill's position and role in the taxonomy system
- Skill usage and trigger conditions
- Project development standards and submission requirements
```

---

## 4. Skill and Prompt Collaboration Patterns

### 4.1 Skill Location Flow (New)

```
User Request → Taxonomy Location → Load SKILL.md → Execute Skill
```

Location Examples:
```
User: "Help me develop UAV object tracking"
Location:
  1. Robot Type: multi_rotor_uav
  2. Function Domain: perception
  3. Specific Skill: px4-vision-nav
  4. Skill Execution: Load SKILL.md, develop vision navigation function according to guide
```

```
User: "Deploy YOLO on RK3588"
Location:
  1. Platform: edge-platforms
  2. Specific Platform: rockchip-rknn
  3. Specific Skill: rknn-model-conversion
  4. Skill Execution: Load SKILL.md, convert and deploy model according to process
```

### 4.2 Prompt Enhancement Flow

```
Skill Execution + Prompt Template → More Precise Output
```

Example:
```
Base: Use multi_rotor_uav/skill-planning/px4-ros2 to generate PX4-ROS2 bridge
Enhance: Also apply template from coding_prompts/(3,1)_ros2_node_implementation.md
Result: Generated node not only has complete functionality but also follows project coding standards
```

### 4.3 Memory Bank Context Preservation

```
Each Task → Update Memory Bank → Maintain Project Context Continuity
```

Example:
```
1. Task Start: Load agents/memory-bank/project-context.md
2. During Development: Record progress in agents/memory-bank/progress.md
3. Task Completion: Update memory-bank files to preserve context
```

---

## 5. Best Practices

### 5.1 Agent-Side Operation Standards

1. **Load First, Then Execute**  
   Don't start coding directly; load relevant skills and prompts first

2. **Maintain Context**  
   Read memory-bank at the start of each session and continuously update during development

3. **Follow Trigger Conventions**  
   Use predefined trigger phrases to interact with skills; avoid custom instructions

4. **Save Progress Timely**  
   After completing key steps, update memory-bank files

### 5.2 User-Side Operation Standards

1. **Provide Clear Requirements**  
   Clearly state: what to do, what not to do, target platform

2. **Specify Reference Resources**  
   If specific skills or prompts need to be used, clearly indicate file paths

3. **Verify Output**  
   After AI generates code, users should verify it meets project standards

---

## 6. Troubleshooting

### 6.1 Skill Not Triggered

**Problem**: AI doesn't recognize trigger phrase  
**Solution**: Explicitly state which skill to use, e.g., "Please use ros2-package-generator skill"

### 6.2 Prompt Not Loaded

**Problem**: AI ignores prompt template  
**Solution**: Provide prompt content directly, e.g., "Please generate code according to this template: [paste template]"

### 6.3 Context Lost

**Problem**: AI doesn't remember previous discussion  
**Solution**: Reload memory-bank, e.g., "Please read agents/memory-bank/progress.md first to understand current progress"

---

## 7. Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│                    Quick Trigger Phrases                │
├─────────────────────────────────────────────────────────┤
│ Create Package   │ @skills/ros2-package-generator        │
│ Debug            │ @skills/ros2-debugging               │
│ Cross Compile   │ @skills/arm64-cross-compile           │
│ Import Bootstrap │ @skills/common/agent-skill-bootstrap │
│ Skill Routing   │ agents/generated/skill-routing.md     │
│ Rebuild Index   │ ./init-agent.sh --target all          │
│ Project Context │ agents/memory-bank/project-context.md │
│ Implementation  │ agents/memory-bank/implementation-plan.md │
│ Progress        │ agents/memory-bank/progress.md       │
└─────────────────────────────────────────────────────────┘
```

---

## 8. Extend Skills with Copilot /create-skill

When adding a new skill, prefer generating a first draft with Copilot `/create-skill`, then place it into the project taxonomy path.

Recommended prompt template:

```text
/create-skill
Create a skill named <skill-name> at agents/skills/<taxonomy-path>/<skill-name>/SKILL.md.
Requirements:
1) frontmatter includes name and description
2) description includes searchable keywords (for example: import skills, rebuild skill index)
3) sections include: when to use, quick reference, execution steps, troubleshooting
4) include executable ROS2 command examples
```

After creating/updating any skill, run:

```bash
./init-agent.sh --target all
```

to refresh `skill-index.md`, `skill-routing.md`, and bootstrap files.

---

## 9. Related Documentation

- [Skills Index](../../agents/skills/README.md)
- [Skill Routing](../../agents/generated/skill-routing.md)
- [Prompt Library](../../agents/prompts/)
- [Memory Bank Templates](../../agents/memory-bank/)
- [Robot Type Guides](../../agents/robots/)
- [Contributing Guide](./CONTRIBUTING.md)

---

*This project is licensed under Apache License 2.0*