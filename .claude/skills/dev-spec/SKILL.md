---
name: dev-spec
description: 通用的【dev】；当采用规格驱动的 specs 模式进行系统或功能构建/规划/修改时触发；用于从需求澄清→设计→任务拆分→实现→验证的规范化交付；当输入当提供 spec.md时，将其作为项目设计的最高规范（Highest-Order Spec），后续需求、设计与任务产物均以此为唯一裁决依据；输出规格文档、设计稿、任务清单与变更日志；默认先计划，确认后执行。
---

# Overview and Intent

## 0. 适用场景与核心目标

- **适用对象**：当团队采用“规格驱动（specs-first）”模式进行系统构建 / 规划 / 编程。
- **核心目标**：
  1) 以用户提供的 **spec.md** 为最高规范（Highest-Order Spec，简称 **HOS**）；
  2) 将 HOS 规范化地下推为 **requirements.md → design.md → tasks.md** 三层；
  3) 强制 **1:1 执行一致性** 与 **计算验证**，避免代理漂移与需求跑偏；
  4) 建立 **全生命周期的变更与追溯**（traceability）。

## 1. 规范层级与冲突裁决（Normative Hierarchy）

**层级自上而下（越上权威越高）：**

**S0. Highest-Order Spec（HOS）**：用户提供的 **spec.md**。  
**S1. Derived Specs**：由 HOS 派生且与其一致的：
- `.claude/specs/{{feature_name}}/requirements.md`（需求）
- `.claude/specs/{{feature_name}}/design.md`（设计）
- `.claude/specs/{{feature_name}}/tasks.md`（任务）

**S2. 实现与其他文档**：代码、脚本、wiki 等。

> **裁决规则**：当 S1/S2 与 S0 发生任何冲突，**以 S0 为准**；当 S2 与 S1 冲突，**以 S1 为准**。  
> **任何**派生文档与实现必须可回溯到 S0 的具体锚点（行号/标题/段落ID/片段哈希）。

## 2. 术语与产物（Glossary & Artifacts）

- **HOS（Highest-Order Spec）**：spec.md。
- **派生产物**：`requirements.md`、`design.md`、`tasks.md` 与 `changelog.md`。
- **Trace Matrix（追溯矩阵）**：S0↔S1↔S2 的多向映射表（见 §7.4 模板）。

## 4. 核心原则（保持通用性）

1. **规范是唯一真相来源（SSOT）**：`design.md` 中的「详细执行流程设计」必须**1:1 映射**到代码实现；同时 **design.md / requirements.md** 又必须与 **S0 spec.md** 一致。  
2. **强制上下文分析**：在任何派生之前，必须做项目目录扫描与复用识别（Workflow 0）。  
3. **严格阶段闸门**：A/需求、B/设计、C/任务均采用 **“预览→确认→落盘”**。  
4. **日志与验证优先**：从需求阶段就明确记录与计算验证，并在设计/实现中强制执行。

---

# Quick Start

1) 提供或确认**spec.md**；Skill 将落盘为只读快照并记录指纹  
2) 进入 **Workflow 0** 自动上下文分析  
3) 按阶段执行 **A 需求 → B 设计 → C 任务**，每步“预览→确认→落盘”  
4) 若 HOS 更新，触发 **Delta & Impact** 并回归审查

---

# Workflows / Function / Inputs / Outputs

## 3. 输入契约：spec.md 接入（Spec Intake Contract）

### 3.1 规范化与冻结（Canonicalize & Freeze）
- 将用户输入的 spec.md **原样保存**为：`.claude/specs/{{feature_name}}/spec.md`（**只读**基线）。

---

## 5. 工作流（Workflows / Functions / I/O）

### Workflow 0：Spec 接入与项目上下文分析（强制）
**触发**：每个特性（feature）开始时自动执行（只读）。  
**输入**：外部 `spec.md`（HOS）与父级/相关项目目录。  
**目标**：
1) **Spec 接入**：落盘 `spec.md`，生成 Spec 概览（标题、摘要、目录）。  
2) **上下文分析**：扫描项目结构、识别可复用组件/数据模型/依赖与约束。  
3) **记录复用决策**：在后续文档中标注“复用自：<组件/模式>”。

**输出**：  
**下一步**：展示 **阶段 A/需求** 的“将写入文件清单与摘要预览”，等待确认。

---

### Workflow 1：需求收集与派生（requirements.md）
**输入**：`spec.md`（S0）与上下文分析报告。  
**强制要求**：
1) **加载或创建** `.claude/specs/{{feature_name}}/requirements.md`。  
2) 使用 **EARS** 语法撰写验收标准；**每条需求**必须包含：
   - `REQ-ID`（可读递增 ID，如 `REQ-001`）
   - `HOS-REF`（指向 `spec.md` 的锚点：标题/段落ID/行号/片段哈希）
   - **日志要求**（事件、级别、字段、留存）
   - **验证要求**（计算/业务/资源与安全）
3) 文档结构建议：
   - Introduction / 术语
   - User Stories
   - **EARS 验收标准清单**
   - **Mandatory Logging Requirements**
   - 非功能性需求（性能、可靠性、安全、合规、可观测性）
   - 约束与开放问题

**门控**：
- 写入前展示预览与差异：  
  `将写入: .claude/specs/{{feature_name}}/requirements.md；是否执行？[确认/修改/取消]`
- 写入后请求审批（reason: `spec-requirements-review`）。未通过则修订循环。
- 通过后询问是否进入 **B/设计**（`[确认/回退/取消]`）。

**输出**：经批准的 `requirements.md`（含 REQ↔HOS 映射）。

---

### Workflow 2：设计文档创建（design.md）
**输入**：通过审批的 `requirements.md`。  
**强制要求**（全部必备）：
- Overview
- Architecture
- **Detailed Execution Flow Design（权威部分）**
- Components & Interfaces
- Data Models
- Directory Structure（分离核心/测试/临时）
- **Logging Architecture（含事件→级别→字段表）**
- Error Handling
- Testing Strategy
- Documentation Sync Plan

**详细执行流程设计**必须包含：  
逐步操作、分支逻辑、错误路径、数据流、**每一步的日志点与级别**、性能监测点、**对 REQ-ID 与 HOS-REF 的反向映射**。

**门控**：
- 写入前预览：  
  `将写入: .claude/specs/{{feature_name}}/design.md；是否执行？[确认/修改/回退/取消]`
- 写入后审批（reason: `spec-design-review`）；未通过则修订。
- 通过后询问是否进入 **C/任务**。

**输出**：经批准的 `design.md`。

---

### Workflow 3：实施规划（tasks.md）
**输入**：通过审批的 `design.md`。  
**强制要求**：
1) **编号复选框清单**（最多两级），严格 **TDD 顺序**：
   a) 先生成/完善测试 → b) 编码/修改 → c) 运行测试与计算验证。  
2) **每个任务项必须包含**：
   - 目录组织说明（放置到何处）
   - 映射：`REQ-ID` ↔ `Design Step` ↔ `HOS-REF`
   - 明确的 DoD（Definition of Done）与验收命令（如 `pytest -k xxx`）
3) **计算验证与内存安全**：为关键路径单列任务。
4) **阶段性审查**（每个里程碑末尾必有）：
   - 设计到代码的一致性审查（逐步比对 Detailed Flow）
   - 实际执行轨迹与设计步骤完全匹配的证据（日志/跟踪ID/测试记录）

**门控**：
- 写入前预览并在 `changelog.md` 追加记录：  
  `将写入: .claude/specs/{{feature_name}}/tasks.md，并在 changelog.md 追加记录；是否执行？[确认/修改/回退/取消]`
- 写入后审批（reason: `spec-tasks-review`）。未通过则修订。
- 通过后进入 **Workflow 4**。

**输出**：经批准的 `tasks.md` 与更新的 `changelog.md`。

---

### Workflow 4：流程结束（仅规划，不执行代码）
- Skill 在 `tasks.md` 获批后终止。  
- 明确提示：**本技能仅负责规划工件**；实际编码/运行需由后续的“实现/交付”工作流处理。

---

## 6. 交互模板（Interaction Templates）

- **标准确认提示（写入前展示）**  
  `将写入: <paths>；关键变更: <summary>。是否执行？[确认/修改/回退/取消]`
- **选项语义**  
  - 确认：执行写入（幂等，覆盖前展示 diff）  
  - 修改：停留当前阶段，接受修订后再预览  
  - 回退：返回上一阶段，以其文档为真源  
  - 取消：立即终止，不做写入

---

## 7. 写入安全、可追溯与目录结构

### 7.1 写入安全（Idempotency & Safety）
- 作用域仅限：`.claude/specs/{{feature_name}}/`  
- 写入前展示 diff，必要时生成带时间戳备份，采用原子写入  
- 在确认提示/日志中**遮蔽敏感信息**

### 7.2 目录结构（可配置）
默认：  
```
project-root/
├── .claude/
│   └── specs/
│       └── {feature_name}/
│           ├── spec.md                 
│           ├── requirements.md
│           ├── design.md
│           ├── tasks.md
├── src/ ...  tests/ ...  docs/ ...  logs/ ...
```
### 7.3 权限控制（Action Zones）
- 🟢 **绿区（自动批准）**：文件读取、创建新文件、diff、生成报告、测试运行命令示例
- 🟡 **黄区（一次确认）**：创建新目录、网络请求、修改配置
- 🔴 **红区（每次确认）**：删除、DROP/TRUNCATE、覆盖生产配置、强推（`git push --force`）

---

## 9. Logging & Validation（强化版）

### 9.1 结构化日志（建议 JSON）
**通用字段**：`timestamp`、`level`、`component`、`operation`、`correlation_id`、`duration_ms`、`outcome`、`error`、`context`  
**级别**：`DEBUG | INFO | WARN | ERROR | FATAL`  
**隐私**：PII/密钥/凭证应在日志前**脱敏/散列/截断**。

### 9.2 事件-级别-字段表（样例）
| 事件 | 级别 | 必备字段 | 触发位置 |
|---|---|---|---|
| HOS_IMPORT | INFO | spec_digest, spec_uri, retrieved_at | Workflow 0 |
| TRACE_BIND | DEBUG | req_id, hos_ref, design_step, task_id | 各阶段 |
| VALIDATION_FAIL | ERROR | check_id, reason, evidence | 测试/验证 |

### 9.3 验证类别
- **逐步计算验证**：数学/算法正确性与边界检查  
- **业务规则验证**：与 HOS 业务条款逐项比对  
- **安全与资源验证**：内存/文件/句柄/并发控制  
- **性能门槛**：吞吐/延迟/资源上限

---

## 10. 测试策略（Testing Strategy）

- **TDD 先行**：在 `tasks.md` 中为每个功能先定义/生成测试  
- **层次化**：单元 / 集成 / 端到端 / 性能 / 可靠性  
- **自动化门禁**：PR/合入前必须通过与 HOS 对齐的“计算验证套件”  
- **可观测证据**：测试运行记录与日志 `correlation_id` 纳入 Evidence 列

---

## 11. 安全实践与配置（Security & Config）

- **严禁硬编码凭证**：不得在 spec 或派生文档中存储明文密码/密钥；一律使用秘密管理器或环境变量注入。  
- **数据库示例**（**占位**，请替换为安全注入方式）：
  ```python
  # 示例：使用环境变量加载
  import os
  DATABASE_CONFIG = {
      "host": os.getenv("DB_HOST"),
      "port": int(os.getenv("DB_PORT", "5432")),
      "database": os.getenv("DB_NAME"),
      "user": os.getenv("DB_USER"),
      "password": os.getenv("DB_PASSWORD"),  # 切勿在文档中填写真实值
  }
  ```
- **最小权限**：只申请必要的表/字段/操作权限；生产环境改写操作需红区确认。

---

## 12. 与实现流程的边界

- 本 Skill **仅创建/更新规划工件**（`spec.md`、`requirements.md`、`design.md`、`tasks.md`）。  
- **不执行** tasks 中的任何代码/脚本；需要由后续的“实现/交付”工作流处理。

---

# Scripts / Reference / Best Practices / Integration Points

## Scripts
- （无绑定脚本；本 Skill 仅产出规范与规划工件。）

## Reference

## Best Practices
- 幂等写入、原子落盘、预览→确认→落盘闸门  
- 结构化日志字段最小集：`timestamp`、`step`、`input_hash`、`output_ref`、`side_effects`、`status`  
- 严禁明文凭证，统一秘密管理/环境变量注入；最小权限原则

## Integration Points
- 审批交互（userInput reasons）：`spec-requirements-review`、`spec-design-review`、`spec-tasks-review`  
- 文件 I/O（读/写）：`.claude/specs/{{feature_name}}/`  
- 项目上下文读取：父级或相关项目目录（只读）