Proactive + Skill Management 整合优化方案                                                                                                    
                                                                                                                                               
  现状分析                                                                                                                                     
                                                                                                                                               
  ┌─────────────────────────────────────────────────────────────────────────────┐                                                              
  │                         当前架构 vs 目标架构                                  │                                                            
  ├─────────────────────────────────────────────────────────────────────────────┤                                                              
  │                                                                              │                                                             
  │  当前 Proactive                         目标架构                             │                                                             
  │  ─────────────────                      ─────────                            │                                                             
  │  • reminders.yaml 独立定义              • 统一到 SKILL.md metadata           │                                                             
  │  • 只有 bazi 有配置                     • 所有 Skill 统一配置                 │                                                            
  │  • 不检查订阅状态                       • 检查 user_skill_subscriptions       │                                                            
  │  • ContentGenerator 硬编码              • 复用 Skill rules/ + CoreAgent       │                                                            
  │  • 只存 DB，前端拉取                    • 支持实时推送 + 对话引导             │                                                            
  │                                                                              │                                                             
  └─────────────────────────────────────────────────────────────────────────────┘                                                              
                                                                                                                                               
  优化方案                                                                                                                                     
                                                                                                                                               
  1. 统一 Proactive 配置到 SKILL.md                                                                                                            
                                                                                                                                               
  当前: reminders.yaml 独立文件                                                                                                                
  优化: 合并到 SKILL.md 的 metadata                                                                                                            
                                                                                                                                               
  # apps/api/skills/bazi/SKILL.md frontmatter 扩展                                                                                             
  ---                                                                                                                                          
  id: bazi                                                                                                                                     
  name: 八字命理                                                                                                                               
  category: professional                                                                                                                       
  pricing:                                                                                                                                     
    type: premium                                                                                                                              
    trial_messages: 3                                                                                                                          
                                                                                                                                               
  # 新增: Proactive 配置 (原 reminders.yaml)                                                                                                   
  proactive:                                                                                                                                   
    enabled: true                                                                                                                              
    reminders:                                                                                                                                 
      - id: daily_fortune                                                                                                                      
        name: 每日运势                                                                                                                         
        trigger:                                                                                                                               
          type: time_based                                                                                                                     
          schedule: "0 4 * * *"                                                                                                                
        content:                                                                                                                               
          generator: rules/daily-fortune.md  # 复用 rules/ 架构!                                                                               
          card_type: DailyFortuneCard                                                                                                          
        priority: medium                                                                                                                       
                                                                                                                                               
      - id: dayun_transition                                                                                                                   
        name: 大运交接                                                                                                                         
        trigger:                                                                                                                               
          type: event_based                                                                                                                    
          event: dayun_change                                                                                                                  
          advance_days: [30, 7, 0]                                                                                                             
        content:                                                                                                                               
          generator: rules/dayun-transition.md                                                                                                 
          card_type: InsightCard                                                                                                               
        priority: high                                                                                                                         
                                                                                                                                               
      - id: fortune_alert                                                                                                                      
        name: 运势预警                                                                                                                         
        trigger:                                                                                                                               
          type: threshold_based                                                                                                                
          metric: daily_fortune_score                                                                                                          
          condition: "<"                                                                                                                       
          threshold: 40                                                                                                                        
          cooldown_days: 7                                                                                                                     
        content:                                                                                                                               
          generator: rules/fortune-alert.md                                                                                                    
        priority: medium                                                                                                                       
                                                                                                                                               
  subscription:                                                                                                                                
    can_unsubscribe: true                                                                                                                      
    push_default: true                                                                                                                         
  ---                                                                                                                                          
                                                                                                                                               
  2. ContentGenerator 复用 Skill Rules                                                                                                         
                                                                                                                                               
  当前: 硬编码的内容生成函数                                                                                                                   
  优化: 复用 rules/*.md + CoreAgent 能力                                                                                                       
                                                                                                                                               
  # services/proactive/content_generator.py 重构                                                                                               
                                                                                                                                               
  class ContentGenerator:                                                                                                                      
      """复用 Skill Rules 的内容生成器"""                                                                                                      
                                                                                                                                               
      async def generate(                                                                                                                      
          self,                                                                                                                                
          task: ReminderTask,                                                                                                                  
          profile: Dict[str, Any],                                                                                                             
          config: Dict[str, Any],                                                                                                              
      ) -> ReminderContent:                                                                                                                    
          """                                                                                                                                  
          流程:                                                                                                                                
          1. 加载 content.generator 指定的 rule 文件                                                                                           
          2. 使用 rule 中的分析要点和检索 Query                                                                                                
          3. 调用 LLM 生成个性化内容                                                                                                           
          4. 返回结构化内容                                                                                                                    
          """                                                                                                                                  
          skill_id = task.skill_id                                                                                                             
          generator_path = config.get("content", {}).get("generator", "")                                                                      
                                                                                                                                               
          # 如果指定了 rule 文件，加载并使用                                                                                                   
          if generator_path.startswith("rules/"):                                                                                              
              rule_content = await self._load_rule(skill_id, generator_path)                                                                   
              return await self._generate_from_rule(                                                                                           
                  task=task,                                                                                                                   
                  profile=profile,                                                                                                             
                  rule=rule_content,                                                                                                           
                  card_type=config.get("content", {}).get("card_type"),                                                                        
              )                                                                                                                                
                                                                                                                                               
          # 降级到默认生成器                                                                                                                   
          return await self._generate_default(task, profile, config)                                                                           
                                                                                                                                               
      async def _generate_from_rule(                                                                                                           
          self,                                                                                                                                
          task: ReminderTask,                                                                                                                  
          profile: Dict[str, Any],                                                                                                             
          rule: str,                                                                                                                           
          card_type: Optional[str],                                                                                                            
      ) -> ReminderContent:                                                                                                                    
          """基于 Rule 生成内容"""                                                                                                             
          # 1. 解析 rule 中的分析要点                                                                                                          
          analysis_points = self._extract_analysis_points(rule)                                                                                
                                                                                                                                               
          # 2. 执行知识检索                                                                                                                    
          knowledge_context = []                                                                                                               
          for point in analysis_points:                                                                                                        
              if point.get("search_query"):                                                                                                    
                  results = await search_db(                                                                                                   
                      table="knowledge_chunks",                                                                                                
                      query=point["search_query"],                                                                                             
                      skill_id=task.skill_id,                                                                                                  
                      top_k=3,                                                                                                                 
                  )                                                                                                                            
                  knowledge_context.extend(results)                                                                                            
                                                                                                                                               
          # 3. 构建 prompt 并生成                                                                                                              
          return await self._generate_with_context(                                                                                            
              task=task,                                                                                                                       
              profile=profile,                                                                                                                 
              rule=rule,                                                                                                                       
              knowledge_context=knowledge_context,                                                                                             
              card_type=card_type,                                                                                                             
          )                                                                                                                                    
                                                                                                                                               
  3. 与 Skill Subscription 集成                                                                                                                
                                                                                                                                               
  当前: 不检查订阅状态                                                                                                                         
  优化: 完全集成 user_skill_subscriptions                                                                                                      
                                                                                                                                               
  # services/proactive/engine.py 扩展                                                                                                          
                                                                                                                                               
  class ProactiveEngine:                                                                                                                       
                                                                                                                                               
      async def _should_send_to_user(                                                                                                          
          self,                                                                                                                                
          user_id: UUID,                                                                                                                       
          skill_id: str,                                                                                                                       
          reminder_id: str,                                                                                                                    
      ) -> bool:                                                                                                                               
          """检查是否应该发送推送"""                                                                                                           
                                                                                                                                               
          # 1. 获取 Skill 元数据                                                                                                               
          skill_meta = self._skill_metadata.get(skill_id, {})                                                                                  
          category = skill_meta.get("category", "professional")                                                                                
                                                                                                                                               
          # 2. Core Skill 始终发送                                                                                                             
          if category == "core":                                                                                                               
              return True                                                                                                                      
                                                                                                                                               
          # 3. 获取用户订阅状态                                                                                                                
          subscription = await SkillSubscriptionRepo.get(user_id, skill_id)                                                                    
                                                                                                                                               
          # 4. Default Skill 检查取消和推送开关                                                                                                
          if category == "default":                                                                                                            
              if subscription and subscription.status == "unsubscribed":                                                                       
                  return False                                                                                                                 
              if subscription and not subscription.push_enabled:                                                                               
                  return False                                                                                                                 
              return True                                                                                                                      
                                                                                                                                               
          # 5. Professional Skill 需要订阅                                                                                                     
          if not subscription or subscription.status != "subscribed":                                                                          
              return False                                                                                                                     
                                                                                                                                               
          return subscription.push_enabled                                                                                                     
                                                                                                                                               
      async def _detect_user_triggers(self, user: Dict[str, Any]) -> List[ReminderTask]:                                                       
          """检测用户触发条件 - 集成订阅检查"""                                                                                                
          tasks = []                                                                                                                           
          user_id = user["user_id"]                                                                                                            
          profile = user["profile"]                                                                                                            
                                                                                                                                               
          for skill_id, meta in self._skill_metadata.items():                                                                                  
              proactive_config = meta.get("proactive", {})                                                                                     
              if not proactive_config.get("enabled", False):                                                                                   
                  continue                                                                                                                     
                                                                                                                                               
              for reminder in proactive_config.get("reminders", []):                                                                           
                  # 先检查订阅状态 (避免无谓的触发检测)                                                                                        
                  if not await self._should_send_to_user(user_id, skill_id, reminder["id"]):                                                   
                      continue                                                                                                                 
                                                                                                                                               
                  # 检测触发条件                                                                                                               
                  should_trigger, event_info = await self.trigger_detector.should_trigger(                                                     
                      trigger_config=reminder.get("trigger", {}),                                                                              
                      profile=profile,                                                                                                         
                      skill_id=skill_id,                                                                                                       
                  )                                                                                                                            
                                                                                                                                               
                  if should_trigger:                                                                                                           
                      tasks.append(ReminderTask(                                                                                               
                          user_id=user_id,                                                                                                     
                          skill_id=skill_id,                                                                                                   
                          reminder_type=reminder["id"],                                                                                        
                          priority=ReminderPriority(reminder.get("priority", "medium")),                                                       
                          trigger_event=event_info.get("event_name") if event_info else None,                                                  
                          trigger_date=event_info.get("event_date") if event_info else date.today(),                                           
                          metadata={                                                                                                           
                              "config": reminder,                                                                                              
                              "event_info": event_info,                                                                                        
                          },                                                                                                                   
                      ))                                                                                                                       
                                                                                                                                               
          return tasks                                                                                                                         
                                                                                                                                               
  4. 前端整合设计                                                                                                                              
                                                                                                                                               
  ┌─────────────────────────────────────────────────────────────────────────────┐                                                              
  │                      前端展示层优化                                          │                                                             
  ├─────────────────────────────────────────────────────────────────────────────┤                                                              
  │                                                                              │                                                             
  │  入口 1: 推送通知                                                            │                                                             
  │  ───────────────                                                             │                                                             
  │  ┌─────────────────────────────────────────────────────────────────┐        │                                                              
  │  │ 🔮 八字命理 · 今日运势                                   9:00 AM │        │                                                             
  │  │                                                                  │        │                                                             
  │  │ 甲木日主，今日戊土当令，适合稳扎稳打。                           │        │                                                             
  │  │                                                                  │        │                                                             
  │  │ ┌─────────────────┐  ┌─────────────────┐                        │        │                                                              
  │  │ │   查看详情       │  │   开始对话       │  ← 点击直接进入聊天   │        │                                                             
  │  │ └─────────────────┘  └─────────────────┘                        │        │                                                              
  │  └─────────────────────────────────────────────────────────────────┘        │                                                              
  │                                                                              │                                                             
  │  入口 2: 聊天页面顶部                                                        │                                                             
  │  ─────────────────                                                           │                                                             
  │  ┌─────────────────────────────────────────────────────────────────┐        │                                                              
  │  │ DailyGreeting 组件 (已有)                                        │        │                                                             
  │  │ + 新增: 点击展开详情 → 触发 use_skill → 自动进入对话             │        │                                                             
  │  └─────────────────────────────────────────────────────────────────┘        │                                                              
  │                                                                              │                                                             
  │  入口 3: 设置页面 Skill 管理                                                 │                                                             
  │  ───────────────────────                                                     │                                                             
  │  ┌─────────────────────────────────────────────────────────────────┐        │                                                              
  │  │ 🔮 八字命理                                             [●]      │        │                                                             
  │  │ 已订阅                                                          │        │                                                              
  │  │                                                                  │        │                                                             
  │  │ 推送设置:                                                        │        │                                                             
  │  │   [●] 每日运势  (每天早上4点)                                    │        │                                                             
  │  │   [●] 大运提醒  (重要节点前提醒)                                 │        │                                                             
  │  │   [○] 运势预警  (运势低于40分时)                                 │        │                                                             
  │  │                                                                  │        │                                                             
  │  │ ┌─────────────────────────────────────────────────────────┐     │        │                                                              
  │  │ │                  取消订阅                                │     │        │                                                             
  │  │ └─────────────────────────────────────────────────────────┘     │        │                                                              
  │  └─────────────────────────────────────────────────────────────────┘        │                                                              
  │                                                                              │                                                             
  └─────────────────────────────────────────────────────────────────────────────┘                                                              
                                                                                                                                               
  5. 新增: Proactive → 对话引导                                                                                                                
                                                                                                                                               
  // 推送通知数据结构扩展                                                                                                                      
  interface ProactiveNotification {                                                                                                            
    id: string;                                                                                                                                
    skill_id: string;                                                                                                                          
    reminder_type: string;                                                                                                                     
    title: string;                                                                                                                             
    content: {                                                                                                                                 
      body: string;                                                                                                                            
      fortune_hint?: string;                                                                                                                   
      action_tip?: string;                                                                                                                     
      // 新增: 对话引导                                                                                                                        
      suggested_prompt?: string;  // "想了解今天适合做什么？"                                                                                  
      quick_actions?: Array<{                                                                                                                  
        label: string;                                                                                                                         
        prompt: string;  // 点击后发送的消息                                                                                                   
      }>;                                                                                                                                      
    };                                                                                                                                         
    card_type?: string;                                                                                                                        
    created_at: string;                                                                                                                        
  }                                                                                                                                            
                                                                                                                                               
  // 前端处理                                                                                                                                  
  function NotificationCard({ notification }: { notification: ProactiveNotification }) {                                                       
    const { startChat } = useChat();                                                                                                           
                                                                                                                                               
    const handleStartChat = (prompt: string) => {                                                                                              
      // 1. 切换到对应 Skill                                                                                                                   
      // 2. 发送预设 prompt                                                                                                                    
      startChat({                                                                                                                              
        skill: notification.skill_id,                                                                                                          
        initialMessage: prompt,                                                                                                                
      });                                                                                                                                      
    };                                                                                                                                         
                                                                                                                                               
    return (                                                                                                                                   
      <Card>                                                                                                                                   
        <CardHeader>                                                                                                                           
          <SkillIcon skillId={notification.skill_id} />                                                                                        
          <span>{notification.title}</span>                                                                                                    
        </CardHeader>                                                                                                                          
        <CardBody>                                                                                                                             
          <p>{notification.content.body}</p>                                                                                                   
          {notification.content.quick_actions && (                                                                                             
            <div className="quick-actions">                                                                                                    
              {notification.content.quick_actions.map(action => (                                                                              
                <Button                                                                                                                        
                  key={action.label}                                                                                                           
                  onClick={() => handleStartChat(action.prompt)}                                                                               
                >                                                                                                                              
                  {action.label}                                                                                                               
                </Button>                                                                                                                      
              ))}                                                                                                                              
            </div>                                                                                                                             
          )}                                                                                                                                   
        </CardBody>                                                                                                                            
      </Card>                                                                                                                                  
    );                                                                                                                                         
  }                                                                                                                                            
                                                                                                                                               
  ---                                                                                                                                          
  目录结构变更                                                                                                                                 
                                                                                                                                               
  apps/api/                                                                                                                                    
  ├── skills/{skill_id}/                                                                                                                       
  │   ├── SKILL.md                    # 包含 proactive 配置                                                                                    
  │   ├── rules/                                                                                                                               
  │   │   ├── daily-fortune.md        # 复用为推送内容生成规则                                                                                 
  │   │   └── ...                                                                                                                              
  │   └── tools/                                                                                                                               
  │                                                                                                                                            
  ├── services/                                                                                                                                
  │   ├── proactive/                                                                                                                           
  │   │   ├── engine.py               # 集成 Skill Subscription                                                                                
  │   │   ├── trigger_detector.py     # 不变                                                                                                   
  │   │   └── content_generator.py    # 复用 rules/ 架构                                                                                       
  │   │                                                                                                                                        
  │   └── skill/                                                                                                                               
  │       ├── subscription_repo.py    # 新建                                                                                                   
  │       └── recommendation.py       # 新建                                                                                                   
                                                                                                                                               
  apps/web/                                                                                                                                    
  ├── components/                                                                                                                              
  │   └── skill/                                                                                                                               
  │       ├── SkillCard.tsx           # Skill Management 组件                                                                                  
  │       └── SkillPushSettings.tsx   # 推送开关细分控制                                                                                       
  │                                                                                                                                            
  └── app/                                                                                                                                     
      └── settings/                                                                                                                            
          └── skill-management/       # Skill 管理页面                                                                                         
                                                                                                                                               
  ---                                                                                                                                          
  实施优先级建议                                                                                                                               
  ┌──────┬───────────────────────────────────┬────────┬──────┐                                                                                 
  │ 阶段 │               内容                │ 复杂度 │ 价值 │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P0   │ Skill Subscription 数据模型 + API │ 低     │ 高   │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P1   │ ProactiveEngine 集成订阅检查      │ 中     │ 高   │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P2   │ 设置页面推送开关 UI               │ 低     │ 高   │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P3   │ ContentGenerator 复用 rules/      │ 高     │ 中   │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P4   │ 推送 → 对话引导                   │ 中     │ 高   │                                                                                 
  ├──────┼───────────────────────────────────┼────────┼──────┤                                                                                 
  │ P5   │ Skill 推荐算法                    │ 高     │ 中   │                                                                                 
  └──────┴───────────────────────────────────┴────────┴──────┘                                                                                 
  ---                                                                                                                                          
  深度访谈问题                                                                                                                                 
                                                                                                                                               
  1. 配置统一: 你更倾向于把 proactive 配置合并到 SKILL.md，还是保持 reminders.yaml 独立但与 SKILL.md 关联？                                    
  2. 推送粒度: 用户是否需要细粒度控制（单独开关每日运势、大运提醒等），还是只需要 Skill 级别的总开关？                                         
  3. 对话引导: 推送内容是否需要"一键开始对话"功能？这对你的业务转化重要吗？                      