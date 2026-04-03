---
name: px4-dev-env
description: PX4 开发环境配置 - Ubuntu/WSL工具链安装、VSCode配置、Docker开发环境
argument-hint: "配置PX4开发环境" / "安装工具链" / "VSCode PX4" / "Docker开发"
user-invocable: true
---

# PX4 开发环境技能

> 用于配置 PX4 软件开发所需的工具链和环境

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装开发工具链
- 配置 VSCode 开发环境
- 使用 Docker 构建
- 设置 WSL 开发环境

---

## 快速参考

### Ubuntu 24.04/22.04

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/PX4/PX4-Autopilot/main/Tools/setup/ubuntu.sh

# 运行安装
bash ubuntu.sh

# 重启终端
source ~/.bashrc
```

### 验证安装

```bash
# 检查工具链
arm-none-eabi-gcc --version
python3 --version
cmake --version
```

---

## Ubuntu 工具链安装

### 步骤 1: 安装基础依赖

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    wget \
    curl \
    zip \
    unzip \
    python3 \
    python3-pip \
    python3-jinja2 \
    python3-rospkg \
    python3-yaml
```

### 步骤 2: 安装 GCC 工具链

```bash
# ARM Cortex-M4 (NuttX)
sudo apt install -y gcc-arm-none-eabi

# ARM Cortex-A (Linux)
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```

### 步骤 3: 安装 Python 依赖

```bash
pip3 install --user \
    numpy \
    toml \
    pyserial \
    pyyaml \
    empy \
    jinja2
```

### 步骤 4: 安装仿真依赖

```bash
# Gazebo (Ubuntu 22.04)
sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt update
sudo apt install -y gz-garden
```

---

## Windows WSL 开发

### 安装 WSL2

```powershell
# 以管理员身份打开 PowerShell
wsl --install -d Ubuntu-22.04
```

### WSL 中安装 PX4 工具链

```bash
# 在 WSL 中
cd ~
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd PX4-Autopilot
bash Tools/setup/ubuntu.sh
```

### 访问飞控 USB

```bash
# 添加用户到 dialout 组
sudo usermod -a -G dialout $USER

# 重新登录

# 通过 USB 访问飞控
# WSL 中使用 USB IP 地址或 COM 端口
```

---

## VSCode 配置

### 安装 VSCode

```bash
# 下载并安装 VSCode
# https://code.visualstudio.com/
```

### PX4 扩展

```
VSCode → Extensions
→ 安装:
  - C/C++ (Microsoft)
  - Python (Microsoft)
  - YAML (Red Hat)
```

### PX4 工作区

```bash
# 打开 PX4 源码目录
code .
```

### 推荐扩展配置

```json
{
  "C_Cpp.default.configurationProvider": "ms-vscode.cpptools",
  "editor.formatOnSave": true,
  "files.associations": {
    "*.cmake": "cmake",
    "CMakeLists.txt": "cmake"
  }
}
```

---

## Docker 开发环境

### 使用 PX4 Docker

```bash
# 克隆源码
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd PX4-Autopilot

# 运行 Docker
./Tools/docker_run.sh

# 在容器中编译
make px4_sitl gz_x500
```

### 自定义 Docker 镜像

```dockerfile
FROM px4io/px4-dev-ros2-jammy:latest

# 安装额外依赖
RUN apt-get update && apt-get install -y \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /src
```

---

## 常用工具

### Git 配置

```bash
# 克隆 PX4 仓库
git clone https://github.com/PX4/PX4-Autopilot.git --recursive

# 更新子模块
git submodule update --recursive

# 切换版本
git checkout v1.14.0
```

### 构建工具

```bash
# 列出可用目标
make list_config_targets

# 查看帮助
make help
```

---

## 故障排除

### 编译失败

```bash
# 清理构建目录
make distclean

# 更新子模块
git submodule update --recursive

# 重新构建
make px4_sitl gz_x500
```

### 工具链缺失

```bash
# 检查安装
which arm-none-eabi-gcc
which python3

# 重新运行安装脚本
bash Tools/setup/ubuntu.sh
```

### Python 包问题

```bash
# 重新安装依赖
pip3 install --user -r Tools/setup/requirements.txt
```

---

## 相关文档

- [PX4 开发工具链](https://docs.px4.io/main/en/dev_setup/dev_env.html)
- [Ubuntu 设置](https://docs.px4.io/main/en/dev_setup/dev_env_linux_ubuntu.html)
- [VSCode 配置](https://docs.px4.io/main/en/dev_setup/vscode.html)