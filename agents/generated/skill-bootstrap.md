# Skill Bootstrap

## 开发工作流

```
1. 读 i18n/zh-CN/AGENTS_CONCISE.md
2. 读 i18n/zh-CN/ANTI_PATTERNS.md（重点：C++ 指针/QoS/并发）
3. 读 skill-index.md（找对应 SKILL.md）
4. 读 SKILL.md（获取实现细节）
5. 生成代码
6. 自检（ANTI_PATTERNS 清单）
7. 更新 memory-bank/ROS2_MEMORY.md
```

## 质量门控

- CMakeLists.txt 必检：find_package / ament_target_dependencies / install / ament_package
- package.xml 必检：<depend> 完整 / Format 3
- C++ 必检：make_shared / QoS 声明 / rclcpp::init+shutdown
- 完成后提醒用户 source install/setup.bash
