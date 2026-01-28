# Skill System v6 测试方案

> 覆盖重构的所有组件：知识分层、关键词匹配、SOP 引擎、多 Skill 融合

## 一、测试架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        测试层次                                  │
├─────────────────────────────────────────────────────────────────┤
│  L1: 单元测试 (Unit Tests)                                       │
│      - SkillLoader 各方法                                        │
│      - 关键词匹配引擎                                             │
│      - SOPEngine 状态机                                          │
├─────────────────────────────────────────────────────────────────┤
│  L2: 集成测试 (Integration Tests)                                │
│      - CoreAgent + SkillLoader                                   │
│      - CoreAgent + SOPEngine                                     │
│      - 工具调用链路                                               │
├─────────────────────────────────────────────────────────────────┤
│  L3: 端到端测试 (E2E Tests)                                      │
│      - 完整用户场景                                               │
│      - 多 Skill 融合场景                                          │
│      - 边界情况                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、L1 单元测试

### 2.1 SkillLoader 测试

**文件**: `apps/api/tests/test_skill_loader.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_load_skill_md` | 加载 SKILL.md | frontmatter 解析、内容提取 |
| `test_load_extended_json` | 加载 extended.json | 规则分层、模式解析 |
| `test_load_cases_json` | 加载 cases.json | 案例结构、关键词提取 |
| `test_load_tools_yaml` | 加载 tools/tools.yaml | 工具定义、分类正确 |
| `test_skill_not_found` | 加载不存在的 Skill | 优雅降级、错误处理 |
| `test_malformed_json` | 加载格式错误的 JSON | 错误处理、日志记录 |

### 2.2 关键词匹配引擎测试

**文件**: `apps/api/tests/test_keyword_matcher.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_extract_keywords_jieba` | jieba 分词提取 | 关键词列表正确 |
| `test_match_rules_exact` | 精确匹配 | 完全匹配的规则优先 |
| `test_match_rules_substring` | 子串匹配 | 双向子串匹配生效 |
| `test_match_rules_scoring` | 评分排序 | 高分规则排前面 |
| `test_match_rules_top_n` | Top-N 限制 | 返回数量正确 |
| `test_match_cases` | 案例匹配 | 相关案例被召回 |
| `test_empty_query` | 空查询 | 返回空结果 |
| `test_no_match` | 无匹配 | 返回空结果 |

### 2.3 SOPEngine 测试

**文件**: `apps/api/tests/test_sop_engine.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_p1_need_birth_info` | P1: 缺少出生信息 | 返回 NEED_INFO |
| `test_p1_has_birth_info` | P1: 有出生信息 | 跳过 P1 |
| `test_p2_need_compute` | P2: 需要计算 | 返回 NEED_COMPUTE |
| `test_p2_has_skill_data` | P2: 已有数据 | 跳过 P2 |
| `test_p3_to_p6_llm_free` | P3-P6: LLM 自由 | 返回 READY_FOR_LLM |
| `test_phase_transition` | 阶段转换 | 状态机正确流转 |

---

## 三、L2 集成测试

### 3.1 CoreAgent + SkillLoader 集成

**文件**: `apps/api/tests/test_agent_skill_integration.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_core_skill_always_loaded` | Core Skill 始终加载 | system prompt 包含 core |
| `test_bazi_skill_activation` | 激活 bazi skill | 知识正确注入 |
| `test_runtime_context_injection` | 运行时上下文注入 | 匹配的规则/案例出现在 prompt |
| `test_multi_skill_fusion` | 多 Skill 融合 | 多个 Skill 内容合并 |

### 3.2 CoreAgent + SOPEngine 集成

**文件**: `apps/api/tests/test_agent_sop_integration.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_sop_collect_triggers_form` | P1 触发表单 | 返回 collect_bazi_info 工具 |
| `test_sop_compute_triggers_calc` | P2 触发计算 | 调用 calculate_bazi |
| `test_sop_llm_free_after_p2` | P2 后 LLM 自由 | 不再强制工具调用 |

### 3.3 工具系统集成

**文件**: `apps/api/tests/test_tool_system.py`

| 测试用例 | 描述 | 验证点 |
|---------|------|--------|
| `test_tools_yaml_loading` | YAML 工具加载 | 工具定义正确解析 |
| `test_tool_execution` | 工具执行 | 调用正确的实现 |
| `test_tool_result_format` | 工具结果格式 | 返回格式符合预期 |

---

## 四、L3 端到端测试

### 4.1 用户场景测试

**文件**: `apps/api/scripts/test_skill_system_e2e.py`

基于 `user case.md` 设计的完整场景：

| 场景 | Skill | 用户消息 | 期望行为 |
|------|-------|---------|---------|
| 认识自我 | bazi | "我想深度了解自己" | 展示命盘 + 解读 |
| 理解当下 | bazi | "最近运势怎么样" | 展示运势 + 分析 |
| 如何改变 | bazi | "今天应该做什么" | 每日建议 |
| 咨询问事 | tarot | "帮我抽张牌" | 抽牌 + 解读 |
| 合盘分析 | zodiac | "我和他合适吗" | 合盘分析 |

### 4.2 SOP 流程测试

| 场景 | 初始状态 | 期望流程 |
|------|---------|---------|
| 新用户首次八字 | 无出生信息 | P1(收集) → P2(计算) → P3-P6(分析) |
| 老用户再次八字 | 有出生信息+命盘 | 直接 P3-P6(分析) |
| 合盘缺对方信息 | 有自己信息 | P1(收集对方) → P2 → P3-P6 |

### 4.3 边界情况测试

| 场景 | 描述 | 期望行为 |
|------|------|---------|
| 模糊请求 | "给点建议" | 先对话了解背景 |
| 无效 Skill | skill="invalid" | 降级到 core |
| 空消息 | message="" | 友好提示 |
| 超长消息 | 10000+ 字符 | 正常处理或截断 |

---

## 五、测试数据

### 5.1 Mock Profile

```python
MOCK_PROFILE_COMPLETE = {
    "basic": {"name": "测试用户"},
    "birth_info": {
        "date": "1990-05-15",
        "time": "14:30",
        "location": "北京"
    }
}

MOCK_PROFILE_NO_BIRTH = {
    "basic": {"name": "测试用户"}
}
```

### 5.2 Mock Skill Data

```python
MOCK_BAZI_DATA = {
    "bazi_chart": {
        "year": {"gan": "庚", "zhi": "午"},
        "month": {"gan": "辛", "zhi": "巳"},
        "day": {"gan": "甲", "zhi": "子"},
        "hour": {"gan": "壬", "zhi": "申"}
    }
}
```

---

## 六、执行方式

### 6.1 单元测试

```bash
# 运行所有单元测试
pytest apps/api/tests/test_skill_loader.py -v
pytest apps/api/tests/test_keyword_matcher.py -v
pytest apps/api/tests/test_sop_engine.py -v

# 运行特定测试
pytest apps/api/tests/test_skill_loader.py::test_load_skill_md -v
```

### 6.2 集成测试

```bash
# 需要 Mock LLM
pytest apps/api/tests/test_agent_skill_integration.py -v
pytest apps/api/tests/test_agent_sop_integration.py -v
```

### 6.3 端到端测试

```bash
# 需要真实 LLM API
python apps/api/scripts/test_skill_system_e2e.py
```

---

## 七、验收标准

| 层次 | 通过率要求 | 说明 |
|------|-----------|------|
| L1 单元测试 | 100% | 所有用例必须通过 |
| L2 集成测试 | 100% | 所有用例必须通过 |
| L3 端到端测试 | ≥90% | 允许 LLM 行为差异 |

### 关键验收点

1. **知识分层**: SKILL.md 始终加载，extended/cases 按需匹配
2. **关键词匹配**: 双向子串匹配，Top-N 返回
3. **SOP 执行**: P1/P2 强制执行，P3-P6 LLM 自由
4. **工具系统**: YAML 配置正确加载和执行
5. **多 Skill 融合**: 多个 Skill 内容正确合并

---

## 八、测试文件清单

```
apps/api/tests/
├── test_skill_loader.py          # SkillLoader 单元测试
├── test_keyword_matcher.py       # 关键词匹配引擎测试
├── test_sop_engine.py            # SOPEngine 单元测试
├── test_agent_skill_integration.py  # Agent+Skill 集成测试
├── test_agent_sop_integration.py    # Agent+SOP 集成测试
├── test_tool_system.py           # 工具系统测试
└── conftest.py                   # pytest fixtures

apps/api/scripts/
└── test_skill_system_e2e.py      # 端到端测试
```
