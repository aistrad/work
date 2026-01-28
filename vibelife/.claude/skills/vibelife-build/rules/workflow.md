# VibeLife Skill 创建工作流详解

## Phase 1: 需求分析

### 1.1 核心问题清单

```
□ Skill ID (英文小写，如 psych, zodiac)
□ Skill 中文名称
□ 一句话描述 (30字以内)
□ 详细描述 (100字以内)
□ 触发词列表 (中英文，逗号分隔)
□ 分类 (wellness/fortune/career/relationship/lifestyle)
□ 定价层级 (free/professional/enterprise)
□ 是否需要出生信息
□ 是否需要计算资源
```

### 1.2 功能规划

```
□ 核心功能 (3-5个)
□ 工具类型:
  - 计算工具 (处理数据)
  - 展示工具 (渲染卡片)
  - 动作工具 (保存/触发)
□ 卡片类型:
  - 表单卡片 (收集输入)
  - 结果卡片 (展示输出)
  - 交互卡片 (用户操作)
□ 规则文件 (知识库章节)
```

### 1.3 知识研究

- 搜索相关 GitHub 项目
- 查找专业文献/标准
- 参考现有实现

## Phase 2: 设计文档

### 2.1 文档结构

```
docs/components/{skill_name}/
├── README.md              # 快速概览 (100-200行)
├── DESIGN.md              # 完整设计 (500-1500行)
├── KNOWLEDGE_BASE.md      # 知识架构 (可选，1000+行)
├── TOOLS_AND_ASSESSMENTS.md  # 工具设计 (可选，500+行)
└── TECHNICAL_SPEC.md      # 技术规格 (可选，500+行)
```

### 2.2 DESIGN.md 大纲

```markdown
# {Skill 名称} 设计文档

## 1. 概述
### 1.1 定位
### 1.2 目标用户
### 1.3 核心价值

## 2. 功能设计
### 2.1 功能列表
### 2.2 用户流程
### 2.3 交互设计

## 3. 技术架构
### 3.1 后端设计
### 3.2 前端设计
### 3.3 数据模型

## 4. 知识库
### 4.1 理论基础
### 4.2 规则系统
### 4.3 提示词设计

## 5. 实现计划
### 5.1 MVP 范围
### 5.2 迭代计划
```

## Phase 3: 后端实现

### 3.1 目录结构

```
apps/api/skills/{skill_name}/
├── SKILL.md           # 元数据 + 规则入口
├── tools/
│   ├── tools.yaml     # 工具声明
│   └── handlers.py    # 工具实现
└── rules/
    ├── _index.md      # 规则索引
    └── {topic}.md     # 具体规则
```

### 3.2 SKILL.md 编写规范

```markdown
---
# YAML Frontmatter - 必填字段
name: skill_id
description: |
  功能描述
  触发词：word1, word2, word3
category: wellness
tier: professional
requires_birth_info: false
requires_compute: false
---

# Skill 中文名

## 专家身份
你是 [专业领域] 专家，具备 [核心能力]。

## 工具使用规则

### 必须使用工具的场景
- 场景1 → 使用 tool_name
- 场景2 → 使用 tool_name

### 工具调用顺序
1. 先调用 X
2. 再调用 Y
3. 最后调用 Z

## 对话风格
- 风格特点1
- 风格特点2

## 安全边界
- 边界1
- 边界2
```

### 3.3 tools.yaml 编写规范

```yaml
version: "1.0"
skill: skill_id

tools:
  # === 计算工具 ===
  compute:
    - name: calculate_something
      description: 计算某个结果
      parameters:
        - name: input_data
          type: object
          required: true
          description: 输入数据
      returns:
        type: object
        description: 计算结果

  # === 展示工具 ===
  display:
    - name: show_result
      description: 展示结果卡片
      card_type: result_card
      parameters:
        - name: data
          type: object
          required: true

  # === 动作工具 ===
  action:
    - name: save_progress
      description: 保存进度
      parameters:
        - name: session_id
          type: string
          required: true
```

### 3.4 handlers.py 编写规范

```python
"""
{Skill Name} 工具处理器
"""

from typing import Any, Dict
from ...services.tool_registry import ToolRegistry, tool_handler, ToolContext

# ═══════════════════════════════════════════════════════════════════════════
# 计算工具
# ═══════════════════════════════════════════════════════════════════════════

@tool_handler("calculate_something")
async def execute_calculate_something(
    args: Dict[str, Any],
    context: ToolContext
) -> Dict[str, Any]:
    """计算某个结果"""
    input_data = args.get("input_data", {})

    # 计算逻辑
    result = process_data(input_data)

    return {
        "success": True,
        "result": result
    }

# ═══════════════════════════════════════════════════════════════════════════
# 展示工具
# ═══════════════════════════════════════════════════════════════════════════

@tool_handler("show_result")
async def execute_show_result(
    args: Dict[str, Any],
    context: ToolContext
) -> Dict[str, Any]:
    """展示结果卡片"""
    data = args.get("data", {})

    # 委托给 show_card
    return await ToolRegistry.execute(
        "show_card",
        {
            "card_type": "result_card",
            "data": data
        },
        context
    )
```

## Phase 4: 前端实现

### 4.1 目录结构

```
apps/web/src/skills/{skill_name}/
├── index.ts           # 入口 (导入卡片，导出配置)
├── config.ts          # 配置常量
└── cards/
    ├── index.ts       # 卡片导出
    ├── ResultCard.tsx # 结果卡片
    └── FormCard.tsx   # 表单卡片
```

### 4.2 config.ts 模板

```typescript
export const SKILL_CONFIG = {
  id: "skill_id",
  name: "Skill 中文名",
  description: "描述",
  category: "wellness",
  tier: "professional",

  cardTypes: {
    resultCard: "result_card",
    formCard: "form_card",
  },
} as const;

export default SKILL_CONFIG;
```

### 4.3 卡片组件模板

```tsx
"use client";

import React from "react";

interface ResultCardProps {
  data: {
    title: string;
    content: string;
    // ...
  };
  onAction?: (action: string, payload?: any) => void;
}

export default function ResultCard({ data, onAction }: ResultCardProps) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 border-b border-gray-100">
        <h3 className="text-lg font-semibold text-gray-900">
          {data.title}
        </h3>
      </div>

      {/* Content */}
      <div className="p-6">
        {data.content}
      </div>

      {/* Actions */}
      {onAction && (
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-100">
          <button
            onClick={() => onAction("next")}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg"
          >
            继续
          </button>
        </div>
      )}
    </div>
  );
}
```

### 4.4 CardRegistry 更新

```typescript
// 在 CardRegistry.ts 的 CARD_TYPES 中添加:
// {Skill Name}
SKILL_RESULT: 'result_card',
SKILL_FORM: 'form_card',

// 在 initCards.ts 中添加懒加载:
registerLazyCard(
  CARD_TYPES.SKILL_RESULT,
  () => import('./skill_name/cards/ResultCard')
);
```

## Phase 5: 验证清单

```
□ TypeScript 编译通过
□ 卡片组件导入正常
□ CardRegistry 注册正确
□ handlers.py 语法正确
□ tools.yaml 格式正确
□ SKILL.md 元数据完整
□ 规则文件引用正确
```
