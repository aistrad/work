# VibeProfile v13 设计文档

> 配置驱动 + LLM 执行的用户画像架构

## 一、核心设计

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         设计哲学                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   配置文件 (JSON/YAML)              LLM 执行引擎                             │
│   ───────────────────              ────────────                             │
│                                                                             │
│   定义 WHAT：                      执行 HOW：                                │
│   - 从哪里提取                     - 理解配置规则                            │
│   - 提取什么                       - 分析输入数据                            │
│   - 写入哪里                       - 执行转换/合并                           │
│   - 合并策略                       - 输出结构化结果                          │
│                                                                             │
│   零硬编码逻辑                      通用能力，无业务代码                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**核心原则**：
1. **配置即规则**：所有提取/转换/合并规则在 JSON 配置
2. **LLM 即引擎**：所有执行逻辑由 LLM 完成，无硬编码算法
3. **代码只做 I/O**：代码只负责读配置、调 LLM、写数据库

## 二、整体架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    VibeProfile 配置驱动 + LLM 执行架构                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  config/vibe_extract.json                                           │   │
│   │  ─────────────────────────                                          │   │
│   │  {                                                                  │   │
│   │    "schema": { ... },        // Vibe 结构定义                       │   │
│   │    "sources": { ... },       // 数据源定义                          │   │
│   │    "extractors": { ... },    // 提取规则                            │   │
│   │    "transforms": { ... },    // 转换规则                            │   │
│   │    "merge_rules": { ... },   // 合并规则                            │   │
│   │    "context_template": "..." // Context 注入模板                    │   │
│   │  }                                                                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                         │                                   │
│                                         ▼                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  VibeExtractor (极简代码)                                           │   │
│   │  ────────────────────────                                           │   │
│   │                                                                     │   │
│   │  1. 读取配置                                                        │   │
│   │  2. 收集输入数据                                                    │   │
│   │  3. 构建 LLM Prompt（配置 + 数据 + 指令）                           │   │
│   │  4. 调用 LLM                                                        │   │
│   │  5. 解析 JSON 输出                                                  │   │
│   │  6. 写入数据库                                                      │   │
│   │                                                                     │   │
│   │  无任何业务逻辑代码                                                 │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                         │                                   │
│                                         ▼                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  LLM 执行引擎                                                       │   │
│   │  ────────────                                                       │   │
│   │                                                                     │   │
│   │  根据配置规则：                                                     │   │
│   │  - 从输入数据中提取信息                                             │   │
│   │  - 应用转换规则                                                     │   │
│   │  - 执行合并策略                                                     │   │
│   │  - 检测事件                                                         │   │
│   │  - 输出结构化 JSON                                                  │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                         │                                   │
│                                         ▼                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  vibe.current / vibe.profile / vibe.timeline                        │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 三、配置文件设计

### 3.1 完整配置 `config/vibe_extract.json`

```json
{
  "version": "13.0",
  "description": "Vibe 提取配置 - 配置驱动 + LLM 执行",

  "schema": {
    "vibe": {
      "current": {
        "description": "当前状态（Hot Layer，实时更新）",
        "fields": {
          "emotion": {
            "type": "enum",
            "values": ["anxious", "sad", "neutral", "content", "excited", "focused"],
            "description": "当前情绪"
          },
          "energy": {
            "type": "enum",
            "values": ["low", "medium", "high"],
            "description": "能量水平"
          },
          "focus": {
            "type": "array",
            "items": "string",
            "description": "当前关注领域"
          },
          "topics": {
            "type": "array",
            "items": "string",
            "max_items": 5,
            "description": "进行中的话题"
          },
          "context": {
            "type": "string",
            "description": "当前对话上下文摘要（一句话）"
          }
        }
      },
      "profile": {
        "description": "稳定画像（Warm Layer，每日更新）",
        "fields": {
          "identity": {
            "archetypes": {
              "type": "array",
              "items": "string",
              "max_items": 3,
              "description": "人格原型"
            },
            "traits": {
              "type": "array",
              "items": "string",
              "max_items": 5,
              "description": "核心特质"
            },
            "style": {
              "type": "string",
              "description": "沟通风格"
            },
            "sources": {
              "type": "object",
              "description": "来源数据追溯"
            }
          },
          "goals": {
            "type": "array",
            "items": {
              "id": "string",
              "title": "string",
              "category": "enum:career|health|relationship|wealth|growth",
              "status": "enum:active|paused|completed",
              "progress": "number:0-100",
              "deadline": "date",
              "mentioned_at": "date"
            },
            "max_items": 10,
            "description": "目标列表"
          },
          "people": {
            "type": "array",
            "items": {
              "id": "string",
              "name": "string",
              "relation": "enum:romantic|family|friend|colleague|other",
              "birth_info": "object",
              "notes": "string",
              "mentioned_at": "date"
            },
            "max_items": 20,
            "description": "关键人物"
          },
          "context": {
            "occupation": "string",
            "industry": "string",
            "life_stage": "enum:student|early_career|career_growth|career_peak|transition|retirement",
            "concerns": {
              "type": "array",
              "max_items": 5
            },
            "interests": {
              "type": "array",
              "max_items": 10
            }
          },
          "preferences": {
            "response_style": "string",
            "language": "string",
            "topics_to_avoid": "array"
          }
        }
      },
      "timeline": {
        "description": "重要事件（Cold Layer，追加存储）",
        "type": "array",
        "max_items": 100,
        "items": {
          "id": "string",
          "date": "date",
          "type": "enum:goal|relationship|decision|milestone|life_event",
          "event": "string",
          "data": "object"
        }
      }
    }
  },

  "sources": {
    "messages": {
      "description": "对话消息",
      "query": "SELECT role, content, created_at FROM messages WHERE conversation_id = :conversation_id ORDER BY created_at DESC LIMIT :limit"
    },
    "skills": {
      "description": "Skill 计算数据",
      "path": "unified_profiles.profile.skills"
    },
    "current_vibe": {
      "description": "当前 Vibe 数据",
      "path": "unified_profiles.profile.vibe"
    }
  },

  "extractors": {
    "realtime": {
      "description": "实时提取器 - 每轮对话后执行",
      "trigger": "on_conversation_turn",
      "input": {
        "messages": {
          "source": "messages",
          "params": { "limit": 10 }
        }
      },
      "output": {
        "target": "vibe.current",
        "strategy": "overwrite"
      },
      "instruction": "分析对话消息，提取用户当前状态。根据 schema.vibe.current 的字段定义输出 JSON。"
    },

    "daily": {
      "description": "定时提取器 - 每日凌晨执行",
      "trigger": "cron:0 4 * * *",
      "input": {
        "messages": {
          "source": "messages",
          "params": { "limit": 200, "days": 7 }
        },
        "skills": {
          "source": "skills",
          "fields": ["bazi", "zodiac", "lifecoach"]
        },
        "current_profile": {
          "source": "current_vibe",
          "path": "profile"
        }
      },
      "output": {
        "target": "vibe.profile",
        "strategy": "merge",
        "merge_rules": {
          "identity.archetypes": { "strategy": "append_unique", "max_items": 3 },
          "identity.traits": { "strategy": "append_unique", "max_items": 5 },
          "goals": { "strategy": "merge_by_field", "field": "title", "max_items": 10 },
          "people": { "strategy": "merge_by_field", "field": "name", "max_items": 20 },
          "context.concerns": { "strategy": "append_unique", "max_items": 5 },
          "context.interests": { "strategy": "append_unique", "max_items": 10 }
        }
      },
      "instruction": "分析用户过去一周的交互记录和 Skill 数据，更新用户画像。根据 merge_rules 合并到现有 profile。只输出有变化的字段。"
    },

    "event_detector": {
      "description": "事件检测器 - 实时检测重要事件",
      "trigger": "on_conversation_turn",
      "input": {
        "messages": {
          "source": "messages",
          "params": { "limit": 5 }
        }
      },
      "output": {
        "target": "vibe.timeline",
        "strategy": "append",
        "max_items": 100
      },
      "detect_rules": [
        {
          "type": "goal",
          "description": "检测新目标设定",
          "indicators": ["想要", "计划", "目标是", "打算", "希望能"]
        },
        {
          "type": "relationship",
          "description": "检测关键人物提及",
          "indicators": ["伴侣", "老公", "老婆", "男朋友", "女朋友", "爸", "妈", "朋友", "同事"]
        },
        {
          "type": "decision",
          "description": "检测重要决策",
          "indicators": ["纠结", "犹豫", "考虑", "要不要", "是否", "选择", "offer"]
        },
        {
          "type": "life_event",
          "description": "检测人生事件",
          "indicators": ["结婚", "订婚", "分手", "买房", "搬家", "怀孕", "升职", "辞职", "生病"]
        }
      ],
      "instruction": "检测对话中是否有重要事件。根据 detect_rules 判断，如有检测到事件，输出符合 schema.vibe.timeline.items 格式的事件。无事件则输出空数组。"
    },

    "skill_sync": {
      "description": "Skill 数据同步器 - Skill 数据更新时执行",
      "trigger": "on_skill_update",
      "rules": [
        {
          "skill": "bazi",
          "when": "chart.day_master exists",
          "transform": {
            "description": "从八字日主提取人格原型",
            "mapping": {
              "wood": { "archetype": "成长者", "traits": ["创新", "进取", "仁慈"] },
              "fire": { "archetype": "表达者", "traits": ["热情", "领导", "直觉"] },
              "earth": { "archetype": "稳定者", "traits": ["务实", "包容", "信守"] },
              "metal": { "archetype": "完善者", "traits": ["精准", "公正", "坚韧"] },
              "water": { "archetype": "智慧者", "traits": ["灵活", "深思", "洞察"] }
            }
          },
          "output": {
            "target": "vibe.profile.identity",
            "strategy": "merge"
          }
        },
        {
          "skill": "zodiac",
          "when": "chart.sun_sign exists",
          "transform": {
            "description": "从星座提取人格原型",
            "mapping": {
              "aries": { "archetype": "开拓者", "traits": ["勇敢", "主动"] },
              "taurus": { "archetype": "稳定者", "traits": ["稳定", "务实"] },
              "gemini": { "archetype": "沟通者", "traits": ["灵活", "好奇"] },
              "cancer": { "archetype": "守护者", "traits": ["敏感", "关怀"] },
              "leo": { "archetype": "领袖者", "traits": ["自信", "慷慨"] },
              "virgo": { "archetype": "完善者", "traits": ["细致", "分析"] },
              "libra": { "archetype": "和谐者", "traits": ["和谐", "公正"] },
              "scorpio": { "archetype": "洞察者", "traits": ["深度", "洞察"] },
              "sagittarius": { "archetype": "探索者", "traits": ["乐观", "探索"] },
              "capricorn": { "archetype": "成就者", "traits": ["务实", "责任"] },
              "aquarius": { "archetype": "创新者", "traits": ["创新", "独立"] },
              "pisces": { "archetype": "直觉者", "traits": ["直觉", "同情"] }
            }
          },
          "output": {
            "target": "vibe.profile.identity",
            "strategy": "merge"
          }
        },
        {
          "skill": "lifecoach",
          "when": "goals exists",
          "output": {
            "source_path": "goals",
            "target": "vibe.profile.goals",
            "strategy": "merge_by_field",
            "field": "title"
          }
        }
      ],
      "instruction": "根据 Skill 数据和转换规则，提取用户身份信息。应用 transform.mapping 进行转换，按 output.strategy 合并到目标位置。"
    }
  },

  "context_injection": {
    "description": "Context 注入配置 - 用于构建 System Prompt",
    "template": "根据 vibe 数据，生成用于注入 System Prompt 的用户上下文描述。格式：【当前状态】【人格原型】【当前目标】【职业背景】【关注问题】。简洁明了，每项一行。",
    "skill_overrides": {
      "lifecoach": {
        "include": ["current", "profile.goals", "profile.context"],
        "exclude": ["profile.identity.sources"]
      },
      "bazi": {
        "include": ["profile.identity.sources.bazi", "current.focus"]
      },
      "zodiac": {
        "include": ["profile.identity.sources.zodiac", "current.focus"]
      }
    }
  }
}
```

## 四、执行引擎设计

```python
# services/vibe/extractor.py

class VibeExtractor:
    """
    配置驱动 + LLM 执行的 Vibe 提取引擎

    代码职责（极简）：
    1. 读取配置
    2. 收集输入数据
    3. 构建 LLM Prompt
    4. 调用 LLM
    5. 写入数据库

    所有业务逻辑由 LLM 根据配置执行
    """

    def __init__(self, config_path: str = "config/vibe_extract.json"):
        self.config = self._load_config(config_path)

    def _load_config(self, path: str) -> dict:
        with open(path, 'r') as f:
            return json.load(f)

    async def execute(
        self,
        user_id: UUID,
        trigger: str,
        context: dict = None
    ) -> dict:
        """
        统一执行入口

        Args:
            user_id: 用户 ID
            trigger: 触发类型 (on_conversation_turn | cron | on_skill_update)
            context: 额外上下文 (如 conversation_id, skill_id, skill_data)

        Returns:
            LLM 输出的结构化结果
        """
        # 1. 找到匹配的 extractors
        extractors = self._match_extractors(trigger)

        results = {}
        for extractor_name, extractor_config in extractors.items():
            # 2. 收集输入数据
            input_data = await self._collect_input(user_id, extractor_config, context)

            # 3. 构建 LLM Prompt
            prompt = self._build_prompt(extractor_config, input_data)

            # 4. 调用 LLM
            llm_output = await self._call_llm(prompt)

            # 5. 写入数据库
            await self._write_output(user_id, extractor_config, llm_output)

            results[extractor_name] = llm_output

        return results

    def _build_prompt(self, extractor_config: dict, input_data: dict) -> str:
        """
        构建 LLM Prompt

        Prompt 结构：
        1. 配置规则（schema + merge_rules + transform 等）
        2. 输入数据
        3. 执行指令
        """
        prompt_parts = []

        # 1. Schema 定义
        prompt_parts.append("## Schema 定义")
        prompt_parts.append(json.dumps(self.config["schema"], ensure_ascii=False, indent=2))

        # 2. 提取规则
        prompt_parts.append("\n## 提取规则")
        prompt_parts.append(json.dumps(extractor_config, ensure_ascii=False, indent=2))

        # 3. 输入数据
        prompt_parts.append("\n## 输入数据")
        prompt_parts.append(json.dumps(input_data, ensure_ascii=False, indent=2))

        # 4. 执行指令
        prompt_parts.append("\n## 执行指令")
        prompt_parts.append(extractor_config.get("instruction", "根据规则提取信息，输出 JSON。"))

        # 5. 输出要求
        prompt_parts.append("\n## 输出要求")
        prompt_parts.append("只输出 JSON，不要其他内容。确保符合 Schema 定义。")

        return "\n".join(prompt_parts)

    async def _call_llm(self, prompt: str) -> dict:
        """调用 LLM 并解析 JSON 输出"""
        response = await chat(
            messages=[{"role": "user", "content": prompt}],
            system="你是一个精确的数据提取和转换引擎。根据配置规则处理数据，输出结构化 JSON。",
            capability="analysis",
            temperature=0.1,  # 低温度确保稳定输出
        )

        # 解析 JSON
        content = response.content if hasattr(response, 'content') else str(response)
        json_match = re.search(r'\{[\s\S]*\}|\[[\s\S]*\]', content)
        if json_match:
            return json.loads(json_match.group())
        return {}

    async def _write_output(self, user_id: UUID, config: dict, output: dict):
        """写入数据库"""
        target = config["output"]["target"]
        strategy = config["output"]["strategy"]

        if target == "vibe.current":
            await UnifiedProfileRepository.update_vibe_current(user_id, output)
        elif target == "vibe.profile":
            await UnifiedProfileRepository.update_vibe_profile(user_id, output)
        elif target == "vibe.timeline":
            if output:  # 可能是空数组
                for event in (output if isinstance(output, list) else [output]):
                    await UnifiedProfileRepository.append_vibe_timeline(user_id, event)

    async def build_context(self, user_id: UUID, skill_id: str = None) -> str:
        """
        构建 Context 注入字符串

        也由 LLM 执行，根据 context_injection 配置
        """
        vibe = await UnifiedProfileRepository.get_vibe(user_id)
        config = self.config["context_injection"]

        # 应用 skill_overrides
        if skill_id and skill_id in config.get("skill_overrides", {}):
            override = config["skill_overrides"][skill_id]
            vibe = self._filter_vibe(vibe, override)

        prompt = f"""
## 配置
{json.dumps(config, ensure_ascii=False)}

## Vibe 数据
{json.dumps(vibe, ensure_ascii=False)}

## 指令
{config['template']}

只输出文本，不要 JSON。
"""
        response = await chat(
            messages=[{"role": "user", "content": prompt}],
            system="你是一个精确的文本生成器。根据配置生成简洁的用户上下文描述。",
            capability="fast",
            temperature=0.1,
        )
        return response.content if hasattr(response, 'content') else str(response)
```

## 五、数据流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         配置驱动 + LLM 执行数据流                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   触发事件                                                                   │
│   ────────                                                                  │
│                                                                             │
│   on_conversation_turn ─┐                                                   │
│   cron:0 4 * * *       ─┼──► VibeExtractor.execute(trigger)                │
│   on_skill_update      ─┘              │                                    │
│                                        │                                    │
│                                        ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  1. 读取 config/vibe_extract.json                                   │   │
│   │  2. 匹配 extractors[trigger]                                        │   │
│   │  3. 收集 input 数据（messages, skills, current_vibe）               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                        │                                    │
│                                        ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  4. 构建 LLM Prompt                                                 │   │
│   │     ┌─────────────────────────────────────────────────────────────┐ │   │
│   │     │  ## Schema 定义                                             │ │   │
│   │     │  { "vibe": { "current": {...}, "profile": {...} } }         │ │   │
│   │     │                                                             │ │   │
│   │     │  ## 提取规则                                                │ │   │
│   │     │  { "output": {...}, "merge_rules": {...}, "transform": {} } │ │   │
│   │     │                                                             │ │   │
│   │     │  ## 输入数据                                                │ │   │
│   │     │  { "messages": [...], "skills": {...} }                     │ │   │
│   │     │                                                             │ │   │
│   │     │  ## 执行指令                                                │ │   │
│   │     │  分析数据，根据规则提取，输出 JSON                          │ │   │
│   │     └─────────────────────────────────────────────────────────────┘ │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                        │                                    │
│                                        ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  5. LLM 执行                                                        │   │
│   │     - 理解 Schema 定义                                              │   │
│   │     - 分析输入数据                                                  │   │
│   │     - 应用 transform mapping                                        │   │
│   │     - 执行 merge_rules                                              │   │
│   │     - 输出结构化 JSON                                               │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                        │                                    │
│                                        ▼                                    │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  6. 写入数据库                                                      │   │
│   │     vibe.current / vibe.profile / vibe.timeline                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 六、代码量对比

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         代码量对比                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   v12 (硬编码)                           v13 (配置 + LLM)                   │
│   ────────────                           ───────────────                    │
│                                                                             │
│   vibe_sync.yaml         ~200 行         vibe_extract.json    ~300 行      │
│   sync.py                ~360 行         extractor.py         ~100 行      │
│   profile_extractor.py   ~390 行         (无)                              │
│   prompt_builder.py      ~500 行         (大幅简化)           ~100 行      │
│   unified_profile_repo   ~300 行 vibe    (简化)               ~100 行      │
│   ─────────────────────────────          ─────────────────────────         │
│   总计                   ~1750 行         总计                 ~600 行      │
│                                                                             │
│   硬编码函数：                           硬编码函数：                        │
│   - transform_element_to_archetype       - _load_config()                  │
│   - transform_sign_to_archetype          - _collect_input()                │
│   - extract_bazi_traits                  - _build_prompt()                 │
│   - extract_zodiac_traits                - _call_llm()                     │
│   - merge_insight()                      - _write_output()                 │
│   - merge_target()                                                         │
│   - _deep_merge()                        所有业务逻辑在配置 + LLM           │
│   - 各种映射逻辑                                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 七、扩展示例

### 7.1 添加新 Skill 同步规则

只需在 `extractors.skill_sync.rules` 添加：

```json
{
  "skill": "mbti",
  "when": "result.type exists",
  "transform": {
    "description": "从 MBTI 提取人格原型",
    "mapping": {
      "INTJ": { "archetype": "策略师", "traits": ["独立", "分析", "远见"] },
      "ENFP": { "archetype": "探索者", "traits": ["热情", "创意", "好奇"] }
    }
  },
  "output": {
    "target": "vibe.profile.identity",
    "strategy": "merge"
  }
}
```

### 7.2 添加新事件检测规则

只需在 `extractors.event_detector.detect_rules` 添加：

```json
{
  "type": "health",
  "description": "检测健康相关事件",
  "indicators": ["体检", "健身", "减肥", "睡眠", "焦虑", "压力大"]
}
```

### 7.3 修改 Context 注入模板

只需修改 `context_injection.template`：

```json
{
  "template": "生成用户画像摘要，包含：1.当前情绪状态 2.核心人格特质 3.近期目标 4.主要关注点。每项不超过20字。"
}
```

## 八、API 设计

```python
class UnifiedProfileRepository:
    """极简 Vibe API - 只负责读写"""

    # 读取
    async def get_vibe(user_id: UUID) -> Dict
    async def get_vibe_current(user_id: UUID) -> Dict
    async def get_vibe_profile(user_id: UUID) -> Dict
    async def get_vibe_timeline(user_id: UUID, limit: int = 20) -> List

    # 写入（由 VibeExtractor 调用）
    async def update_vibe_current(user_id: UUID, data: Dict) -> None
    async def update_vibe_profile(user_id: UUID, data: Dict) -> None
    async def append_vibe_timeline(user_id: UUID, event: Dict) -> str


class VibeExtractor:
    """配置驱动 + LLM 执行"""

    async def execute(user_id: UUID, trigger: str, context: dict = None) -> dict
    async def build_context(user_id: UUID, skill_id: str = None) -> str
```

## 九、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v13 | 2026-01-23 | 配置驱动 + LLM 执行：所有业务逻辑在配置，执行由 LLM 完成 |
| v12 | 2026-01-20 | 配置驱动同步：vibe_sync.yaml + 硬编码执行逻辑 |
| v11 | 2026-01-15 | 初版配置化尝试 |
