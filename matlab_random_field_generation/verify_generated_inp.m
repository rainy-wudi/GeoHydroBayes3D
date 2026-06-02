function verify_generated_inp(generated_file)
% 快速验证生成的inp

fid = fopen(generated_file, 'r');
lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line), lines{end+1} = line; end
end
fclose(fid);

fprintf('========================================\n');
fprintf('验证: %s\n', generated_file);
fprintf('总行数: %d\n', length(lines));
fprintf('========================================\n\n');

% 统计关键内容
part_count = 0;
material_positions = [];
rf_material_count = 0;
step_found = false;

for i = 1:length(lines)
    line_upper = upper(strtrim(lines{i}));
    
    if startsWith(line_upper, '*PART')
        part_count = part_count + 1;
    end
    
    if startsWith(line_upper, '*MATERIAL')
        material_positions(end+1) = i;
        if contains(lines{i}, 'RF_MAT')
            rf_material_count = rf_material_count + 1;
            if rf_material_count <= 3  % 显示前3个
                fprintf('[%d] 随机场材料: %s\n', i, strtrim(lines{i}));
            end
        end
    end
    
    if startsWith(line_upper, '*STEP')
        step_found = true;
        fprintf('[%d] Step找到\n', i);
    end
end

fprintf('\n统计:\n');
fprintf('  Part数量: %d\n', part_count);
fprintf('  材料总数: %d\n', length(material_positions));
fprintf('  随机场材料: %d\n', rf_material_count);
fprintf('  是否有Step: %s\n', iif(step_found, '✅', '❌'));

% 检查第一个RF材料是否在第一个Part内
if rf_material_count > 0
    first_rf_pos = [];
    first_part_end = [];
    
    for i = 1:length(lines)
        line_upper = upper(strtrim(lines{i}));
        if isempty(first_rf_pos) && contains(lines{i}, 'RF_MAT')
            first_rf_pos = i;
        end
        if startsWith(line_upper, '*END PART')
            first_part_end = i;
            break;
        end
    end
    
    if ~isempty(first_rf_pos) && ~isempty(first_part_end)
        if first_rf_pos < first_part_end
            fprintf('\n✅ 随机场材料在第一个Part内 (行%d < 行%d)\n', ...
                    first_rf_pos, first_part_end);
        else
            fprintf('\n❌ 随机场材料不在第一个Part内！\n');
        end
    end
end

fprintf('========================================\n\n');

function result = iif(condition, true_val, false_val)
    if condition, result = true_val; else, result = false_val; end
end

end
