# 🎨 VibeLife V8：前端架构视觉规范
> **设计哲学**：流动 (Fluid)、响应 (Reactive)、AI 原生 (AI-Native)。
> 我们不只是构建页面，而是在编排 **智能的流动**。

---

## 1. 🌌 架构全景 (Architecture Panorama)

从传统的“层级堆叠”转向“数据流动的管道”。数据从 API 涌入，经过 Core 的处理，注入 State 容器，最终由 Shell 呈现给 Experience 层。

```mermaid
graph TD
    %% Styling
    classDef experience fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef shell fill:#f3e5f5,stroke:#4a148c,stroke-width:2px;
    classDef core fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    classDef state fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef api fill:#eceff1,stroke:#37474f,stroke-width:1px,stroke-dasharray: 5 5;
    classDef proactive fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,stroke-dasharray: 5 5;

    subgraph User_Touchpoints ["✨ Experience Layer (用户触点)"]
        direction LR
        Onboard(🚀 新手引导)
        Chat(💬 对话空间)
        Market(🎯 技能市场)
        Prism(💎 身份棱镜)
        Settings(⚙️ 设置中心)
    end

    subgraph Container_System ["🖼️ Shell Layer (全息容器)"]
        UnifiedShell[📱 统一 Shell 容器]
        NavRail[📍 导航轨]
        SidePanel[🧩 上下文侧边栏]
        
        ProactiveFloat((🔔 主动层))
        
        UnifiedShell --> NavRail
        UnifiedShell --> SidePanel
        ProactiveFloat -.-> UnifiedShell
    end

    subgraph Intelligence_Engine ["🧠 Core Layer (智能内核)"]
        ChatCore[[🤖 ChatCore<br>AI SDK 流式响应]]
        SkillCore[[📦 SkillCore<br>注册表]]
        CardCore[[🃏 CardCore<br>动态渲染]]
        ProactiveEngine[[⚡ ProactiveCore<br>推送逻辑]]
    end

    subgraph Data_Ecosystem ["💾 State Layer (状态生态)"]
        AuthContext[(🔐 认证)]
        SkillContext[(🎯 技能)]
        UserContext[(👤 用户)]
        PushContext[(📫 通知)]
    end

    subgraph Backend ["☁️ API Layer (源头)"]
        APIs[REST / WebSocket / SSE]
    end

    %% Flows
    User_Touchpoints --> UnifiedShell
    UnifiedShell --> ChatCore
    UnifiedShell --> SkillCore
    
    ChatCore --> CardCore
    ProactiveEngine -.-> ProactiveFloat
    
    ChatCore ==> SkillContext
    SkillCore ==> SkillContext
    ProactiveEngine ==> PushContext
    
    AuthContext -.-> APIs
    UserContext -.-> APIs
    
    %% Apply Classes
    class Onboard,Chat,Market,Prism,Settings experience;
    class UnifiedShell,NavRail,SidePanel shell;
    class ProactiveFloat proactive;
    class ChatCore,SkillCore,CardCore,ProactiveEngine core;
    class AuthContext,SkillContext,UserContext,PushContext state;
    class APIs api;
```

```text
                                         .-------------------.
                                         |    Experience     |
                                         |  [Chat] [Market]  |
                                         '--------+----------'
                                                  |
        . - - - - - - - - - - - - - .             v
        |       Proactive Layer     |    .-------------------.
        |     (Floating Overlay)    | ~> |       Shell       |
        ' - - - - - - - - - - - - - '    | [Nav] [Main] [Side]|
                                         '--------+----------'
                                                  |
                                                  v
                                         .-------------------.
                                         |       Core        |
                                         | [Chat] [Skill] [Card]|
                                         '--------+----------'
                                                  |
                                                  v
                                         .-------------------.
                                         |       State       |
                                         |  (Auth) (User)    |
                                         '--------+----------'
                                                  :
                                                  v
                                           (  API Cloud  )
```

---

## 2. 🔄 AI 原生交互闭环 (Interaction Loop)

传统 App 是线性的死胡同，AI 原生应用是无限的螺旋上升。

### ⚡ Vibe 闭环
用户的一个意图 (Intent)，不再止于一个结果 (Result)，而是触发新的主动建议 (Proactive Agency)。

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 用户
    participant Vibe as ✨ Vibe 引擎
    participant Tools as 🛠️ 能力工具
    participant UI as 🃏 自适应 UI
    
    User->>Vibe: 🗣️ 表达意图 (Intent)
    activate Vibe
    note right of User: "我想了解下周运势..."
    
    Vibe->>Vibe: 🧠 意图理解 & 路由
    Vibe->>Tools: 🔧 调用 Skill (星盘/八字)
    Tools-->>Vibe: 📊 返回结构化数据
    
    Vibe->>UI: 🎨 指令: 渲染 ShowCard
    activate UI
    UI-->>User: 🖼️ 展示: 运势趋势图
    deactivate UI
    
    Vibe--)User: 💡 主动建议 (Proactive)
    note left of Vibe: "检测到水逆，是否查看避坑指南?"
    deactivate Vibe
    
    User->>Vibe: 🗣️ 后续追问 (Follow-up)
    note right of User: 形成持续对话闭环
```

```text
      User Input                     AI Processing                   User Feedback
     .----------.                  .---------------.                .-------------.
     |  Intent  | ---------------> |  Vibe Engine  | -------------> | Follow-up?  |
     '----+-----'                  '-------+-------'                '------+------'
          ^                                |  |                            |
          |                                |  | (1. Call Tool)             |
          | (Loop)                         |  v                            |
          |                          .-----+-----.                         |
          |                          |   Tools   |                         |
          |                          '-----+-----'                         |
          |                                | (2. Data)                     |
          |                                v                               |
          |                          .-----+-----.                         |
          |                          |    UI     | <-----------------------'
          |                          '-----+-----'
          |                                | (3. ShowCard)
          |                                v
          '------------------------ ( Proactive Agency )
```

---

## 3. 🖼️ 全息 Shell (Holographic Shell)

`UnifiedShell` 是一个智能的响应式容器，它根据设备尺寸和上下文自动形变。

### 📱 组件解剖

```mermaid
classDiagram
    class UnifiedShell {
        +设备类型 device
        +布局模式 mode
        +render() 渲染
    }

    class Navigation {
        <<导航组件>>
        +PC端: NavRail (左侧)
        +移动端: BottomBar (底部)
    }

    class MainStage {
        <<核心区域>>
        +内容区
        +动态面包屑
    }

    class ContextPanel {
        <<可折叠面板>>
        +PC端: 右侧 SidePanel
        +移动端: 抽屉 / 浮层
        +内容: 动态变化 (VibeID / Skill详情)
    }

    class ProactiveOverlay {
        <<悬浮层>>
        +Toast 提醒
        +悬浮卡片
        +模态框
        +Z-Index: 最高层级
    }

    UnifiedShell *-- Navigation
    UnifiedShell *-- MainStage
    UnifiedShell *-- ContextPanel
    UnifiedShell *-- ProactiveOverlay
```

```text
    +-----------------------------------------------------------+
    |  [ NavRail ]  |      Main Stage         | [ SidePanel ]   |
    |      .        |                         |                 |
    |      .        |    (Chat / Market)      |  (Context /     |
    |      .        |                         |   Details)      |
    |      .        |                         |                 |
    |               |                         |                 |
    |               +-------------------------+                 |
    |               |    Proactive Overlay    |                 |
    |               |    (Floating Layer)     |                 |
    +---------------+-------------------------+-----------------+
    
    <------------------ Unified Shell Container ----------------->
```

### 🧠 智能侧边栏策略 (Smart SidePanel)
SidePanel 不是静态的，它是一面“魔镜”，根据当前的主舞台内容反射出辅助信息。

| **主舞台** (Main Stage) | **侧边魔镜** (Side Panel) | **视觉意图** (Visual Intent) |
| :--- | :--- | :--- |
| 💬 **Chat (对话)** | **VibeID 预览** | 左侧对话，右侧实时更新画像，体现“深度理解” (Deep Understanding) |
| 🎯 **Market (市场)** | **Skill 详情** | 左侧浏览，右侧展示详情与配置，减少页面跳转 |
| 💎 **Identity (身份)** | **维度深钻** | 左侧全览，右侧钻取单一维度的历史趋势 |

---

## 4. 🃏 卡片渲染逻辑 (Card Rendering)

`CardCore` 是前端的“视觉翻译官”。它负责将枯燥的 JSON 数据翻译成生动的 UI 卡片。我们采用 **“渐进式降级” (Progressive Fallback)** 策略。

```mermaid
flowchart TD
    Input[📥 Tool 调用结果] --> Identify{🆔 卡片类型?}
    
    Identify -- "已知类型 (如 bazi-chart)" --> CustomComponent[✨ 渲染专用组件]
    
    Identify -- "未知类型" --> CheckFallback{🔙 有降级提示?}
    
    CheckFallback -- "有 (如 list)" --> RenderPattern[📐 渲染通用模式]
    
    CheckFallback -- "无" --> AnalyzeData{🔍 分析数据结构}
    
    AnalyzeData -- "数组 Array" --> RenderList[📋 渲染智能列表]
    AnalyzeData -- "键值对 Key-Value" --> RenderDesc[📝 渲染描述列表]
    AnalyzeData -- "Markdown 文本" --> RenderText[📄 渲染文本]
    
    subgraph Patterns [通用模式库]
        RenderList
        RenderDesc
        RenderText
    end
    
    CustomComponent --> FinalUI[🎨 最终 UI 卡片]
    RenderPattern --> FinalUI
    Patterns --> FinalUI
    
    style CustomComponent fill:#c8e6c9,stroke:#2e7d32
    style RenderPattern fill:#fff9c4,stroke:#fbc02d
    style AnalyzeData fill:#ffccbc,stroke:#d84315
```

```text
    [ Tool Result JSON ]
             |
             v
    /------------------\
    |  Known CardType? | --(Yes)--> [ Custom Component ]
    \------------------/             (Bazi / Chart)
             | (No)
             v
    /------------------\
    |  Fallback Hint?  | --(Yes)--> [ Generic Pattern ]
    \------------------/             (List / Table)
             | (No)
             v
    [   Data Analysis  ]
    [ (Array / Object) ] ---------> [ Smart Render ]
                                     (Text / KV / List)
```

---

## 5. 🧬 状态生态 (State Ecosystem)

状态不再是零散的变量，而是层层包裹的生态圈。

```typescript
// ⚛️ VibeLife App 的原子结构
<AppProviders>
  {/* 1. 身份层：你是谁？ */}
  <AuthProvider>
    <UserProvider>
      
      {/* 2. 能力层：你能做什么？ */}
      <SkillProvider>
        
        {/* 3. 互动层：正在发生什么？ */}
        <ProactiveProvider>
          
          {/* 4. 视觉层：看起来如何？ */}
          <ThemeProvider>
            <UnifiedShell>
               {/* 舞台已就绪 */}
               <Component {...pageProps} />
            </UnifiedShell>
          </ThemeProvider>
          
        </ProactiveProvider>
      </SkillProvider>
      
    </UserProvider>
  </AuthProvider>
</AppProviders>
```

```text
           .---------------------------------.
          /          AuthProvider             \
         /   .-----------------------------.   \
        |   /        UserProvider           \   |
        |  |   .-------------------------.   |  |
        |  |  /      SkillProvider        \  |  |
        |  | |   .---------------------.   | |  |
        |  | |  /  ProactiveProvider    \  | |  |
        |  | | |   .-----------------.   | | |  |
        |  | | |  |   UnifiedShell    |  | | |  |
        |  | | |  |    (Component)    |  | | |  |
        |  | | |   '-----------------'   | | |  |
        |  | |  \_______________________/  | |  |
        |  |  \_________________________/  | |  |
        |   \___________________________/   |  |
         \_________________________________/  /
          '---------------------------------'
```

---

> **视觉总结**: 
> VibeLife V8 不仅仅是一个 UI；它是一个 **生命接口 (Living Interface)**。
> 它会呼吸 (主动关怀 Proactive)，会思考 (智能内核 Core)，并能随需应变 (全息容器 Shell)。
