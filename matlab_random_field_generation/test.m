%% 测试脚本：验证生成的inp文件

% 加载元数据
load('RandomField_Full/metadata/master_metadata.mat');

% 选择第一个作业
test_job = metadata.all_jobs_info{1};
test_inp = fullfile(metadata.config.output_folder, 'inp_files', ...
                    [test_job.job_name, '.inp']);

fprintf('测试文件: %s\n', test_inp);

% 检查文件大小
file_info = dir(test_inp);
fprintf('文件大小: %.2f MB\n', file_info.bytes / 1024^2);

% 检查材料定义数量
fid = fopen(test_inp, 'r');
n_materials = 0;
while ~feof(fid)
    line = fgetl(fid);
    if contains(line, '*Material')
        n_materials = n_materials + 1;
    end
end
fclose(fid);

fprintf('材料数量: %d\n', n_materials);
fprintf('预期数量: %d\n', metadata.n_elements);

if n_materials == metadata.n_elements
    fprintf('✅ 验证通过！每个单元都有独立材料\n');
else
    fprintf('❌ 验证失败！材料数不匹配\n');
end
