function [node, elelist, element, etype] = read_inp_mesh_fast(inp_file)
% 快速读取inp网格（修复版 - 避免重复单元ID）

fprintf('读取inp文件: %s\n', inp_file);

fid = fopen(inp_file, 'r');
if fid == -1
    error('无法打开: %s', inp_file);
end

node = [];
element_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
etype = '';

in_node = false;
in_elem = false;

line_count = 0;
node_count = 0;
elem_count = 0;

while ~feof(fid)
    line = fgetl(fid);
    line_count = line_count + 1;
    
    if ~ischar(line)
        continue;
    end
    
    line = strtrim(line);
    line_upper = upper(line);
    
    % 跳过空行和注释
    if isempty(line) || startsWith(line, '**')
        continue;
    end
    
    % 检测*NODE关键字
    if startsWith(line_upper, '*NODE')
        in_node = true;
        in_elem = false;
        continue;
    end
    
    % 检测*ELEMENT关键字
    if startsWith(line_upper, '*ELEMENT')
        in_node = false;
        in_elem = true;
        
        % 提取单元类型
        if isempty(etype) && contains(line, 'type=')
            tokens = regexp(line, 'type=(\S+)', 'tokens', 'ignorecase');
            if ~isempty(tokens)
                etype = strtrim(tokens{1}{1});
                etype = regexprep(etype, ',.*', '');  % 移除逗号后的内容
            end
        end
        continue;
    end
    
    % 其他关键字：停止当前读取模式
    if startsWith(line, '*') && ~startsWith(line, '**')
        in_node = false;
        in_elem = false;
        continue;
    end
    
    % 读取节点数据
    if in_node
        try
            data = str2num(line);
            if ~isempty(data) && length(data) >= 4
                node(end+1, :) = data(1:4);
                node_count = node_count + 1;
            end
        catch
            % 忽略解析错误
        end
    end
    
    % 读取单元数据
    if in_elem
        try
            % 处理可能的多行单元定义
            full_line = line;
            
            % 如果行以逗号结尾，继续读取下一行
            while endsWith(strtrim(full_line), ',') && ~feof(fid)
                next_line = fgetl(fid);
                line_count = line_count + 1;
                
                if ischar(next_line)
                    next_line = strtrim(next_line);
                    % 如果下一行是关键字，停止
                    if startsWith(next_line, '*')
                        fseek(fid, -length(next_line)-2, 'cof');  % 回退
                        break;
                    end
                    full_line = [full_line, ' ', next_line];
                else
                    break;
                end
            end
            
            % 解析单元数据
            data = str2num(full_line);
            
            if ~isempty(data) && length(data) >= 2
                elem_id = data(1);
                conn = data(2:end);
                
                % ✅ 使用Map避免重复
                if ~isKey(element_map, elem_id)
                    element_map(elem_id) = conn;
                    elem_count = elem_count + 1;
                end
            end
        catch
            % 忽略解析错误
        end
    end
end

fclose(fid);

fprintf('  读取完成: %d行\n', line_count);
fprintf('  节点: %d\n', node_count);
fprintf('  单元: %d\n', elem_count);
fprintf('  单元类型: %s\n', etype);

% ✅ 从Map转换为数组（确保唯一性）
elem_ids = cell2mat(keys(element_map));
elem_ids = sort(elem_ids);

elelist = elem_ids(:);
element = cell(length(elelist), 1);

for i = 1:length(elelist)
    element{i} = element_map(elelist(i));
end

fprintf('  最终单元数: %d (唯一)\n', length(elelist));
fprintf('  单元ID范围: [%d, %d]\n', min(elelist), max(elelist));

% 最终验证
if length(elelist) ~= length(unique(elelist))
    error('内部错误：单元ID仍然不唯一');
end

end
