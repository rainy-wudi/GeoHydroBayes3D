#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
批量提交ABAQUS任务 - 完整映射版
特点：大文件、长读取时间
"""

import os
import subprocess
import time
import psutil
from datetime import datetime
from concurrent.futures import ProcessPoolExecutor, as_completed

def check_memory():
    """检查可用内存"""
    mem = psutil.virtual_memory()
    return mem.available / (1024**3)  # GB

def submit_job(job_name, job_id, total_jobs):
    """提交单个作业"""
    
    # 检查内存
    mem_available = check_memory()
    if mem_available < 12:
        print(f"[{job_id}] ⚠️  内存不足({mem_available:.1f}GB)，等待...")
        time.sleep(60)
        return submit_job(job_name, job_id, total_jobs)
    
    start_time = time.time()
    
    # 切换目录
    os.chdir("inp_files")
    
    cmd = f"abaqus job={job_name} interactive cpus=2"
    
    print(f"[{job_id}/{total_jobs}] 🚀 开始: {job_name}")
    print(f"                时间: {datetime.now().strftime('%H:%M:%S')}")
    print(f"                内存: {mem_available:.1f}GB")
    
    try:
        result = subprocess.run(cmd, shell=True, 
                                capture_output=True, text=True, 
                                timeout=3600)  # 1小时超时
        
        elapsed = time.time() - start_time
        
        if result.returncode == 0:
            status = f"✅ 成功 ({elapsed/60:.1f}分钟)"
        else:
            status = f"❌ 失败 (代码{result.returncode})"
    
    except subprocess.TimeoutExpired:
        status = "⏱️  超时 (>60分钟)"
    except Exception as e:
        status = f"💥 异常: {str(e)}"
    
    os.chdir("..")
    
    print(f"[{job_id}/{total_jobs}] {status}\n")
    
    return job_name, status, elapsed if "elapsed" in locals() else 0

if __name__ == "__main__":
    print("="*70)
    print("      ABAQUS批量计算 - 完整单元映射版")
    print("="*70)
    print()
    
    jobs = [
        "Job_P001_R01",
    ]

    total_jobs = len(jobs)
    
    print(f"总任务数: {total_jobs}")
    print(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"可用内存: {check_memory():.1f} GB")
    print()
    print("⚠️  注意: 每个作业约20-30分钟")
    print("⚠️  大文件读取时间: 5-15分钟")
    print()

    # 并行设置（根据内存调整）
    max_workers = 2 if check_memory() > 32 else 1
    print(f"并行度: {max_workers}\n")
    
    results = {}
    start_time = time.time()

    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(submit_job, job, i+1, total_jobs): job
                   for i, job in enumerate(jobs)}
        
        for future in as_completed(futures):
            job_name, status, elapsed = future.result()
            results[job_name] = (status, elapsed)

    total_time = time.time() - start_time
    success_count = sum(1 for s, _ in results.values() if "成功" in s)
    total_compute_time = sum(t for _, t in results.values())
    
    print()
    print("="*70)
    print("              ✅ 计算完成")
    print("="*70)
    print(f"成功/总数: {success_count}/{total_jobs}")
    print(f"总耗时: {total_time/3600:.2f} 小时")
    print(f"实际计算: {total_compute_time/3600:.2f} CPU小时")
    print(f"平均时间: {total_time/total_jobs/60:.1f} 分钟/任务")
    
    # 保存日志
    with open("submit_log.txt", "w", encoding="utf-8") as f:
        for job, (status, elapsed) in results.items():
            f.write(f"{job}: {status} ({elapsed:.1f}s)\n")
    
    print("\n日志已保存: submit_log.txt")
