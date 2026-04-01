# i18n 多语言文档索引

本目录按语种拆分文档，每个语种目录固定包含两个文件：

- `README.md`：该语种的说明与导航
- `CHANGELOG.md`：该语种文档的变更记录

---

## 目录结构

```text
i18n/
├── README.md
├── en/
│   ├── README.md
│   └── CHANGELOG.md
└── zh-CN/
    ├── README.md
    └── CHANGELOG.md
```

---

## 语种入口

- 简体中文: `./zh-CN/README.md`
- English: `./en/README.md`

---

## 维护约定

新增语种时请遵循同样结构：

1. 创建语种目录（如 `ja-JP/`）
2. 补齐 `README.md` 和 `CHANGELOG.md`
3. 在本索引中加入对应入口
