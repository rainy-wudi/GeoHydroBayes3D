function samples = lhsdesign_with_bounds(n_samples, bounds)
% 生成带边界约束的拉丁超立方采样

n_params = size(bounds, 1);

% 检查是否有lhsdesign
if exist('lhsdesign', 'file')
    X_unit = lhsdesign(n_samples, n_params, 'criterion', 'maximin');
else
    warning('未找到lhsdesign，使用简化版');
    X_unit = manual_lhs(n_samples, n_params);
end

% 映射到实际范围
samples = zeros(n_samples, n_params);

for i = 1:n_params
    lb = bounds(i, 1);
    ub = bounds(i, 2);
    
    % 渗透系数用对数空间
    if i <= 3
        log_lb = log(lb);
        log_ub = log(ub);
        samples(:, i) = exp(log_lb + (log_ub - log_lb) * X_unit(:, i));
    else
        samples(:, i) = lb + (ub - lb) * X_unit(:, i);
    end
end

end

function X = manual_lhs(n, d)
% 简单LHS实现
X = zeros(n, d);
for i = 1:d
    perm = randperm(n);
    X(:, i) = (perm' - rand(n, 1)) / n;
end
end
