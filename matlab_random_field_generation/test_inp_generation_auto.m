clear all
clc

fprintf('========================================\n');
fprintf('自动检测并选择inp生成策略\n');
fprintf('========================================\n\n');

%% 1. 读取模板
template_file = 'Job-0.inp';

if ~exist(template_file, 'file')
    error('未找到模板文件: %s', template_file);
end

fprintf('[1] 分析模板结构...\n');

fid = fopen(template_file, 'r');
has_part = false;
has_assembly = false;
line_count = 0;

while ~feof(fid)
    line = fgetl(fid);
    line_count = line_count + 1;
    
    if ~ischar(line)
        continue;
    end
    
    line_upper = upper(strtrim(line));
    
    if startsWith(line_upper, '*PART')
        has_part = true;
    end
    
    if startsWith(line_upper, '*ASSEMBLY')
        has_assembly = true;
    end
end
fclose(fid);

fprintf('    总行数: %d\n', line_count);
fprintf('    包含*Part: %s\n', mat2str(has_part));
fprintf('    包含*Assembly: %s\n', mat2str(has_assembly));

%% 2. 选择策略
if has_part && has_assembly
    fprintf('\n[2] 使用完整结构策略\n');
    strategy = 'full';
else
    fprintf('\n[2] 使用简化结构策略\n');
    strategy = 'simple';
end

%% 3. 生成测试数据
fprintf('\n[3] 生成测试数据...\n');

[node, elelist, element, ~] = read_inp_mesh_fast(template_file);
fprintf('    单元数: %d\n', length(elelist));

% 生成测试K场
K_field = logspace(-8, -6, length(elelist))';
E_values = [3e7, 3e7, 3e7];
nu_values = [0.3, 0.3, 0.3];

%% 4. 生成inp
fprintf('\n[4] 生成inp文件...\n');

output_file = 'test_output.inp';

tic;
if strcmp(strategy, 'full')
    generate_inp_with_permeability_optimized(template_file, output_file, ...
                                             elelist, K_field, E_values, nu_values);
else
    generate_inp_simple_structure(template_file, output_file, ...
                                   elelist, K_field, E_values, nu_values);
end
t = toc;

fprintf('\n========================================\n');
fprintf('✅ 测试完成\n');
fprintf('    耗时: %.2f 秒\n', t);
fprintf('    输出: %s\n', output_file);
fprintf('    大小: %.2f MB\n', dir(output_file).bytes / 1024^2);
fprintf('========================================\n\n');

fprintf('下一步：ABAQUS验证\n');
fprintf('  abaqus datacheck job=test_output interactive\n\n');
