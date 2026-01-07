import sys
import time
from db_manager import (
    insert_gemini_job,
    get_gemini_job_by_title,
    get_tasks_by_job_id,
    init_connection_pool,
    close_connection_pool
)
from loguru import logger

# 配置日志
log_day_str = '{time:%Y-%m-%d}'
logger.add(f'logs/{__name__}.{log_day_str}.log', rotation="1 day", retention='1 months', level="INFO")

def create_gemini_job(title: str, tasks: list):
    """
    创建 Gemini Job 和多个 Tasks（直接操作数据库）
    :param title: job 的标题
    :param tasks: tasks 列表，每个 task 是包含 model, prompt_type, prompt, file_path, file_type, save_doc 的字典
    :return: (success: bool, job_id: int, task_ids: list)
    """
    try:
        # 检查是否已存在相同 title 的 job
        existing_job = get_gemini_job_by_title(title)
        if existing_job:
            job_id = existing_job['id']
            # 获取该 job 下的所有 task_ids
            tasks_list = get_tasks_by_job_id(job_id)
            task_ids = [task['id'] for task in tasks_list]
            err_msg = f"已存在相同 title 的 job (job_id: {job_id})"
            logger.info(err_msg)
            print(f"✗ {err_msg}")
            print(f"  已存在的 Job ID: {job_id}，包含 {len(task_ids)} 个 Tasks")
            print(f"  Task IDs: {task_ids}")
            return False, job_id, task_ids
        
        # 如果不存在，则创建新的 job
        err, job_id, task_ids = insert_gemini_job(title, tasks)
        
        if err:
            print(f"✗ 创建失败: {err}")
            return False, None, []
        else:
            print(f"✓ 成功创建 Job (ID: {job_id})，包含 {len(task_ids)} 个 Tasks")
            print(f"  Task IDs: {task_ids}")
            return True, job_id, task_ids
            
    except Exception as e:
        print(f"✗ 发生错误: {e}")
        logger.error(f"创建 Gemini Job 失败: {e}")
        return False, None, []

def main():
    # 初始化数据库连接池
    init_connection_pool()
    
    try:
        if len(sys.argv) > 1:
            # 从命令行参数获取 prompt
            prompt = " ".join(sys.argv[1:])
        else:
            # 默认测试 prompt
            prompt = "根据2025年10月之后的最新信息,写一份美股消费信贷行业的分析报告,尤其是重要的上市公司syf和ally等"
        
        summary_prompt = '''
请按如下JSON格式生成上述报告的:
{
"topic": "",
"type": "company,sector,industry,theme中选一个",
"summary": "",
"title": "",
"year": "财经年份",
"quarter": "财经季度",
"content_type": "research,transcript,report等",
"ticker": "公司上市代码",
"ticker_cn": "公司中文名",
"company": "",
"country": "公司总部所在国家英文缩写",
}
        '''

        print("直接操作数据库创建 Gemini Job")
        print(f"Prompt: {prompt[:100]}...")
        print("-" * 60)
        
        # 创建测试任务
        title = "美股消费信贷行业分析报告"
        tasks = [
            {
                "model": "deep_research",
                "prompt_type": "analysis",
                "prompt": prompt,
                "file_path": "",
                "file_type": "md",
                "save_doc": True
            },
            {
                "model": "standard",
                "prompt_type": "summary",
                "prompt": summary_prompt,
                "file_path": "",
                "file_type": "txt",
                "save_doc": True
            }
        ]
        
        # 第一次调用
        print("\n[测试 1] 创建包含 2 个 Tasks 的 Job...")
        success1, job_id1, task_ids1 = create_gemini_job(title, tasks)
        if success1:
            print(f"✓ 成功创建包含 {len(task_ids1)} 个 Tasks 的 Job: {job_id1}")
        
        # 创建测试任务
        title = "地球上面积最大和最小的国家分别是什么?"
        tasks = [
            {
                "model": "standard",
                "prompt_type": "",
                "prompt": "地球上面积最大和最小的国家分别是什么?",
                "file_path": "",
                "file_type": "txt",
                "save_doc": False
            },
            {
                "model": "standard",
                "prompt_type": "",
                "prompt": "它们的面积具体是怎么形成这样的?",
                "file_path": "",
                "file_type": "txt",
                "save_doc": True
            }
        ]
        
        # 第二次调用
        print("\n[测试 2] 创建包含 2 个 Tasks 的 Job...")
        success2, job_id2, task_ids2 = create_gemini_job(title, tasks)
        if success2:
            print(f"✓ 成功创建包含 {len(task_ids2)} 个 Tasks 的 Job: {job_id2}")
        
        # 第三次调用 - 测试重复 title
        print("\n[测试 3] 尝试创建相同 title 的 Job（应该返回已存在的 job）...")
        success3, job_id3, task_ids3 = create_gemini_job(title, tasks)
        if not success3 and job_id3:
            print(f"✓ 正确检测到已存在的 Job: {job_id3}")
        
        print("\n" + "-" * 60)
        print("测试完成")
        
    finally:
        # 关闭数据库连接池
        close_connection_pool()

if __name__ == "__main__":
    main()

