-- ═══════════════════════════════════════════════════════════════════════════
-- Skill Management Migration
-- Version: 015
-- Description: 创建 Skill 订阅管理相关表
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. 用户 Skill 订阅表
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_skill_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,

    -- 订阅状态
    status VARCHAR(20) NOT NULL DEFAULT 'subscribed',  -- subscribed | unsubscribed

    -- 推送开关
    push_enabled BOOLEAN DEFAULT true,

    -- 时间戳
    subscribed_at TIMESTAMPTZ DEFAULT now(),
    unsubscribed_at TIMESTAMPTZ,

    -- 试用追踪
    trial_messages_used INTEGER DEFAULT 0,

    -- 元数据
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- 唯一约束
    CONSTRAINT uk_user_skill UNIQUE(user_id, skill_id),

    -- 状态约束
    CONSTRAINT chk_status CHECK (status IN ('subscribed', 'unsubscribed'))
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_skill_subs_user ON user_skill_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_skill_subs_skill ON user_skill_subscriptions(skill_id);
CREATE INDEX IF NOT EXISTS idx_skill_subs_status ON user_skill_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_skill_subs_push ON user_skill_subscriptions(push_enabled) WHERE status = 'subscribed';

-- 注释
COMMENT ON TABLE user_skill_subscriptions IS 'Skill 订阅管理表';
COMMENT ON COLUMN user_skill_subscriptions.status IS '订阅状态: subscribed=已订阅, unsubscribed=已取消';
COMMENT ON COLUMN user_skill_subscriptions.push_enabled IS '是否开启该 Skill 的推送通知';
COMMENT ON COLUMN user_skill_subscriptions.trial_messages_used IS '已使用的试用消息数';


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Skill 使用记录表
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS skill_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,

    -- 行为类型
    action VARCHAR(50) NOT NULL,  -- chat | tool_call | view_card | subscribe | unsubscribe | try

    -- 元数据 (可选)
    metadata JSONB DEFAULT '{}',

    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 索引 (用于推荐算法)
CREATE INDEX IF NOT EXISTS idx_usage_user_time ON skill_usage_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_skill ON skill_usage_log(skill_id);
CREATE INDEX IF NOT EXISTS idx_usage_action ON skill_usage_log(action);

-- 按时间分区 (可选，大数据量时启用)
-- CREATE INDEX IF NOT EXISTS idx_usage_created ON skill_usage_log(created_at);

-- 注释
COMMENT ON TABLE skill_usage_log IS 'Skill 使用记录，用于推荐算法';
COMMENT ON COLUMN skill_usage_log.action IS '行为类型: chat=对话, tool_call=工具调用, view_card=查看卡片, subscribe=订阅, unsubscribe=取消订阅, try=试用';


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Skill 推荐屏蔽表
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS skill_recommendation_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vibe_users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,

    -- 屏蔽类型
    block_type VARCHAR(20) NOT NULL DEFAULT 'permanent',  -- permanent | temporary

    -- 临时屏蔽到期时间
    expires_at TIMESTAMPTZ,

    -- 时间戳
    created_at TIMESTAMPTZ DEFAULT now(),

    -- 唯一约束
    CONSTRAINT uk_block_user_skill UNIQUE(user_id, skill_id)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_blocks_user ON skill_recommendation_blocks(user_id);

-- 注释
COMMENT ON TABLE skill_recommendation_blocks IS '用户屏蔽的推荐 Skill';
COMMENT ON COLUMN skill_recommendation_blocks.block_type IS '屏蔽类型: permanent=永久不推荐, temporary=暂时隐藏';


-- ═══════════════════════════════════════════════════════════════════════════
-- 4. 初始化默认订阅 (为现有用户)
-- ═══════════════════════════════════════════════════════════════════════════

-- 为所有用户初始化 core Skill (始终激活)
INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
SELECT id, 'core', 'subscribed', true
FROM vibe_users
WHERE NOT EXISTS (
    SELECT 1 FROM user_skill_subscriptions
    WHERE user_skill_subscriptions.user_id = vibe_users.id
    AND user_skill_subscriptions.skill_id = 'core'
)
ON CONFLICT (user_id, skill_id) DO NOTHING;

-- 为所有用户初始化 mindfulness Skill (默认激活)
INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
SELECT id, 'mindfulness', 'subscribed', true
FROM vibe_users
WHERE NOT EXISTS (
    SELECT 1 FROM user_skill_subscriptions
    WHERE user_skill_subscriptions.user_id = vibe_users.id
    AND user_skill_subscriptions.skill_id = 'mindfulness'
)
ON CONFLICT (user_id, skill_id) DO NOTHING;

-- 为所有用户初始化 lifecoach Skill (默认激活)
INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
SELECT id, 'lifecoach', 'subscribed', true
FROM vibe_users
WHERE NOT EXISTS (
    SELECT 1 FROM user_skill_subscriptions
    WHERE user_skill_subscriptions.user_id = vibe_users.id
    AND user_skill_subscriptions.skill_id = 'lifecoach'
)
ON CONFLICT (user_id, skill_id) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
-- 5. 触发器：更新 updated_at
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION update_skill_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_skill_subscription_updated ON user_skill_subscriptions;
CREATE TRIGGER trg_skill_subscription_updated
    BEFORE UPDATE ON user_skill_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_skill_subscription_timestamp();


-- ═══════════════════════════════════════════════════════════════════════════
-- 6. 触发器：新用户自动初始化默认 Skill
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION init_default_skill_subscriptions()
RETURNS TRIGGER AS $$
BEGIN
    -- Core Skill (始终激活)
    INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
    VALUES (NEW.id, 'core', 'subscribed', true)
    ON CONFLICT (user_id, skill_id) DO NOTHING;

    -- Mindfulness (默认激活)
    INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
    VALUES (NEW.id, 'mindfulness', 'subscribed', true)
    ON CONFLICT (user_id, skill_id) DO NOTHING;

    -- Lifecoach (默认激活)
    INSERT INTO user_skill_subscriptions (user_id, skill_id, status, push_enabled)
    VALUES (NEW.id, 'lifecoach', 'subscribed', true)
    ON CONFLICT (user_id, skill_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_init_skill_subscriptions ON vibe_users;
CREATE TRIGGER trg_init_skill_subscriptions
    AFTER INSERT ON vibe_users
    FOR EACH ROW
    EXECUTE FUNCTION init_default_skill_subscriptions();


-- ═══════════════════════════════════════════════════════════════════════════
-- 7. 视图：用户 Skill 订阅汇总
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_user_skill_summary AS
SELECT
    u.id AS user_id,
    u.email,
    COUNT(s.id) FILTER (WHERE s.status = 'subscribed') AS subscribed_count,
    COUNT(s.id) FILTER (WHERE s.push_enabled = true AND s.status = 'subscribed') AS push_enabled_count,
    array_agg(s.skill_id) FILTER (WHERE s.status = 'subscribed') AS subscribed_skills
FROM vibe_users u
LEFT JOIN user_skill_subscriptions s ON s.user_id = u.id
GROUP BY u.id, u.email;

COMMENT ON VIEW v_user_skill_summary IS '用户 Skill 订阅汇总视图';


-- ═══════════════════════════════════════════════════════════════════════════
-- 8. 视图：Skill 统计
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_skill_stats AS
SELECT
    skill_id,
    COUNT(*) FILTER (WHERE status = 'subscribed') AS subscriber_count,
    COUNT(*) FILTER (WHERE push_enabled = true AND status = 'subscribed') AS push_enabled_count,
    AVG(trial_messages_used)::NUMERIC(10,2) AS avg_trial_usage,
    MAX(subscribed_at) AS latest_subscription
FROM user_skill_subscriptions
GROUP BY skill_id;

COMMENT ON VIEW v_skill_stats IS 'Skill 订阅统计视图';


-- ═══════════════════════════════════════════════════════════════════════════
-- 完成
-- ═══════════════════════════════════════════════════════════════════════════

-- 验证
DO $$
BEGIN
    RAISE NOTICE 'Migration 015: Skill Management tables created successfully';
    RAISE NOTICE 'Tables: user_skill_subscriptions, skill_usage_log, skill_recommendation_blocks';
    RAISE NOTICE 'Views: v_user_skill_summary, v_skill_stats';
END $$;
