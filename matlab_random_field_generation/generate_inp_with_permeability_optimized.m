function generate_inp_with_permeability_optimized(template_file, output_file, ...
                                                  elelist, K_values, E_values, nu_values)
% 正确版本：截面在Part内，材料在Assembly后

%% 预处理
[elelist, ia] = unique(elelist, 'stable');
K_values = K_values(ia);

n_bins = 50;
fluid_sw = 9810.0;

%% 读取模板
fid = fopen(template_file, 'r');
template_lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line), template_lines{end+1} = line; end
end
fclose(fid);

fprintf('        模板行数: %d\n', length(template_lines));

%% K值分档
log_edges = linspace(log10(min(K_values)*0.9), log10(max(K_values)*1.1), n_bins+1);
bin_centers = 10.^(0.5*(log_edges(1:end-1) + log_edges(2:end)));
bin_indices = discretize(K_values, 10.^log_edges);
bin_indices(isnan(bin_indices) | bin_indices < 1) = 1;
bin_indices(bin_indices > n_bins) = n_bins;
unique_bins = unique(bin_indices);

fprintf('        K值档位: %d\n', length(unique_bins));

%% 生成材料定义（放在Assembly后）
material_lines = {};
material_lines{end+1} = '**';
material_lines{end+1} = '** ================================================';
material_lines{end+1} = '** RANDOM FIELD MATERIALS';
material_lines{end+1} = '** ================================================';

for i = 1:length(unique_bins)
    bin_id = unique_bins(i);
    mat_name = sprintf('RF_MAT_%03d', bin_id);
    
    material_lines{end+1} = '**';
    material_lines{end+1} = sprintf('*Material, name=%s', mat_name);
    material_lines{end+1} = '*Density';
    material_lines{end+1} = ' 2000.,';
    material_lines{end+1} = '*Elastic';
    material_lines{end+1} = sprintf(' %.6e, %.4f', E_values(1), nu_values(1));
    material_lines{end+1} = sprintf('*Permeability, specific=%.1f', fluid_sw);
    material_lines{end+1} = sprintf(' %.6e,', bin_centers(bin_id));
end

%% 生成截面定义（放在Part内）
section_lines = {};
section_lines{end+1} = '**';
section_lines{end+1} = '** ================================================';
section_lines{end+1} = '** RANDOM FIELD SECTIONS';
section_lines{end+1} = '** ================================================';

for i = 1:length(unique_bins)
    bin_id = unique_bins(i);
    elem_ids = elelist(bin_indices == bin_id);
    
    elset_name = sprintf('RF_ELSET_%03d', bin_id);
    mat_name = sprintf('RF_MAT_%03d', bin_id);
    
    section_lines{end+1} = '**';
    section_lines{end+1} = sprintf('*Elset, elset=%s', elset_name);
    
    for j = 1:16:length(elem_ids)
        ids = elem_ids(j:min(j+15, end));
        section_lines{end+1} = [' ', strjoin(arrayfun(@num2str, ids, 'Un', 0), ', ')];
    end
    
    section_lines{end+1} = sprintf('*Solid Section, elset=%s, material=%s', elset_name, mat_name);
    section_lines{end+1} = ' 1.,';
end

section_lines{end+1} = '**';

%% ✅ 找到两个插入位置
% 位置1：第一个*End Part之前（插入截面）
part_insert_pos = [];

% 位置2：*End Assembly之后（插入材料）
assembly_insert_pos = [];

for i = 1:length(template_lines)
    line_upper = upper(strtrim(template_lines{i}));
    
    % 找第一个*End Part
    if isempty(part_insert_pos) && startsWith(line_upper, '*END PART')
        part_insert_pos = i - 1;
        fprintf('        截面插入位置: 第%d行之后（*End Part之前）\n', part_insert_pos);
    end
    
    % 找*End Assembly
    if startsWith(line_upper, '*END ASSEMBLY')
        assembly_insert_pos = i;
        fprintf('        材料插入位置: 第%d行之后（*End Assembly之后）\n', assembly_insert_pos);
    end
    
    if ~isempty(part_insert_pos) && ~isempty(assembly_insert_pos)
        break;
    end
end

if isempty(part_insert_pos)
    error('未找到*End Part');
end

if isempty(assembly_insert_pos)
    error('未找到*End Assembly');
end

%% ✅ 组装输出
output_lines = {};

% Part 1（到截面插入点）
output_lines = [output_lines, template_lines(1:part_insert_pos)];

% 插入截面定义（在Part内）
output_lines = [output_lines, section_lines];

% Part 1结束 到 Assembly结束
output_lines = [output_lines, template_lines(part_insert_pos+1:assembly_insert_pos)];

% 插入材料定义（在Assembly后）
output_lines = [output_lines, material_lines];

% 剩余所有内容（原始材料、Step等）
output_lines = [output_lines, template_lines(assembly_insert_pos+1:end)];

fprintf('        输出行数: %d (原始:%d, 新增:%d)\n', ...
        length(output_lines), length(template_lines), ...
        length(material_lines) + length(section_lines));

%% 写入文件
fid = fopen(output_file, 'w');
if fid == -1
    error('无法创建: %s', output_file);
end

for i = 1:length(output_lines)
    fprintf(fid, '%s\n', output_lines{i});
end

fclose(fid);

fprintf('        ✅ 生成完成\n\n');

end
