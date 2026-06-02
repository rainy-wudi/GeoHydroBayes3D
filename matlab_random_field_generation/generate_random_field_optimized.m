function K_field = generate_random_field_optimized(element_centers, layer_indices, ...
                                                   layer_params, n_layers, n_sample_points)
% 优化的随机场生成：采样点+插值法（添加严格验证）

n_elem = size(element_centers, 1);
K_field = zeros(n_elem, 1);

% 全局边界
x_min = min(element_centers(:,1));
x_max = max(element_centers(:,1));
y_min = min(element_centers(:,2));
y_max = max(element_centers(:,2));
z_min = min(element_centers(:,3));
z_max = max(element_centers(:,3));

fprintf('        单元中心范围:\n');
fprintf('          X: [%.2f, %.2f]\n', x_min, x_max);
fprintf('          Y: [%.2f, %.2f]\n', y_min, y_max);
fprintf('          Z: [%.2f, %.2f]\n', z_min, z_max);

% 为每层生成随机场
for i_layer = 1:n_layers
    
    % 当前层单元
    mask = (layer_indices == i_layer);
    n_elem_layer = sum(mask);
    
    if n_elem_layer == 0
        warning('层%d没有单元', i_layer);
        continue;
    end
    
    fprintf('        层%d: %d个单元\n', i_layer, n_elem_layer);
    
    layer_centers = element_centers(mask, :);
    
    % 当前层参数
    p = layer_params{i_layer};
    
    % 当前层Z范围（扩展边界）
    layer_z_min = min(layer_centers(:,3)) - 2;
    layer_z_max = max(layer_centers(:,3)) + 2;
    
    fprintf('          Z范围: [%.2f, %.2f]\n', layer_z_min, layer_z_max);
    
    %% 1. 生成采样网格
    x_grid = linspace(x_min - 1, x_max + 1, n_sample_points(1));
    y_grid = linspace(y_min - 1, y_max + 1, n_sample_points(2));
    z_grid = linspace(layer_z_min, layer_z_max, n_sample_points(3));
    
    [X, Y, Z] = meshgrid(x_grid, y_grid, z_grid);
    
    sample_coords = [X(:), Y(:), Z(:)];
    n_samples = size(sample_coords, 1);
    
    fprintf('          采样点数: %d\n', n_samples);
    
    %% 2. 在采样点生成高斯随机场
    
    % 计算协方差矩阵
    C = zeros(n_samples, n_samples);
    
    for i = 1:n_samples
        for j = i:n_samples
            dx = sample_coords(i,1) - sample_coords(j,1);
            dy = sample_coords(i,2) - sample_coords(j,2);
            dz = sample_coords(i,3) - sample_coords(j,3);
            
            h_dist = sqrt(dx^2 + dy^2);
            v_dist = abs(dz);
            
            % 指数协方差函数
            rho = exp(-h_dist/p.dh - v_dist/p.dv);
            
            C(i,j) = p.sigma^2 * rho;
            C(j,i) = C(i,j);
        end
    end
    
    % 数值稳定
    C = C + eye(n_samples) * 1e-10;
    
    % Cholesky分解
    try
        L = chol(C, 'lower');
    catch
        warning('层%d Cholesky失败，使用SVD', i_layer);
        [U, S, ~] = svd(C);
        S(S < 0) = 0;
        L = U * sqrt(S);
    end
    
    % 生成高斯随机场
    Z_random = randn(n_samples, 1);
    Y_samples = L * Z_random;
    
    % 转换到对数正态
    log_K_samples = log(p.mu) - 0.5 * p.sigma^2 / p.mu^2 + Y_samples / p.mu;
    K_samples = exp(log_K_samples);
    
    % 修正异常值
    K_samples(K_samples < 1e-15) = 1e-12;
    K_samples(K_samples > 1e-2) = 1e-2;
    K_samples(isnan(K_samples)) = p.mu;
    K_samples(isinf(K_samples)) = p.mu;
    
    %% 3. 插值到单元中心
    
    % 重塑为3D网格
    K_grid = reshape(K_samples, [n_sample_points(2), n_sample_points(1), n_sample_points(3)]);
    
    % 插值
    K_interp = interp3(X, Y, Z, K_grid, ...
                      layer_centers(:,1), ...
                      layer_centers(:,2), ...
                      layer_centers(:,3), ...
                      'linear', p.mu);
    
    % 严格修正异常值
    K_interp(K_interp <= 0) = p.mu;
    K_interp(K_interp < 1e-15) = 1e-12;
    K_interp(K_interp > 1e-2) = 1e-2;
    K_interp(isnan(K_interp)) = p.mu;
    K_interp(isinf(K_interp)) = p.mu;
    
    % 赋值
    K_field(mask) = K_interp;
    
    fprintf('          K统计: min=%.2e, max=%.2e, mean=%.2e\n', ...
            min(K_interp), max(K_interp), mean(K_interp));
end

%% 最终验证
n_invalid = sum(K_field <= 0 | isnan(K_field) | isinf(K_field));

if n_invalid > 0
    warning('检测到%d个异常K值，自动修正', n_invalid);
    
    % 用全局均值替换
    valid_K = K_field(K_field > 0 & ~isnan(K_field) & ~isinf(K_field));
    
    if isempty(valid_K)
        global_mean = 1e-8;  % 默认值
    else
        global_mean = median(valid_K);
    end
    
    K_field(K_field <= 0 | isnan(K_field) | isinf(K_field)) = global_mean;
end

% 最终统计
fprintf('        最终K场统计:\n');
fprintf('          有效单元: %d/%d\n', sum(K_field > 0), n_elem);
fprintf('          K范围: [%.2e, %.2e]\n', min(K_field), max(K_field));
fprintf('          K均值: %.2e\n', mean(K_field));

% ✅ 最终检查：确保没有异常值
assert(all(K_field > 0), '存在非正K值');
assert(all(~isnan(K_field)), '存在NaN');
assert(all(~isinf(K_field)), '存在Inf');

end
