#!/bin/bash
# ros2-build-feedback.sh — AI 代码生成后的自动编译验证
# 用法: ./ros2-build-feedback.sh <package_path>
# 退出码: 0=编译成功, 1=编译失败, 2=无colcon包

set -e

PACKAGE_PATH="${1:-.}"

echo "============================================"
echo "  ros2-build-feedback: 自动编译验证"
echo "============================================"
echo "包路径: $PACKAGE_PATH"
echo ""

# 切换到包目录
cd "$(dirname "$0")/../../" && cd "$PACKAGE_PATH" 2>/dev/null || {
    echo "错误: 无法进入目录: $PACKAGE_PATH"
    exit 2
}

# 检查是否是 ROS2 包
if [ ! -f "package.xml" ]; then
    echo "错误: 不是 ROS2 包（无 package.xml）"
    exit 2
fi

PACKAGE_NAME=$(basename "$(pwd)")
echo "包名: $PACKAGE_NAME"
echo ""

# ── 执行编译 ──────────────────────────────────────────
echo ">>> 执行 colcon build ..."
echo ""

BUILD_OUTPUT=$(colcon build 2>&1)
BUILD_EXIT=$?

# ── 分析结果 ──────────────────────────────────────────
echo ""
echo "============================================"
echo "  编译结果分析"
echo "============================================"

if [ $BUILD_EXIT -eq 0 ]; then
    echo "✅ 编译成功（零错误）"
    echo ""
    echo "生成的文件:"
    find install -name "*.so" 2>/dev/null | head -5 | sed 's/^/  /'
    echo ""
    echo ">>> 编译验证通过 ✓"
    exit 0
fi

# ── 解析错误 ──────────────────────────────────────────
echo "❌ 编译失败（错误数统计）"
echo ""

# 统计错误类型
ERROR_TYPES=$(echo "$BUILD_OUTPUT" | grep -E "error:" | sed 's/:.*//' | sort | uniq -c | sort -rn)
if [ -n "$ERROR_TYPES" ]; then
    echo "错误类型统计:"
    echo "$ERROR_TYPES" | while read count rest; do
        printf "  %4d  %s\n" "$count" "$rest"
    done
    echo ""
fi

# ── 分类错误并给出修复建议 ───────────────────────────
echo "============================================"
echo "  错误分类 & 修复建议"
echo "============================================"

# 1. CMake 链接错误
if echo "$BUILD_OUTPUT" | grep -q "undefined reference\|ld: cannot find\|link error"; then
    echo ""
    echo "🔧 [CMake 链接错误] — 缺少 ament_export_dependencies"
    echo ""
    echo "   常见原因:"
    echo "   1. CMakeLists.txt 缺少: ament_export_dependencies(rclcpp)"
    echo "   2. add_library 的 target 没有 link 依赖库"
    echo "   3. 依赖的包没有正确 find_package"
    echo ""
    
    # 提取具体缺失的符号
    UNDEFINED=$(echo "$BUILD_OUTPUT" | grep "undefined reference" | head -3)
    if [ -n "$UNDEFINED" ]; then
        echo "   缺失符号示例:"
        echo "$UNDEFINED" | sed 's/^/   /'
        echo ""
    fi
    
    # 提取缺失的库
    MISSING_LIBS=$(echo "$BUILD_OUTPUT" | grep "cannot find -l" | sed 's/^/   /')
    if [ -n "$MISSING_LIBS" ]; then
        echo "   缺失库文件:"
        echo "$MISSING_LIBS"
        echo ""
    fi
fi

# 2. 头文件找不到
if echo "$BUILD_OUTPUT" | grep -q "fatal error:\|No such file or directory"; then
    echo ""
    echo "🔧 [头文件找不到] — include 路径配置错误"
    echo ""
    echo "   常见原因:"
    echo "   1. CMakeLists.txt 缺少: include_directories(include)"
    echo "   2. target_include_directories 没有添加到库目标"
    echo "   3. find_package 没有正确声明依赖"
    echo ""
    
    MISSING_HEADERS=$(echo "$BUILD_OUTPUT" | grep "fatal error:" | sed 's/fatal error: //' | sed "s/ //" | head -3)
    if [ -n "$MISSING_HEADERS" ]; then
        echo "   缺失的头文件:"
        echo "$MISSING_HEADERS" | sed 's/^/   /'
        echo ""
    fi
fi

# 3.ament_auto 缺失
if echo "$BUILD_OUTPUT" | grep -q "ament_auto not found\|ament_auto_find_build_dependencies"; then
    echo ""
    echo "🔧 [ament_auto 宏不存在]"
    echo ""
    echo "   解决方案: 在 CMakeLists.txt 顶部添加"
    echo '   ament_auto_find_build_dependencies()'
    echo ""
fi

# 4. Python 依赖问题
if echo "$BUILD_OUTPUT" | grep -q "ModuleNotFoundError\|No module named"; then
    echo ""
    echo "🔧 [Python 依赖缺失]"
    echo ""
    MISSING_PY=$(echo "$BUILD_OUTPUT" | grep "ModuleNotFoundError" | head -2 | sed 's/^/   /')
    echo "   $MISSING_PY"
    echo ""
    echo "   解决方案: pip install <module> 或在 package.xml 添加 <exec_depend>"
    echo ""
fi

# 5.ament_cmake 版本问题
if echo "$BUILD_OUTPUT" | grep -q "CMAKE_CXX_STANDARD"; then
    echo ""
    echo "🔧 [C++ 标准版本问题]"
    echo ""
    echo "   解决方案: 在 CMakeLists.txt 添加:"
    echo '   if(CMAKE_CXX_STANDARD LESS 17)'
    echo '     set(CMAKE_CXX_STANDARD 17)'
    echo '   endif()'
    echo ""
fi

# 6.ament_export 缺失（最重要！）
if echo "$BUILD_OUTPUT" | grep -q "ament_export\|ament_target_dependencies"; then
    echo ""
    echo "🔧 [ament_export_dependencies 缺失 — 这是最常见的错误]"
    echo ""
    echo "   完整正确格式（必须同时有这三行）:"
    echo '   ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)'
    echo '   ament_export_dependencies(rclcpp)'
    echo '   ament_export_include_directories(include)'
    echo '   ament_export_libraries(${PROJECT_NAME})'
    echo ""
fi

# 7. 未知错误
if echo "$BUILD_OUTPUT" | grep -qE "error:|undefined reference|cannot find"; then
    OTHER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "error:" | grep -v "ament_export\|undefined reference\|cannot find\|fatal error" | head -5)
    if [ -n "$OTHER_ERRORS" ]; then
        echo ""
        echo "📋 [其他错误]"
        echo "$OTHER_ERRORS" | sed 's/^/   /'
        echo ""
    fi
fi

# ── 修复命令建议 ───────────────────────────────────
echo "============================================"
echo "  快速修复命令"
echo "============================================"
echo ""
echo "# 查看完整编译输出"
echo "colcon build --event-handlers console_direct+ 2>&1 | tee build.log"
echo ""
echo "# 只重新编译指定包（更快）"
echo "colcon build --packages-select $PACKAGE_NAME"
echo ""
echo "# 清理后重新编译"
echo "rm -rf build/ install/ log/ && colcon build"
echo ""

# 输出原始错误供 AI 解析
echo "============================================"
echo "  原始错误（供 AI 修正使用）"
echo "============================================"
echo "$BUILD_OUTPUT" | grep -E "error:|warning:" | head -30

exit 1
