# i18n — 多语言文档

> 本目录存放 vibe-coding-ros2 项目文档的多语言翻译版本。

## 目录结构

```
i18n/
├── README.md            # 本文件
├── translate-docs.sh    # 翻译工作流脚本
├── README.zh-CN.md      # 中文版 README
├── README.ja-JP.md      # 日文版 README
├── README.ko-KR.md      # 韩文版 README
├── CLAUDE.md.zh-CN.md   # 中文版 CLAUDE.md
├── CLAUDE.md.ja-JP.md   # 日文版 CLAUDE.md
└── ...
```

## 翻译工作流

### 环境准备

```bash
# DeepL API（推荐，准确率高）
export DEEPL_API_KEY=your_key_here

# 或 Google Translate（无需 API key）
# 自动检测，无需配置
```

### 翻译单个文件

```bash
# DeepL 翻译
bash i18n/translate-docs.sh README.md ja-JP --deepl

# Google 翻译
bash i18n/translate-docs.sh CLAUDE.md zh-CN --google
```

### 翻译整个目录

```bash
# 翻译整个 memory-bank（多语言同时生成）
for lang in ja-JP ko-KR; do
  bash i18n/translate-docs.sh agents/memory-bank/ $lang --deepl
done
```

### 翻译所有核心文档

```bash
for lang in ja-JP ko-KR zh-CN; do
  bash i18n/translate-docs.sh README.md $lang --deepl
  bash i18n/translate-docs.sh CLAUDE.md $lang --deepl
  bash i18n/translate-docs.sh AGENTS.md $lang --deepl
done
```

## 支持语言

| 语言代码 | 说明 |
|---------|------|
| `zh-CN` | 简体中文 |
| `zh-TW` | 繁体中文 |
| `ja-JP` | 日语 |
| `ko-KR` | 韩语 |
| `en-US` | 英语（参考） |
| `de-DE` | 德语 |
| `fr-FR` | 法语 |
| `es-ES` | 西班牙语 |

## 翻译原则

1. **保持格式**：Markdown 结构不变
2. **代码块不翻译**：代码片段（``` ``` ``` 内的内容）原样保留
3. **术语一致**：建立术语表，避免同一术语多种翻译
4. **CI 集成**：PR 时自动检查翻译完整性

## 术语表（Glossary）

| 英文 | 中文 | 日文 | 韩文 |
|------|------|------|------|
| Lifecycle Node | 生命周期节点 | ライフサイクルノード | 라이프사이클 노드 |
| CMake | CMake | CMake | CMake |
| QoS | 服务质量 | QoS（サービス品質）| QoS |
| Nav2 | Nav2 | Nav2 | Nav2 |
| MoveIt | MoveIt | MoveIt | MoveIt |
| Gazebo | Gazebo | Gazebo | Gazebo |
| colcon | colcon | colcon | colcon |
| ament | ament | ament | ament |
|ament_export | ament导出 | amentエクスポート | ament 내보내기 |
