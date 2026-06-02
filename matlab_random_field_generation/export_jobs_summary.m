function export_jobs_summary(all_jobs_info, csv_file)
% 导出作业摘要CSV（修复版）

fprintf('导出作业摘要: %s\n', csv_file);

fid = fopen(csv_file, 'w');

if fid == -1
    error('无法创建CSV文件: %s', csv_file);
end

% 表头
fprintf(fid, 'JobID,JobName,ParamGroup,Realization,K_min,K_max,mu_clay,mu_silt,mu_sand,COV,dh,dv\n');

% 数据
for i = 1:length(all_jobs_info)
    
    % ✅ 修复：从cell数组中提取结构体
    job = all_jobs_info{i};  % 使用 {} 而不是 ()
    
    % 检查是否为空
    if isempty(job)
        warning('作业 #%d 为空，跳过', i);
        continue;
    end
    
    % 检查字段是否存在
    if ~isstruct(job)
        warning('作业 #%d 不是结构体，跳过', i);
        continue;
    end
    
    % 写入CSV行
    fprintf(fid, '%d,%s,%d,%d,%.6e,%.6e', ...
            job.job_id, ...
            job.job_name, ...
            job.param_group, ...
            job.realization, ...
            job.K_range(1), ...
            job.K_range(2));
    
    % 添加参数值
    if isfield(job, 'params') && ~isempty(job.params)
        for j = 1:length(job.params)
            fprintf(fid, ',%.6e', job.params(j));
        end
    end
    
    fprintf(fid, '\n');
end

fclose(fid);

fprintf('  ✅ 导出完成，共%d条记录\n', length(all_jobs_info));

end
