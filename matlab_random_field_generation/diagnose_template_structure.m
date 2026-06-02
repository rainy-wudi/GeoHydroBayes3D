function diagnose_template_structure(template_file)
% 诊断模板的完整结构

fid = fopen(template_file, 'r');
if fid == -1
    error('无法打开: %s', template_file);
end

lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line), lines{end+1} = line; end
end
fclose(fid);

fprintf('========================================\n');
fprintf('模板结构诊断: %s\n', template_file);
fprintf('总行数: %d\n', length(lines));
fprintf('========================================\n\n');

% 查找关键结构
part_start = [];
part_end = [];
assembly_start = [];
assembly_end = [];
material_positions = [];
section_positions = [];
step_start = [];

for i = 1:length(lines)
    line_upper = upper(strtrim(lines{i}));
    
    if startsWith(line_upper, '*PART')
        part_start(end+1) = i;
        fprintf('[%d] *Part 开始\n', i);
    elseif startsWith(line_upper, '*END PART')
        part_end(end+1) = i;
        fprintf('[%d] *End Part\n', i);
    elseif startsWith(line_upper, '*ASSEMBLY')
        assembly_start = i;
        fprintf('[%d] *Assembly 开始\n', i);
    elseif startsWith(line_upper, '*END ASSEMBLY')
        assembly_end = i;
        fprintf('[%d] *End Assembly\n', i);
    elseif startsWith(line_upper, '*MATERIAL')
        material_positions(end+1) = i;
        fprintf('[%d] *Material: %s\n', i, strtrim(lines{i}));
    elseif startsWith(line_upper, '*SOLID SECTION')
        section_positions(end+1) = i;
        fprintf('[%d] *Solid Section: %s\n', i, strtrim(lines{i}));
    elseif startsWith(line_upper, '*STEP')
        step_start = i;
        fprintf('[%d] *Step 开始\n', i);
        break;  % 只找第一个Step
    end
end

fprintf('\n========================================\n');
fprintf('结构分析:\n');
fprintf('========================================\n');

% 判断材料定义位置
if ~isempty(material_positions)
    fprintf('\n原模板材料定义位置:\n');
    for i = 1:length(material_positions)
        pos = material_positions(i);
        
        % 判断在哪个区域
        if ~isempty(part_start) && ~isempty(part_end)
            in_part = false;
            for j = 1:length(part_start)
                if pos > part_start(j) && pos < part_end(j)
                    in_part = true;
                    fprintf('  第%d个材料(行%d): 在Part内 ✅\n', i, pos);
                    break;
                end
            end
            if ~in_part
                if ~isempty(assembly_start) && pos > assembly_start
                    fprintf('  第%d个材料(行%d): 在Assembly后 ❌\n', i, pos);
                elseif ~isempty(part_end) && pos > part_end(end)
                    fprintf('  第%d个材料(行%d): 在Part结束后 ❌\n', i, pos);
                else
                    fprintf('  第%d个材料(行%d): 在Part之前 ⚠️\n', i, pos);
                end
            end
        end
    end
else
    fprintf('\n⚠️  模板中没有*Material定义\n');
end

% 判断截面定义位置
if ~isempty(section_positions)
    fprintf('\n原模板截面定义位置:\n');
    for i = 1:length(section_positions)
        pos = section_positions(i);
        
        if ~isempty(part_start) && ~isempty(part_end)
            in_part = false;
            for j = 1:length(part_start)
                if pos > part_start(j) && pos < part_end(j)
                    in_part = true;
                    fprintf('  第%d个截面(行%d): 在Part内 ✅\n', i, pos);
                    break;
                end
            end
            if ~in_part
                fprintf('  第%d个截面(行%d): 在Part外 ❌\n', i, pos);
            end
        end
    end
else
    fprintf('\n⚠️  模板中没有*Solid Section定义\n');
end

fprintf('\n========================================\n');
fprintf('推荐插入策略:\n');
fprintf('========================================\n');

if ~isempty(part_end)
    fprintf('✅ 在 *End Part 之前插入材料和截面\n');
    fprintf('   插入位置: 第%d行之前\n', part_end(1));
elseif ~isempty(assembly_start)
    fprintf('⚠️  在 *Assembly 之前插入\n');
    fprintf('   插入位置: 第%d行之前\n', assembly_start);
else
    fprintf('❌ 无法确定插入位置，请手动检查\n');
end

fprintf('\n========================================\n');

% 显示Part附近的内容（用于确认结构）
if ~isempty(part_end)
    fprintf('\n*End Part 附近内容:\n');
    fprintf('========================================\n');
    start_show = max(1, part_end(1) - 5);
    end_show = min(length(lines), part_end(1) + 5);
    for i = start_show:end_show
        if i == part_end(1)
            fprintf('[%d] >>> %s <<<\n', i, lines{i});
        else
            fprintf('[%d]     %s\n', i, lines{i});
        end
    end
end

end
