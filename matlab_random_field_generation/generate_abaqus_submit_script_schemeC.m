function generate_abaqus_submit_script_schemeC(output_folder, all_jobs_info)
% 生成ABAQUS提交脚本（修复版）

script_file = fullfile(output_folder, 'submit_all_jobs.py');
fid = fopen(script_file, 'w');

if fid == -1
    error('无法创建脚本文件: %s', script_file);
end

fprintf(fid, '#!/usr/bin/env python\n');
fprintf(fid, '# -*- coding: utf-8 -*-\n');
fprintf(fid, '"""\n');
fprintf(fid, '批量提交ABAQUS渗流计算任务 - 方案C\n');
fprintf(fid, '生成时间: %s\n', datestr(now));
fprintf(fid, '总任务数: %d\n', length(all_jobs_info));
fprintf(fid, '"""\n\n');

fprintf(fid, 'import os\n');
fprintf(fid, 'import subprocess\n');
fprintf(fid, 'import time\n');
fprintf(fid, 'from datetime import datetime\n\n');

fprintf(fid, 'def submit_job(job_name, job_id, total_jobs):\n');
fprintf(fid, '    """提交单个ABAQUS作业"""\n');
fprintf(fid, '    start_time = time.time()\n');
fprintf(fid, '    \n');
fprintf(fid, '    print(f"[{job_id}/{total_jobs}] 开始: {job_name} - {datetime.now().strftime(''%%H:%%M:%%S'')}")\n');
fprintf(fid, '    \n');
fprintf(fid, '    cmd = f"abaqus job={job_name} cpus=4 interactive"\n');
fprintf(fid, '    \n');
fprintf(fid, '    try:\n');
fprintf(fid, '        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=600)\n');
fprintf(fid, '        \n');
fprintf(fid, '        if result.returncode == 0:\n');
fprintf(fid, '            elapsed = time.time() - start_time\n');
fprintf(fid, '            status = f"成功 ({elapsed:.1f}秒)"\n');
fprintf(fid, '        else:\n');
fprintf(fid, '            status = f"失败 (返回码: {result.returncode})"\n');
fprintf(fid, '    \n');
fprintf(fid, '    except subprocess.TimeoutExpired:\n');
fprintf(fid, '        status = "超时 (>10分钟)"\n');
fprintf(fid, '    except Exception as e:\n');
fprintf(fid, '        status = f"异常: {str(e)}"\n');
fprintf(fid, '    \n');
fprintf(fid, '    print(f"[{job_id}/{total_jobs}] 完成: {job_name} - {status}")\n');
fprintf(fid, '    \n');
fprintf(fid, '    return job_name, status\n\n');

fprintf(fid, 'if __name__ == "__main__":\n');
fprintf(fid, '    print("="*60)\n');
fprintf(fid, '    print("批量ABAQUS计算任务")\n');
fprintf(fid, '    print("="*60)\n');
fprintf(fid, '    \n');
fprintf(fid, '    # 作业列表\n');
fprintf(fid, '    jobs = [\n');

% ✅ 修复：正确访问cell数组
for i = 1:length(all_jobs_info)
    job = all_jobs_info{i};  % 使用 {}
    
    if ~isempty(job) && isstruct(job) && isfield(job, 'job_name')
        fprintf(fid, '        "%s",\n', job.job_name);
    else
        warning('作业 #%d 无效，跳过', i);
    end
end

fprintf(fid, '    ]\n\n');
fprintf(fid, '    total_jobs = len(jobs)\n');
fprintf(fid, '    print(f"总任务数: {total_jobs}")\n');
fprintf(fid, '    print(f"开始时间: {datetime.now().strftime(''%%Y-%%m-%%d %%H:%%M:%%S'')}")\n');
fprintf(fid, '    print()\n\n');

fprintf(fid, '    results = {}\n');
fprintf(fid, '    start_time = time.time()\n\n');

fprintf(fid, '    # 串行执行（如需并行，使用ProcessPoolExecutor）\n');
fprintf(fid, '    for i, job in enumerate(jobs, 1):\n');
fprintf(fid, '        job_name, status = submit_job(job, i, total_jobs)\n');
fprintf(fid, '        results[job_name] = status\n');
fprintf(fid, '        time.sleep(1)  # 间隔1秒\n\n');

fprintf(fid, '    # 统计结果\n');
fprintf(fid, '    total_time = time.time() - start_time\n');
fprintf(fid, '    success_count = sum(1 for s in results.values() if "成功" in s)\n');
fprintf(fid, '    \n');
fprintf(fid, '    print()\n');
fprintf(fid, '    print("="*60)\n');
fprintf(fid, '    print("计算完成")\n');
fprintf(fid, '    print("="*60)\n');
fprintf(fid, '    print(f"成功: {success_count}/{total_jobs}")\n');
fprintf(fid, '    print(f"总耗时: {total_time/3600:.2f} 小时")\n');
fprintf(fid, '    print(f"平均: {total_time/total_jobs:.1f} 秒/任务")\n');
fprintf(fid, '    print(f"结束时间: {datetime.now().strftime(''%%Y-%%m-%%d %%H:%%M:%%S'')}")\n');
fprintf(fid, '    \n');
fprintf(fid, '    # 保存日志\n');
fprintf(fid, '    with open("submit_log.txt", "w", encoding="utf-8") as f:\n');
fprintf(fid, '        for job, status in results.items():\n');
fprintf(fid, '            f.write(f"{job}: {status}\\n")\n');
fprintf(fid, '    \n');
fprintf(fid, '    print("\\n日志已保存: submit_log.txt")\n');

fclose(fid);

fprintf('✅ 提交脚本已生成: %s\n', script_file);

% 添加执行权限（Linux/Mac）
if isunix
    system(sprintf('chmod +x "%s"', script_file));
end

end
