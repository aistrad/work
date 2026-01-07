这是一个非常典型的 **"生成式 AI + 传统算法"** 结合的系统设计。

核心流程可以拆解为：

1. **算（传统算法）：** 利用开源库进行精准的真太阳时计算和八字排盘（这是 AI 难以精准计算的数学逻辑部分）。
2. **写（数据库交互）：** 将排盘结果构造成 Prompt，利用你提供的 `db_manager.py` 写入数据库。
3. **读（异步轮询）：** 前端/后端轮询数据库状态，等待 Deep Research 完成并展示。

以下是详细的系统设计与实现方案。

---

###一、 系统架构设计系统采用 **前后端分离** 架构，通过 **PostgreSQL** 作为任务队列和数据交换中心。

**技术栈建议：**

* **前端：** React / Vue (提供生日和出生地选择)。
* **后端：** Python FastAPI (高性能，易于集成异步数据库操作)。
* **算法库：** `lunar_python` (GitHub 开源项目，支持真太阳时和八字)。
* **数据库交互：** 复用提供的 `db_manager.py`。

---

###二、 核心模块实现####1. 八字排盘模块 (The Calculator)Deep Research 需要精准的输入。普通公历转农历不够准确，必须计算**真太阳时**（根据经纬度调整时间）。

**推荐开源库：** [6tail/lunar-python](https://github.com/6tail/lunar-python)

```python
# bazi_engine.py
from lunar_python import Solar, Lunar
from typing import Dict

def calculate_bazi(year, month, day, hour, minute, longitude) -> Dict:
    """
    计算真太阳时八字
    :param longitude: 出生地经度（计算真太阳时必须）
    """
    # 1. 建立公历时间对象
    solar = Solar.fromYmdHms(year, month, day, hour, minute, 0)
    
    # 2. 转换为农历对象 (不立刻转八字，先根据经度修正时间)
    # lunar_python 库可以直接根据经度获取真太阳时的八字
    lunar = solar.getLunar()
    
    # 获取八字（自动处理早晚子时等复杂逻辑，但真太阳时需要手动通过时间偏移计算或使用库的高级功能）
    # 这里简化逻辑：先计算真太阳时的时间戳，再重新生成 Solar 对象
    # (实际生产建议使用 sxtwl 或 lunar_python 的高级特性)
    
    # 获取四柱
    ba_zi = lunar.getEightChar()
    
    # 修正真太阳时逻辑 (简易版)
    # 比如：北京时间 12:00 在乌鲁木齐实际上还是早上，八字可能不同
    # 此处假设传入的时间已经是根据经度调整过的，或者使用库的内置功能
    
    return {
        "year_pillar": ba_zi.getYear(),   # 年柱
        "month_pillar": ba_zi.getMonth(), # 月柱
        "day_pillar": ba_zi.getDay(),     # 日柱
        "hour_pillar": ba_zi.getTime(),   # 时柱
        "wuxing": ba_zi.getYearWuXing() + ba_zi.getMonthWuXing() + ... # 五行统计
        # "day_master": ... 日主等信息
    }

```

####2. Prompt 工程与任务投递 (The Producer)利用你提供的 `insert_gemini_job` 将计算好的八字封装成 Deep Research 任务。

```python
# task_service.py
from db_manager import insert_gemini_job
from bazi_engine import calculate_bazi

def submit_bazi_task(user_data):
    """
    用户提交生日 -> 计算八字 -> 写入数据库
    """
    # 1. 计算八字
    bazi_result = calculate_bazi(
        user_data['year'], user_data['month'], user_data['day'],
        user_data['hour'], user_data['minute'], user_data['longitude']
    )
    
    bazi_text = f"{bazi_result['year_pillar']}年 {bazi_result['month_pillar']}月 {bazi_result['day_pillar']}日 {bazi_result['hour_pillar']}时"
    
    # 2. 构建 Deep Research Prompt
    # 这里的 Prompt 设计非常关键，需要引导模型进行“深度推理”
    prompt_content = f"""
    请作为一位专业的国学与命理学研究专家，对以下八字进行深度解析报告。
    
    **客户信息**：
    - 性别：{user_data['gender']}
    - 八字排盘：{bazi_text}
    
    **报告要求**：
    1. **全局格局分析**：分析日主强弱、喜用神选取、格局高低。
    2. **性格深层剖析**：结合五行生克，分析其显性性格与潜意识。
    3. **流年大运推演**：结合当前年份（{datetime.now().year}），预测未来3-5年的关键转折点。
    4. **人生建议**：针对事业、财运、健康给出具体的可执行建议。
    
    请输出一篇结构严谨、逻辑清晰、不少于2000字的深度分析报告。
    """

    # 3. 构造 Task 结构 (参考 gemini_db_test.py 中的结构)
    tasks = [
        {
            "model": "deep_research", # 确保这是你们后台Worker识别的模型ID
            "prompt_type": "bazi_analysis",
            "prompt": prompt_content,
            "file_path": "",
            "file_type": "md",
            "save_doc": True # 我们希望生成文档
        }
    ]
    
    job_title = f"{user_data['name']} - 八字深度报告"
    
    # 4. 写入数据库
    err, job_id, task_ids = insert_gemini_job(job_title, tasks)
    
    if err:
        raise Exception(f"任务提交失败: {err}")
    
    return job_id

```

####3. 结果轮询 API (The Consumer Interface)由于 Deep Research 是耗时操作，前端不能傻等，需要一个接口查询状态。利用 `get_tasks_by_job_id`。

```python
# api_server.py (FastAPI 示例)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from db_manager import get_gemini_job_by_id, get_tasks_by_job_id, init_connection_pool

app = FastAPI()

# 启动时初始化连接池
@app.on_event("startup")
def startup():
    init_connection_pool()

class BaziRequest(BaseModel):
    name: str
    gender: str
    year: int
    month: int
    day: int
    hour: int
    minute: int
    longitude: float # 经度用于真太阳时

@app.post("/api/calculate")
def create_report(req: BaziRequest):
    try:
        job_id = submit_bazi_task(req.dict())
        return {"job_id": job_id, "status": "processing"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/report/{job_id}")
def get_report(job_id: int):
    # 1. 检查 Job 状态
    job = get_gemini_job_by_id(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="任务不存在")
        
    # 2. 如果任务未完成 (假设 status 10 为完成)
    if job['status'] < 10:
        return {"status": "processing", "progress": job['status']}
    
    # 3. 获取任务结果
    tasks = get_tasks_by_job_id(job_id)
    if not tasks:
        return {"status": "error", "message": "无子任务数据"}
        
    # 假设第一个任务就是主报告
    main_task = tasks[0]
    
    # 返回结果文本或下载链接
    return {
        "status": "completed",
        "content": main_task['output_text'], # 假设Worker将结果写回了output_text
        "doc_url": main_task['output_url']   # 或者是文档链接
    }

```

---

###三、 前端交互设计 (流程图)前端页面需要处理“等待感”，因为 Deep Research 可能需要几分钟。

1. **输入页：**
* 表单：姓名、性别、日期控件、出生地（接入地图API获取经纬度，或者简单的省份选择映射经度）。
* 按钮：“生成天命报告”。


2. **加载页（Loading）：**
* 显示：“正在计算真太阳时...正在排盘...Deep Research正在连接宇宙能量...”
* 技术实现：每隔 3-5 秒调用一次 `GET /api/report/{job_id}`。


3. **结果页：**
* 左侧：展示传统的八字排盘图（四柱、十神）。
* 右侧/下方：Markdown 渲染 Deep Research 生成的万字长文。



---

###四、 关键路径与注意事项1. **真太阳时问题：**
* 这是八字算命中最容易被忽略但最关键的一步。北京时间 12:00 在新疆和在上海的太阳角度完全不同。
* **方案：** 必须要求用户输入出生城市，后台维护一个城市经度映射表，或者直接调地图 API。公式：`真太阳时 = 平太阳时 + 经度差修正 + 均时差(Equation of Time)`。 `lunar-python` 库能辅助解决大部分问题。


2. **Deep Research 上下文控制：**
* 直接扔八字给 AI，它可能会胡编乱造。
* **方案：** 在 Prompt 中嵌入一些“硬规则”或“排盘基础知识”作为上下文（Context Injection）。例如：“已知日元为甲木，生于寅月，得令...” 先让 AI 复述这些硬性算出的事实，再让它进行推演，可以大幅降低幻觉。


3. **数据库状态更新：**
* 你的 `db_manager.py` 只有写入逻辑。你需要确保后台有一个 Worker 进程（可能是你提到的“deep research 接口”）在不断读取 `status=0` 的任务，处理完后调用 `update_gemini_task_status` 更新 `output_text` 和 `status=10`。



###五、 总结下步行动你已经有了完善的数据库管理层（`db_manager.py`），接下来的工作重点是：

1. **Web 这一层**：用 FastAPI 封装 `submit_bazi_task`。
2. **算法这一层**：引入 `lunar_python` 实现真太阳时转换。
3. **Worker 这一层**：确保你的后台 Worker 能正确识别 `model="deep_research"` 的任务并回填数据。