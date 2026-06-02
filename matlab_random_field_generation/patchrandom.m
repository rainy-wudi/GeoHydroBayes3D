%% 简化版：快速可视化单个随机场
clc; clear; close all;

%% 设置
inp_file = 'Job_P001_R01.inp';
part = 'diceng';

%% 读取并绘制
[nodes, elements] = read_inp_simple(inp_file, part);
centers = calc_centers(nodes, elements);

% 生成一个简单的随机场
field = randn(size(centers, 1), 1);  % 随机值

% 绘图
figure('Position', [100, 100, 1000, 800]);
plot_field_simple(nodes, elements, field);                                                                                         
title('随机场可视化');
colorbar;

%% 简化读取函数
function [nodes, elements] = read_inp_simple(filename, part_name)
    fid = fopen(filename, 'r');
    lines = {};
    while ~feof(fid)
        lines{end+1} = fgetl(fid);
    end
    fclose(fid);
    
    % 找到部件
    part_idx = find(contains(lines, ['*Part, name=' part_name]), 1);
    
    % 读节点
    node_idx = find(contains(lines(part_idx:end), '*Node'), 1) + part_idx;
    nodes = [];
    i = node_idx;
    while i <= length(lines) && ~startsWith(lines{i}, '*')
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
    while i <= length(lines) && ~startsWith(lines{i}, '*')
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
        else
            continue;
        end
        
        patch('Faces', faces, 'Vertices', coords, ...
            'FaceColor', 'flat', 'FaceVertexCData', field(i), ...
            'EdgeColor', 'k', 'EdgeAlpha', 0.1);
    end
    
    colormap jet;
    axis equal;
    view(3);
    xlabel('X'); ylabel('Y'); zlabel('Z');
    grid on;
end
