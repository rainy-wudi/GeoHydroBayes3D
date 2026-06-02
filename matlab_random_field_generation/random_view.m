%% 简化版：读取INP中的渗透系数并可视化
clc; clear; close all;

%% 设置
inp_file = 'Job_P001_R01.inp';
part = 'diceng';

%% 1. 读取网格
fprintf('读取网格...\n');
[nodes, elements] = read_inp_simple(inp_file, part);
centers = calc_centers(nodes, elements);
fprintf('单元数: %d\n', size(elements, 1));

%% 2. 读取真实的渗透系数（从INP文件）
fprintf('读取渗透系数...\n');
field = read_permeability_from_inp(inp_file, size(elements, 1));

fprintf('渗透系数统计:\n');
fprintf('  最小值: %.3e m/s\n', min(field));
fprintf('  最大值: %.3e m/s\n', max(field));
fprintf('  平均值: %.3e m/s\n', mean(field));
fprintf('  标准差: %.3e m/s\n', std(field));

%% 3. 绘图
figure('Position', [100, 100, 1200, 800]);
plot_field_simple(nodes, elements, field);
title(sprintf('渗透系数随机场 (均值=%.2e m/s)', mean(field)), 'FontSize', 14);
cb = colorbar;
cb.Label.String = '渗透系数 (m/s)';
cb.Label.FontSize = 12;

% 如果跨度大，用对数刻度
if max(field)/min(field) > 100
    set(gca, 'ColorScale', 'log');
end

saveas(gcf, '渗透系数场.png');
fprintf('\n完成！已保存: 渗透系数场.png\n');

%% ========== 新增函数：读取INP中的渗透系数 ==========
function k_field = read_permeability_from_inp(filename, n_elem)
    % 读取INP文件中定义的渗透系数
    txt = fileread(filename);
    
    % 1. 读取所有材料的渗透系数
    fprintf('  解析材料...\n');
    mat_pattern = '\*Material,\s*name=(\S+)';
    mat_names = regexp(txt, mat_pattern, 'tokens');
    mat_names = [mat_names{:}];
    
    k_pattern = '\*Permeability[^\n]*\n\s*([\d.eE+-]+)';
    k_values = regexp(txt, k_pattern, 'tokens');
    k_values = cellfun(@str2double, [k_values{:}]);
    
    fprintf('  找到 %d 个材料\n', length(mat_names));
    
    % 2. 读取单元-材料分配
    fprintf('  解析单元材料分配...\n');
    lines = strsplit(txt, '\n');
    k_field = zeros(n_elem, 1);
    
    % 查找 *Solid Section 和对应的 *Elset
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        if startsWith(line, '*Solid Section') || startsWith(line, '*Soils')
            % 提取 elset 和 material
            elset_match = regexp(line, 'elset=([^,\s]+)', 'tokens');
            mat_match = regexp(line, 'material=([^,\s]+)', 'tokens');
            
            if ~isempty(elset_match) && ~isempty(mat_match)
                elset_name = elset_match{1}{1};
                mat_name = mat_match{1}{1};
                
                % 找到材料对应的k值
                mat_idx = find(strcmp(mat_names, mat_name));
                if ~isempty(mat_idx)
                    k_val = k_values(mat_idx);
                    
                    % 找到elset包含的单元
                    elem_list = find_elset_elements(lines, elset_name);
                    
                    % 赋值
                    if ~isempty(elem_list)
                        k_field(elem_list) = k_val;
                    end
                end
            end
        end
    end
    
    % 检查是否所有单元都有值
    if sum(k_field == 0) > 0
        fprintf('  ⚠️  警告: %d 个单元没有渗透系数\n', sum(k_field == 0));
    end
end

function elem_list = find_elset_elements(lines, elset_name)
    % 查找elset包含的单元编号
    elem_list = [];
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        if startsWith(line, '*Elset') && contains(line, ['elset=' elset_name])
            % 读取单元号
            j = i + 1;
            while j <= length(lines)
                data_line = strtrim(lines{j});
                if startsWith(data_line, '*')
                    break;
                end
                
                % 解析单元号（处理逗号分隔）
                nums = str2num(strrep(data_line, ',', ' '));
                elem_list = [elem_list, nums];
                j = j + 1;
            end
            break;
        end
    end
end

%% ========== 原有函数 ==========
function [nodes, elements] = read_inp_simple(filename, part_name)
    fid = fopen(filename, 'r');
    lines = {};
    while ~feof(fid)
        lines{end+1} = fgetl(fid);
    end
    fclose(fid);
    
    part_idx = find(contains(lines, ['*Part, name=' part_name]), 1);
    
    % 读节点
    node_idx = find(contains(lines(part_idx:end), '*Node'), 1) + part_idx;
    nodes = [];
    i = node_idx;
    while i <= length(lines) && ~startsWith(strtrim(lines{i}), '*')
        data = str2num(lines{i});
        if ~isempty(data)
            nodes = [nodes; data];
        end
        i = i + 1;
    end
    
    % 读单元
    elem_idx = find(contains(lines(part_idx:end), '*Element'), 1) + part_idx;
    elements = [];
    i = elem_idx;
    while i <= length(lines) && ~startsWith(strtrim(lines{i}), '*')
        data = str2num(lines{i});
        if ~isempty(data)
            elements = [elements; data];
        end
        i = i + 1;
    end
end

function centers = calc_centers(nodes, elements)
    n_elem = size(elements, 1);
    n_dim = size(nodes, 2) - 1;
    centers = zeros(n_elem, n_dim);
    
    fprintf('  计算单元中心...\n');
    for i = 1:n_elem
        node_ids = elements(i, 2:end);
        node_ids = node_ids(node_ids > 0);
        coords = zeros(length(node_ids), n_dim);
        for j = 1:length(node_ids)
            idx = find(nodes(:,1) == node_ids(j), 1);
            coords(j,:) = nodes(idx, 2:end);
        end
        centers(i,:) = mean(coords, 1);
    end
end

function plot_field_simple(nodes, elements, field)
    hold on;
    
    for i = 1:size(elements, 1)
        node_ids = elements(i, 2:end);
        node_ids = node_ids(node_ids > 0);
        coords = zeros(length(node_ids), 3);
        
        for j = 1:length(node_ids)
            idx = find(nodes(:,1) == node_ids(j), 1);
            coords(j,:) = nodes(idx, 2:4);
        end
        
        % 四面体
        if size(coords,1) == 4
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];
        % 六面体
        elseif size(coords,1) == 8
            faces = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 5 6 7 8; 1 2 3 4];
        % 二次四面体（10节点）
        elseif size(coords,1) == 10
            coords = coords(1:4, :);  % 只用角节点
            faces = [1 2 3; 1 2 4; 2 3 4; 1 3 4];
        else
            continue;
        end
        
        patch('Faces', faces, 'Vertices', coords, ...
            'FaceColor', 'flat', 'FaceVertexCData', field(i), ...
            'EdgeColor', 'none', 'FaceAlpha', 0.9);
    end
    
    colormap jet;
    axis equal tight;
    view(3);
    xlabel('X (m)', 'FontSize', 12);
    ylabel('Y (m)', 'FontSize', 12);
    zlabel('Z (m)', 'FontSize', 12);
    grid on;
    lighting gouraud;
    camlight('headlight');
    hold off;
end
