# Vibe-Codierung-ROS2
> KI-gestützte ROS2-Entwicklungs-Toolchain: → Kompilierbare Paketkompilierungs-Validierungsfehler generieren → Auto-Fix
---
# 🔥 # GitHub-Statistiken
<p align="left"><img src="https://visitor-badge.laobi.icu/badge?page_id=MIUAV.vibe-coding-ros2" alt="Visitor Badge" /><img src="https://img.shields.io/badge/version-v0.3.0-green?style=flat-square" alt="Version" /><img src="https://img.shields.io/badge/ROS2-Humble%20%7C%20Iron%20%7C%20Jazzy-green?style=flat-square" alt="ROS2 Distros" /><img src="https://img.shields.io/badge/C%2B%2B-17%2B-blue?style=flat-square" alt="C++ Standard" /><img src="https://img.shields.io/badge/workflows-5%20CI%20jobs-blue?style=flat-square" alt="CI Status" /></p>
# 🔥 # → Differenzierung → der Schmerzauflösung
<details open><summary><b>Zum Erweitern klicken — 3 Sekunden, um mehr über dieses Tool zu erfahren</b></summary>
* * Problempunkte: * * Das Schreiben von ROS2-Code mit AI, CMake Link Error Debugging dauert länger als das Schreiben von Code.Drei Pits, von denen die KI nichts weiß: CMakes Abhängigkeit von der Hölle, das Versagen der QoS-Stille und die Lifecycle-Statusmaschine.
* * Auflösung: * * Bereitstellung eines validierten Vorlagenskeletts (CMakeLists wird mit drei Zeilen Exportregeln + korrektem LifecycleNode + korrektem QoS geliefert), KI iteriert auf der Vorlage, kompiliert und verarbeitet die Geschäftslogik nach der Übergabe.
* * Differenzierung: * * Compile closed loop — `Generate → colcon build error → report → AI repair suggestion → retry`, solve CMake/QoS/Lifecycle error in 3 rounds.
* * Toolchain-Architektur: * *
```
Interface Definition ──→ Package Skeleton Generation ──→ Build Verification ──→ Error Fixing
(optional)        (required)           (automatic)
   │             │              │
   ▼             ▼              ▼
ros2-      ros2-package-  ros2-build-
msg-gen     generator.sh    verify-loop.sh
              │              │
              ▼              ▼
          ros2-cpp-node.sh ←──┘
              │
              ▼
          ros2-launch-gen / ros2-srv-gen / ros2-param-wizard

Auxiliary tools: ros2-debug (8 error diagnostics) / ros2-format (clang-format) / ros2-cmake-fix
```</details>
---
# ⚡ 5 Minuten Schnellstart

```bash
bash scripts/generators/ros2-package-generator.sh my_controller cpp rclcpp,std_msgs,geometry_msgs

bash scripts/ros2-build-verify-loop.sh my_controller

bash scripts/generators/ros2-cpp-node.sh lifecycle my_controller rclcpp,std_msgs

cd my_controller && colcon build && source install/setup.bash
ros2 run my_controller my_controller_node
```
> Jeder Schritt wird von einem Validierungsskript begleitet.Folgen Sie und senden Sie den Fehler an die KI, wenn Sie auf ein Problem stoßen: "Beheben Sie es gemäß den obigen Regeln".
---
# 🔑 Kernregeln (Pflichtlektüre)
<details><summary><b>Drei kritische Schwächen in CMake/QoS/Lifecycle</b></summary>
# CMake hängt von der Hölle ab
ROS2 CMakeLists.txt * * muss drei Zeilen gleichzeitig haben * *, von denen eine unverzichtbar ist:

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})
```
> Fehlende → Kompilierung eines → Zeilenlink-Fehlers ist fehlgeschlagen.
# QoS-Stille fehlgeschlagen
ROS2-Standard-QoS ist "zuverlässig + volatil".Fehlgeleitete Stille:

```cpp
// Control commands (cmd_vel) — must be reliable
QoS(10).reliable()   // ✅ Control commands

// Sensor data (camera/lidar) — allow dropped frames
QoS(10).best_effort()  // ✅ Sensors

// Lifecycle state — new subscribers receive latest state
QoS(10).transient_local()  // ✅ State broadcast
```
# Lebenszyklus-Zustandsmaschine
Produktionsrobotersteuerung * * muss LifecycleNode * * verwenden:

```cpp
// ✅ Correct — on_configure/on_activate/on_deactivate/on_cleanup
class RobotController : public rclcpp_lifecycle::LifecycleNode { };

// ❌ Wrong — cannot gracefully shutdown/restart
class RobotController : public rclcpp::Node { };
```</details>
---
# 🧪 Toolchain
<details><summary><b>Zum Erweitern klicken — alle Skripte auf einen Blick</b></summary>
# Generatoren (Skripte/Generatoren/— 22 insgesamt)
| Skript | Zweck ||------|------|| `ros2-package-generator.sh` | ROS2-Paket generieren (cpp/python/mixed) || `ros2-interface-generator.sh` | Generiere msg/srv/action interface package || `ros2-msg-generator.sh` | Interaktiver .msg-Datei-Assistent || `ros2-srv-generator.sh` | Interaktiver .srv/.action-Assistent || `ros2-launch-generator.sh` | Launch.py (Lebenszyklus/normal/Komponente) generieren || `ros2-cpp-node.sh` | C + + -Knoten erzeugen (Publisher/Subscriber/Lifecycle/Service/Action/Timer) || `ros2-nav2-node-generator.sh` | Nav2 kompatible Knoten (Lifecycle/Costmap/Controller) || `ros2-control-node-generator.sh` | ros2_control Hardware-Schnittstelle (DiffDrive/JointTrajectory) || `ros2-moveit-generator.sh` | MoveIt2 Bewegungsplanung (move_group/cartesian/pick_place) || `ros2-simulator-generator.sh` | Pavillon-Simulationspaket (Diff/Manipulator/Drohne/Vierbeiner) || `ros2-slam-generator.sh` | Slam-Konfiguration (2D/3D/Kartograph/Lidar_imu_Fusion) || `ros2-diagnostics-generator.sh` | Roboterdiagnose (allgemein/mobil/Manipulator/Drohne) || `ros2-multi-agent-generator.sh` | Multi-Machine-Koordination (Formation/Auktion/BOIDs/Orca) || `ros2-behavior-tree-generator.sh` | Verhaltensbaum (Patrouille/Navigation/Pick_place/Exploration) || `ros2-rl-controller-generator.sh` | Reinforcement Learning Controller (DDPG/PPO/SAC/TD3) || `ros2-camera-calibration-generator.sh` | Kamerakalibrierung (interne/externe/Hand-Auge/Lidar_Kamera) || `ros2-param-generator.sh` | Parameterkonfiguration (diff/arm/quadrotor/ackermann) || `ros2-gazebo-world-generator.sh` | Pavillon-Szene (Lager/Büro/Outdoor/Labyrinth/Fabrik) || `ros2-mission-generator.sh` | Aufgaben-Skript (Patrouille/Vermessung/Inspektion/Lieferung/Erkundung) || `ros2-data-logger.sh` | Datenprotokoll-Wiedergabe (full/sensors/nav) || `ros2-orchestrate.sh` | * * Unified Orchestrator * *: Beschreiben Sie das → gesamte Projekt || `ros2-safety-generator.sh` | Robotersicherheit (Crash-Erkennung/Not-Aus/Geofencing/Hitl) |
# Verifizierung und Reparatur
| Skript | Zweck ||------|------|| `ros2-build-verify-loop.sh` | Kompilieren → Fehleranalyse → LLM Fix Empfohlene → Wiederholung (bis zu 3 Runden) || `ros2-build-feedback.sh` | colcon build Fehlerinterpretation + Korrekturvorschläge || `ros2-debug.sh` | Klasse 8 ROS2-Fehler Auto-Diagnose || `ros2-cmake-fix.sh` | CMake-Abhängigkeitsdiagnose || `ros2-format.sh` | Formatprüfung/-reparatur im Clang-Format |
Hilfswerkzeuge
| Skript | Zweck ||------|------|| `ros2-bag-tool.sh` | Beutelprotokollanalyse (Aufzeichnung von Informationen + Häufigkeit + Fehlererkennung) || `ros2-param-wizard.sh` | Parameter YAML-Generierung + Validierung || `ros2-performance-monitor.sh` | Runtime Performance Monitoring Hook (C + + -Header) |
# Testvorlagen (test-templates/)
| Dokument | Zweck ||------|------|| `src/publisher_test.cpp` | gtest publisher test (frequency + thread safety) || `src/lifecycle_test.cpp` | gtest lifecycle testing (Zustandsautomat + atomarer Betrieb) |
</details>
---
# 🗂️ Projektstruktur

```
vibe-coding-ros2/
├── README.md
├── SOUL.md / SYSTEM.md / CLAUDE.md
│
├── agents/
│   ├── skills/
│   ├── memory-bank/
│   └── prompts/
│
├── scripts/
│   ├── generators/
│   ├── validators/
│   ├── debugger/               # ros2-debug.sh
│   └── ros2-*.sh
│
└── examples/
    └── mcp-workflow/
        └── cases/
```
---
# 📋 # Fallindex
| Gehäuse | Roboter | Aufgabe ||------|--------|------|| `wheeleled-nav2/` | Auf Rädern | Nav2 Navigation || `drone-exploration/` | Drohne | Erkunden || `go2-scurve/` | Vierbeiner | S-Kurvenbahn || `manipulator-pickplace/` | Roboterarm | grab-and-place || `lifecycle-node-demo/` | Allgemein | LifecycleNode Production Specification || `action-fibonacci-demo/` | Generisch | ROS2 Aktionsmodus |
Jeder Fall enthält `PLAN.md' (Toolchain-Schritt) + `SKILL.md' (technische Spezifikation) + `VERIFY.md` (Verifizierungsmethode).
---
Schnellstart

```bash
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

bash scripts/ros2-build-verify-loop.sh my_robot

bash scripts/generators/ros2-cpp-node.sh lifecycle my_robot rclcpp,std_msgs
```
---
Genehmigungen
Apache-2.0 · [Lizenz] (Lizenz)
---
# 🗺️ Roadmap
Siehe [PROJECT_ROADMAP.md] (PROJECT_ROADMAP.md) für Details (v0.2 → v0.3 → v1.0 Roadmap)
