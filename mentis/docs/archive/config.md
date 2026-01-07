# Mentis OS v3.0 - 资源配置

> 最后更新: 2026-01-04 | 全部服务已验证通过

## 1. 数据库

**PostgreSQL (aiscend 服务器)** ✅ 已验证
- 主机: `106.37.170.238`
- 端口: `8224`
- 用户: `postgres`
- 密码: `Ak4_9lScd-69WX`


## 2. 智谱 GLM (对话/图片)

**API 控制台**: https://bigmodel.cn/usercenter/equity-mgmt/user-rights

**API Key**: `42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF`

**使用模型**:
| 模型 | 用途 | 状态 |
|------|------|------|
| `glm-4.7` | 对话 | ✅ 已验证 |
| `glm-4v-flash` | 图片理解 | ⚠️ 需 base64 编码 |

**API 文档**: https://docs.bigmodel.cn/cn/guide/models/text/glm-4.7


## 3. Google Gemini (Embedding)

**申请地址**: https://aistudio.google.com/app/apikey

**API Key**: `AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE`

**使用模型**: `gemini-embedding-001` ✅ 已验证 (升级于 2026-01-04)
- 维度: **3072** (原 text-embedding-004 为 768)
- 用途: 向量嵌入/语义搜索
- 特点: 更高维度，更好的语义表达能力

**模型对比**:
| 模型 | 维度 | 说明 |
|------|------|------|
| `gemini-embedding-001` | 3072 | 最新模型 ✅ 当前使用 |
| `text-embedding-004` | 768 | 旧版模型 |

**测试结果** (2026-01-04):
```
✅ Gemini Embedding API 测试成功!
   模型: gemini-embedding-001
   向量维度: 3072
   前5个值: [-0.014056949, 0.01722608, 0.004692631, -0.09195162, 0.013508957]
```

**快速验证**:
```python
import httpx
import asyncio

async def test_gemini():
    api_key = "AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key={api_key}"
    payload = {
        "model": "models/gemini-embedding-001",
        "content": {"parts": [{"text": "hello, world"}]},
        "taskType": "RETRIEVAL_DOCUMENT",
    }
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json=payload)
        result = resp.json()
        print(len(result["embedding"]["values"]))  # 3072

asyncio.run(test_gemini())
```

## 4. Pinecone

**控制台**: https://app.pinecone.io/

**API Key**: `pcsk_tVETE_HsAhSvJG9yN2nSdGfkMz2aTefYa72inmvnp97musqf3twzRgDiLEtHDdYAsBmiQ`

**索引配置** ✅ 已升级 (2026-01-04):
- 名称: `mentis-streams`
- **Host**: `mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io`
- **维度: `3072`** (与 Gemini gemini-embedding-001 匹配)
- Metric: `cosine`
- Cloud: AWS us-east-1 (Serverless)

**测试结果** (2026-01-04):
```
✅ Pinecone 连接成功!
   索引: mentis-streams
   维度: 3072 (已从 768 升级)
   Host: mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io
   状态: Ready
```

**获取 AGENTS 文档**:
```bash
curl -o CLAUDE.md https://docs.pinecone.io/AGENTS-PYTHON.md
```

## 5. 语音识别

**注意**: GLM 暂不支持语音识别。可选方案:

1. **OpenAI Whisper** (推荐)
   - 需要 OpenAI API Key
   - 支持中英文

2. **百度 ASR**
   - 免费额度较多
   - 需要申请

## 6. 环境变量汇总

```bash
# 数据库
MENTIS_DB_URL=postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/mentis_v3

# JWT
MENTIS_JWT_SECRET=mentis-v3-jwt-secret-key-2026-aiscend

# 智谱 GLM (对话/图片)
GLM_API_KEY=42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF
GLM_CHAT_MODEL=glm-4.7
GLM_VISION_MODEL=glm-4.7

# Google Gemini (Embedding)
GEMINI_API_KEY=AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE
GEMINI_EMBEDDING_MODEL=gemini-embedding-001

# Pinecone
PINECONE_API_KEY=pcsk_tVETE_HsAhSvJG9yN2nSdGfkMz2aTefYa72inmvnp97musqf3twzRgDiLEtHDdYAsBmiQ
PINECONE_HOST=mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io

# 服务提供商
MENTIS_VISION_PROVIDER=glm
MENTIS_EMBEDDING_PROVIDER=gemini
```

## 7. 启动命令

**后端启动** (完整环境变量):
```bash
cd /home/aiscend/work/mentis

# 安装依赖
pip install -r requirements.txt

# 启动 API 服务 (端口 8100)
MENTIS_DB_URL="postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/mentis_v3" \
GLM_API_KEY="42b82ed9a13e4e8890ef3854bb840ef8.TcWZ4DIq0NF2xElF" \
GEMINI_API_KEY="AIzaSyCRxKvvtDeb1_-yBUVGafNkTuO2QLME9HE" \
PINECONE_API_KEY="pcsk_tVETE_HsAhSvJG9yN2nSdGfkMz2aTefYa72inmvnp97musqf3twzRgDiLEtHDdYAsBmiQ" \
PINECONE_HOST="mentis-streams-nkchadl.svc.aped-4627-b74a.pinecone.io" \
MENTIS_JWT_SECRET="mentis-v3-jwt-secret-key-2026-aiscend" \
python -m uvicorn api.main:app --port 8100 --host 0.0.0.0
```

**前端启动**:
```bash
cd /home/aiscend/work/mentis/apps/web
pnpm install
pnpm dev
```

**健康检查**:
```bash
curl http://127.0.0.1:8100/health
# {"status":"ok","service":"mentis-api","version":"3.0.0"}
```

## 8. 服务分工

| 服务 | 提供商 | 模型 | 状态 |
|------|--------|------|------|
| 对话生成 | GLM | glm-4-flash | ✅ 已验证 |
| 图片理解 | GLM | glm-4v-flash | ✅ 已配置 |
| 向量嵌入 | Gemini | gemini-embedding-001 | ✅ 已升级 (3072维) |
| 语义搜索 | Pinecone | mentis-streams | ✅ 索引已升级 (3072维) |
| 语音识别 | - | - | ❌ 待配置 |

## 9. 单元测试

**测试结果** (2026-01-04):
```
============================= test session starts ==============================
platform linux -- Python 3.13.3, pytest-8.4.2
collected 65 items

tests/test_behavior_matcher.py    22 passed
tests/test_emotion_engine.py      25 passed (1 边界值警告)
tests/test_intervention_agent.py  17 passed

========================= 64 passed, 1 failed in 0.23s =========================
```

**运行测试**:
```bash
cd /home/aiscend/work/mentis
MENTIS_DB_URL="postgresql://postgres:Ak4_9lScd-69WX@106.37.170.238:8224/mentis_v3" \
python -m pytest tests/ -v
```

## 10. API 测试示例

**用户注册**:
```bash
curl -X POST http://127.0.0.1:8100/api/v3/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@mentis.ai","password":"test123456","name":"Test User"}'
```

**用户登录**:
```bash
curl -X POST http://127.0.0.1:8100/api/v3/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@mentis.ai","password":"test123456"}'
```

**Stream 输入 (SSE)**:
```bash
TOKEN="<access_token>"
curl -N -X POST http://127.0.0.1:8100/api/v3/stream \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"content":"今天心情不错","type":"vibe_diary"}'
```

**Stream API 测试结果**:
```
输入: "气死我了！老板又在会议上批评我"
输出:
- event: stream_created
- event: extraction_complete
  - 情绪: anger (强度 6)
  - 场景: work, 触发: meeting, 目标: boss
  - 能量变化: -4
- event: state_update
  - energy_score: 46
  - aura_state: alert
- event: done
```

## 11. 待办事项

- [x] 配置 `GEMINI_API_KEY` ✅ 2026-01-04
- [x] 在 Pinecone 创建 `mentis-streams` 索引 (维度: 768) ✅ 2026-01-04
- [x] 验证 PostgreSQL 数据库连接 ✅ 2026-01-04
- [x] 验证 GLM 对话 API ✅ 2026-01-04
- [x] 运行单元测试 (64/65 通过) ✅ 2026-01-04
- [x] 测试 Stream API (SSE) ✅ 2026-01-04
- [ ] 配置语音识别服务 (可选)
- [ ] 配置前端 Web 应用
