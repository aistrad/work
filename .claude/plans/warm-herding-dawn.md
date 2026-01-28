# VibeID 用户分析报告生成计划

## 用户信息
- **出生日期**: 1980-02-11 14:30
- **性别**: 男
- **出生地**: 北京

## 目标
调用 VibeID skill 现有程序流程，生成完整人格分析报告

## 执行步骤

### Step 1: 创建报告生成脚本
`apps/api/scripts/generate_vibe_id_report.py`

### Step 2: 调用核心服务链
```
BaziCalculator → BaziAnalyzer → ZodiacAnalyzer → FusionEngine → Explainer
```

### Step 3: 输出 Markdown 报告
包含完整数据：八字四柱、星盘度数、计算过程、四维原型、12原型得分

## 输出
`/home/aiscend/work/vibelife/docs/prd/VibeID/sample_report_1980-02-11.md`
