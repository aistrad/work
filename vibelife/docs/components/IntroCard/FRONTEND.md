  ---                                                                                                                                           
  SkillIntroCard 前端实现指南                                                                                                                   
                                                                                                                                                
  Version: 1.0.0 | 2026-01-20                                                                                                                   
                                                                                                                                                
  ---                                                                                                                                           
  1. 组件结构                                                                                                                                   
                                                                                                                                                
  apps/web/src/skills/shared/SkillIntroCard/                                                                                                    
  ├── index.tsx              # 主组件                                                                                                           
  ├── Header.tsx             # 头部组件                                                                                                         
  ├── FeatureList.tsx        # 功能列表                                                                                                         
  ├── FeatureItem.tsx        # 单个功能项                                                                                                       
  ├── QuickStart.tsx         # 快速开始                                                                                                         
  ├── PricingSection.tsx     # 定价信息                                                                                                         
  ├── SettingsSection.tsx    # 设置选项                                                                                                         
  ├── StatusBadge.tsx        # 状态徽章                                                                                                         
  ├── types.ts               # 类型定义                                                                                                         
  ├── hooks/                                                                                                                                    
  │   ├── useSkillIntro.ts   # 数据获取                                                                                                         
  │   └── useSubscription.ts # 订阅操作                                                                                                         
  └── styles.ts              # 样式常量                                                                                                         
                                                                                                                                                
  ---                                                                                                                                           
  2. 主组件实现                                                                                                                                 
                                                                                                                                                
  // index.tsx                                                                                                                                  
  "use client";                                                                                                                                 
                                                                                                                                                
  import { motion, AnimatePresence } from "framer-motion";                                                                                      
  import { X } from "lucide-react";                                                                                                             
  import { registerCard } from "@/skills/CardRegistry";                                                                                         
  import { useSkillIntro, useMarkFirstUse } from "./hooks/useSkillIntro";                                                                       
  import Header from "./Header";                                                                                                                
  import FeatureList from "./FeatureList";                                                                                                      
  import QuickStart from "./QuickStart";                                                                                                        
  import PricingSection from "./PricingSection";                                                                                                
  import SettingsSection from "./SettingsSection";                                                                                              
  import type { SkillIntroCardProps, IntroCardAction, SectionType } from "./types";                                                             
                                                                                                                                                
  const DEFAULT_SECTIONS: Record<string, SectionType[]> = {                                                                                     
    full: ["header", "features", "quickstart", "pricing", "settings"],                                                                          
    compact: ["header", "features", "quickstart"],                                                                                              
    mini: ["header"],                                                                                                                           
  };                                                                                                                                            
                                                                                                                                                
  function SkillIntroCard({                                                                                                                     
    skillId,                                                                                                                                    
    variant = "compact",                                                                                                                        
    sections: propSections,                                                                                                                     
    dismissible = true,                                                                                                                         
    onAction,                                                                                                                                   
    className = "",                                                                                                                             
    initialData,                                                                                                                                
  }: SkillIntroCardProps) {                                                                                                                     
    const [dismissed, setDismissed] = useState(false);                                                                                          
    const { data, isLoading, error } = useSkillIntro(skillId, initialData);                                                                     
    const markFirstUse = useMarkFirstUse(skillId);                                                                                              
                                                                                                                                                
    // 首次使用时标记                                                                                                                           
    useEffect(() => {                                                                                                                           
      if (data?.is_first_use) {                                                                                                                 
        markFirstUse.mutate();                                                                                                                  
      }                                                                                                                                         
    }, [data?.is_first_use]);                                                                                                                   
                                                                                                                                                
    if (dismissed || isLoading || error || !data) {                                                                                             
      return null;                                                                                                                              
    }                                                                                                                                           
                                                                                                                                                
    const { skill, subscription, settings } = data;                                                                                             
                                                                                                                                                
    // 确定显示的 sections                                                                                                                      
    const sections = propSections                                                                                                               
      || skill.intro_card?.default_sections                                                                                                     
      || DEFAULT_SECTIONS[variant];                                                                                                             
                                                                                                                                                
    // 主题色                                                                                                                                   
    const themeColor = skill.color || "#6366F1";                                                                                                
                                                                                                                                                
    const handleAction = (action: IntroCardAction) => {                                                                                         
      if (action.type === "dismiss") {                                                                                                          
        setDismissed(true);                                                                                                                     
      }                                                                                                                                         
      onAction?.(action);                                                                                                                       
    };                                                                                                                                          
                                                                                                                                                
    const showSection = (section: SectionType) => sections.includes(section);                                                                   
                                                                                                                                                
    return (                                                                                                                                    
      <motion.div                                                                                                                               
        initial={{ opacity: 0, y: 20 }}                                                                                                         
        animate={{ opacity: 1, y: 0 }}                                                                                                          
        exit={{ opacity: 0, y: -20 }}                                                                                                           
        className={`skill-intro-card rounded-xl overflow-hidden border border-white/10 backdrop-blur-sm ${className}`}                          
        style={{                                                                                                                                
          background: `linear-gradient(135deg, ${themeColor}10 0%, ${themeColor}05 100%)`,                                                      
          borderColor: `${themeColor}30`,                                                                                                       
        }}                                                                                                                                      
      >                                                                                                                                         
        {/* Dismiss Button */}                                                                                                                  
        {dismissible && (                                                                                                                       
          <button                                                                                                                               
            onClick={() => handleAction({ type: "dismiss" })}                                                                                   
            className="absolute top-3 right-3 p-1.5 rounded-lg hover:bg-white/10 transition-colors z-10"                                        
          >                                                                                                                                     
            <X className="w-4 h-4 text-text-tertiary" />                                                                                        
          </button>                                                                                                                             
        )}                                                                                                                                      
                                                                                                                                                
        {/* Header */}                                                                                                                          
        {showSection("header") && (                                                                                                             
          <Header                                                                                                                               
            skill={skill}                                                                                                                       
            subscription={subscription}                                                                                                         
            variant={variant}                                                                                                                   
            themeColor={themeColor}                                                                                                             
          />                                                                                                                                    
        )}                                                                                                                                      
                                                                                                                                                
        {/* Features */}                                                                                                                        
        {showSection("features") && (                                                                                                           
          <FeatureList                                                                                                                          
            features={skill.features}                                                                                                           
            subscription={subscription}                                                                                                         
            variant={variant}                                                                                                                   
            onAction={handleAction}                                                                                                             
          />                                                                                                                                    
        )}                                                                                                                                      
                                                                                                                                                
        {/* QuickStart */}                                                                                                                      
        {showSection("quickstart") && (                                                                                                         
          <QuickStart                                                                                                                           
            prompts={skill.showcase.demo_prompts}                                                                                               
            ctaText={skill.intro_card?.cta_text}                                                                                                
            onAction={handleAction}                                                                                                             
          />                                                                                                                                    
        )}                                                                                                                                      
                                                                                                                                                
        {/* Pricing */}                                                                                                                         
        {showSection("pricing") && (                                                                                                            
          <PricingSection                                                                                                                       
            skillId={skillId}                                                                                                                   
            pricing={skill.pricing}                                                                                                             
            subscription={subscription}                                                                                                         
            onAction={handleAction}                                                                                                             
          />                                                                                                                                    
        )}                                                                                                                                      
                                                                                                                                                
        {/* Settings */}                                                                                                                        
        {showSection("settings") && subscription?.status === "subscribed" && (                                                                  
          <SettingsSection                                                                                                                      
            skillId={skillId}                                                                                                                   
            settingsDef={skill.settings || []}                                                                                                  
            currentSettings={settings}                                                                                                          
            subscription={subscription}                                                                                                         
            onAction={handleAction}                                                                                                             
          />                                                                                                                                    
        )}                                                                                                                                      
      </motion.div>                                                                                                                             
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  // 注册到 CardRegistry                                                                                                                        
  registerCard("skill_intro", SkillIntroCard);                                                                                                  
                                                                                                                                                
  export default SkillIntroCard;                                                                                                                
                                                                                                                                                
  ---                                                                                                                                           
  3. 子组件实现                                                                                                                                 
                                                                                                                                                
  3.1 Header.tsx                                                                                                                                
                                                                                                                                                
  import { motion } from "framer-motion";                                                                                                       
  import StatusBadge from "./StatusBadge";                                                                                                      
  import type { SkillMetadata, UserSubscription, IntroCardVariant } from "./types";                                                             
                                                                                                                                                
  interface HeaderProps {                                                                                                                       
    skill: SkillMetadata;                                                                                                                       
    subscription: UserSubscription | null;                                                                                                      
    variant: IntroCardVariant;                                                                                                                  
    themeColor: string;                                                                                                                         
  }                                                                                                                                             
                                                                                                                                                
  export default function Header({ skill, subscription, variant, themeColor }: HeaderProps) {                                                   
    if (variant === "mini") {                                                                                                                   
      return (                                                                                                                                  
        <div className="flex items-center justify-between px-4 py-3">                                                                           
          <div className="flex items-center gap-2">                                                                                             
            <span className="text-xl">{skill.icon}</span>                                                                                       
            <span className="font-medium text-text-primary">{skill.name}</span>                                                                 
            <span className="text-text-tertiary">·</span>                                                                                       
            <span className="text-sm text-text-secondary">{skill.showcase.tagline}</span>                                                       
          </div>                                                                                                                                
          <StatusBadge subscription={subscription} compact />                                                                                   
        </div>                                                                                                                                  
      );                                                                                                                                        
    }                                                                                                                                           
                                                                                                                                                
    return (                                                                                                                                    
      <motion.div                                                                                                                               
        initial={{ opacity: 0 }}                                                                                                                
        animate={{ opacity: 1 }}                                                                                                                
        className="px-5 py-4"                                                                                                                   
        style={{                                                                                                                                
          background: `linear-gradient(135deg, ${themeColor}20 0%, transparent 100%)`,                                                          
        }}                                                                                                                                      
      >                                                                                                                                         
        <div className="flex items-start gap-4">                                                                                                
          {/* Icon */}                                                                                                                          
          <div                                                                                                                                  
            className="w-14 h-14 rounded-xl flex items-center justify-center text-3xl shrink-0"                                                 
            style={{ backgroundColor: `${themeColor}20` }}                                                                                      
          >                                                                                                                                     
            {skill.icon}                                                                                                                        
          </div>                                                                                                                                
                                                                                                                                                
          {/* Info */}                                                                                                                          
          <div className="flex-1 min-w-0">                                                                                                      
            <div className="flex items-center gap-2 mb-1">                                                                                      
              <h3 className="text-lg font-semibold text-text-primary">{skill.name}</h3>                                                         
              <StatusBadge subscription={subscription} />                                                                                       
            </div>                                                                                                                              
            <p className="text-sm text-text-secondary">{skill.showcase.tagline}</p>                                                             
                                                                                                                                                
            {/* Highlights */}                                                                                                                  
            {variant === "full" && skill.showcase.highlights.length > 0 && (                                                                    
              <div className="flex flex-wrap gap-2 mt-3">                                                                                       
                {skill.showcase.highlights.map((highlight, i) => (                                                                              
                  <span                                                                                                                         
                    key={i}                                                                                                                     
                    className="text-xs px-2 py-1 rounded-full bg-white/10 text-text-secondary"                                                  
                  >                                                                                                                             
                    {highlight}                                                                                                                 
                  </span>                                                                                                                       
                ))}                                                                                                                             
              </div>                                                                                                                            
            )}                                                                                                                                  
          </div>                                                                                                                                
        </div>                                                                                                                                  
      </motion.div>                                                                                                                             
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  3.2 FeatureList.tsx                                                                                                                           
                                                                                                                                                
  import { useState } from "react";                                                                                                             
  import { motion, AnimatePresence } from "framer-motion";                                                                                      
  import { ChevronDown, Sparkles, Crown } from "lucide-react";                                                                                  
  import type { SkillFeature, UserSubscription, IntroCardAction } from "./types";                                                               
                                                                                                                                                
  interface FeatureListProps {                                                                                                                  
    features: SkillFeature[];                                                                                                                   
    subscription: UserSubscription | null;                                                                                                      
    variant: string;                                                                                                                            
    onAction: (action: IntroCardAction) => void;                                                                                                
  }                                                                                                                                             
                                                                                                                                                
  const TIER_BADGES = {                                                                                                                         
    free: null,                                                                                                                                 
    basic: { icon: Sparkles, label: "基础", color: "text-blue-400" },                                                                           
    premium: { icon: Crown, label: "高级", color: "text-amber-400" },                                                                           
  };                                                                                                                                            
                                                                                                                                                
  export default function FeatureList({ features, subscription, variant, onAction }: FeatureListProps) {                                        
    const [expandedId, setExpandedId] = useState<string | null>(null);                                                                          
    const isCompact = variant === "compact";                                                                                                    
                                                                                                                                                
    const handleFeatureClick = (feature: SkillFeature) => {                                                                                     
      if (feature.action?.type === "send_prompt" && feature.demo_prompt) {                                                                      
        onAction({ type: "send_prompt", prompt: feature.demo_prompt });                                                                         
      } else if (feature.action?.type === "navigate" && feature.action.id) {                                                                    
        onAction({                                                                                                                              
          type: "navigate",                                                                                                                     
          target: feature.action.target || "rule",                                                                                              
          id: feature.action.id                                                                                                                 
        });                                                                                                                                     
      } else {                                                                                                                                  
        setExpandedId(expandedId === feature.name ? null : feature.name);                                                                       
      }                                                                                                                                         
    };                                                                                                                                          
                                                                                                                                                
    return (                                                                                                                                    
      <div className="px-5 py-4 border-t border-white/5">                                                                                       
        <div className="flex items-center justify-between mb-3">                                                                                
          <h4 className="text-sm font-medium text-text-secondary">功能特性</h4>                                                                 
          {isCompact && (                                                                                                                       
            <button className="text-xs text-accent hover:underline">                                                                            
              查看全部                                                                                                                          
            </button>                                                                                                                           
          )}                                                                                                                                    
        </div>                                                                                                                                  
                                                                                                                                                
        <div className={`grid gap-2 ${isCompact ? "grid-cols-2" : "grid-cols-3"}`}>                                                             
          {features.slice(0, isCompact ? 4 : undefined).map((feature) => {                                                                      
            const isExpanded = expandedId === feature.name;                                                                                     
            const tierBadge = TIER_BADGES[feature.tier];                                                                                        
            const isLocked = feature.tier !== "free" && subscription?.status !== "subscribed";                                                  
                                                                                                                                                
            return (                                                                                                                            
              <motion.div                                                                                                                       
                key={feature.name}                                                                                                              
                layout                                                                                                                          
                className={`                                                                                                                    
                  relative rounded-lg border transition-all cursor-pointer                                                                      
                  ${isExpanded ? "col-span-full bg-white/10 border-white/20" : "bg-white/5 border-white/10 hover:border-white/20"}              
                  ${isLocked ? "opacity-70" : ""}                                                                                               
                `}                                                                                                                              
                onClick={() => handleFeatureClick(feature)}                                                                                     
              >                                                                                                                                 
                <div className="p-3">                                                                                                           
                  <div className="flex items-start gap-2">                                                                                      
                    <span className="text-xl">{feature.icon}</span>                                                                             
                    <div className="flex-1 min-w-0">                                                                                            
                      <div className="flex items-center gap-1.5">                                                                               
                        <span className="text-sm font-medium text-text-primary truncate">                                                       
                          {feature.name}                                                                                                        
                        </span>                                                                                                                 
                        {tierBadge && (                                                                                                         
                          <tierBadge.icon className={`w-3 h-3 ${tierBadge.color}`} />                                                           
                        )}                                                                                                                      
                      </div>                                                                                                                    
                      {!isCompact && (                                                                                                          
                        <p className="text-xs text-text-tertiary mt-0.5 line-clamp-1">                                                          
                          {feature.description}                                                                                                 
                        </p>                                                                                                                    
                      )}                                                                                                                        
                    </div>                                                                                                                      
                    <ChevronDown                                                                                                                
                      className={`w-4 h-4 text-text-tertiary transition-transform ${isExpanded ? "rotate-180" : ""}`}                           
                    />                                                                                                                          
                  </div>                                                                                                                        
                                                                                                                                                
                  {/* Expanded Content */}                                                                                                      
                  <AnimatePresence>                                                                                                             
                    {isExpanded && (                                                                                                            
                      <motion.div                                                                                                               
                        initial={{ height: 0, opacity: 0 }}                                                                                     
                        animate={{ height: "auto", opacity: 1 }}                                                                                
                        exit={{ height: 0, opacity: 0 }}                                                                                        
                        className="mt-3 pt-3 border-t border-white/10"                                                                          
                      >                                                                                                                         
                        <p className="text-sm text-text-secondary mb-3">                                                                        
                          {feature.description}                                                                                                 
                        </p>                                                                                                                    
                        {feature.demo_prompt && (                                                                                               
                          <button                                                                                                               
                            onClick={(e) => {                                                                                                   
                              e.stopPropagation();                                                                                              
                              onAction({ type: "send_prompt", prompt: feature.demo_prompt! });                                                  
                            }}                                                                                                                  
                            className="text-sm text-accent hover:underline"                                                                     
                          >                                                                                                                     
                            试试看 →                                                                                                            
                          </button>                                                                                                             
                        )}                                                                                                                      
                      </motion.div>                                                                                                             
                    )}                                                                                                                          
                  </AnimatePresence>                                                                                                            
                </div>                                                                                                                          
              </motion.div>                                                                                                                     
            );                                                                                                                                  
          })}                                                                                                                                   
        </div>                                                                                                                                  
      </div>                                                                                                                                    
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  3.3 QuickStart.tsx                                                                                                                            
                                                                                                                                                
  import { motion } from "framer-motion";                                                                                                       
  import { MessageSquare, Copy, Check } from "lucide-react";                                                                                    
  import { useState } from "react";                                                                                                             
  import type { IntroCardAction } from "./types";                                                                                               
                                                                                                                                                
  interface QuickStartProps {                                                                                                                   
    prompts: string[];                                                                                                                          
    ctaText?: string;                                                                                                                           
    onAction: (action: IntroCardAction) => void;                                                                                                
  }                                                                                                                                             
                                                                                                                                                
  export default function QuickStart({ prompts, ctaText, onAction }: QuickStartProps) {                                                         
    const [copiedIndex, setCopiedIndex] = useState<number | null>(null);                                                                        
                                                                                                                                                
    const handleCopy = async (prompt: string, index: number) => {                                                                               
      await navigator.clipboard.writeText(prompt);                                                                                              
      setCopiedIndex(index);                                                                                                                    
      setTimeout(() => setCopiedIndex(null), 2000);                                                                                             
    };                                                                                                                                          
                                                                                                                                                
    const handleSend = (prompt: string) => {                                                                                                    
      onAction({ type: "send_prompt", prompt });                                                                                                
    };                                                                                                                                          
                                                                                                                                                
    return (                                                                                                                                    
      <div className="px-5 py-4 border-t border-white/5">                                                                                       
        <h4 className="text-sm font-medium text-text-secondary mb-3">                                                                           
          {ctaText || "快速开始"}                                                                                                               
        </h4>                                                                                                                                   
                                                                                                                                                
        <div className="space-y-2">                                                                                                             
          {prompts.slice(0, 3).map((prompt, index) => (                                                                                         
            <motion.div                                                                                                                         
              key={index}                                                                                                                       
              initial={{ opacity: 0, x: -10 }}                                                                                                  
              animate={{ opacity: 1, x: 0 }}                                                                                                    
              transition={{ delay: index * 0.1 }}                                                                                               
              className="group flex items-center gap-2 p-3 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 hover:border-accent/30
   transition-all cursor-pointer"                                                                                                               
              onClick={() => handleSend(prompt)}                                                                                                
            >                                                                                                                                   
              <MessageSquare className="w-4 h-4 text-accent shrink-0" />                                                                        
              <span className="flex-1 text-sm text-text-primary truncate">                                                                      
                {prompt}                                                                                                                        
              </span>                                                                                                                           
              <button                                                                                                                           
                onClick={(e) => {                                                                                                               
                  e.stopPropagation();                                                                                                          
                  handleCopy(prompt, index);                                                                                                    
                }}                                                                                                                              
                className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-white/10 transition-all"                                      
              >                                                                                                                                 
                {copiedIndex === index ? (                                                                                                      
                  <Check className="w-4 h-4 text-green-400" />                                                                                  
                ) : (                                                                                                                           
                  <Copy className="w-4 h-4 text-text-tertiary" />                                                                               
                )}                                                                                                                              
              </button>                                                                                                                         
            </motion.div>                                                                                                                       
          ))}                                                                                                                                   
        </div>                                                                                                                                  
      </div>                                                                                                                                    
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  3.4 PricingSection.tsx                                                                                                                        
                                                                                                                                                
  import { Sparkles, Crown, ArrowRight } from "lucide-react";                                                                                   
  import { useSubscribe } from "./hooks/useSkillIntro";                                                                                         
  import type { SkillPricing, UserSubscription, IntroCardAction } from "./types";                                                               
                                                                                                                                                
  interface PricingSectionProps {                                                                                                               
    skillId: string;                                                                                                                            
    pricing: SkillPricing;                                                                                                                      
    subscription: UserSubscription | null;                                                                                                      
    onAction: (action: IntroCardAction) => void;                                                                                                
  }                                                                                                                                             
                                                                                                                                                
  export default function PricingSection({                                                                                                      
    skillId,                                                                                                                                    
    pricing,                                                                                                                                    
    subscription,                                                                                                                               
    onAction                                                                                                                                    
  }: PricingSectionProps) {                                                                                                                     
    const subscribe = useSubscribe(skillId);                                                                                                    
                                                                                                                                                
    const status = subscription?.status || "unsubscribed";                                                                                      
    const trialRemaining = subscription?.trial_messages_remaining ?? pricing.trial_messages;                                                    
    const hasTrial = trialRemaining > 0;                                                                                                        
                                                                                                                                                
    const handleSubscribe = () => {                                                                                                             
      if (status === "subscribed") {                                                                                                            
        // 已订阅，跳转管理页                                                                                                                   
        onAction({ type: "navigate", target: "url", id: `/settings/subscriptions` });                                                           
      } else {                                                                                                                                  
        // 订阅                                                                                                                                 
        subscribe.mutate(true);                                                                                                                 
        onAction({ type: "subscribe", skillId });                                                                                               
      }                                                                                                                                         
    };                                                                                                                                          
                                                                                                                                                
    if (pricing.type === "free") {                                                                                                              
      return null;                                                                                                                              
    }                                                                                                                                           
                                                                                                                                                
    return (                                                                                                                                    
      <div className="px-5 py-4 border-t border-white/5 bg-gradient-to-r from-amber-500/5 to-transparent">                                      
        <div className="flex items-center justify-between">                                                                                     
          <div className="flex items-center gap-2">                                                                                             
            <Crown className="w-4 h-4 text-amber-400" />                                                                                        
            <span className="text-sm text-text-secondary">                                                                                      
              {status === "subscribed" ? (                                                                                                      
                "已订阅高级功能"                                                                                                                
              ) : status === "trial" ? (                                                                                                        
                `试用中 · 剩余 ${trialRemaining} 次`                                                                                            
              ) : hasTrial ? (                                                                                                                  
                `可免费试用 ${trialRemaining} 次`                                                                                               
              ) : (                                                                                                                             
                "高级功能"                                                                                                                      
              )}                                                                                                                                
            </span>                                                                                                                             
          </div>                                                                                                                                
                                                                                                                                                
          <button                                                                                                                               
            onClick={handleSubscribe}                                                                                                           
            disabled={subscribe.isPending}                                                                                                      
            className={`                                                                                                                        
              flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium transition-all                                                 
              ${status === "subscribed"                                                                                                         
                ? "bg-white/10 text-text-secondary hover:bg-white/20"                                                                           
                : "bg-accent text-white hover:bg-accent/90"                                                                                     
              }                                                                                                                                 
            `}                                                                                                                                  
          >                                                                                                                                     
            {subscribe.isPending ? (                                                                                                            
              "处理中..."                                                                                                                       
            ) : status === "subscribed" ? (                                                                                                     
              "管理订阅"                                                                                                                        
            ) : hasTrial ? (                                                                                                                    
              <>免费试用 <ArrowRight className="w-4 h-4" /></>                                                                                  
            ) : (                                                                                                                               
              <>立即订阅 <ArrowRight className="w-4 h-4" /></>                                                                                  
            )}                                                                                                                                  
          </button>                                                                                                                             
        </div>                                                                                                                                  
      </div>                                                                                                                                    
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  3.5 SettingsSection.tsx                                                                                                                       
                                                                                                                                                
  import { useState } from "react";                                                                                                             
  import { Bell, Mic, Clock, ChevronDown } from "lucide-react";                                                                                 
  import { useUpdateSettings } from "./hooks/useSkillIntro";                                                                                    
  import type { SkillSetting, UserSkillSettings, UserSubscription, IntroCardAction } from "./types";                                            
                                                                                                                                                
  interface SettingsSectionProps {                                                                                                              
    skillId: string;                                                                                                                            
    settingsDef: SkillSetting[];                                                                                                                
    currentSettings: UserSkillSettings | null;                                                                                                  
    subscription: UserSubscription | null;                                                                                                      
    onAction: (action: IntroCardAction) => void;                                                                                                
  }                                                                                                                                             
                                                                                                                                                
  const SETTING_ICONS: Record<string, any> = {                                                                                                  
    push_enabled: Bell,                                                                                                                         
    voice_mode: Mic,                                                                                                                            
    reminder_hour: Clock,                                                                                                                       
  };                                                                                                                                            
                                                                                                                                                
  export default function SettingsSection({                                                                                                     
    skillId,                                                                                                                                    
    settingsDef,                                                                                                                                
    currentSettings,                                                                                                                            
    subscription,                                                                                                                               
    onAction,                                                                                                                                   
  }: SettingsSectionProps) {                                                                                                                    
    const updateSettings = useUpdateSettings(skillId);                                                                                          
                                                                                                                                                
    const handleToggle = (key: string, value: boolean) => {                                                                                     
      updateSettings.mutate({ [key]: value });                                                                                                  
      onAction({ type: "toggle_setting", key, value });                                                                                         
    };                                                                                                                                          
                                                                                                                                                
    const handleSelect = (key: string, value: string) => {                                                                                      
      updateSettings.mutate({ [key]: value });                                                                                                  
      onAction({ type: "toggle_setting", key, value });                                                                                         
    };                                                                                                                                          
                                                                                                                                                
    if (settingsDef.length === 0) return null;                                                                                                  
                                                                                                                                                
    return (                                                                                                                                    
      <div className="px-5 py-4 border-t border-white/5">                                                                                       
        <h4 className="text-sm font-medium text-text-secondary mb-3">个性化设置</h4>                                                            
                                                                                                                                                
        <div className="space-y-3">                                                                                                             
          {settingsDef.map((setting) => {                                                                                                       
            const Icon = SETTING_ICONS[setting.key] || Bell;                                                                                    
            const currentValue =                                                                                                                
              setting.key === "push_enabled"                                                                                                    
                ? subscription?.push_enabled                                                                                                    
                : (currentSettings as any)?.[setting.key] ?? setting.default;                                                                   
                                                                                                                                                
            return (                                                                                                                            
              <div key={setting.key} className="flex items-center justify-between">                                                             
                <div className="flex items-center gap-2">                                                                                       
                  <Icon className="w-4 h-4 text-text-tertiary" />                                                                               
                  <span className="text-sm text-text-primary">{setting.name}</span>                                                             
                </div>                                                                                                                          
                                                                                                                                                
                {setting.type === "toggle" && (                                                                                                 
                  <button                                                                                                                       
                    onClick={() => handleToggle(setting.key, !currentValue)}                                                                    
                    className={`                                                                                                                
                      w-10 h-6 rounded-full transition-colors relative                                                                          
                      ${currentValue ? "bg-accent" : "bg-white/20"}                                                                             
                    `}                                                                                                                          
                  >                                                                                                                             
                    <div                                                                                                                        
                      className={`                                                                                                              
                        absolute top-1 w-4 h-4 rounded-full bg-white transition-transform                                                       
                        ${currentValue ? "left-5" : "left-1"}                                                                                   
                      `}                                                                                                                        
                    />                                                                                                                          
                  </button>                                                                                                                     
                )}                                                                                                                              
                                                                                                                                                
                {setting.type === "select" && setting.options && (                                                                              
                  <div className="relative">                                                                                                    
                    <select                                                                                                                     
                      value={currentValue}                                                                                                      
                      onChange={(e) => handleSelect(setting.key, e.target.value)}                                                               
                      className="appearance-none bg-white/10 border border-white/20 rounded-lg px-3 py-1.5 pr-8 text-sm text-text-primary       
  cursor-pointer"                                                                                                                               
                    >                                                                                                                           
                      {setting.options.map((opt) => (                                                                                           
                        <option key={opt.value} value={opt.value}>                                                                              
                          {opt.label}                                                                                                           
                        </option>                                                                                                               
                      ))}                                                                                                                       
                    </select>                                                                                                                   
                    <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-4 h-4 text-text-tertiary pointer-events-none" />        
                  </div>                                                                                                                        
                )}                                                                                                                              
              </div>                                                                                                                            
            );                                                                                                                                  
          })}                                                                                                                                   
        </div>                                                                                                                                  
      </div>                                                                                                                                    
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  ---                                                                                                                                           
  4. 注册到 CardRegistry                                                                                                                        
                                                                                                                                                
  // apps/web/src/skills/initCards.ts                                                                                                           
                                                                                                                                                
  // 添加导入                                                                                                                                   
  import './shared/SkillIntroCard';                                                                                                             
                                                                                                                                                
  // 或在 initializeCardRegistry 中显式注册                                                                                                     
  import SkillIntroCard from './shared/SkillIntroCard';                                                                                         
  registerCard('skill_intro', SkillIntroCard);                                                                                                  
                                                                                                                                                
  ---                                                                                                                                           
  5. 使用示例                                                                                                                                   
                                                                                                                                                
  5.1 在对话中使用（通过工具调用）                                                                                                              
                                                                                                                                                
  // ToolCardRenderer 会自动渲染                                                                                                                
  <ShowCard cardType="skill_intro" data={{ skill_id: "lifecoach", variant: "compact" }} />                                                      
                                                                                                                                                
  5.2 在页面中直接使用                                                                                                                          
                                                                                                                                                
  import SkillIntroCard from '@/skills/shared/SkillIntroCard';                                                                                  
                                                                                                                                                
  function SkillDetailPage({ skillId }: { skillId: string }) {                                                                                  
    const handleAction = (action: IntroCardAction) => {                                                                                         
      if (action.type === 'send_prompt') {                                                                                                      
        // 跳转到对话页并发送                                                                                                                   
        router.push(`/chat?prompt=${encodeURIComponent(action.prompt)}`);                                                                       
      }                                                                                                                                         
    };                                                                                                                                          
                                                                                                                                                
    return (                                                                                                                                    
      <SkillIntroCard                                                                                                                           
        skillId={skillId}                                                                                                                       
        variant="full"                                                                                                                          
        onAction={handleAction}                                                                                                                 
      />                                                                                                                                        
    );                                                                                                                                          
  }                                                                                                                                             
                                                                                                                                                
  ---                                                                                                                                           
  设计文档已完成，包含：                                                                                                                        
  - SPEC.md - 组件规格（已写入文件）                                                                                                            
  - DATA.md - 数据结构（已写入文件）                                                                                                            
  - API.md - API 设计（已写入文件）                                                                                                             
  - FRONTEND.md - 前端实现（上面输出）                                              