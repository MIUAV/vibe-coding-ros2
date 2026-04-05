# industrial-integration — Agent 执行计划

## Phase 0: PLC 通信确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list | grep -E "plc|modbus|opcua"
mcp__ros2__service_list | grep -E "emergency|stop"
```

### 验证
- [ ] PLC IP 地址已知
- [ ] Modbus/OPCUA 配置正确
- [ ] 网络连通性正常

---

## Phase 1: Modbus/OPCUA 驱动

### Agent
`MCP-BUILD`

### 目标
实现 ROS2 与 PLC 的通信驱动。

### 实现检查点
- [ ] `ModbusClient` 或 `OPCUAClient` 节点
- [ ] 读取寄存器映射（机器人状态 → PLC）
- [ ] 写入寄存器映射（PLC → 机器人指令）
- [ ] 通信超时检测（> 100ms）
- [ ] QoS: RELIABLE（工业控制必须可靠）

### 验证
- [ ] 读/写寄存器正确
- [ ] 通信延迟 < 50ms
- [ ] 通信超时检测工作

---

## Phase 2: IEC 任务调度

### Agent
`MCP-BUILD`

### 目标
实现 IEC 61131-3 风格的顺序功能图（SFC）任务调度。

### 实现检查点
- [ ] `TaskScheduler` 类（SFC 状态机）
- [ ] 任务状态：WAIT → READY → RUNNING → DONE → WAIT
- [ ] PLC 指令解码（工序号 → 目标位置）
- [ ] 任务完成确认回传

### 验证
- [ ] 正确响应 PLC 生产指令
- [ ] 任务切换时间 < 1s

---

## Phase 3: 急停安全

### Agent
`MCP-BUILD`

### 目标
急停信号的双通道安全处理。

### 实现检查点
- [ ] `SafetyMonitor` 类
- [ ] 急停信号检测（订阅 `/emergency_stop`）
- [ ] 急停时立即停止所有运动
- [ ] PLC 报警状态回传
- [ ] 恢复序列（急停解除 → 复位 → 继续）

### 验证
- [ ] 急停响应时间 < 10ms
- [ ] 急停后机器人立即停止
- [ ] 恢复流程正确

---

## Phase 4: 生产线集成测试

### Agent
`MCP-SIM`

### 验证
- [ ] 连续生产 100 个工件
- [ ] 无通信错误
- [ ] 无急停误触发
- [ ] 任务完成率 100%
