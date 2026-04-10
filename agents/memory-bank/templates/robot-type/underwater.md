# Underwater Robot (AUV/ROV) Context

## 类型区分
| 类型 | 说明 | 通信 |
|------|------|------|
| AUV | 自主水下航行器，无线 | 水声/卫星 |
| ROV | 有缆遥控，支持脐带缆 | 有线光纤 |

## 特殊挑战
- **水声通信**：低带宽（9600bps）、高延迟（0.67km/s）、误码率高
- **静水压力**：深度每增加 10m ≈ 1atm，需耐压密封
- **定位**：水面 GPS → 传递深度；水下次要靠 DVL/视觉/水声定位

## 关键依赖
- `sensor_msgs/FluidPressure` — 深度计 `/depth`
- `sensor_msgs/Image` — 光学相机（需水下灯）
- `gps_common/NavSatFix` — GPS（仅水面）
- `geographic_msgs/GeoPoseStamped` — 地理坐标

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/depth` | `FluidPressure` | 静水压力（深度） |
| `/dvl/data` | `TwistWithCovarianceStamped` | DVL 测速 |
| `/camera/image_raw` | `Image` | 水下相机（需补光） |
| `/heading` | `Heading` | 磁罗盘航向 |

## 生成器选择
- 仿真：`ros2-simulator-generator.sh underwater`（水密度、阻力模型）
- SLAM：`ros2-slam-generator.sh visual|lidar_visual`（水下视觉里程计）
- 传感器融合：`ros2-sensor-fusion-generator.sh kalman_filtering`（深度+姿态）
