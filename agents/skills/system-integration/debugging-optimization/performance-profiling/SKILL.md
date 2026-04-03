---
name: performance-profiling
description: 性能分析技能 - 延迟分析、CPU/内存分析、跟踪工具、性能优化
argument-hint: 性能分析 OR profiling OR latency OR perf OR optimization
user-invocable: true
---

# 性能分析技能

> ROS2 性能分析与优化

---

## 何时使用

当需要以下帮助时使用此技能：
- 延迟分析
- CPU/内存分析
- 跟踪工具
- 性能优化
- 瓶颈定位

---

## 核心实现

### 延迟分析

```python
import time
import numpy as np

class LatencyAnalyzer:
    def __init__(self):
        self.latencies = []
        
    def measure_callback_latency(self, callback, *args, **kwargs):
        """测量回调延迟"""
        start = time.monotonic()
        result = callback(*args, **kwargs)
        end = time.monotonic()
        
        latency = (end - start) * 1000  # ms
        self.latencies.append(latency)
        
        return result
        
    def get_statistics(self):
        """获取延迟统计"""
        if not self.latencies:
            return {}
            
        return {
            'mean': np.mean(self.latencies),
            'std': np.std(self.latencies),
            'min': np.min(self.latencies),
            'max': np.max(self.latencies),
            'p50': np.percentile(self.latencies, 50),
            'p95': np.percentile(self.latencies, 95),
            'p99': np.percentile(self.latencies, 99)
        }
        
    def reset(self):
        """重置统计"""
        self.latencies = []
```

### 端到端延迟测量

```python
class EndToEndLatencyMeasure:
    def __init__(self, node):
        self.node = node
        self.timestamps = {}
        
        # 订阅消息
        self.sub = node.create_subscription(
            LaserScan, '/scan', self.scan_callback, 10)
            
        # 发布延迟统计
        self.pub = node.create_publisher(Float64, '/latency/scan', 10)
        
    def scan_callback(self, msg):
        # 记录接收时间
        recv_time = self.node.get_clock().now().nanoseconds
        
        # 获取消息头时间
        if msg.header.stamp.sec > 0:
            sent_time = msg.header.stamp.sec * 1e9 + msg.header.stamp.nanosec
            latency_ms = (recv_time - sent_time) / 1e6
            
            latency_msg = Float64()
            latency_msg.data = latency_ms
            self.pub.publish(latency_msg)
```

### CPU/内存分析

```bash
# top 命令
top -p $(pidof -x node_executable)

# pidstat (sysstat)
pidstat -p $(pidof node) 1

# 内存分析
valgrind --tool=massif ./executable
# 查看结果
ms_print massif.out.*

# CPU 热点分析
perf record -g -p $(pidof node)
perf report
```

### ROS2 内置性能分析

```python
# 使用 rclpy 的性能分析
import cProfile
import pstats

class PerformanceProfiler:
    def __init__(self):
        self.profiler = cProfile.Profile()
        
    def profile_function(self, func, *args, **kwargs):
        """分析函数性能"""
        self.profiler.enable()
        result = func(*args, **kwargs)
        self.profiler.disable()
        
        stats = pstats.Stats(self.profiler)
        stats.sort_stats('cumulative')
        stats.print_stats(20)
        
        return result
        
    def get_hotspots(self, n=10):
        """获取热点函数"""
        stats = pstats.Stats(self.profiler)
        stats.sort_stats('tottime')
        return stats.print_stats(n)
```

### 跟踪工具 (tracetools)

```bash
# 安装
sudo apt install ros-iron-tracetools

# 启动跟踪
ros2 launch tracetools launch.py

# 跟踪文件
ls ~/.ros/trace/

# 分析
python3 -m tracetools_analyze ~/.ros/trace/.../
```

### 并行化优化

```python
class ParallelProcessor:
    def __init__(self, num_workers=4):
        from concurrent.futures import ThreadPoolExecutor
        self.executor = ThreadPoolExecutor(max_workers=num_workers)
        
    def process_parallel(self, items, process_func):
        """并行处理"""
        futures = []
        for item in items:
            future = self.executor.submit(process_func, item)
            futures.append(future)
            
        results = [f.result() for f in futures]
        return results
        
    def shutdown(self):
        self.executor.shutdown()
```

### 内存优化

```python
class ObjectPool:
    """对象池 - 减少内存分配"""
    
    def __init__(self, factory, pool_size=10):
        self.factory = factory
        self.pool = [factory() for _ in range(pool_size)]
        
    def acquire(self):
        if self.pool:
            return self.pool.pop()
        return self.factory()
        
    def release(self, obj):
        if len(self.pool) < 100:  # 限制池大小
            self.pool.append(obj)
```

### 实时性优化

```bash
# 实时内核
uname -r  # 检查是否为 PREEMPT_RT 内核

# 线程优先级
chrt -f 10 -p $(pidof node)  # FIFO 调度，优先级 10

# CPU 亲和性
taskset -c 2-3 $(pidof node)  # 绑定到 CPU 2-3
```
