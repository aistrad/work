---
name: vibe-knowledge
description: VibeLife Knowledge（Curator 专注版）— 仅负责资料搜寻、质量评估与下载归档；不包含向量化入库。
---

# Overview and Intent

## 0. 适用场景与核心目标

- **适用对象**：VibeLife 项目开发者，需要快速搜集高质量知识资料
- **核心目标**：
  1) 多源搜索并筛选高质量资料
  2) 评估来源可信度与完整性
  3) 下载并归档到 **`/data/knowledge`**

## 1. 下载目录规范

```
/data/knowledge/
├── bazi/
├── zodiac/
├── mbti/
└── misc/
```

**支持格式**：`.md`, `.txt`, `.pdf`, `.epub`, `.docx`, `.html`

---

# Workflows

## Workflow 0：默认（Curator 全流程）

**命令**：
```bash
/vibe-knowledge
/vibe-knowledge --topic bazi
```

**步骤**：
1. 多源搜索（GitHub、Google、Kanripo 等）
2. 质量评估（完整性、准确性、来源可信度）
3. 下载与归档到 `/data/knowledge/<topic>/`
4. 输出下载清单与简短总结

## Workflow 1：仅搜索（search）

**命令**：
```bash
/vibe-knowledge search --topic zodiac
```

**输出**：
- 候选来源列表（含评分与理由）

## Workflow 2：下载与归档（download）

**命令**：
```bash
/vibe-knowledge download --topic mbti
```

**输出**：
- 下载文件清单
- 归档路径（`/data/knowledge/<topic>/`）

---

# Notes

- 本技能 **不做** 向量化入库，不触发 ingestion worker。
- 如需入库处理，请使用 `vibeknowledge`（数据同步与向量化）。

---

# Changelog

## 2026-01-11
- 从 `vibelife-knowledge` 改名为 `vibe-knowledge`
- 聚焦 Curator 搜寻与下载
- 统一下载目标目录为 `/data/knowledge`
