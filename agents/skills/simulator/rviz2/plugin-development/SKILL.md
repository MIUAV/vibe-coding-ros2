---
name: plugin-development
description: RViz2 插件开发技能 - 自定义显示类型、工具插件、面板插件
argument-hint: "rviz插件开发" / "自定义显示" / "工具插件"
user-invocable: true
---

# RViz2 Plugin Development Skill

> 用于开发 RViz2 插件和扩展

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建自定义显示类型
- 开发工具插件
- 添加新的面板
- 扩展 RViz2 功能

---

## 快速参考

### 创建插件包

```bash
cd ~/ros2_ws/src
ros2 pkg create rviz2_my_plugin --dependencies rviz_rendering rviz_ogre_vendor
cd rviz2_my_plugin
mkdir src
```

---

## 显示插件

### 基本显示类

```cpp
#include <rviz_common/display.hpp>

namespace rviz_my_plugin
{
  class MyDisplay : public rviz_common::Display
  {
    Q_OBJECT
  public:
    MyDisplay();
    ~MyDisplay() override;
    
  protected:
    void onInitialize() override;
    void update(float dt, ros::Time time) override;
    void reset() override;
    
  private:
    rviz_rendering::Object * object_;
    Ogre::SceneNode * scene_node_;
  };
}
```

### 实现文件

```cpp
#include "my_display.h"

namespace rviz_my_plugin
{
  MyDisplay::MyDisplay()
    : Display()
  {
    // 设置显示属性
    auto * category = property_manager_->createCategory("My Properties");
    
    // 添加属性
    color_property_ = new rviz_common::properties::ColorProperty(
      "Color", QColor(255, 255, 255),
      "Color of the object",
      this, SLOT(updateColor()));
  }
  
  void MyDisplay::onInitialize()
  {
    // 创建场景对象
    scene_node_ = scene_manager_->getRootSceneNode()->createChildSceneNode();
    
    // 初始化对象
    object_ = new rviz_rendering::Shape(
      rviz_rendering::Shape::Type::Sphere,
      scene_manager_,
      scene_node_);
  }
  
  void MyDisplay::update(float dt, ros::Time time)
  {
    // 更新显示逻辑
  }
  
  void MyDisplay::reset()
  {
    // 重置状态
  }
}

#include <pluginlib/class_list_macros.hpp>
PLUGINLIB_EXPORT_CLASS(rviz_my_plugin::MyDisplay, rviz_common::Display)
```

---

## CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.10)
project(rviz2_my_plugin)

# 找到 RViz2
find_package(ament_cmake REQUIRED)
find_package(rviz_common REQUIRED)
find_package(rviz_rendering REQUIRED)
find_package(rviz_ogre_vendor REQUIRED)

# 创建插件库
add_library(rviz2_my_plugin SHARED
  src/my_display.cpp
)

target_link_libraries(rviz2_my_plugin
  rviz_common::rviz_common
  rviz_rendering::rviz_rendering
)

# 安装插件
pluginlib_export_plugin_config_file(rviz2_my_plugin_plugins.xml)

# 安装
ament_export_targets(rviz2_my_pluginTargets HAS_LIBRARY_TARGET)
ament_install_hooks(PROJECT space "${ament_cMAKE_PROJECT_HOOK_INSTALL_SPACE_DIR}/rviz2_my_plugin_hooks.cmake")

install(
  TARGETS rviz2_my_plugin
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include
)
```

### 插件描述文件

```xml
<!-- rviz2_my_plugin_plugins.xml -->
<library path="rviz2_my_plugin">
  <class name="rviz_my_plugin/MyDisplay"
         type="rviz_my_plugin::MyDisplay"
         base_class_type="rviz_common::Display">
    <description>My custom display plugin</description>
  </class>
</library>
```

---

## 工具插件

### 基本工具类

```cpp
#include <rviz_common/tool.hpp>

namespace rviz_my_plugin
{
  class MyTool : public rviz_common::Tool
  {
    Q_OBJECT
  public:
    MyTool();
    ~MyTool() override;
    
    virtual void onInitialize() override;
    virtual void activate() override;
    virtual void deactivate() override;
    
    virtual int processKeyEvent(QKeyEvent *event, rviz_common::RenderPanel *panel) override;
    virtual int processMouseEvent(rviz_common::MouseEvent &event, rviz_common::RenderPanel *panel) override;
    
  private:
    void onSelect(const Ogre::Vector3 &point);
  };
}
```

### 工具实现

```cpp
#include "my_tool.h"

namespace rviz_my_plugin
{
  MyTool::MyTool()
    : Tool()
  {
    shortcut_key_ = 'm';  // 快捷键
  }
  
  void MyTool::onInitialize()
  {
    // 设置光标
    cursor_ = QCursor(Qt::CrossCursor);
  }
  
  void MyTool::activate()
  {
    // 激活工具
  }
  
  void MyTool::deactivate()
  {
    // 停用工具
  }
  
  int MyTool::processMouseEvent(rviz_common::MouseEvent &event, rviz_common::RenderPanel *panel)
  {
    if (event.leftDown())
    {
      // 获取 3D 位置
      Ogre::Vector3 point;
      if (panel->getManager()->getScene()->getRaycastResult(event.x(), event.y(), point))
      {
        onSelect(point);
      }
    }
    return 0;
  }
}

#include <pluginlib/class_list_macros.hpp>
PLUGINLIB_EXPORT_CLASS(rviz_my_plugin::MyTool, rviz_common::Tool)
```

---

## 面板插件

### 基本面板类

```cpp
#include <rviz_common/panel.hpp>

namespace rviz_my_plugin
{
  class MyPanel : public rviz_common::Panel
  {
    Q_OBJECT
  public:
    MyPanel(QWidget *parent = nullptr);
    
  protected:
    void load(const rviz_common::Config &config) override;
    void save(rviz_common::Config config) const override;
    
  private:
    QPushButton * button_;
    QLabel * label_;
    
  private Q_SLOTS:
    void onButtonClicked();
  };
}
```

### 面板实现

```cpp
#include "my_panel.h"

namespace rviz_my_plugin
{
  MyPanel::MyPanel(QWidget *parent)
    : Panel(parent)
  {
    // 创建 UI
    QVBoxLayout * layout = new QVBoxLayout;
    
    button_ = new QPushButton("Click Me");
    label_ = new QLabel("Status: Ready");
    
    layout->addWidget(button_);
    layout->addWidget(label_);
    
    setLayout(layout);
    
    connect(button_, SIGNAL(clicked()), this, SLOT(onButtonClicked()));
  }
  
  void MyPanel::load(const rviz_common::Config &config)
  {
    Panel::load(config);
    // 加载配置
  }
  
  void MyPanel::save(rviz_common::Config config) const
  {
    Panel::save(config);
    // 保存配置
  }
  
  void MyPanel::onButtonClicked()
  {
    label_->setText("Clicked!");
  }
}

#include <pluginlib/class_list_macros.hpp>
PLUGINLIB_EXPORT_CLASS(rviz_my_plugin::MyPanel, rviz_common::Panel)
```

---

## 属性系统

### 创建属性

```cpp
#include <rviz_common/properties/property.hpp>

// 创建属性
auto * prop = property_manager_->createProperty<BoolProperty>(
  "Enabled", "Enable display", true, this, SLOT(onEnableChanged()));

auto * color_prop = property_manager_->createProperty<ColorProperty>(
  "Color", "Object color", QColor(255, 0, 0), this, SLOT(onColorChanged()));

auto * float_prop = property_manager_->createProperty<FloatProperty>(
  "Scale", "Object scale", 1.0, this, SLOT(onScaleChanged()));

auto * string_prop = property_manager_->createProperty<StringProperty>(
  "Topic", "Topic name", "/my_topic", this, SLOT(onTopicChanged()));
```

---

## 场景管理

### 创建对象

```cpp
// 创建网格对象
auto * mesh = new rviz_rendering::MeshObject(scene_manager_, scene_node_);

// 创建线段
auto * line = new rviz_rendering::Line(scene_manager_, scene_node_);
line->setPoints(start, end);
line->setColor(r, g, b, a);

// 创建箭头
auto * arrow = new rviz_rendering::Arrow(scene_manager_, scene_node_);
arrow->setDirection(direction);
arrow->setScale(scale);

// 创建文本
auto * text = new rviz_rendering::MovableText("Label", "Arial", 0.1);
text->setPosition(position);
```

---

## 构建和安装

```bash
# 构建
cd ~/ros2_ws
colcon build --packages-select rviz2_my_plugin

# 运行
rviz2
# 添加显示时选择 rviz_my_plugin/MyDisplay
```

---

## 常见问题

### 问题 1: 插件不加载

**解决方案**：检查插件描述文件路径，确认库文件安装位置正确

---

## 另见

- [display-configuration](../display-configuration/) - 显示配置
- [marker-visualization](../marker-visualization/) - 标记可视化