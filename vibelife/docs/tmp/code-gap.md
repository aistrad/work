  VibeLife 项目深度代码审查报告

  执行摘要

  | 维度       | 评分      | 说明                               |
  |------------|-----------|------------------------------------|
  | 后端完成度 | 75%       | 核心引擎完备，但持久化和支付有缺口 |
  | 前端完成度 | 45%       | 组件存在但大量未接入页面           |
  | 安全性     | ⚠️ 中风险 | 多个 Critical 级安全问题           |
  | 数据库     | 60%       | Schema 与代码不匹配                |
  | 支付系统   | 30%       | 骨架阶段，未配置密钥               |

  ---
  🔴 CRITICAL 安全问题（必须立即修复）

  1. 硬编码 JWT 密钥

  文件: apps/api/services/identity/jwt.py:15
  SECRET = os.getenv("VIBELIFE_JWT_SECRET", "dev-secret-key-change-in-production")
  风险: 生产环境如未设置环境变量，将使用不安全的默认密钥

  2. 硬编码数据库密码

  文件: apps/api/stores/db.py:21-24
  "postgresql://postgres:password@localhost:5432/vibelife"

  3. 敏感端点缺少认证

  文件: apps/api/routes/billing.py:133-274
  - get_user_subscription(user_id) - 任何人可查询任意用户订阅
  - cancel_subscription(user_id) - 任何人可取消任意用户订阅！

  4. 开发支付绕过端点暴露

  文件: apps/api/routes/payment.py:692-713
  @router.post("/dev-complete")  # 生产环境必须禁用！

  5. 内存存储关键数据

  文件: apps/api/services/interview/interview_service.py:184
  self._sessions: Dict[UUID, InterviewSession] = {}  # 重启丢失！

  ---
  🟠 HIGH 优先级问题

  后端问题

  | #   | 问题                                  | 文件         | 行号           |
  |-----|---------------------------------------|--------------|----------------|
  | 1   | skill_id vs skill 字段名不一致        | 多个文件     | -              |
  | 2   | 用户上下文缺失 get_user_profile(None) | chat.py      | 164            |
  | 3   | RAG 知识库未集成到聊天流程            | chat.py      | 177-183        |
  | 4   | 重复的 LLM/Portrait 服务实现          | vibe_engine/ | -              |
  | 5   | 异常被静默吞掉                        | chat.py      | 93-98, 113-117 |
  | 6   | Webhook 签名验证可被绕过              | payment.py   | 428-432        |

  前端问题

  | #   | 问题                            | 文件              | 行号    |
  |-----|---------------------------------|-------------------|---------|
  | 1   | 流式响应未实现 - 使用同步 fetch | ChatContainer.tsx | 224-300 |
  | 2   | Token 刷新 bug - 使用过期 token | api.ts            | 107     |
  | 3   | ~12 个组件已构建但未接入页面    | components/       | -       |
  | 4   | 聊天消息无持久化 - 导航后丢失   | ChatContainer.tsx | 208-210 |
  | 5   | Voice mode 未传递给后端         | ChatContainer.tsx | 243     |

  数据库问题

  | #   | 问题         | 说明                                   |
  |-----|--------------|----------------------------------------|
  | 1   | 表名不匹配   | 代码用 vibe_users，Schema 定义 users   |
  | 2   | 向量维度混乱 | 1024/1536/3072 三种维度混用            |
  | 3   | 无事务支持   | 所有 DB 操作无事务包装                 |
  | 4   | 缺失表       | skill_profiles, skill_conversations 等 |

  ---
  🟡 MEDIUM 优先级问题

  代码质量

  1. 死代码: apps/api/archive/ 包含废弃的 mirror/reminder 服务
  2. 重复定义: ChatRequest 在 models/skill.py 和 routes/chat.py 各定义一次
  3. 全局可变状态: _llm_service 单例模式影响测试
  4. 硬编码 Stripe Price ID: apps/api/services/billing/stripe_service.py:256-272

  配置问题

  1. 环境变量未设置: Stripe/Airwallex 密钥在 .env 中被注释
  2. K8s 占位符: deployment.yaml 使用 ghcr.io/your-org/vibelife-*
  3. 缺少 K8s Secret: 敏感数据无 Secret manifest

  ---
  📊 组件接入状态

  已构建但未使用的组件

  | 组件             | 路径                                         | 状态            |
  |------------------|----------------------------------------------|-----------------|
  | LifeKLine        | components/fortune/LifeKLine.tsx             | ❌ 未接入       |
  | IdentityPrism    | components/identity/IdentityPrism.tsx        | ❌ 未接入       |
  | ZodiacChart      | components/chart/ZodiacChart.tsx             | ❌ 未接入       |
  | NowNextCard      | components/trend/NowNextCard.tsx             | ❌ 未接入       |
  | RelationshipCard | components/relationship/RelationshipCard.tsx | ❌ 导入但未渲染 |
  | TriToggle        | components/ui/TriToggle.tsx                  | ❌ 未接入       |
  | ShareModal       | components/share/ShareModal.tsx              | ❌ 未接入       |
  | FileUploader     | components/upload/FileUploader.tsx           | ❌ 未接入       |

  页面功能缺失

  | 功能        | 状态        | 位置                     |
  |-------------|-------------|--------------------------|
  | PDF 下载    | TODO        | report/[id]/page.tsx:183 |
  | 支付流程    | TODO        | report/[id]/page.tsx:377 |
  | K-Line 查看 | console.log | chat/page.tsx:45         |
  | 登出        | console.log | chat/page.tsx:137        |

  ---
  🔧 修复优先级建议

  Week 1: 安全 + 基础架构

  1. 移除所有硬编码密钥，强制环境变量
  2. 为敏感端点添加认证中间件
  3. 禁用/删除 /dev-complete 端点
  4. 统一 skill 字段命名

  Week 2: 数据持久化

  1. 统一数据库 Schema 与代码表名
  2. 实现 Interview Session 持久化
  3. 添加事务支持
  4. 集成 RAG 到聊天流程

  Week 3: 前端功能

  1. 实现流式响应 (useChat hook)
  2. 修复 Token 刷新逻辑
  3. 接入 LifeKLine/IdentityPrism/BaziChart 到 InsightPanel
  4. 实现 Voice mode 完整链路

  Week 4: 支付 + 打磨

  1. 配置 Stripe/Airwallex 密钥
  2. 实现订阅管理完整流程
  3. 添加 Webhook 签名验证
  4. 清理死代码和重复实现

  ---
  问题汇总

  | 严重级别    | 数量 |
  |-------------|------|
  | 🔴 CRITICAL | 5    |
  | 🟠 HIGH     | 13   |
  | 🟡 MEDIUM   | 8    |
  | 🟢 LOW      | 6    |

  ---
  有任何问题想深入讨论吗？比如：
  1. 某个具体问题的修复方案
  2. 架构重构建议
  3. 优先级调整
  4. 其他代码区域的审查

> 输出到/home/aiscend/work/vibelife/docs/archive/v3 

● 明白，我将把代码审查报告输出到 /home/aiscend/work/vibelife/docs/archive/v3 目录。让我先创建计划文件。

● Updated plan
  ⎿  /plan to preview

● 好的，我现在将完整的代码审查报告写入到指定目录。