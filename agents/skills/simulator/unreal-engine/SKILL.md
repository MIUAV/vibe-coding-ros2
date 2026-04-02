---
name: unreal-engine
description: Unreal Engine 机器人仿真开发技能 - 高保真仿真、物理引擎集成、传感器模拟
argument-hint: "unreal仿真" / "UE机器人" / "创建仿真场景" / "虚幻引擎"
user-invocable: true
---

# Unreal Engine Robot Simulation Skill

> 用于 Unreal Engine 机器人仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 使用 Unreal Engine 创建机器人仿真
- 配置高保真传感器模拟
- 集成 ROS2/ROS1
- 开发自定义插件
- 构建虚拟环境

---

## 快速参考

### 系统要求

- **操作系统**: Windows 10/11 或 Linux (通过 Unreal Engine 5.4+)
- **GPU**: NVIDIA RTX 2080+ (推荐 RTX 3080+)
- **显存**: 8GB+ (强烈建议 16GB+)
- **存储**: 100GB+ SSD
- **内存**: 16GB+

### 安装 Unreal Engine

```bash
# 1. 安装 Epic Games Launcher
# 下载并安装 Epic Games Launcher

# 2. 安装 Unreal Engine 5.4+
# 在 Epic Games Launcher 中选择 Unreal Engine → 库 → 安装 5.4

# 3. 安装源码版本 (可选)
git clone -b 5.4 https://github.com/EpicGames/UnrealEngine.git
cd UnrealEngine
./Setup.sh
./GenerateProjectFiles.sh
```

### 创建机器人项目

```bash
# 1. 创建新项目
# 在 Epic Games Launcher 中:
# Unreal Engine → 新项目 → 游戏 → 空白 → C++ → Next
# 项目名称: RobotSimulation
# 目标平台: Desktop
# 质量: Maximum

# 2. 添加项目模板
# Content Browser → Add → Feature or Content Pack → Robot Simulation
```

### 目录结构

```
RobotSimulation/
├── Content/                    # 资源
│   ├── Robots/               # 机器人模型
│   ├── Environments/        # 环境
│   ├── Sensors/              # 传感器
│   └── Maps/                 # 地图
├── Source/                    # 源代码
│   ├── RobotSimulation/     # 主模块
│   ├── Ros2Bridge/          # ROS 桥接
│   └── Sensors/              # 传感器插件
├── Config/                    # 配置文件
└── Saved/                    # 保存数据
```

---

## ROS 集成

### 安装 Unreal Engine ROS2 插件

```bash
# 1. 克隆 ROS2 插件
cd ~/UnrealProjects/RobotSimulation/Plugins
git clone https://github.com/roboticsbuildingblocks/unreal_ros2_bridge.git

# 2. 构建项目
cd ~/UnrealProjects/RobotSimulation
./Build.sh

# 3. 启用插件
# 编辑 → 插件 → 启用 "ROS2 Bridge"
```

### ROS2 桥接配置

```cpp
// UnrealROS2Bridge.Build.cs
PublicDependencyModuleNames.AddRange(
    new string[]
    {
        "Core",
        "CoreUObject",
        "Engine",
        "InputCore",
        "rosidl_typesupport_cpp",
        "rclcpp",
    }
);
```

### 发布话题

```cpp
// MyRobotActor.cpp
#include "Ros2Bridge/Public/ROS2Publisher.h"

void AMyRobotActor::BeginPlay()
{
    Super::BeginPlay();
    
    // 创建发布者
    Publisher = NewObject<UROS2Publisher>(this);
    Publisher->Initialize(
        "/robot/odometry",
        "nav_msgs/msg/Odometry",
        this);
}

void AMyRobotActor::Tick(float DeltaTime)
{
    Super::Tick(DeltaTime);
    
    // 发布里程计消息
    FROS2OdometryMsg Msg;
    Msg.header.stamp = FROSTime::Now();
    Msg.header.frame_id = "odom";
    Msg.child_frame_id = "base_link";
    Msg.pose.pose.position.X = GetActorLocation().X / 100.0; // cm to m
    Msg.pose.pose.position.Y = GetActorLocation().Y / 100.0;
    Msg.twist.twist.linear.x = Velocity.X;
    
    Publisher->Publish(Msg);
}
```

### 订阅话题

```cpp
// 订阅 cmd_vel
Subscriber = NewObject<UROS2Subscriber>(this);
Subscriber->Initialize(
    "/cmd_vel",
    "geometry_msgs/msg/Twist",
    this,
    &AMyRobotActor::OnCmdVelReceived);

void AMyRobotActor::OnCmdVelReceived(UROS2Msg* Msg)
{
    UGeometryMsgTwist* TwistMsg = Cast<UGeometryMsgTwist>(Msg);
    TargetVelocity.X = TwistMsg->linear.x;
    TargetVelocity.Y = TwistMsg->linear.y;
    TargetVelocity.Z = TwistMsg->angular.z;
}
```

---

## 机器人模型

### 导入机器人模型

```bash
# 支持格式
# - FBX (.fbx) - 首选
# - glTF (.gltf, .glb)
# - OBJ (.obj)

# 导入步骤
# 1. 内容浏览器 → 添加 → 导入到 /Game/Robots/
# 2. 选择文件 → 打开
# 3. 导入设置:
#    - 骨骼: 启用
#    - 材质: 自动创建
#    - 网格: 合并
# 4. 点击导入
```

### 创建骨骼网格体

```cpp
// MyRobot.h
UCLASS()
class AMyRobot : public AActor
{
    GENERATED_BODY()
    
public:
    UPROPERTY(VisibleAnywhere)
    USkeletalMeshComponent* SkeletalMesh;
    
    UPROPERTY(VisibleAnywhere)
    UPhysicsConstraintComponent* LeftWheelJoint;
    
    UPROPERTY(VisibleAnywhere)
    UPhysicsConstraintComponent* RightWheelJoint;
};
```

```cpp
// MyRobot.cpp
void AMyRobot::BeginPlay()
{
    Super::BeginPlay();
    
    // 配置关节
    LeftWheelJoint->SetConstrainedComponents(
        SkeletalMesh, "wheel_bone_l",
        MeshRoot, "base_bone"
    );
    
    // 设置驱动
    LeftWheelJoint->SetAngularSwing1Limit(
        ACM_Locked, 0.0
    );
    
    // 启用电机
    LeftWheelJoint->SetAngularDriveMode(
        EAngularDriveMode::Velocity
    );
    LeftWheelJoint->SetAngularVelocityDrive(
        true, true
    );
}
```

### 物理配置

```cpp
// 物理资源设置
UPhysicsAsset* PhysicsAsset = Mesh->GetPhysicsAsset();

// 配置碰撞
for (UPhysicsBodySetup* Body : PhysicsAsset->PhysicsBodySetup)
{
    Body->CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
    Body->Mass = 5.0f;
    Body->InertiaTensor = FVector(0.1f, 0.1f, 0.1f);
}
```

---

## 传感器模拟

### RGB 摄像头

```cpp
// 添加摄像头组件
UCameraComponent* Camera = NewObject<UCameraComponent>(this);
Camera->SetRelativeLocation(FVector(10.0f, 0.0f, 5.0f));
Camera->SetFieldOfView(90.0f);
Camera->bUseFieldOfViewForLOD = true;
Camera->RegisterComponent();

// 获取图像
void AMyRobot::Tick(float DeltaTime)
{
    // 渲染目标
    if (Camera->RenderTarget)
    {
        // 获取 GPU 纹理
        FTextureResource* Texture = Camera->RenderTarget->GetResource();
        
        // 转换为 ROS 图像
        FUInt8Image Image;
        Camera->RenderTarget->ReadPixels(Image);
        
        // 发布图像
        ImagePublisher->Publish(Image);
    }
}
```

### 深度摄像头

```cpp
// 配置深度渲染
DepthCamera->CameraSettings->DepthOfFieldMethod = EDepthOfFieldMethod::SDF;
DepthCamera->CameraSettings->bOverride_DepthOfFieldBlurRadius = true;
DepthCamera->CameraSettings->DepthOfFieldBlurAmount = 0.0f;

// 启用深度写入
DepthCamera->CameraSettings->bWriteDepth = true;

// 获取深度数据
void AMyRobot::GetDepthImage(TArray<float>& DepthData)
{
    FRenderTarget* Target = DepthCamera->RenderTarget.Get();
    TArray<FColor> Colors;
    Target->ReadPixels(Colors);
    
    // 转换为深度
    for (int32 i = 0; i < Colors.Num(); i++)
    {
        DepthData.Add(Colors[i].R / 255.0f * MaxDepth);
    }
}
```

### 激光雷达

```cpp
// LiDAR 组件
UCLASS()
class ALidarSensor : public UActorComponent
{
    UPROPERTY(EditAnywhere)
    int32 ScanResolution = 360;
    
    UPROPERTY(EditAnywhere)
    float MaxRange = 100.0f;
    
    UPROPERTY(EditAnywhere)
    float MinRange = 0.1f;
    
    UPROPERTY(EditAnywhere)
    float HorizontalFOV = 360.0f;
    
    UPROPERTY(EditAnywhere)
    float VerticalFOV = 30.0f;
    
    UPROPERTY(EditAnywhere)
    int32 VerticalResolution = 16;
};

void ALidarSensor::TickComponent()
{
    // 射线检测
    TArray<FHitResult> Hits;
    FCollisionQueryParams QueryParams;
    QueryParams.AddIgnoredActor(GetOwner());
    
    for (int32 v = 0; v < VerticalResolution; v++)
    {
        for (int32 h = 0; h < ScanResolution; h++)
        {
            float AngleH = (h * HorizontalFOV / ScanResolution) - (HorizontalFOV / 2);
            float AngleV = (v * VerticalFOV / VerticalResolution) - (VerticalFOV / 2);
            
            FVector Direction = UKismetMathLibrary::Conv_EulerToVector(AngleV, AngleH, 0);
            FVector End = GetComponentLocation() + Direction * MaxRange;
            
            bool bHit = GetWorld()->LineTraceSingleByChannel(
                Hits,
                GetComponentLocation(),
                End,
                ECC_Visibility,
                QueryParams
            );
            
            if (bHit)
            {
                PointCloud.Add(Hits[0].Distance);
            }
            else
            {
                PointCloud.Add(MaxRange);
            }
        }
    }
    
    // 发布点云
    LidarPublisher->Publish(PointCloud);
}
```

### IMU 传感器

```cpp
// IMU 模拟
UCLASS()
class AImuSensor : public UActorComponent
{
    UPROPERTY(EditAnywhere)
    float AccelerationNoise = 0.01f;
    
    UPROPERTY(EditAnywhere)
    float GyroNoise = 0.001f;
    
    UPROPERTY(EditAnywhere)
    float UpdateRate = 100.0f;
};

void AImuSensor::TickComponent()
{
    // 获取父对象速度
    AActor* Parent = GetOwner();
    FVector Velocity = Parent->GetVelocity();
    
    // 获取角速度
    FVector AngularVelocity = Parent->GetAngularVelocityInDegrees();
    
    // 添加噪声
    FVector AccelNoise(
        FMath::RandRange(-AccelerationNoise, AccelerationNoise),
        FMath::RandRange(-AccelerationNoise, AccelerationNoise),
        FMath::RandRange(-AccelerationNoise, AccelerationNoise)
    );
    
    // 转换为 ROS 坐标系
    FVector LinearAcceleration = -Velocity.GetSafeNormal() * 9.81; // 重力
    
    // 发布 IMU 消息
    FROS2ImuMsg ImuMsg;
    ImuMsg.header.stamp = FROSTime::Now();
    ImuMsg.angular_velocity.x = AngularVelocity.X * PI / 180.0;
    ImuMsg.angular_velocity.y = AngularVelocity.Y * PI / 180.0;
    ImuMsg.angular_velocity.z = AngularVelocity.Z * PI / 180.0;
    ImuMsg.linear_acceleration = LinearAcceleration + AccelNoise;
    
    Publisher->Publish(ImuMsg);
}
```

---

## 环境构建

### 创建地形

```bash
# 1. 创建景观
# 放置 Actors → 基础 → 景观

# 2. 雕刻工具
# 模式 → 雕刻 → 高度 → 绘制

# 3. 添加材质
# 材质 → 创建 → 添加纹理
```

### 添加静态物体

```cpp
// 批量放置物体
void ASpawner::SpawnObjects()
{
    for (int32 i = 0; i < 100; i++)
    {
        FVector Location(
            FMath::RandRange(-500, 500),
            FMath::RandRange(-500, 500),
            0
        );
        
        FActorSpawnParameters Params;
        Params.SpawnCollisionHandlingOverride = 
            ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
        
        GetWorld()->SpawnActor<AActor>(
            CubeClass,
            Location,
            FRotator::ZeroRotator,
            Params
        );
    }
}
```

### 光照设置

```cpp
// 动态光照
UDirectionalLightComponent* Sun = NewObject<UDirectionalLightComponent>(this);
Sun->SetIntensity(3.0f);
Sun->SetLightColor(FLinearColor(1.0f, 0.95f, 0.9f));
Sun->SetActorRotation(FRotator(-45, 45, 0));
Sun->RegisterComponent();

// 阴影
Sun->SetCastShadows(true);
Sun->SetShadowBias(0.5f);
Sun->SetShadowSlopeBias(0.5f);
```

---

## 性能优化

### 多线程

```cpp
// 并行物理
void AMyRobot::Tick(float DeltaTime)
{
    // 在游戏线程
    FVector InputForce = CalculateInputForce();
    
    // 提交到物理线程
    ENQUEUE_UNREAL_FUNCTION(
        Mesh->AddForce(InputForce * 1000.0f);
    );
}
```

### LOD 设置

```cpp
// 网格 LOD
for (USkeletalMeshLODInfo* LODInfo : SkeletalMesh->LODInfo)
{
    LODInfo->ScreenSize = 0.5f;
}

// 纹理 LOD
Texture->LODGroup = TEXTUREGROUP_World;
Texture->MipLoadSettings = EMipLoadSettings::MipLoadOnStart;
```

### 渲染优化

```cpp
// 禁用不必要的效果
PostProcess->bAllowMotionBlur = false;
PostProcess->bAllowTemporalAA = false;

// 减少阴影距离
Sun->SetShadowDistanceFadeoutMultiplier(0.1f);
```

---

## 打包与部署

### Windows 打包

```bash
# 打包项目
# 文件 → 打包 → 项目 → Windows → 打包

# 或使用命令行
UnrealPak.exe -create=Project.upack -output=Ship/WindowsNoEditor.pak
```

### Linux 部署

```bash
# 交叉编译
./Build.sh Linux Development -SkipBuild -SkipDeploy

# 或使用 Docker
docker build -t unreal_robot_sim .
```

---

## 常见问题

### 问题 1: 性能不足

**解决方案**：
- 降低渲染分辨率
- 减少并行环境数
- 禁用不必要的视觉效果

### 问题 2: ROS 连接失败

**解决方案**：
- 检查网络设置
- 确认 ROS_DOMAIN_ID
- 验证话题名称匹配

### 问题 3: 物理不稳定

**解决方案**：
- 调整物理步长
- 增加约束迭代次数
- 检查质量设置

---

## 相关资源

- [Unreal Engine 官方文档](https://dev.epicgames.com/documentation/zh-cn/unreal-engine/running-unreal-engine?application_version=4.27)
- [Unreal Engine ROS 插件](https://github.com/roboticsbuildingblocks/unreal_ros2_bridge)
- [Unreal Robotics](https://github.com/isaac-sim/IsaacSimExternalContent)

---

## 另见

- [project-setup](./project-setup/) - 项目设置
- [robot-integration](./robot-integration/) - 机器人集成
- [ros2-integration](./ros2-integration/) - ROS2 集成
- [Gazebo Harmonic](../gazebo-harmonic/) - 仿真配置
- [RViz2 开发技能](../rviz2/) - 可视化配置
- [IsaacLab](../isaaclab/) - Isaac Lab 仿真