function visualize_parameter_samples(param_samples, param_names, param_bounds)
% 可视化参数采样

n_params = size(param_samples, 2);

figure('Position', [100, 100, 1200, 800]);

% 边际分布
for i = 1:n_params
    subplot(2, n_params, i);
    histogram(param_samples(:,i), 20, 'FaceColor', [0.3, 0.6, 0.9]);
    xlabel(param_names{i});
    ylabel('频数');
    title(sprintf('%s 分布', param_names{i}));
    
    if i <= 3
        set(gca, 'XScale', 'log');
    end
    grid on;
end

% 关键参数对
key_pairs = [1,2; 2,3; 4,5];

for ipair = 1:size(key_pairs, 1)
    subplot(2, n_params, n_params + ipair);
    
    idx1 = key_pairs(ipair, 1);
    idx2 = key_pairs(ipair, 2);
    
    scatter(param_samples(:,idx1), param_samples(:,idx2), 30, 'filled', ...
            'MarkerFaceAlpha', 0.6);
    xlabel(param_names{idx1});
    ylabel(param_names{idx2});
    
    if idx1 <= 3
        set(gca, 'XScale', 'log');
    end
    if idx2 <= 3
        set(gca, 'YScale', 'log');
    end
    grid on;
end

sgtitle('参数空间采样', 'FontSize', 14);

try
    saveas(gcf, 'parameter_sampling.png');
catch
    warning('图片保存失败');
end

end
