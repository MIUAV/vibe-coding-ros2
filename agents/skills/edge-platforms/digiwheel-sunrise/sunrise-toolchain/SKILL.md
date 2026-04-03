---
name: sunrise-toolchain
description: 旭日交叉编译工具链 - aarch64 交叉编译 ARM开发
argument-hint: 交叉编译 OR aarch64 OR ARM OR toolchain
user-invocable: true
---

# Sunrise 交叉编译技能

> 旭日系列交叉编译环境

## 何时使用

- 交叉编译应用
- 驱动开发
- 性能优化

## 工具链

```bash
# 安装aarch64工具链
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 编译
aarch64-linux-gnu-gcc -o app main.c -march=armv8.2a
```

## CMake配置

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
```

## 运行

```bash
# 复制到设备
scp target/aarch64/user@device:/home/
```