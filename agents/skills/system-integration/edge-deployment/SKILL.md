---
name: edge-deployment
description: 边缘部署 — Docker/容器化、资源限制、NVIDIA JetPack、实时内核配置，适用于机器人边缘计算设备
argument-hint: 边缘部署 OR edge deployment OR Docker OR JetPack OR NVIDIA OR 嵌入式 OR 资源限制
user-invocable: true
---

# edge-deployment — 边缘部署 SKILL

## Docker 部署

```dockerfile
FROM ros:humble

WORKDIR /workspace
COPY . .

# 资源限制
MEM_LIMIT: 2g
CPUS: 4

CMD ["bash", "entrypoint.sh"]
```

## NVIDIA JetPack

| 组件 | 版本 |
|------|------|
| JetPack | 5.1+ |
| CUDA | 11.8+ |
| TensorRT | 8.5+ |
| L4T | 35.x |

## 实时性

```bash
# Linux PREEMPT_RT 内核
sudo apt install linux-image-rt
# 启动参数: processor.max_cstate=1 intel_idle.max_cstate=0
```

## 禁止

- ❌ Docker 不设资源限制（OOM killer）
- ❌ Jetson 用桌面版 CUDA（版本不匹配）
