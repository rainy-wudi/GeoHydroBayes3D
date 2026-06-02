function generate_submit_script_full(config, all_jobs_info)
% 生成针对大文件优化的提交脚本

script_file = fullfile(config.output_folder, 'submit_all_jobs.py');
fid = fopen(script_file, 'w');

fprintf(fid, '#!/usr/bin/env python\n');
fprintf(fid, '# -*- coding: utf-8 -*-\n');
fprintf(fid, '"""\n');
fprintf(fid, '批量提交ABAQUS任务 - 完整映射版\n');
fprintf(fid, '特点：大文件、长读取时间\n');
fprintf(fid, '"""\n\n');

fprintf(fid, 'import os\n');
fprintf(fid, 'import subprocess\n');
fprintf(fid, 'import time\n');
fprintf(fid, 'import psutil\n');
fprintf(fid, 'from datetime import datetime\n');
fprintf(fid, 'from concurrent.futures import ProcessPoolExecutor, as_completed\n\n');

% 内存监控函数
fprintf(fid, 'def check_memory():\n');
fprintf(fid, '    """检查可用内存"""\n');
fprintf(fid, '    mem = psutil.virtual_memory()\n');
fprintf(fid, '    return mem.available / (1024**3)  # GB\n\n');

% 提交单个作业
fprintf(fid, 'def submit_job(job_name, job_id, total_jobs):\n');
fprintf(fid, '    """提交单个作业"""\n');
fprintf(fid, '    \n');
fprintf(fid, '    # 检查内存\n');
fprintf(fid, '    mem_available = check_memory()\n');
fprintf(fid, '    if mem_available < 12:\n');
fprintf(fid, '        print(f"[{job_id}] ⚠️  内存不足({mem_available:.1f}GB)，等待...")\n');
fprintf(fid, '        time.sleep(60)\n');
fprintf(fid, '        return submit_job(job_name, job_id, total_jobs)\n');
fprintf(fid, '    \n');
fprintf(fid, '    start_time = time.time()\n');
fprintf(fid, '    \n');
fprintf(fid, '    # 切换目录\n');
fprintf(fid, '    os.chdir("inp_files")\n');
fprintf(fid, '    \n');
fprintf(fid, '    cmd = f"abaqus job={job_name} interactive cpus=2"\n');
fprintf(fid, '    \n');
fprintf(fid, '    print(f"[{job_id}/{total_jobs}] 🚀 开始: {job_name}")\n');
fprintf(fid, '    print(f"                时间: {datetime.now().strftime(''%%H:%%M:%%S'')}")\n');
fprintf(fid, '    print(f"                内存: {mem_available:.1f}GB")\n');
fprintf(fid, '    \n');
fprintf(fid, '    try:\n');
fprintf(fid, '        result = subprocess.run(cmd, shell=True, \n');
fprintf(fid, '                                capture_output=True, text=True, \n');
fprintf(fid, '                                timeout=3600)  # 1小时超时\n');
fprintf(fid, '        \n');
fprintf(fid, '        elapsed = time.time() - start_time\n');
fprintf(fid, '        \n');
fprintf(fid, '        if result.returncode == 0:\n');
fprintf(fid, '            status = f"✅ 成功 ({elapsed/60:.1f}分钟)"\n');
fprintf(fid, '        else:\n');
fprintf(fid, '            status = f"❌ 失败 (代码{result.returncode})"\n');
fprintf(fid, '    \n');
fprintf(fid, '    except subprocess.TimeoutExpired:\n');
fprintf(fid, '        status = "⏱️  超时 (>60分钟)"\n');
fprintf(fid, '    except Exception as e:\n');
fprintf(fid, '        status = f"💥 异常: {str(e)}"\n');
fprintf(fid, '    \n');
fprintf(fid, '    os.chdir("..")\n');
fprintf(fid, '    \n');
fprintf(fid, '    print(f"[{job_id}/{total_jobs}] {status}\\n")\n');
fprintf(fid, '    \n');
fprintf(fid, '    return job_name, status, elapsed if "elapsed" in locals() else 0\n\n');

% 主程序
fprintf(fid, 'if __name__ == "__main__":\n');
fprintf(fid, '    print("="*70)\n');
fprintf(fid, '    print("      ABAQUS批量计算 - 完整单元映射版")\n');
fprintf(fid, '    print("="*70)\n');
fprintf(fid, '    print()\n');
fprintf(fid, '    \n');

% 作业列表
fprintf(fid, '    jobs = [\n');
for i = 1:length(all_jobs_info)
    fprintf(fid, '        "%s",\n', all_jobs_info{i}.job_name);
end
fprintf(fid, '    ]\n\n');

fprintf(fid, '    total_jobs = len(jobs)\n');
fprintf(fid, '    \n');
fprintf(fid, '    print(f"总任务数: {total_jobs}")\n');
fprintf(fid, '    print(f"开始时间: {datetime.now().strftime(''%%Y-%%m-%%d %%H:%%M:%%S'')}")\n');
fprintf(fid, '    print(f"可用内存: {check_memory():.1f} GB")\n');
fprintf(fid, '    print()\n');
fprintf(fid, '    print("⚠️  注意: 每个作业约20-30分钟")\n');
fprintf(fid, '    print("⚠️  大文件读取时间: 5-15分钟")\n');
fprintf(fid, '    print()\n\n');

% 并行设置
fprintf(fid, '    # 并行设置（根据内存调整）\n');
fprintf(fid, '    max_workers = 2 if check_memory() > 32 else 1\n');
fprintf(fid, '    print(f"并行度: {max_workers}\\n")\n');
fprintf(fid, '    \n');
fprintf(fid, '    results = {}\n');
fprintf(fid, '    start_time = time.time()\n\n');

% 执行
fprintf(fid, '    with ProcessPoolExecutor(max_workers=max_workers) as executor:\n');
fprintf(fid, '        futures = {executor.submit(submit_job, job, i+1, total_jobs): job\n');
fprintf(fid, '                   for i, job in enumerate(jobs)}\n');
fprintf(fid, '        \n');
fprintf(fid, '        for future in as_completed(futures):\n');
fprintf(fid, '            job_name, status, elapsed = future.result()\n');
fprintf(fid, '            results[job_name] = (status, elapsed)\n\n');

% 统计
fprintf(fid, '    total_time = time.time() - start_time\n');
fprintf(fid, '    success_count = sum(1 for s, _ in results.values() if "成功" in s)\n');
fprintf(fid, '    total_compute_time = sum(t for _, t in results.values())\n');
fprintf(fid, '    \n');
fprintf(fid, '    print()\n');
fprintf(fid, '    print("="*70)\n');
fprintf(fid, '    print("              ✅ 计算完成")\n');
fprintf(fid, '    print("="*70)\n');
fprintf(fid, '    print(f"成功/总数: {success_count}/{total_jobs}")\n');
fprintf(fid, '    print(f"总耗时: {total_time/3600:.2f} 小时")\n');
fprintf(fid, '    print(f"实际计算: {total_compute_time/3600:.2f} CPU小时")\n');
fprintf(fid, '    print(f"平均时间: {total_time/total_jobs/60:.1f} 分钟/任务")\n');
fprintf(fid, '    \n');
fprintf(fid, '    # 保存日志\n');
fprintf(fid, '    with open("submit_log.txt", "w", encoding="utf-8") as f:\n');
fprintf(fid, '        for job, (status, elapsed) in results.items():\n');
fprintf(fid, '            f.write(f"{job}: {status} ({elapsed:.1f}s)\\n")\n');
fprintf(fid, '    \n');
fprintf(fid, '    print("\\n日志已保存: submit_log.txt")\n');

fclose(fid);

fprintf('✅ 提交脚本已生成: %s\n', script_file);

% Linux权限
if isunix
    system(sprintf('chmod +x %s', script_file));
end

end
