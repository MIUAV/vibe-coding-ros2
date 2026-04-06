#!/bin/bash
# ros2-gazebo-world-generator.sh — Gazebo world 场景生成器
# 用法: bash ros2-gazebo-world-generator.sh <world_name> [world_type]
# world_type: empty | warehouse | office | outdoor | maze | factory
#
# 示例: bash ros2-gazebo-world-generator.sh my_world warehouse

WORLD_NAME="${1:-}"
WORLD_TYPE="${2:-empty}"

if [[ -z "$WORLD_NAME" ]]; then
    echo "用法: $0 <世界名> [场景类型]"
    echo "  empty    — 空旷世界（默认）"
    echo "  warehouse — 仓库货架场景"
    echo "  office   — 办公室场景"
    echo "  outdoor  — 室外地形"
    echo "  maze    — 迷宫障碍"
    echo "  factory  — 工厂车间"
    exit 1
fi

mkdir -p "$WORLD_NAME/worlds" "$WORLD_NAME/models"

# ════════════════════════════════════════════════════════════
# 空世界
# ════════════════════════════════════════════════════════════
if [[ "$WORLD_TYPE" == "empty" ]]; then

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME">
    <physics type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    <scene>
      <ambient>0.5 0.5 0.5 1</ambient>
      <grid>true</grid>
      <shadows>true</shadows>
    </scene>
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <specular>0.2 0.2 0.2 1</specular>
      <attenuation><range>1000</range><constant>0.9</constant><linear>0.01</linear><quadratic>0.001</quadratic></attenuation>
      <direction>-0.5 0.1 -0.9</direction>
    </light>
    <model name="ground_plane">
      <static>true</static>
      <link name="ground_link">
        <collision><plane><normal>0 0 1</normal><size>100 100</size></plane></collision>
        <visual><plane><normal>0 0 1</normal><size>100 100</size><material><ambient>0.5 0.5 0.5 1</ambient><diffuse>0.9 0.9 0.9 1</diffuse></material></plane></visual>
      </link>
    </model>
  </world>
</sdf>
WORLDEOF

# ════════════════════════════════════════════════════════════
# 仓库场景
# ════════════════════════════════════════════════════════════
elif [[ "$WORLD_TYPE" == "warehouse" ]]; then

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME_warehouse">
    <physics type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    <scene><ambient>0.4 0.4 0.4 1</ambient><grid>false</grid></scene>
    <light type="directional" name="sun"><pose>0 0 10 0 0 0</pose><diffuse>0.8 0.8 0.8 1</diffuse><direction>-0.5 0.1 -0.9</direction></light>

    <!-- 地面 -->
    <model name="floor">
      <static>true</static>
      <link name="link">
        <collision><plane><normal>0 0 1</normal><size>50 50</size></plane></collision>
        <visual><plane><normal>0 0 1</normal><size>50 50</size><material><ambient>0.6 0.5 0.4 1</ambient></material></plane></visual>
      </link>
    </model>

    <!-- 货架A (长排) -->
    <model name="shelf_row_A">
      <static>true</static>
      <link name="link">
        <pose>5 0 0 0 0 0</pose>
        <collision><box><size>1 20 3</size></box></collision>
        <visual><box><size>1 20 3</size></box><material><ambient>0.5 0.3 0.1 1</ambient></material></visual>
      </link>
    </model>

    <!-- 货架B -->
    <model name="shelf_row_B">
      <static>true</static>
      <link name="link">
        <pose>-5 0 0 0 0 0</pose>
        <collision><box><size>1 20 3</size></box></collision>
        <visual><box><size>1 20 3</size></box><material><ambient>0.5 0.3 0.1 1</ambient></material></visual>
      </link>
    </model>

    <!-- 货架单元 (分散) -->
    <model name="shelf_unit_1">
      <static>true</static>
      <link name="link">
        <pose>3 5 0 0 0 0</pose>
        <collision><box><size>2 1 2.5</size></box></collision>
        <visual><box><size>2 1 2.5</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual>
      </link>
    </model>
    <model name="shelf_unit_2">
      <static>true</static>
      <link name="link">
        <pose>3 -5 0 0 0 0</pose>
        <collision><box><size>2 1 2.5</size></box></collision>
        <visual><box><size>2 1 2.5</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual>
      </link>
    </model>
    <model name="shelf_unit_3">
      <static>true</static>
      <link name="link">
        <pose>-3 5 0 0 0 0</pose>
        <collision><box><size>2 1 2.5</size></box></collision>
        <visual><box><size>2 1 2.5</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual>
      </link>
    </model>
    <model name="shelf_unit_4">
      <static>true</static>
      <link name="link">
        <pose>-3 -5 0 0 0 0</pose>
        <collision><box><size>2 1 2.5</size></box></collision>
        <visual><box><size>2 1 2.5</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual>
      </link>
    </model>

    <!-- 中间障碍物 -->
    <model name="crate_1">
      <static>true</static>
      <link name="link">
        <pose>0 3 0.25 0 0 0</pose>
        <collision><box><size>0.5 0.5 0.5</size></box></collision>
        <visual><box><size>0.5 0.5 0.5</size></box><material><ambient>0.8 0.6 0.3 1</ambient></material></visual>
      </link>
    </model>
    <model name="crate_2">
      <static>true</static>
      <link name="link">
        <pose>0 -3 0.25 0 0 0</pose>
        <collision><box><size>0.5 0.5 0.5</size></box></collision>
        <visual><box><size>0.5 0.5 0.5</size></box><material><ambient>0.8 0.6 0.3 1</ambient></material></visual>
      </link>
    </model>

    <!-- 检测站 -->
    <model name="station">
      <static>true</static>
      <link name="link">
        <pose>8 0 0 0 0 0</pose>
        <collision><box><size>1 2 1.5</size></box></collision>
        <visual><box><size>1 2 1.5</size></box><material><ambient>0.3 0.5 0.3 1</ambient></material></visual>
      </link>
    </model>
  </world>
</sdf>
WORLDEOF

# ════════════════════════════════════════════════════════════
# 办公室场景
# ════════════════════════════════════════════════════════════
elif [[ "$WORLD_TYPE" == "office" ]]; then

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME_office">
    <physics type="ode"><max_step_size>0.001</max_step_size><real_time_factor>1.0</real_time_factor><real_time_update_rate>1000</real_time_update_rate></physics>
    <scene><ambient>0.5 0.5 0.5 1</ambient><grid>false</grid></scene>
    <light type="directional" name="sun"><pose>0 0 10 0 0 0</pose><diffuse>0.8 0.8 0.8 1</diffuse><direction>-0.5 0.1 -0.9</direction></light>

    <!-- 地板 -->
    <model name="floor"><static>true</static><link name="link"><collision><plane><normal>0 0 1</normal><size>30 30</size></plane></collision><visual><plane><normal>0 0 1</normal><size>30 30</size><material><ambient>0.8 0.8 0.8 1</ambient></material></plane></visual></link></model>

    <!-- 外墙 -->
    <model name="wall_n"><static>true</static><link name="link"><pose>0 15 1.5 0 0 0</pose><collision><box><size>30 0.2 3</size></box></collision><visual><box><size>30 0.2 3</size></box><material><ambient>0.9 0.9 0.9 1</ambient></material></visual></link></model>
    <model name="wall_s"><static>true</static><link name="link"><pose>0 -15 1.5 0 0 0</pose><collision><box><size>30 0.2 3</size></box></collision><visual><box><size>30 0.2 3</size></box><material><ambient>0.9 0.9 0.9 1</ambient></material></visual></link></model>
    <model name="wall_e"><static>true</static><link name="link"><pose>15 0 1.5 0 0 1.57</pose><collision><box><size>30 0.2 3</size></box></collision><visual><box><size>30 0.2 3</size></box><material><ambient>0.9 0.9 0.9 1</ambient></material></visual></link></model>
    <model name="wall_w"><static>true</static><link name="link"><pose>-15 0 1.5 0 0 1.57</pose><collision><box><size>30 0.2 3</size></box></collision><visual><box><size>30 0.2 3</size></box><material><ambient>0.9 0.9 0.9 1</ambient></material></visual></link></model>

    <!-- 隔断墙 -->
    <model name="partition_1"><static>true</static><link name="link"><pose>5 0 1.5 0 0 0</pose><collision><box><size>0.2 10 3</size></box></collision><visual><box><size>0.2 10 3</size></box><material><ambient>0.7 0.7 0.8 1</ambient></material></visual></link></model>
    <model name="partition_2"><static>true</static><link name="link"><pose>-5 0 1.5 0 0 0</pose><collision><box><size>0.2 10 3</size></box></collision><visual><box><size>0.2 10 3</size></box><material><ambient>0.7 0.7 0.8 1</ambient></material></visual></link></model>

    <!-- 桌子 -->
    <model name="desk_1"><static>true</static><link name="link"><pose>3 5 0.4 0 0 0</pose><collision><box><size>1.5 0.8 0.8</size></box></collision><visual><box><size>1.5 0.8 0.8</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual></link></model>
    <model name="desk_2"><static>true</static><link name="link"><pose>-3 5 0.4 0 0 0</pose><collision><box><size>1.5 0.8 0.8</size></box></collision><visual><box><size>1.5 0.8 0.8</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual></link></model>
    <model name="desk_3"><static>true</static><link name="link"><pose>3 -5 0.4 0 0 0</pose><collision><box><size>1.5 0.8 0.8</size></box></collision><visual><box><size>1.5 0.8 0.8</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual></link></model>
    <model name="desk_4"><static>true</static><link name="link"><pose>-3 -5 0.4 0 0 0</pose><collision><box><size>1.5 0.8 0.8</size></box></collision><visual><box><size>1.5 0.8 0.8</size></box><material><ambient>0.6 0.4 0.2 1</ambient></material></visual></link></model>
  </world>
</sdf>
WORLDEOF

# ════════════════════════════════════════════════════════════
# 室外地形
# ════════════════════════════════════════════════════════════
elif [[ "$WORLD_TYPE" == "outdoor" ]]; then

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME_outdoor">
    <physics type="ode"><max_step_size>0.001</max_step_size><real_time_factor>1.0</real_time_update_rate>1000</real_time_update_rate></physics>
    <scene><ambient>0.6 0.7 1.0 1</ambient><grid>false</grid></scene>
    <light type="directional" name="sun"><cast_shadows>true</cast_shadows><pose>10 -10 20 0 0 0</pose><diffuse>1 1 0.9 1</diffuse><specular>0.1 0.1 0.1 1</specular><direction>-0.5 0.1 -0.9</direction></light>

    <!-- 粗糙地面 -->
    <model name="ground">
      <static>true</static>
      <link name="link">
        <collision><heightmap><uri>file://media/materials/textures/heightmap.png</uri><size>100 100 2</size><pos>0 0 0</pos></heightmap></collision>
        <visual><geometry><heightmap><uri>file://media/materials/textures/heightmap.png</uri><size>100 100 2</size></heightmap></geometry></visual>
      </link>
    </model>

    <!-- 树木 -->
    <model name="tree_1"><static>true</static><link name="link"><pose>5 5 0 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>4</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>4</length></cylinder><material><ambient>0.3 0.5 0.1 1</ambient></material></visual></link></model>
    <model name="tree_2"><static>true</static><link name="link"><pose>-7 3 0 0 0 0</pose><collision><cylinder><radius>0.4</radius><length>5</length></cylinder></collision><visual><cylinder><radius>0.4</radius><length>5</length></cylinder><material><ambient>0.3 0.5 0.1 1</ambient></material></visual></link></model>
    <model name="tree_3"><static>true</static><link name="link"><pose>8 -4 0 0 0 0</pose><collision><cylinder><radius>0.35</radius><length>4.5</length></cylinder></collision><visual><cylinder><radius>0.35</radius><length>4.5</length></cylinder><material><ambient>0.3 0.5 0.1 1</ambient></material></visual></link></model>
    <model name="tree_4"><static>true</static><link name="link"><pose>-4 -8 0 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>3.5</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>3.5</length></cylinder><material><ambient>0.3 0.5 0.1 1</ambient></material></visual></link></model>

    <!-- 建筑 -->
    <model name="building_1">
      <static>true</static>
      <link name="link">
        <pose>15 0 2 0 0 0</pose>
        <collision><box><size>8 6 4</size></box></collision>
        <visual><box><size>8 6 4</size></box><material><ambient>0.7 0.7 0.7 1</ambient></material></visual>
      </link>
    </model>
    <model name="building_2">
      <static>true</static>
      <link name="link">
        <pose>-12 8 1.5 0 0 0</pose>
        <collision><box><size>6 4 3</size></box></collision>
        <visual><box><size>6 4 3</size></box><material><ambient>0.6 0.6 0.6 1</ambient></material></visual>
      </link>
    </model>
  </world>
</sdf>
WORLDEOF

# ════════════════════════════════════════════════════════════
# 迷宫障碍
# ════════════════════════════════════════════════════════════
elif [[ "$WORLD_TYPE" == "maze" ]]; then

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME_maze">
    <physics type="ode"><max_step_size>0.001</max_step_size><real_time_factor>1.0</real_time_update_rate>1000</real_time_update_rate></physics>
    <scene><ambient>0.2 0.2 0.2 1</ambient><grid>false</grid></scene>
    <light type="directional" name="sun"><pose>0 0 10 0 0 0</pose><diffuse>0.5 0.5 0.5 1</diffuse><direction>-0.5 0.1 -0.9</direction></light>

    <model name="floor"><static>true</static><link name="link"><collision><plane><normal>0 0 1</normal><size>20 20</size></plane></collision><visual><plane><normal>0 0 1</normal><size>20 20</size><material><ambient>0.3 0.3 0.3 1</ambient></material></plane></visual></link></model>

    <!-- 迷宫墙壁（简化版） -->
    <!-- 外墙 -->
    <model name="wall_out_n"><static>true</static><link name="link"><pose>0 10 1 0 0 0</pose><collision><box><size>20 0.3 2</size></box></collision><visual><box><size>20 0.3 2</size></box><material><ambient>0.4 0.2 0.1 1</ambient></material></visual></link></model>
    <model name="wall_out_s"><static>true</static><link name="link"><pose>0 -10 1 0 0 0</pose><collision><box><size>20 0.3 2</size></box></collision><visual><box><size>20 0.3 2</size></box><material><ambient>0.4 0.2 0.1 1</ambient></material></visual></link></model>
    <model name="wall_out_e"><static>true</static><link name="link"><pose>10 0 1 0 0 1.57</pose><collision><box><size>20 0.3 2</size></box></collision><visual><box><size>20 0.3 2</size></box><material><ambient>0.4 0.2 0.1 1</ambient></material></visual></link></model>
    <model name="wall_out_w"><static>true</static><link name="link"><pose>-10 0 1 0 0 1.57</pose><collision><box><size>20 0.3 2</size></box></collision><visual><box><size>20 0.3 2</size></box><material><ambient>0.4 0.2 0.1 1</ambient></material></visual></link></model>

    <!-- 迷宫内部隔断 -->
    <model name="wall_a"><static>true</static><link name="link"><pose>3 5 1 0 0 0</pose><collision><box><size>0.3 6 2</size></box></collision><visual><box><size>0.3 6 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
    <model name="wall_b"><static>true</static><link name="link"><pose>-3 -5 1 0 0 0</pose><collision><box><size>0.3 6 2</size></box></collision><visual><box><size>0.3 6 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
    <model name="wall_c"><static>true</static><link name="link"><pose>5 0 1 0 0 1.57</pose><collision><box><size>0.3 8 2</size></box></collision><visual><box><size>0.3 8 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
    <model name="wall_d"><static>true</static><link name="link"><pose>-5 0 1 0 0 1.57</pose><collision><box><size>0.3 8 2</size></box></collision><visual><box><size>0.3 8 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
    <model name="wall_e"><static>true</static><link name="link"><pose>0 3 1 0 0 0</pose><collision><box><size>4 0.3 2</size></box></collision><visual><box><size>4 0.3 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
    <model name="wall_f"><static>true</static><link name="link"><pose>0 -3 1 0 0 0</pose><collision><box><size>4 0.3 2</size></box></collision><visual><box><size>4 0.3 2</size></box><material><ambient>0.3 0.15 0.05 1</ambient></material></visual></link></model>
  </world>
</sdf>
WORLDEOF

# ════════════════════════════════════════════════════════════
# 工厂车间
# ════════════════════════════════════════════════════════════
else  # factory

cat > "$WORLD_NAME/worlds/${WORLD_NAME}.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="WORLDNAME_factory">
    <physics type="ode"><max_step_size>0.001</max_step_size><real_time_factor>1.0</real_time_update_rate>1000</real_time_update_rate></physics>
    <scene><ambient>0.3 0.3 0.3 1</ambient><grid>false</grid><background>0.1 0.1 0.1 1</background></scene>
    <light type="directional" name="sun"><pose>0 0 15 0 0 0</pose><diffuse>0.6 0.6 0.6 1</diffuse><specular>0.05 0.05 0.05 1</specular><direction>-0.5 0.1 -0.9</direction></light>

    <model name="floor"><static>true</static><link name="link"><collision><plane><normal>0 0 1</normal><size>60 60</size></plane></collision><visual><plane><normal>0 0 1</normal><size>60 60</size><material><ambient>0.2 0.2 0.2 1</ambient></material></plane></visual></link></model>

    <!-- 工作台 -->
    <model name="workbench_1"><static>true</static><link name="link"><pose>5 5 0.5 0 0 0</pose><collision><box><size>3 1 1</size></box></collision><visual><box><size>3 1 1</size></box><material><ambient>0.4 0.4 0.5 1</ambient></material></visual></link></model>
    <model name="workbench_2"><static>true</static><link name="link"><pose>-5 5 0.5 0 0 0</pose><collision><box><size>3 1 1</size></box></collision><visual><box><size>3 1 1</size></box><material><ambient>0.4 0.4 0.5 1</ambient></material></visual></link></model>
    <model name="workbench_3"><static>true</static><link name="link"><pose>5 -5 0.5 0 0 0</pose><collision><box><size>3 1 1</size></box></collision><visual><box><size>3 1 1</size></box><material><ambient>0.4 0.4 0.5 1</ambient></material></visual></link></model>
    <model name="workbench_4"><static>true</static><link name="link"><pose>-5 -5 0.5 0 0 0</pose><collision><box><size>3 1 1</size></box></collision><visual><box><size>3 1 1</size></box><material><ambient>0.4 0.4 0.5 1</ambient></material></visual></link></model>

    <!-- 传送带 -->
    <model name="conveyor">
      <static>true</static>
      <link name="link">
        <pose>0 0 0.3 0 0 0</pose>
        <collision><box><size>8 0.8 0.1</size></box></collision>
        <visual><box><size>8 0.8 0.1</size></box><material><ambient>0.3 0.3 0.3 1</ambient></material></visual>
      </link>
    </model>

    <!-- 货架 -->
    <model name="rack_row"><static>true</static><link name="link"><pose>12 0 0 0 0 0</pose><collision><box><size>1 15 3</size></box></collision><visual><box><size>1 15 3</size></box><material><ambient>0.5 0.3 0.1 1</ambient></material></visual></link></model>
    <model name="rack_row_neg"><static>true</static><link name="link"><pose>-12 0 0 0 0 0</pose><collision><box><size>1 15 3</size></box></collision><visual><box><size>1 15 3</size></box><material><ambient>0.5 0.3 0.1 1</ambient></material></visual></link></model>

    <!-- 桶形障碍 -->
    <model name="barrel_1"><static>true</static><link name="link"><pose>3 8 0.4 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>0.8</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>0.8</length></cylinder><material><ambient>0.8 0.2 0.2 1</ambient></material></visual></link></model>
    <model name="barrel_2"><static>true</static><link name="link"><pose>-3 8 0.4 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>0.8</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>0.8</length></cylinder><material><ambient>0.8 0.2 0.2 1</ambient></material></visual></model>
    <model name="barrel_3"><static>true</static><link name="link"><pose>3 -8 0.4 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>0.8</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>0.8</length></cylinder><material><ambient>0.8 0.2 0.2 1</ambient></material></visual></model>
    <model name="barrel_4"><static>true</static><link name="link"><pose>-3 -8 0.4 0 0 0</pose><collision><cylinder><radius>0.3</radius><length>0.8</length></cylinder></collision><visual><cylinder><radius>0.3</radius><length>0.8</length></cylinder><material><ambient>0.8 0.2 0.2 1</ambient></material></visual></model>
  </world>
</sdf>
WORLDEOF
fi

sed -i "s/WORLDNAME/$WORLD_NAME/g" "$WORLD_NAME/worlds/${WORLD_NAME}.world"

# ── README ────────────────────────────────────────────────
cat > "$WORLD_NAME/README.md" <<RDMEOF
# $WORLD_NAME — Gazebo World

**场景类型:** $WORLD_TYPE

## 包含内容

- `worlds/${WORLD_NAME}.world` — Gazebo world 文件
- `models/` — 模型文件（可扩展）

## 使用方法

```bash
# 方法1: 直接加载
gazebo worlds/${WORLD_NAME}.world

# 方法2: 通过 ros2_gazebo
ros2 launch gazebo_ros gazebo.launch.py world_file:=worlds/${WORLD_NAME}.world
```

## 场景特性

| 场景 | 特点 |
|------|------|
| warehouse | 货架巷道、货物堆放、导航测试 |
| office | 办公室隔断、桌子、导航+定位测试 |
| outdoor | 树木、建筑、地形、室外导航 |
| maze | 迷宫墙壁、SLAM 路径规划测试 |
| factory | 传送带、工作台、货架、AGV 导航 |
RDMEOF

echo ""
echo "Generated: $WORLD_NAME/worlds/${WORLD_NAME}.world"
echo "Generated: $WORLD_NAME/README.md"
echo ""
echo "World type: $WORLD_TYPE"
echo ""
echo "Launch:"
echo "  gazebo $WORLD_NAME/worlds/${WORLD_NAME}.world"
echo "  ros2 launch gazebo_ros gazebo.launch.py world_file:=$WORLD_NAME/worlds/${WORLD_NAME}.world"
