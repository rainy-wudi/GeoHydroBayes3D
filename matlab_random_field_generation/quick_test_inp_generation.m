function quick_test_inp_generation()
% 一键测试inp生成

fprintf('========================================\n');
fprintf('快速测试inp生成\n');
fprintf('========================================\n\n');

%% 1. 检查模板
fprintf('[1] 检查模板文件...\n');
if ~exist('Job-0.inp', 'file')
    error('模板文件 Job-0.inp 不存在');
end
fprintf('    ✅ 模板存在\n\n');

%% 2. 重新生成
fprintf('[2] 重新生成随机场...\n');
if exist('RandomField_SchemeC', 'dir')
    rmdir('RandomField_SchemeC', 's');
    fprintf('    已清理旧文件\n');
end

try
    batch_random_field_generator;
    fprintf('    ✅ 生成完成\n\n');
catch ME
    fprintf('    ❌ 生成失败: %s\n', ME.message);
    return;
end

%% 3. 验证完整性
fprintf('[3] 验证第一个生成文件...\n');
gen_files = dir('RandomField_SchemeC/*.inp');

if isempty(gen_files)
    fprintf('    ❌ 未找到生成的文件\n');
    return;
end

generated_file = fullfile(gen_files(1).folder, gen_files(1).name);
fprintf('    文件: %s\n\n', gen_files(1).name);

verify_inp_integrity('Job-0.inp', generated_file);

%% 4. ABAQUS datacheck
fprintf('\n[4] ABAQUS Datacheck...\n');
job_name = strrep(gen_files(1).name, '.inp', '');
cmd = sprintf('abaqus datacheck job=%s interactive', ...
              fullfile('RandomField_SchemeC', job_name));

fprintf('    执行: %s\n', cmd);
system(cmd);

% 检查结果
dat_file = fullfile('RandomField_SchemeC', [job_name, '.dat']);
if exist(dat_file, 'file')
    fprintf('    ✅ Datacheck执行完成\n');
    
    fid = fopen(dat_file, 'r');
    content = fread(fid, '*char')';
    fclose(fid);
    
    if contains(content, '***ERROR')
        fprintf('    ❌ 发现错误，查看.dat文件\n');
    else
        fprintf('    ✅ 无错误\n');
    end
else
    fprintf('    ⚠️  未生成.dat文件\n');
end

fprintf('\n========================================\n');
fprintf('测试完成\n');
fprintf('========================================\n');

end
