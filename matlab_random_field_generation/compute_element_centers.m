function centers = compute_element_centers(node, element)
% 快速计算单元中心

n_elem = length(element);
centers = zeros(n_elem, 3);

% 构建节点映射
node_map = containers.Map(node(:,1), 1:size(node,1));

for i = 1:n_elem
    conn = element{i};
    
    coords = zeros(length(conn), 3);
    for j = 1:length(conn)
        if isKey(node_map, conn(j))
            idx = node_map(conn(j));
            coords(j, :) = node(idx, 2:4);
        end
    end
    
    centers(i, :) = mean(coords, 1);
end

end
