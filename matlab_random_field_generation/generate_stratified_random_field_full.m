function [K_realizations, RFgrid] = generate_stratified_random_field_full(...
    element_centers, mu, cov, dh, dv, var, stra, n_realizations)
% 生成完整分层随机场（每个单元独立K值）
%
% 与简化版的区别：
%   - 不做降维近似（保留所有变异）
%   - 完整协方差矩阵（内存优化）
%   - 精确空间相关性

n_elem = size(element_centers, 1);
n_layers = length(mu);
K_realizations = zeros(n_elem, n_realizations);

fprintf('    ┌────────────────────────────────────────┐\n');
fprintf('    │  完整随机场生成（无损版）              │\n');
fprintf('    └────────────────────────────────────────┘\n');

for ilay = 1:n_layers
    
    fprintf('    第%d层: ', ilay);
    
    % 找到该层的单元
    z_coords = element_centers(:, 3);
    layer_mask = (z_coords >= stra(ilay)) & (z_coords < stra(ilay+1));
    
    n_elem_layer = sum(layer_mask);
    
    if n_elem_layer == 0
        fprintf('无单元\n');
        continue;
    end
    
    fprintf('%d个单元 ', n_elem_layer);
    
    layer_centers = element_centers(layer_mask, :);
    
    % 参数
    mean_val = mu(ilay);
    cov_val = cov(ilay);
    theta_h = dh(ilay);
    theta_v = dv(ilay);
    sigma = cov_val * mean_val;
    
    %% ----------------------------------------
    %% 策略：分块计算协方差（节省内存）
    %% ----------------------------------------
    
    if n_elem_layer > 5000
        % 大规模：使用EOLE降维
        fprintf('[EOLE] ');
        
        % 采样点（用于构建低秩近似）
        n_sample = min(2000, n_elem_layer);
        sample_idx = randperm(n_elem_layer, n_sample);
        sample_centers = layer_centers(sample_idx, :);
        
        % 采样点之间的协方差
        C_sample = compute_covariance_block(sample_centers, sample_centers, ...
                                           theta_h, theta_v, sigma);
        
        % 特征值分解
        [eigvec_sample, eigval_sample] = eig(C_sample);
        eigval_sample = diag(eigval_sample);
        [eigval_sample, idx] = sort(eigval_sample, 'descend');
        eigvec_sample = eigvec_sample(:, idx);
        
        % 保留主要特征值
        cumsum_eig = cumsum(eigval_sample) / sum(eigval_sample);
        n_eig = find(cumsum_eig >= 0.98, 1);  % 98%能量
        n_eig = min(n_eig, 500);  % 最多500个
        
        eigval_trunc = eigval_sample(1:n_eig);
        eigvec_trunc = eigvec_sample(:, 1:n_eig);
        
        fprintf('%d特征 ', n_eig);
        
        % 扩展到所有单元
        C_all_sample = compute_covariance_block(layer_centers, sample_centers, ...
                                                theta_h, theta_v, sigma);
        
        % Nystrom扩展
        eigvec_all = (C_all_sample * eigvec_trunc) ./ sqrt(eigval_trunc');
        
        % 生成实现
        for i_real = 1:n_realizations
            xi = randn(n_eig, 1);
            Y = eigvec_all * (sqrt(eigval_trunc) .* xi);
            
            % 对数正态
            log_K = log(mean_val) - 0.5*sigma^2/mean_val^2 + Y / mean_val;
            K_layer = exp(log_K);
            
            % 深度趋势
            if var(ilay) > 0
                depth_factor = 1 + var(ilay) * ...
                    (layer_centers(:,3) - stra(ilay)) / (stra(ilay+1) - stra(ilay));
                K_layer = K_layer .* depth_factor;
            end
            
            K_realizations(layer_mask, i_real) = K_layer;
        end
        
    else
        % 小规模：完整协方差矩阵
        fprintf('[Full] ');
        
        % 完整协方差
        C_full = compute_covariance_block(layer_centers, layer_centers, ...
                                          theta_h, theta_v, sigma);
        
        % Cholesky分解（更稳定）
        try
            L = chol(C_full + eye(n_elem_layer)*1e-10, 'lower');
            use_chol = true;
        catch
            % 如果Cholesky失败，用特征值分解
            [eigvec_full, eigval_full] = eig(C_full);
            eigval_full = diag(eigval_full);
            eigval_full(eigval_full < 0) = 0;
            L = eigvec_full * diag(sqrt(eigval_full));
            use_chol = false;
        end
        
        % 生成实现
        for i_real = 1:n_realizations
            xi = randn(n_elem_layer, 1);
            Y = L * xi;
            
            % 对数正态
            log_K = log(mean_val) - 0.5*sigma^2/mean_val^2 + Y / mean_val;
            K_layer = exp(log_K);
            
            % 深度趋势
            if var(ilay) > 0
                depth_factor = 1 + var(ilay) * ...
                    (layer_centers(:,3) - stra(ilay)) / (stra(ilay+1) - stra(ilay));
                K_layer = K_layer .* depth_factor;
            end
            
            K_realizations(layer_mask, i_real) = K_layer;
        end
    end
    
    fprintf('✓\n');
end

% 网格信息
RFgrid.element_centers = element_centers;
RFgrid.stra = stra;
RFgrid.params.mu = mu;
RFgrid.params.cov = cov;
RFgrid.params.dh = dh;
RFgrid.params.dv = dv;
RFgrid.n_realizations = n_realizations;

end

%% 辅助函数：分块协方差计算
function C = compute_covariance_block(centers1, centers2, theta_h, theta_v, sigma)
% 计算两组点之间的协方差（向量化）

n1 = size(centers1, 1);
n2 = size(centers2, 1);

% 提取坐标
x1 = centers1(:, 1);
y1 = centers1(:, 2);
z1 = centers1(:, 3);

x2 = centers2(:, 1);
y2 = centers2(:, 2);
z2 = centers2(:, 3);

% 向量化距离计算
dx = bsxfun(@minus, x1, x2');
dy = bsxfun(@minus, y1, y2');
dz = bsxfun(@minus, z1, z2');

% 各向异性距离
r = sqrt((dx.^2 + dy.^2)/theta_h^2 + dz.^2/theta_v^2);

% 指数型协方差
rho = exp(-r);

% 协方差矩阵
C = sigma^2 * rho;

end
