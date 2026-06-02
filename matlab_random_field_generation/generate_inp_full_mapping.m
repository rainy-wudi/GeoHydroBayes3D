function generate_inp_full_mapping(template_file, output_folder, job_name, ...
                                   elelist, K_values, E_values, nu_values, config)
% 生成完整单元映射的inp文件
%
% 方法：
%   1. 每个单元独立材料
%   2. 使用INCLUDE文件分块（避免单文件过大）
%   3. 优化写入格式

n_elements = length(elelist);

%% ----------------------------------------
%% 路径设置
%% ----------------------------------------
inp_folder = fullfile(output_folder, 'inp_files');
include_folder = fullfile(output_folder, 'include_files');

main_inp_file = fullfile(inp_folder, [job_name, '.inp']);

%% ----------------------------------------
%% Step 1: 读取模板
%% ----------------------------------------
template_lines = read_template_lines(template_file);

%% ----------------------------------------
%% Step 2: 写入主inp文件
%% ----------------------------------------
fid_main = fopen(main_inp_file, 'w');

% 写入文件头
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');
fprintf(fid_main, '** 随机场inp文件：%s\n', job_name);
fprintf(fid_main, '** 生成时间: %s\n', datestr(now));
fprintf(fid_main, '** 单元数: %d\n', n_elements);
fprintf(fid_main, '** 映射: 每个单元独立K值\n');
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');

% 复制节点和单元定义
write_template_section(fid_main, template_lines, 'nodes_and_elements');

%% ----------------------------------------
%% Step 3: 材料定义（使用INCLUDE分块）
%% ----------------------------------------
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');
fprintf(fid_main, '** 材料定义（INCLUDE文件）\n');
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');

if config.use_include_files
    % 分块写入INCLUDE文件
    chunk_size = config.chunk_size;  % 每个文件包含的材料数
    n_chunks = ceil(n_elements / chunk_size);
    
    for i_chunk = 1:n_chunks
        include_filename = sprintf('%s_materials_%03d.inc', job_name, i_chunk);
        fprintf(fid_main, '*INCLUDE, INPUT=%s\n', ...
                fullfile('..', 'include_files', include_filename));
    end
    
    % 实际写入INCLUDE文件
    for i_chunk = 1:n_chunks
        idx_start = (i_chunk-1)*chunk_size + 1;
        idx_end = min(i_chunk*chunk_size, n_elements);
        
        include_filepath = fullfile(include_folder, ...
                                    sprintf('%s_materials_%03d.inc', job_name, i_chunk));
        
        write_materials_chunk(include_filepath, elelist(idx_start:idx_end), ...
                             K_values(idx_start:idx_end), E_values, nu_values);
    end
    
else
    % 直接写入主文件（不推荐，文件会很大）
    for i = 1:n_elements
        elem_id = elelist(i);
        K_val = K_values(i);
        
        fprintf(fid_main, '*Material, name=Mat_Elem%d\n', elem_id);
        fprintf(fid_main, '*Density\n 2000.,\n');
        fprintf(fid_main, '*Elastic\n %.6e, %.4f\n', E_values(1), nu_values(1));
        fprintf(fid_main, '*Permeability, specific=%.6e\n', K_val);
        fprintf(fid_main, ' 1., 1., 1.\n');
    end
end

%% ----------------------------------------
%% Step 4: 截面定义
%% ----------------------------------------
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');
fprintf(fid_main, '** 截面定义\n');
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');

for i = 1:n_elements
    elem_id = elelist(i);
    
    % 单元集合
    fprintf(fid_main, '*Elset, elset=Elset_Elem%d\n', elem_id);
    fprintf(fid_main, ' %d\n', elem_id);
    
    % 截面
    fprintf(fid_main, '*Solid Section, elset=Elset_Elem%d, material=Mat_Elem%d\n', ...
            elem_id, elem_id);
    fprintf(fid_main, ',\n');
end

%% ----------------------------------------
%% Step 5: 复制边界条件和分析步
%% ----------------------------------------
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');
fprintf(fid_main, '** 边界条件和分析步（来自模板）\n');
fprintf(fid_main, '** ════════════════════════════════════════════════════\n');

write_template_section(fid_main, template_lines, 'boundary_and_steps');

fclose(fid_main);

end

%% ----------------------------------------
%% 辅助函数
%% ----------------------------------------
function lines = read_template_lines(filename)
% 读取模板文件所有行

fid = fopen(filename, 'r');
lines = {};
while ~feof(fid)
    lines{end+1} = fgetl(fid);
end
fclose(fid);

end

function write_template_section(fid, template_lines, section_name)
% 写入模板的特定部分

switch section_name
    case 'nodes_and_elements'
        % 复制到材料定义之前
        for i = 1:length(template_lines)
            line = template_lines{i};
            if contains(line, '*Material') || contains(line, '*Solid Section')
                break;
            end
            fprintf(fid, '%s\n', line);
        end
        
    case 'boundary_and_steps'
        % 复制边界条件和分析步
        start_copy = false;
        for i = 1:length(template_lines)
            line = template_lines{i};
            
            if contains(line, '*Boundary') || contains(line, '*Initial Conditions') || ...
               contains(line, '*Step')
                start_copy = true;
            end
            
            if start_copy
                fprintf(fid, '%s\n', line);
            end
        end
end

end

function write_materials_chunk(filename, elem_chunk, K_chunk, E_values, nu_values)
% 写入一个材料块文件

fid = fopen(filename, 'w');

fprintf(fid, '** 材料块文件\n');
fprintf(fid, '** 包含 %d 个材料定义\n', length(elem_chunk));
fprintf(fid, '** 生成时间: %s\n\n', datestr(now));

for i = 1:length(elem_chunk)
    elem_id = elem_chunk(i);
    K_val = K_chunk(i);
    
    fprintf(fid, '*Material, name=Mat_Elem%d\n', elem_id);
    fprintf(fid, '*Density\n 2000.,\n');
    fprintf(fid, '*Elastic\n %.6e, %.4f\n', E_values(1), nu_values(1));
    fprintf(fid, '*Permeability, specific=%.6e\n', K_val);
    fprintf(fid, ' 1., 1., 1.\n');
end

fclose(fid);

end
