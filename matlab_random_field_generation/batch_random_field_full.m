%% ============================================
%% 方案C-Full：58573个单元完整映射版本
%% ============================================
% 特点：每个单元独立K值，无精度损失
% 警告：生成文件很大，需要16GB+内存运行ABAQUS
%% ============================================

clc; clear; close all;

fprintf('\n');
fprintf('████████████████████████████████████████████████████████\n');
fprintf('██                                                    ██\n');
fprintf('██      方案C-Full：完整单元映射版                    ██\n');
fprintf('██      58573个单元 → 58573个独立K值                 ██\n');
fprintf('██                                                    ██\n');
fprintf('████████████████████████████████████████████████████████\n');
fprintf('\n');

%% ============================================
%% Step 1: 配置参数
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 1: 配置参数\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

config = struct();

% 采样配置
config.n_param_samples = 1;            % 参数组数
config.n_realizations_per_param = 1;   % 每组实现数
config.total_jobs = config.n_param_samples * config.n_realizations_per_param;

% 输出设置
config.output_folder = 'RandomField_Full';
config.use_include_files = true;  % 使用INCLUDE分块（强烈推荐）
config.use_parallel = true;       % 并行写入（需要Parallel Toolbox）
config.chunk_size = 1000;         % 每块材料数（用于分割INCLUDE文件）

fprintf('配置信息:\n');
fprintf('  参数组数: %d\n', config.n_param_samples);
fprintf('  每组实现: %d\n', config.n_realizations_per_param);
fprintf('  总任务数: %d\n', config.total_jobs);
fprintf('  使用INCLUDE分块: %s\n', mat2str(config.use_include_files));
fprintf('  并行写入: %s\n', mat2str(config.use_parallel));
fprintf('\n');

% 警告提示
fprintf('⚠️  注意事项:\n');
fprintf('   • 每个inp文件约 200-500 MB\n');
fprintf('   • 总空间需求: ~%.1f GB\n', config.total_jobs * 0.35);
fprintf('   • ABAQUS需要 16GB+ 内存\n');
fprintf('   • 单个作业读取时间: 5-15分钟\n\n');

prompt = '是否继续? (y/n): ';
user_input = input(prompt, 's');
if ~strcmpi(user_input, 'y')
    fprintf('已取消。\n');
    return;
end

%% ============================================
%% Step 2: 参数空间采样
%% ============================================
fprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 2: 参数空间采样\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% 参数边界
param_bounds = [
    1e-9,  1e-7;    % μ_粘土
    1e-8,  1e-6;    % μ_粉土
    1e-7,  1e-5;    % μ_砂土
    0.5,   2.0;     % COV
    2.0,   10.0;    % dh
    0.5,   3.0;     % dv
];

param_names = {'μ_粘土', 'μ_粉土', 'μ_砂土', 'COV', 'dh', 'dv'};

fprintf('生成拉丁超立方采样...\n');
param_samples = lhsdesign_with_bounds(config.n_param_samples, param_bounds);

fprintf('✅ 采样完成！\n');
fprintf('   采样点数: %d\n', size(param_samples, 1));
fprintf('   采样维度: %d\n\n', size(param_samples, 2));

%% ============================================
%% Step 3: 加载网格数据
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 3: 加载网格数据\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% 模板文件
inp_template = 'Job-0.inp';  % [修改为你的模板]

if ~exist(inp_template, 'file')
    error('❌ 未找到模板文件: %s', inp_template);
end

fprintf('读取网格文件: %s\n', inp_template);
[node, elelist, element, etype] = read_inp_mesh(inp_template);

n_elements = length(elelist);

fprintf('网格信息:\n');
fprintf('  节点数: %d\n', size(node, 1));
fprintf('  单元数: %d\n', n_elements);
fprintf('  单元类型: %s\n\n', etype);

% 验证单元数
if n_elements ~= 58573
    warning('⚠️  单元数(%d)与预期(58573)不符，请确认', n_elements);
end

% 计算单元中心
fprintf('计算单元中心坐标...\n');
tic;
element_centers = compute_element_centers(node, element);
fprintf('✅ 完成！耗时: %.2f 秒\n\n', toc);

% 确定性参数
E_deterministic = [21000000, 21000000, 21000000];
nu_deterministic = [0.25, 0.25, 0.25];

% 分层
stra = [0, 50, 150, 200];  % [修改为实际分层]

%% ============================================
%% Step 4: 创建输出目录结构
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 4: 创建目录结构\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

if ~exist(config.output_folder, 'dir')
    mkdir(config.output_folder);
end

% 创建子目录
subdirs = {'inp_files', 'include_files', 'metadata', 'logs'};
for i = 1:length(subdirs)
    subdir_path = fullfile(config.output_folder, subdirs{i});
    if ~exist(subdir_path, 'dir')
        mkdir(subdir_path);
    end
end

fprintf('✅ 目录结构创建完成\n\n');

%% ============================================
%% Step 5: 批量生成随机场和inp文件
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 5: 批量生成随机场\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

fprintf('总任务数: %d\n', config.total_jobs);
fprintf('预计时间: %.1f 分钟\n\n', config.total_jobs * 0.5);

% 创建日志
log_file = fullfile(config.output_folder, 'logs', 'generation_log.txt');
fid_log = fopen(log_file, 'w');
fprintf(fid_log, '随机场生成日志\n');
fprintf(fid_log, '开始时间: %s\n\n', datestr(now));
fclose(fid_log);

% 存储所有作业信息
all_jobs_info = cell(config.total_jobs, 1);
job_counter = 0;

% 开始计时
total_tic = tic;

%% 循环参数组
for i_param = 1:config.n_param_samples
    
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    fprintf('[%d/%d] 参数组 #%d\n', i_param, config.n_param_samples, i_param);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    % 提取参数
    mu_clay = param_samples(i_param, 1);
    mu_silt = param_samples(i_param, 2);
    mu_sand = param_samples(i_param, 3);
    cov_val = param_samples(i_param, 4);
    dh = param_samples(i_param, 5);
    dv = param_samples(i_param, 6);
    
    fprintf('参数: [%.2e, %.2e, %.2e, %.2f, %.2f, %.2f]\n', ...
            param_samples(i_param, :));
    
    % 构造分层参数
    mu = [mu_clay, mu_silt, mu_sand];
    cov = [cov_val, cov_val, cov_val]';
    dh_vec = ones(3,1) * dh;
    dv_vec = ones(3,1) * dv;
    var = [1e-9, 1e-8, 1e-7];
    
    % 生成随机场
    fprintf('  生成 %d 个随机场实现...\n', config.n_realizations_per_param);
    
    param_tic = tic;
    [K_realizations, RFgrid] = generate_stratified_random_field_full(...
        element_centers, mu, cov, dh_vec, dv_vec, var, stra, ...
        config.n_realizations_per_param);
    param_time = toc(param_tic);
    
    fprintf('  ✅ 随机场生成完成 (%.1f秒)\n', param_time);
    fprintf('  开始写入inp文件...\n');
    
    % 为每个实现生成inp
    write_tic = tic;
    
    if config.use_parallel && config.n_realizations_per_param > 4
        % 并行写入
        fprintf('  使用并行模式 (parfor)...\n');
        
        parfor i_real = 1:config.n_realizations_per_param
            job_id = (i_param-1)*config.n_realizations_per_param + i_real;
            job_name = sprintf('Job_P%03d_R%02d', i_param, i_real);
            
            K_current = K_realizations(:, i_real);
            
            % 生成inp文件
            generate_inp_full_mapping(...
                inp_template, ...
                config.output_folder, ...
                job_name, ...
                elelist, ...
                K_current, ...
                E_deterministic, ...
                nu_deterministic, ...
                config);
        end
        
    else
        % 串行写入
        for i_real = 1:config.n_realizations_per_param
            job_counter = job_counter + 1;
            job_name = sprintf('Job_P%03d_R%02d', i_param, i_real);
            
            K_current = K_realizations(:, i_real);
            
            % 生成inp文件
            generate_inp_full_mapping(...
                inp_template, ...
                config.output_folder, ...
                job_name, ...
                elelist, ...
                K_current, ...
                E_deterministic, ...
                nu_deterministic, ...
                config);
            
            % 记录信息
            job_info = struct();
            job_info.job_id = job_counter;
            job_info.job_name = job_name;
            job_info.param_group = i_param;
            job_info.realization = i_real;
            job_info.params = param_samples(i_param, :);
            
            all_jobs_info{job_counter} = job_info;
            
            % 进度
            if mod(job_counter, 10) == 0
                fprintf('    [%d/%d] 已生成 %.1f%%\n', ...
                        job_counter, config.total_jobs, ...
                        job_counter/config.total_jobs*100);
            end
        end
    end
    
    write_time = toc(write_tic);
    fprintf('  ✅ inp文件写入完成 (%.1f秒)\n', write_time);
    fprintf('  平均速度: %.2f秒/文件\n\n', write_time/config.n_realizations_per_param);
    
    % 保存当前参数组的K场数据
    K_data_file = fullfile(config.output_folder, 'metadata', ...
                           sprintf('K_fields_P%03d.mat', i_param));
    save(K_data_file, 'K_realizations', 'RFgrid', '-v7.3');
end

total_time = toc(total_tic);

fprintf('\n');
fprintf('████████████████████████████████████████████████████████\n');
fprintf('██                                                    ██\n');
fprintf('██      ✅ 所有随机场生成完成！                       ██\n');
fprintf('██                                                    ██\n');
fprintf('████████████████████████████████████████████████████████\n');
fprintf('\n');
fprintf('统计信息:\n');
fprintf('  总耗时: %.1f 分钟\n', total_time/60);
fprintf('  平均速度: %.2f 秒/作业\n', total_time/config.total_jobs);
fprintf('  输出位置: %s\n', config.output_folder);
fprintf('  总文件数: %d\n', config.total_jobs);
fprintf('\n');

%% ============================================
%% Step 6: 保存元数据
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 6: 保存元数据\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

metadata = struct();
metadata.config = config;
metadata.param_samples = param_samples;
metadata.param_names = param_names;
metadata.param_bounds = param_bounds;
metadata.all_jobs_info = all_jobs_info;
metadata.element_list = elelist;
metadata.element_centers = element_centers;
metadata.n_elements = n_elements;
metadata.stra = stra;
metadata.generation_time = datetime('now');
metadata.total_time = total_time;

metadata_file = fullfile(config.output_folder, 'metadata', 'master_metadata.mat');
save(metadata_file, 'metadata', '-v7.3');

fprintf('✅ 元数据已保存: %s\n\n', metadata_file);

%% ============================================
%% Step 7: 生成提交脚本
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 7: 生成ABAQUS提交脚本\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

generate_submit_script_full(config, all_jobs_info);

%% ============================================
%% Step 8: 生成使用说明
%% ============================================
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('  Step 8: 生成使用说明\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

readme_file = fullfile(config.output_folder, 'README.txt');
fid = fopen(readme_file, 'w');

fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '        方案C-Full：完整单元映射随机场\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n\n');

fprintf(fid, '生成时间: %s\n', datestr(now));
fprintf(fid, '单元总数: %d\n', n_elements);
fprintf(fid, '作业总数: %d\n', config.total_jobs);
fprintf(fid, '参数组数: %d\n', config.n_param_samples);
fprintf(fid, '每组实现: %d\n\n', config.n_realizations_per_param);

fprintf(fid, '【目录结构】\n');
fprintf(fid, '  inp_files/       - inp主文件（%d个）\n', config.total_jobs);
fprintf(fid, '  include_files/   - INCLUDE材料文件\n');
fprintf(fid, '  metadata/        - 元数据和K场数据\n');
fprintf(fid, '  logs/            - 生成日志\n\n');

fprintf(fid, '【文件大小】\n');
fprintf(fid, '  单个inp文件: ~%.0f MB\n', 0.35*1024);
fprintf(fid, '  总空间占用: ~%.1f GB\n\n', config.total_jobs*0.35);

fprintf(fid, '【运行步骤】\n');
fprintf(fid, '1. 检查磁盘空间（需要%.1f GB）\n', config.total_jobs*0.35*1.2);
fprintf(fid, '2. 确保ABAQUS可用（需要16GB+内存）\n');
fprintf(fid, '3. 运行提交脚本:\n');
fprintf(fid, '   cd %s\n', config.output_folder);
fprintf(fid, '   python submit_all_jobs.py\n\n');

fprintf(fid, '4. 监控进度:\n');
fprintf(fid, '   tail -f submit_log.txt\n\n');

fprintf(fid, '【重要提示】\n');
fprintf(fid, '⚠ 每个作业读取inp文件需要5-15分钟\n');
fprintf(fid, '⚠ 单个作业完整运行时间: ~20-30分钟\n');
fprintf(fid, '⚠ 建议并行数: 2-4（取决于内存）\n');
fprintf(fid, '⚠ 预计总时间: %.0f-%.0f 小时\n\n', ...
        config.total_jobs*0.4, config.total_jobs*0.5);

fprintf(fid, '═══════════════════════════════════════════════════════════\n');

fclose(fid);

fprintf('✅ 使用说明已生成: %s\n\n', readme_file);

%% 最终提示
fprintf('════════════════════════════════════════════════════════\n');
fprintf('🎉 全部完成！\n');
fprintf('════════════════════════════════════════════════════════\n');
fprintf('\n');
fprintf('下一步:\n');
fprintf('  1. 查看README: %s\n', readme_file);
fprintf('  2. 检查样例inp: %s\n', fullfile(config.output_folder, 'inp_files', 'Job_P001_R01.inp'));
fprintf('  3. 提交计算: cd %s && python submit_all_jobs.py\n', config.output_folder);
fprintf('\n');
