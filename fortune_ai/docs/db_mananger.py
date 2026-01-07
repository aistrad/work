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
    pool = get_connection_pool()
    conn = None
    try:
        conn = pool.getconn()
        yield conn
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"数据库操作失败: {e}")
        raise
    finally:
        if conn:
            pool.putconn(conn)

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
                INSERT INTO public.gemini_job (title, status, created_at, updated_at)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """
            cursor.execute(job_insert_query, (title, 0, now, now))
            job_id = cursor.fetchone()[0]
            logger.info(f"成功创建 Gemini Job，ID: {job_id}")
            
            # 2. 批量插入 gemini_task
            task_ids = []
            task_insert_query = """
                INSERT INTO public.gemini_task (
                    job_id, model, prompt_type, prompt, file_path, file_type,
                    gemini_url, output_url, output_text, output_file_path,
                    save_doc, status, created_at, updated_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """
            
            for task in tasks:
                # 处理 Pydantic 模型或字典
                if hasattr(task, 'model_dump'):
                    # Pydantic v2
                    task_dict = task.model_dump()
                elif hasattr(task, 'dict'):
                    # Pydantic v1
                    task_dict = task.dict()
                elif isinstance(task, dict):
                    # 已经是字典
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
                        '',  # gemini_url
                        '',  # output_url
                        '',  # output_text
                        '',  # output_file_path
                        task_dict.get('save_doc', False),
                        0,  # status
                        now,
                        now
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

def get_all_gemini_jobs() -> List[Dict]:
    """获取所有 Gemini 任务"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_job
                ORDER BY created_at DESC
            """
            cursor.execute(select_query)
            jobs = cursor.fetchall()
            
            # 将 RealDictRow 转换为普通字典
            result = [dict(job) for job in jobs]
            logger.info(f"成功获取 {len(result)} 个任务")
            return result
        except Exception as e:
            logger.error(f"获取所有任务失败: {e}")
            raise
        finally:
            cursor.close()

def get_all_gemini_tasks() -> List[Dict]:
    """获取所有 Gemini 子任务"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_task
                ORDER BY created_at DESC
            """
            cursor.execute(select_query)
            tasks = cursor.fetchall()
            
            # 将 RealDictRow 转换为普通字典
            result = [dict(task) for task in tasks]
            logger.info(f"成功获取 {len(result)} 个子任务")
            return result
        except Exception as e:
            logger.error(f"获取所有子任务失败: {e}")
            raise
        finally:
            cursor.close()

def get_gemini_task_by_id(task_id: int) -> Optional[Dict]:
    """根据 ID 获取 Gemini 任务"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_task
                WHERE id = %s
            """
            cursor.execute(select_query, (task_id,))
            task = cursor.fetchone()
            
            if task:
                result = dict(task)
                logger.info(f"成功获取子任务 ID: {task_id}")
                return result
            else:
                logger.warning(f"未找到子任务 ID: {task_id}")
                return None
        except Exception as e:
            logger.error(f"获取子任务失败: {e}")
            raise
        finally:
            cursor.close()

def get_gemini_job_by_id(job_id: int) -> Optional[Dict]:
    """根据 job_id 获取 Gemini 任务"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_job
                WHERE id = %s
            """
            cursor.execute(select_query, (job_id,))
            job = cursor.fetchone()
            
            if job:
                result = dict(job)
                logger.info(f"成功获取任务 job_id: {job_id}")
                return result
            else:
                logger.warning(f"未找到任务 job_id: {job_id}")
                return None
        except Exception as e:
            logger.error(f"获取任务失败: {e}")
            raise
        finally:
            cursor.close()

def get_gemini_job_by_title(title: str) -> Optional[Dict]:
    """根据 title 获取 Gemini 任务（返回最新的一个）"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_job
                WHERE title = %s
                ORDER BY created_at DESC
                LIMIT 1
            """
            cursor.execute(select_query, (title,))
            job = cursor.fetchone()
            
            if job:
                result = dict(job)
                logger.info(f"成功获取任务 title: {title}, job_id: {result['id']}")
                return result
            else:
                logger.info(f"未找到任务 title: {title}")
                return None
        except Exception as e:
            logger.error(f"获取任务失败: {e}")
            raise
        finally:
            cursor.close()

def get_tasks_by_job_id(job_id: int) -> List[Dict]:
    """根据 job_id 获取该 job 下的所有 tasks，按 task_id 从小到大排序"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            select_query = """
                SELECT *
                FROM public.gemini_task
                WHERE job_id = %s
                ORDER BY id ASC
            """
            cursor.execute(select_query, (job_id,))
            tasks = cursor.fetchall()
            
            result = [dict(task) for task in tasks]
            logger.info(f"成功获取 job_id {job_id} 下的 {len(result)} 个 tasks")
            return result
        except Exception as e:
            logger.error(f"获取 job_id {job_id} 下的 tasks 失败: {e}")
            raise
        finally:
            cursor.close()

def get_pending_gemini_jobs() -> List[Dict]:
    """获取所有待处理的任务 (status < 10)"""
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            # COMPLETED = 10
            select_query = """
                SELECT *
                FROM public.gemini_job
                WHERE status < 10
                ORDER BY created_at ASC
            """
            cursor.execute(select_query)
            jobs = cursor.fetchall()
            
            result = [dict(job) for job in jobs]
            logger.info(f"成功获取 {len(result)} 个待处理任务")
            return result
        except Exception as e:
            logger.error(f"获取待处理任务失败: {e}")
            raise
        finally:
            cursor.close()

def update_gemini_task_status(job_id: int, task_id: int, status: int, output_url: str = None, output_file_path: str = None, gemini_url: str = None, output_text: str = None):
    """更新任务状态和相关信息"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            # 构建更新查询，只更新提供的字段
            update_fields = ["status = %s", "updated_at = %s"]
            update_values = [status, datetime.now()]
            
            if output_url is not None:
                update_fields.append("output_url = %s")
                update_values.append(output_url)
            
            if output_file_path is not None:
                update_fields.append("output_file_path = %s")
                update_values.append(output_file_path)
            
            if gemini_url is not None:
                update_fields.append("gemini_url = %s")
                update_values.append(gemini_url)

                job_update_query = f"""
                    UPDATE public.gemini_job
                    SET gemini_url = %s
                    WHERE id = %s
                """
                cursor.execute(job_update_query, [gemini_url, job_id])
            
            if output_text is not None:
                update_fields.append("output_text = %s")
                update_values.append(output_text)
            
            update_query = f"""
                UPDATE public.gemini_task
                SET {', '.join(update_fields)}
                WHERE job_id = %s AND id = %s
            """
            update_values.append(job_id)
            update_values.append(task_id)
            
            cursor.execute(update_query, update_values)
            conn.commit()
            
            logger.info(f"成功更新子任务 ID: {task_id}, status: {status}")
        except Exception as e:
            conn.rollback()
            logger.error(f"更新任务状态失败: {e}")
            raise
        finally:
            cursor.close()

def update_gemini_job_status(job_id: int, status: int, gemini_url: str = None):
    """更新任务状态和相关信息"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            # 构建更新查询，只更新提供的字段
            update_fields = ["status = %s", "updated_at = %s"]
            update_values = [status, datetime.now()]
            
            if gemini_url is not None:
                update_fields.append("gemini_url = %s")
                update_values.append(gemini_url)
            
            update_query = f"""
                UPDATE public.gemini_job
                SET {', '.join(update_fields)}
                WHERE id = %s
            """
            update_values.append(job_id)
            
            cursor.execute(update_query, update_values)
            conn.commit()
            
            logger.info(f"成功更新任务 job_id: {job_id}, status: {status}")
        except Exception as e:
            conn.rollback()
            logger.error(f"更新任务 job_id: {job_id} 状态失败: {e}")
            raise
        finally:
            cursor.close()

def close_connection_pool():
    """关闭连接池（通常在应用关闭时调用）"""
    global _connection_pool
    if _connection_pool:
        _connection_pool.closeall()
        _connection_pool = None
        logger.info("数据库连接池已关闭")
