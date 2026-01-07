import os
import logging
from datetime import datetime
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)

# 数据库配置（从环境变量读取，禁止硬编码凭证）
DATABASE_CONFIG = {
    "host": os.getenv("GEMINI_DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("GEMINI_DB_PORT", "5432")),
    "database": os.getenv("GEMINI_DB_NAME", "gemini"),
    "user": os.getenv("GEMINI_DB_USER", "postgres"),
    "password": os.getenv("GEMINI_DB_PASSWORD", ""),
}

# 连接池配置
MIN_CONNECTIONS = 2
MAX_CONNECTIONS = 10

# 全局连接池
_connection_pool = None

def init_connection_pool():
    """初始化数据库连接池"""
    global _connection_pool
    if _connection_pool is None:
        try:
            _connection_pool = psycopg2.pool.ThreadedConnectionPool(
                MIN_CONNECTIONS,
                MAX_CONNECTIONS,
                **DATABASE_CONFIG
            )
            logger.info("数据库连接池初始化成功")
        except Exception as e:
            logger.error(f"数据库连接池初始化失败: {e}")
            raise
    return _connection_pool

def get_connection_pool():
    """获取连接池（如果未初始化则先初始化）"""
    if _connection_pool is None:
        return init_connection_pool()
    return _connection_pool

@contextmanager
def get_db_connection():
    """获取数据库连接的上下文管理器"""
    pool_conn = get_connection_pool()
    conn = None
    try:
        conn = pool_conn.getconn()
        yield conn
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"数据库操作失败: {e}")
        raise
    finally:
        if conn:
            pool_conn.putconn(conn)

def insert_gemini_job(title: str, tasks: list) -> tuple:
    """
    一次性创建 Gemini Job 和多个 Tasks
    :param title: job 的 标题
    :param tasks: tasks 列表，每个 task 可以是 Pydantic 模型或字典，包含 model, prompt_type, prompt, file_path, file_type, save_doc
    :return: (err, job_id, task_ids)
    """
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            now = datetime.now()
            
            # 1. 先插入 gemini_job
            job_insert_query = """
                INSERT INTO public.gemini_job (job_name, status, created_at, updated_at, gemini_url, save_path, user_email)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """
            cursor.execute(job_insert_query, (title, 0, now, now, '', '', ''))
            job_id = cursor.fetchone()[0]
            logger.info(f"成功创建 Gemini Job，ID: {job_id}")
            
            # 2. 批量插入 gemini_task
            task_ids = []
            task_insert_query = """
                INSERT INTO public.gemini_task (
                    job_id, model, task_name, prompt, input_file_path, output_file_type,
                    gemini_url, output_url, output_text, output_file_path,
                    save_doc, status, created_at, updated_at, output_code
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """
            
            for task in tasks:
                # 处理 Pydantic 模型或字典
                if hasattr(task, 'model_dump'):
                    task_dict = task.model_dump()
                elif hasattr(task, 'dict'):
                    task_dict = task.dict()
                elif isinstance(task, dict):
                    task_dict = task
                else:
                    raise ValueError(f"不支持的 task 类型: {type(task)}")
                
                cursor.execute(
                    task_insert_query,
                    (
                        job_id,
                        task_dict.get('model', ''),
                        task_dict.get('prompt_type', ''),
                        task_dict.get('prompt', ''),
                        task_dict.get('file_path', ''),
                        task_dict.get('file_type', ''),
                        task_dict.get('gemini_url', ''),
                        task_dict.get('output_url', ''),
                        task_dict.get('output_text', ''),
                        task_dict.get('output_file_path', ''),
                        task_dict.get('save_doc', False),
                        task_dict.get('status', 0),
                        now,
                        now,
                        task_dict.get('output_code', ''),
                    )
                )
                task_id = cursor.fetchone()[0]
                task_ids.append(task_id)
                logger.info(f"成功创建 Gemini Task，ID: {task_id}, job_id: {job_id}")
            
            conn.commit()
            logger.info(f"成功创建 Gemini Job {job_id} 和 {len(task_ids)} 个 Tasks")
            return None, job_id, task_ids
            
        except Exception as e:
            conn.rollback()
            logger.error(f"创建 Gemini Job 失败: {e}")
            return str(e), None, []

def get_tasks_by_job_id(job_id: int) -> List[Dict]:
    """获取某 Job 下的所有 task"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_task
                WHERE job_id = %s
                ORDER BY created_at ASC
            """
            cursor.execute(select_query, (job_id,))
            tasks = cursor.fetchall()
            return [dict(task) for task in tasks]
        except Exception as e:
            logger.error(f"获取任务失败: {e}")
            raise
        finally:
            cursor.close()
