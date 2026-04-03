---
name: 3d-pointcloud-map
description: 3D 点云地图技能 - OctoMap、TSDF、语义点云、稠密重建
argument-hint: "3D地图" / "OctoMap" / "TSDF" / "点云地图" / "semantic map"
user-invocable: true
---

# 3D 点云地图技能

> 3D 环境地图构建

---

## 何时使用

当需要以下帮助时使用此技能：
- OctoMap 八叉树地图
- TSDF 体积重建
- 语义点云地图
- 3D 栅格地图
- 稠密重建

---

## 核心实现

### OctoMap

```python
import numpy as np

class OctoMap:
    def __init__(self, resolution=0.1):
        self.resolution = resolution
        self.max_depth = 16
        self.nodes = {}
        
    def update(self, points, pose):
        """更新 3D 点云地图"""
        for point in points:
            # 变换到世界坐标系
            world_point = self.transform(point, pose)
            
            # 更新体素
            self.update_voxel(world_point, occupied=True)
            
    def update_voxel(self, point, occupied=True):
        """更新体素"""
        key = self.point_to_key(point)
        
        if key not in self.nodes:
            self.nodes[key] = {
                'probability': 0.5,
                'children': {}
            }
            
        # 递归更新
        self.update_node(self.nodes[key], point, occupied)
        
    def point_to_key(self, point):
        """点坐标转体素键"""
        depth = self.max_depth
        scale = self.resolution * (2 ** (self.max_depth - depth))
        return (
            int(point[0] / scale),
            int(point[1] / scale),
            int(point[2] / scale)
        )
```

### TSDF 体积融合

```python
class TSDFVolume:
    def __init__(self, volume_size=1.0, resolution=256):
        self.resolution = resolution
        self.voxel_size = volume_size / resolution
        self.volume = np.zeros((resolution, resolution, resolution), dtype=np.float32)
        
    def integrate(self, depth_image, K, T):
        """融合深度图"""
        h, w = depth_image.shape
        
        for v in range(0, h, 2):
            for u in range(0, w, 2):
                d = depth_image[v, u]
                
                if d <= 0 or d > 5.0:
                    continue
                    
                # 反投影
                x = (u - K[0, 2]) * d / K[0, 0]
                y = (v - K[1, 2]) * d / K[1, 1]
                z = d
                
                # 变换到世界坐标系
                point_world = T @ np.array([x, y, z, 1])
                
                # 体积索引
                ix = int(point_world[0] / self.voxel_size)
                iy = int(point_world[1] / self.voxel_size)
                iz = int(point_world[2] / self.voxel_size)
                
                # TSDF 更新
                if 0 <= ix < self.resolution:
                    self.update_tsdf(ix, iy, iz, point_world[2] - z)
                    
    def update_tsdf(self, x, y, z, sdf):
        """更新 TSDF 值"""
        self.volume[x, y, z] = np.clip(sdf / self.voxel_size, -1, 1)
```
