# LLM 模型配置系统架构

> **版本**: v1.0
> **日期**: 2026-01-10
> **状态**: 已实现

---

## 概述

VibeLife 采用完全配置化的 LLM 模型管理系统，所有模型名称、API 地址、fallback 链都在配置文件中管理，代码中无硬编码。

## 架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         配置优先级（从高到低）                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. 环境变量 (.env)                                                     │
│     └─ GEMINI_CHAT_MODEL, CLAUDE_API_KEY, etc.                         │
│                                                                         │
│  2. YAML 配置文件 (config/models.yaml)                                  │
│     └─ 模型定义、提供商配置、默认路由、fallback 链                       │
│                                                                         │
│  3. 数据库动态规则 (model_routes 表)                                    │
│     └─ 用户层级路由、A/B 测试、配额规则                                  │
│                                                                         │
│  4. 代码默认值 (仅作为最终兜底)                                          │
│     └─ glm-4-flash                                                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. 配置文件 (`apps/api/config/models.yaml`)

```yaml
providers:
  glm:
    base_url: "${GLM_BASE_URL:https://open.bigmodel.cn/api/paas/v4}"
    api_key_env: "GLM_API_KEY"
  gemini:
    base_url: "${GEMINI_BASE_URL:https://new.12ai.org/v1}"
    api_key_env: "GEMINI_API_KEY"
    backup_urls: [...]
  claude:
    base_url: "${CLAUDE_BASE_URL:https://www.zz166.cn/api}"
    api_key_env: "CLAUDE_API_KEY"

models:
  glm-4-flash:
    provider: glm
    model_name: "${GLM_CHAT_MODEL:glm-4-flash}"
    capabilities: [chat]
  gemini-flash:
    provider: gemini
    model_name: "${GEMINI_CHAT_MODEL:gemini-2.5-flash}"
    capabilities: [chat, analysis]
  claude-opus:
    provider: claude
    model_name: "${CLAUDE_MODEL:claude-opus-4-5-20251101}"
    capabilities: [chat, analysis, vision]

defaults:
  chat:
    primary: gemini-flash
    fallback: [glm-4-flash, claude-opus]
  image_gen:
    primary: gemini-image
    fallback: []

global_fallback: glm-4-flash
```

### 2. 配置加载器 (`services/model_router/config.py`)

- `load_model_config()` - 加载 YAML 配置
- `get_model_config()` - 获取全局配置实例
- `reload_config()` - 运行时重新加载
- 支持 `${VAR:default}` 环境变量替换

### 3. 统一客户端 (`services/model_router/client.py`)

```python
from services.model_router import chat, stream, generate_image

# 统一入口，自动处理路由和 fallback
response = await chat(
    messages=[{"role": "user", "content": "你好"}],
    capability="chat",
    user_id="user-123",
    user_tier="pro"
)
```

### 4. 路由器 (`services/model_router/router.py`)

- `resolve()` - 根据上下文选择模型
- `_get_default_selection()` - 从配置读取默认模型
- `_get_fallback_selection()` - 从配置读取全局兜底

## Fallback 机制

### 触发条件

1. **API 调用失败**：网络错误、超时、API 返回错误码（4xx/5xx）
2. **配额超限**：当前模型配额用完

### Fallback 链示例

```
chat 请求:
  gemini-flash (主力)
      ↓ 失败
  glm-4-flash (备选1)
      ↓ 失败
  claude-opus (备选2)
      ↓ 失败
  glm-4-flash (全局兜底)
```

## 便捷管理脚���

```bash
# 列出当前配置
python apps/api/scripts/update_model_config.py --list

# 从 docs/apikey.md 同步
python apps/api/scripts/update_model_config.py --sync-from-docs

# 设置主力模型
python apps/api/scripts/update_model_config.py --set-primary chat claude-opus

# 验证配置
python apps/api/scripts/update_model_config.py --validate

# 运行时重新加载
python apps/api/scripts/update_model_config.py --reload
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `apps/api/config/models.yaml` | 模型配置文件 |
| `apps/api/services/model_router/config.py` | 配置加载器 |
| `apps/api/services/model_router/client.py` | 统一 LLM 客户端 |
| `apps/api/services/model_router/router.py` | 路由器核心逻辑 |
| `apps/api/services/model_router/quota.py` | 配额管理 |
| `apps/api/services/model_router/cache.py` | 内存缓存 |
| `apps/api/services/vibe_engine/llm.py` | 底层 LLM 服务 |
| `apps/api/scripts/update_model_config.py` | 配置管理脚本 |

## 模型清单

| ID | 提供商 | 模型名 | 能力 | 用途 |
|----|--------|--------|------|------|
| glm-4-flash | GLM | glm-4-flash | chat | 快速对话、兜底 |
| glm-4.7 | GLM | glm-4.7 | chat, analysis | 深度分析 |
| gemini-flash | Gemini | gemini-2.5-flash | chat, analysis | 主力对话 |
| gemini-image | Gemini | gemini-2.5-flash-image | image_gen | 图像生成 |
| claude-opus | Claude | claude-opus-4-5-20251101 | chat, analysis, vision | 高级分析 |

## 更新历史

- **2026-01-10**: 初始版本，完全配置化实现
