# Vibe Landing Page 设计文档汇总

> **版本**: v11.0 (莫兰迪简约)
> **设计风格**: 「莫兰迪简约」+ Linear 精致风格
> **更新日期**: 2026-01-17
> **重大更新**: PERMA 色系 + Merriweather 字体

---

## 文档导航

### 核心文档

1. **[主设计文档 (LANDING_PAGE_DESIGN.md)](./LANDING_PAGE_DESIGN.md)** ⭐ 必读
   - v11.0 当前方案 (莫兰迪简约)
   - PERMA 色彩系统
   - Merriweather 字体规范
   - 技术实现规范
   - v10.0/v9.0 历史方案 (附录)

2. **[Onboarding表单详细设计 (ONBOARDING_FORM_DESIGN.md)](./ONBOARDING_FORM_DESIGN.md)**
   - Hero区集成基础表单
   - Onboarding完整4步流程

3. **[实施清单 (IMPLEMENTATION_CHECKLIST.md)](./IMPLEMENTATION_CHECKLIST.md)** 开发必备
   - v11.0 实施任务
   - PERMA 色彩系统迁移

---

## 快速开始

```bash
# 安装依赖
cd apps/web && npm install

# 启动开发服务器
npm run dev

# 访问 http://localhost:3000/onboarding
```

---

## v11.0 核心变更

### PERMA 色彩系统

| 维度 | 颜色 | 色值 | 含义 |
|------|------|------|------|
| **P** | Sage Green | #8A9A5B | 积极情绪 |
| **E** | Dusty Blue | #667B99 | 投入/心流 |
| **R** | Terracotta | #C27B67 | 积极关系 |
| **M** | Mustard Yellow | #CCB464 | 人生意义 |
| **A** | Slate Purple | #786D8C | 成就感 |

### 字体替换

```
Fraunces (v10.0) → Merriweather (v11.0)
```

### 移除的旧调色板

- ❌ vellum-* (羊皮纸色系)
- ❌ gold-* (古金色系)
- ❌ mystic-* (神秘紫色系)
- ❌ ink-* (墨色系)

---

## 技术规格

```typescript
{
  framework: 'Next.js 14',
  fonts: { brand: 'Merriweather', body: 'Inter' },
  colors: 'PERMA 五色系',
  performance: { LCP: '< 2.5s', Accessibility: '> 95' }
}
```

---

**从 [主设计文档](./LANDING_PAGE_DESIGN.md) 开始！**
