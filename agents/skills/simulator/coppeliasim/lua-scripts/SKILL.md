---
name: lua-scripts
description: CoppeliaSim Lua 脚本技能 - 场景脚本、-child 脚本、远程 API
argument-hint: CoppeliaSim Lua OR 场景脚本 OR 远程API
user-invocable: true
---

# CoppeliaSim Lua Scripts Skill

> 用于 CoppeliaSim Lua 脚本

---

## 快速参考

### 基本脚本

```lua
-- 获取对象
robot = sim.getObjectHandle('Robot')

-- 主循环
function sysCall_thread()
    while true do
        -- 获取传感器数据
        sensor = sim.readSensor(sensorHandle)
        
        -- 控制电机
        sim.setJointTargetVelocity(motor, 1.0)
        
        sim.wait(0.05)
    end
end
```

---

## 另见

- [remote-api](../remote-api/) - 远程 API