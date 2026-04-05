---
name: calibration
description: 机器人传感器标定 — 相机内参/外参、激光雷达-相机外参、IMU 零偏标定、手眼标定，适用于所有传感器融合系统
argument-hint: 标定 OR calibration OR 内参 OR 外参 OR 手眼标定 OR IMU 标定 OR intrinsic OR extrinsic
user-invocable: true
---

# calibration — 传感器标定 SKILL

## 引用技能

- `agents/skills/perception/camera-perception/`
- `agents/skills/ros2-debug/`

## 标定类型

| 类型 | 工具 | 说明 |
|------|------|------|
| 相机内参 | Kalibr / intrinsic calibration | fx, fy, cx, cy, k1, k2, p1, p2 |
| 相机-激光雷达外参 | Kalibr / extrinsic calibration | 旋转矩阵 + 平移向量 |
| IMU 零偏 | imu_utils | 零偏 + 比例因子 |
| 手眼标定 | easy_handeye | Eye-in-hand / Eye-to-hand |

## Kalibr 标定

```bash
# 相机内参标定
ros2 launch kalibr kalibr_create_target_pdf.launch.py \
  target_type:='aprilgrid' \
  tagCols:=6 tagRows:=4 tagSize:=0.0335 tagSpacing:=0.3

# 录制数据
ros2 bag record -o calib_data /camera/image_raw /camera/camera_info

# 标定
kalibr_calibrate_cameras --target target.yaml --bag calib_data.bag
```

## 相机-激光雷达外参标定

```bash
ros2 launch kalibr kalibr_create_target_pdf.launch.py

kalibr_calibrate_target \
  --target aprilgrid.yaml \
  --bag lidar_camera.bag \
  --cam camchain.yaml \
  --imu imu.yaml
```

## 禁止

- ❌ 标定板不平整（引入系统性误差）
- ❌ 不验证标定结果就用于融合（重投影误差 > 1 pixel）
- ❌ IMU 不做零偏标定直接用于 EKF（漂移爆炸）
