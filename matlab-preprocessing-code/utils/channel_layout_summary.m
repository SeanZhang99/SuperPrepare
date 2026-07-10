function varargout = channel_summary(varargin)
% CHANNEL_LAYOUT_SUMMARY - 分析 EEG 数据集的通道布局
% 获取各个数据集的通道布局名称顺序，并支持计算交集和并集
%
% 本函数的数据集通道信息来源于 get_dataset_info.m 中的硬编码定义
%
% 用法：
%   layouts = channel_layout_summary()
%     返回所有数据集的通道布局信息（已按固定 10-20/10-10 系统排序算法排序）
%
%   [intersection, union_result] = channel_layout_summary(selected_datasets)
%     计算选定数据集通道布局的交集和并集
%     selected_datasets: 字符串数组或 cell 数组，例如 ["NJU_preprocessed", "KUL_preprocessed"]
%
%   [intersection, union_result, layouts] = channel_layout_summary(selected_datasets)
%     同时返回所有数据集的布局信息
%
% 示例：
%   % 查看所有数据集的通道布局
%   layouts = channel_layout_summary();
%   for i = 1:length(layouts)
%       fprintf("%s (nch=%d): %s\n", layouts(i).dataset_name, layouts(i).nch, ...
%           strjoin(layouts(i).sorted_channels, ", "));
%   end
%
%   % 计算 NJU 和 KUL 的交集和并集
%   [intersect_ch, union_ch] = channel_layout_summary(["NJU_preprocessed", "KUL_preprocessed"]);
%   fprintf("Intersection (%d channels): %s\n", length(intersect_ch), strjoin(intersect_ch, ", "));
%   fprintf("Union (%d channels): %s\n", length(union_ch), strjoin(union_ch, ", "));

% 获取所有通道布局
all_layouts = get_all_channel_layouts();

% 如果没有输入参数，只返回所有布局
if nargin == 0 || isempty(varargin{1})
    varargout{1} = all_layouts;
    if nargout > 1
        varargout{2} = string([]);
    end
    if nargout > 2
        varargout{3} = string([]);
    end
    return;
end

selected_datasets = varargin{1};

% 统一转换为字符串数组
if iscell(selected_datasets)
    selected_datasets = string(selected_datasets);
elseif ischar(selected_datasets)
    selected_datasets = string(selected_datasets);
elseif ~isstring(selected_datasets)
    error("selected_datasets must be a string array, cell array, or char array");
end

% 验证数据集名称
available_names = [all_layouts.dataset_name];
for i = 1:length(selected_datasets)
    if ~ismember(selected_datasets(i), available_names)
        error("Unknown dataset: %s", selected_datasets(i));
    end
end

% 收集选定数据集的通道（已排序）
selected_channels = {};
valid_count = 0;
for i = 1:length(selected_datasets)
    idx = find(strcmp(available_names, selected_datasets(i)), 1);
    ch = all_layouts(idx).sorted_channels;
    if ~isempty(ch)
        valid_count = valid_count + 1;
        selected_channels{valid_count} = ch;
    else
        warning("Dataset %s has empty channel layout, skipping", selected_datasets(i));
    end
end

if valid_count == 0
    error("No valid datasets with channel layouts selected");
end

% 计算交集
intersection = selected_channels{1};
for i = 2:valid_count
    intersection = intersect(intersection, selected_channels{i});
end

% 计算并集
union_result = selected_channels{1};
for i = 2:valid_count
    union_result = union(union_result, selected_channels{i});
end

% 对结果进行固定排序
intersection = sort_channels(intersection);
union_result = sort_channels(union_result);

% 返回结果
varargout{1} = intersection;
if nargout > 1
    varargout{2} = union_result;
end
if nargout > 2
    varargout{3} = all_layouts;
end
end

%% 子函数：获取所有数据集的通道布局
function layouts = get_all_channel_layouts()
% 定义所有数据集名称（与 get_dataset_info.m 中的 case 对应）
dataset_names = [
    "NJU_raw"; "NJU_preprocessed"; "KUL_raw"; "KUL_preprocessed";
    "Alices_raw"; "sparKULee_raw"; "sparKULee_preprocessed";
    "DTU_raw"; "DTU_preprocessed"; "PKU_preprocessed";
    "PKU-NBD_preprocessed"; "Estart_preprocessed"; "AHU_preprocessed";
    "KUL-AV-GC_preprocessed"; "NUS_preprocessed"; "CocktailParty_preprocessed"
    ];

% 定义每个数据集的通道布局（与 get_dataset_info.m 中的 channel 变量一致）
channel_cells = cell(length(dataset_names), 1);

% NJU_raw & NJU_preprocessed (32 channels)
channel_cells{1} = [
    "Cz"; "Fz"; "Fp1"; "F7"; "F3"; "FC1"; "C3"; "FC5"; "FT9"; "T7"; "CP5";
    "CP1"; "P3"; "P7"; "PO9"; "O1"; "Pz"; "Oz"; "O2"; "PO10"; "P8"; "P4"; "CP2";
    "CP6"; "T8"; "FT10"; "FC6"; "C4"; "FC2"; "F4"; "F8"; "Fp2"
    ];
channel_cells{2} = channel_cells{1};

% KUL_raw & KUL_preprocessed (64 channels)
channel_cells{3} = [
    "Fp1"; "AF7"; "AF3"; "F1"; "F3"; "F5"; "F7"; "FT7"; "FC5"; "FC3"; "FC1"; "C1"; "C3"; "C5"; "T7"; "TP7"; "CP5"; "CP3"; "CP1"; "P1"; "P3"; "P5"; "P7"; "P9"; "PO7"; "PO3"; "O1"; "Iz"; "Oz"; "POz"; "Pz"; "CPz"; "Fpz"; "Fp2"; "AF8"; "AF4"; "AFz"; "Fz"; "F2"; "F4"; "F6"; "F8"; "FT8"; "FC6"; "FC4"; "FC2"; "FCz"; "Cz"; "C2"; "C4"; "C6"; "T8"; "TP8"; "CP6"; "CP4"; "CP2"; "P2"; "P4"; "P6"; "P8"; "P10"; "PO8"; "PO4"; "O2"
    ];
channel_cells{4} = channel_cells{3};

% Alices_raw (empty channel layout)
channel_cells{5} = string([]);

% sparKULee_raw & sparKULee_preprocessed (64 channels)
channel_cells{6} = [
    "Fp1"; "AF7"; "AF3"; "F1"; "F3"; "F5"; "F7"; "FT7"; "FC5"; "FC3"; "FC1"; "C1"; "C3"; "C5"; "T7"; "TP7"; "CP5"; "CP3"; "CP1"; "P1"; "P3"; "P5"; "P7"; "P9"; "PO7"; "PO3"; "O1"; "Iz"; "Oz"; "POz"; "Pz"; "CPz"; "Fpz"; "Fp2"; "AF8"; "AF4"; "AFz"; "Fz"; "F2"; "F4"; "F6"; "F8"; "FT8"; "FC6"; "FC4"; "FC2"; "FCz"; "Cz"; "C2"; "C4"; "C6"; "T8"; "TP8"; "CP6"; "CP4"; "CP2"; "P2"; "P4"; "P6"; "P8"; "P10"; "PO8"; "PO4"; "O2"
    ];
channel_cells{7} = channel_cells{6};

% DTU_raw & DTU_preprocessed (64 channels)
channel_cells{8} = [
    "Fp1"; "AF7"; "AF3"; "F1"; "F3"; "F5"; "F7"; "FT7"; "FC5"; "FC3"; "FC1"; "C1"; "C3"; "C5"; "T7"; "TP7"; "CP5"; "CP3"; "CP1"; "P1"; "P3"; "P5"; "P7"; "P9"; "PO7"; "PO3"; "O1"; "Iz"; "Oz"; "POz"; "Pz"; "CPz"; "Fpz"; "Fp2"; "AF8"; "AF4"; "AFz"; "Fz"; "F2"; "F4"; "F6"; "F8"; "FT8"; "FC6"; "FC4"; "FC2"; "FCz"; "Cz"; "C2"; "C4"; "C6"; "T8"; "TP8"; "CP6"; "CP4"; "CP2"; "P2"; "P4"; "P6"; "P8"; "P10"; "PO8"; "PO4"; "O2"
    ];
channel_cells{9} = channel_cells{8};

% PKU_preprocessed (59 channels)
channel_cells{10} = [
    "Fpz"; "Fp1"; "Fp2"; "AF3"; "AF4"; "AF7"; "AF8"; "Fz"; "F1"; "F2"; "F3"; "F4"; "F5"; "F6"; "F7"; "F8"; "FCz"; "FC1"; "FC2"; "FC3"; "FC4"; "FC5"; "FC6"; "FT7"; "FT8"; "Cz"; "C1"; "C2"; "C3"; "C4"; "C5"; "C6"; "T7"; "T8"; "CP1"; "CP2"; "CP3"; "CP4"; "CP5"; "CP6"; "TP7"; "TP8"; "Pz"; "P3"; "P4"; "P5"; "P6"; "P7"; "P8"; "POz"; "PO3"; "PO4"; "PO5"; "PO6"; "PO7"; "PO8"; "Oz"; "O1"; "O2"
    ];

% PKU-NBD_preprocessed (59 channels)
channel_cells{11} = channel_cells{10};

% Estart_preprocessed (63 channels)
channel_cells{12} = [
    "AF3"; "AF4"; "AF7"; "AF8"; "C1"; "C2"; "C3"; "C4"; "C5"; "C6"; "CP1"; "CP2"; "CP3"; "CP4"; "CP5"; "CP6"; "CPz"; "Cz"; "F1"; "F2"; "F3"; "F4"; "F5"; "F6"; "F7"; "F8"; "FC1"; "FC2"; "FC3"; "FC4"; "FC5"; "FC6"; "Fp1"; "Fp2"; "FT10"; "FT7"; "FT8"; "FT9"; "Fz"; "O1"; "O2"; "Oz"; "P1"; "P2"; "P3"; "P4"; "P5"; "P6"; "P7"; "P8"; "PO3"; "PO7"; "PO8"; "POz"; "Pz"; "FCz"; "T7"; "T8"; "TP10"; "TP7"; "TP8"; "TP9"; "AFz"
    ];

% AHU_preprocessed (32 channels) - note: original uses commas, converted to vertical array
channel_cells{13} = [
    "Fp1"; "Fp2"; "F7"; "F3"; "Fz"; "F4"; "F8"; "FT7"; "FC3"; "FCz"; "FC4"; "FT8"; "T7"; "C3"; "Cz"; "C4"; "T8"; "TP7"; "CP3"; "CPz"; "CP4"; "TP8"; "A1"; "P7"; "P3"; "Pz"; "P4"; "P8"; "A2"; "O1"; "Oz"; "O2"
    ];

% KUL-AV-GC_preprocessed (64 channels)
channel_cells{14} = [
    "Fp1"; "AF7"; "AF3"; "F1"; "F3"; "F5"; "F7"; "FT7"; "FC5"; "FC3"; "FC1"; "C1"; "C3"; "C5"; "T7"; "TP7"; "CP5"; "CP3"; "CP1"; "P1"; "P3"; "P5"; "P7"; "P9"; "PO7"; "PO3"; "O1"; "Iz"; "Oz"; "POz"; "Pz"; "CPz"; "Fpz"; "Fp2"; "AF8"; "AF4"; "AFz"; "Fz"; "F2"; "F4"; "F6"; "F8"; "FT8"; "FC6"; "FC4"; "FC2"; "FCz"; "Cz"; "C2"; "C4"; "C6"; "T8"; "TP8"; "CP6"; "CP4"; "CP2"; "P2"; "P4"; "P6"; "P8"; "P10"; "PO8"; "PO4"; "O2"
    ];

% NUS_preprocessed (64 channels)
channel_cells{15} = [
    "Fp1"; "Fp2"; "F3"; "F4"; "C3"; "C4"; "P3"; "P4"; "O1"; "O2"; "F7"; "F8"; "T7"; "T8"; "P7"; "P8"; "Fz"; "Cz"; "Pz"; "Oz"; "FC1"; "FC2"; "CP1"; "CP2"; "FC5"; "FC6"; "CP5"; "CP6"; "TP9"; "TP10"; "POz"; "F1"; "F2"; "C1"; "C2"; "P1"; "P2"; "AF3"; "AF4"; "FC3"; "FC4"; "CP3"; "CP4"; "PO3"; "PO4"; "F5"; "F6"; "C5"; "C6"; "P5"; "P6"; "AF7"; "AF8"; "FT7"; "FT8"; "TP7"; "TP8"; "PO7"; "PO8"; "FT9"; "FT10"; "Fpz"; "CPz"; "FCz"
    ];

% CocktailParty_preprocessed (empty channel layout)
channel_cells{16} = string([]);

% 构建结构体数组
n = length(dataset_names);
layouts = struct(...
    'dataset_name', cell(n,1), ...
    'channels', cell(n,1), ...
    'sorted_channels', cell(n,1), ...
    'nch', cell(n,1) ...
    );

for i = 1:n
    layouts(i).dataset_name = dataset_names(i);
    layouts(i).channels = channel_cells{i};
    layouts(i).nch = length(channel_cells{i});
    if ~isempty(channel_cells{i})
        layouts(i).sorted_channels = sort_channels(channel_cells{i});
    else
        layouts(i).sorted_channels = string([]);
    end
end
end

%% 子函数：固定排序算法（标准 10-20/10-10 系统顺序）
function sorted = sort_channels(channels)
% 按照标准 EEG 10-20/10-10 系统电极物理位置排序
% 顺序规则：从前额（Frontal Pole）到枕骨（Occipital），每行从左到右

standard_order = [
    "Fp1"; "Fpz"; "Fp2";
    "AF7"; "AF3"; "AFz"; "AF4"; "AF8";
    "F7"; "F5"; "F3"; "F1"; "Fz"; "F2"; "F4"; "F6"; "F8";
    "FT9"; "FT7"; "FC5"; "FC3"; "FC1"; "FCz"; "FC2"; "FC4"; "FC6"; "FT8"; "FT10";
    "T7"; "C5"; "C3"; "C1"; "Cz"; "C2"; "C4"; "C6"; "T8";
    "TP9"; "TP7"; "CP5"; "CP3"; "CP1"; "CPz"; "CP2"; "CP4"; "CP6"; "TP8"; "TP10";
    "P9"; "P7"; "P5"; "P3"; "P1"; "Pz"; "P2"; "P4"; "P6"; "P8"; "P10";
    "PO9"; "PO7"; "PO5"; "PO3"; "POz"; "PO4"; "PO6"; "PO8"; "PO10";
    "O1"; "Oz"; "O2";
    "Iz";
    "A1"; "A2"
    ];

n_std = length(standard_order);
n_ch = length(channels);

% 如果输入为空，直接返回
if n_ch == 0
    sorted = string([]);
    return;
end

% 计算每个通道的排序索引
indices = zeros(n_ch, 1);
unknown_mask = false(n_ch, 1);

for i = 1:n_ch
    idx = find(strcmp(standard_order, channels(i)), 1);
    if ~isempty(idx)
        indices(i) = idx;
    else
        unknown_mask(i) = true;
        indices(i) = inf; % 临时标记为无限大
    end
end

% 对未知通道按字母排序并分配索引
if any(unknown_mask)
    unknown_channels = channels(unknown_mask);
    [~, unknown_sort_idx] = sort(unknown_channels);
    unknown_indices = find(unknown_mask);
    for j = 1:length(unknown_indices)
        indices(unknown_indices(unknown_sort_idx(j))) = n_std + j;
    end
end

% 按索引排序
[~, sort_idx] = sort(indices);
sorted = channels(sort_idx);
end

%% 新增子函数：计算通道交集与数据集数量的 trade-off 并绘制曲线
function tradeoff = channel_intersection_tradeoff(selected_datasets)
% CHANNEL_INTERSECTION_TRADEOFF - 分析通道交集与数据集数量的 trade-off
% 在用户选定的数据集范围内，遍历所有可能的 k 个数据集组合，
% 计算每种组合下的交集大小，并绘制 trade-off 曲线。
%
% 用法：
%   tradeoff = channel_intersection_tradeoff(["KUL_preprocessed", "DTU_preprocessed", "PKU_preprocessed"]);
%   figure; plot(tradeoff.num_datasets, tradeoff.max_intersection, '-o');
%
% 输入：
%   selected_datasets - 字符串数组，用户选定的数据集名称
%
% 输出结构体字段：
%   - num_datasets      : 组合中的数据集数量 k (k=2..N)
%   - max_intersection  : 该 k 下所有组合的最大交集通道数
%   - min_intersection  : 该 k 下所有组合的最小交集通道数
%   - mean_intersection : 该 k 下所有组合的平均交集通道数
%   - median_intersection: 该 k 下所有组合的中位数交集通道数
%   - std_intersection  : 该 k 下所有组合的标准差
%   - num_combinations  : 该 k 下的组合总数
%   - best_combinations : cell 数组，最大交集对应的 {数据集名称数组}
%   - best_intersections: cell 数组，最大交集对应的 {通道名称数组}
%   - all_combinations  : cell 数组，该 k 下所有组合的数据集名称
%   - all_intersections : cell 数组，该 k 下所有组合的交集通道

    all_layouts = get_all_channel_layouts();
    
    % 转换和验证输入
    if iscell(selected_datasets)
        selected_datasets = string(selected_datasets);
    elseif ischar(selected_datasets)
        selected_datasets = string(selected_datasets);
    elseif ~isstring(selected_datasets)
        error("selected_datasets must be a string array, cell array, or char array");
    end
    
    available_names = [all_layouts.dataset_name];
    for i = 1:length(selected_datasets)
        if ~ismember(selected_datasets(i), available_names)
            error("Unknown dataset: %s", selected_datasets(i));
        end
    end
    
    % 收集通道（跳过空布局的数据集）
    valid_datasets = string([]);
    selected_channels = {};
    for i = 1:length(selected_datasets)
        idx = find(strcmp(available_names, selected_datasets(i)), 1);
        ch = all_layouts(idx).sorted_channels;
        if ~isempty(ch)
            valid_datasets(end+1) = selected_datasets(i);
            selected_channels{end+1} = ch;
        else
            warning("Dataset %s has empty channel layout, skipping", selected_datasets(i));
        end
    end
    
    N = length(valid_datasets);
    if N < 2
        error("Need at least 2 datasets with valid channel layouts, got %d", N);
    end
    
    % 初始化结果结构体
    max_k = N;
    tradeoff = struct();
    tradeoff.num_datasets = (2:max_k)';
    tradeoff.max_intersection = zeros(max_k-1, 1);
    tradeoff.min_intersection = zeros(max_k-1, 1);
    tradeoff.mean_intersection = zeros(max_k-1, 1);
    tradeoff.median_intersection = zeros(max_k-1, 1);
    tradeoff.std_intersection = zeros(max_k-1, 1);
    tradeoff.num_combinations = zeros(max_k-1, 1);
    tradeoff.best_combinations = cell(max_k-1, 1);
    tradeoff.best_intersections = cell(max_k-1, 1);
    tradeoff.all_combinations = cell(max_k-1, 1);
    tradeoff.all_intersections = cell(max_k-1, 1);
    
    % 遍历 k = 2..N
    for k = 2:max_k
        combos = nchoosek(1:N, k);
        n_combos = size(combos, 1);
        intersections = zeros(n_combos, 1);
        intersect_details = cell(n_combos, 1);
        combo_names = cell(n_combos, 1);
        
        for c = 1:n_combos
            idx = combos(c, :);
            combo_names{c} = valid_datasets(idx);
            
            inter = selected_channels{idx(1)};
            for j = 2:k
                inter = intersect(inter, selected_channels{idx(j)});
            end
            inter = sort_channels(inter);
            intersections(c) = length(inter);
            intersect_details{c} = inter;
        end
        
        tradeoff.max_intersection(k-1) = max(intersections);
        tradeoff.min_intersection(k-1) = min(intersections);
        tradeoff.mean_intersection(k-1) = mean(intersections);
        tradeoff.median_intersection(k-1) = median(intersections);
        tradeoff.std_intersection(k-1) = std(intersections);
        tradeoff.num_combinations(k-1) = n_combos;
        tradeoff.all_combinations{k-1} = combo_names;
        tradeoff.all_intersections{k-1} = intersect_details;
        
        % 找到达到最大交集的所有组合
        best_idx = find(intersections == tradeoff.max_intersection(k-1));
        best_combos = cell(length(best_idx), 1);
        best_inters = cell(length(best_idx), 1);
        for b = 1:length(best_idx)
            combo_idx = combos(best_idx(b), :);
            best_combos{b} = valid_datasets(combo_idx);
            best_inters{b} = intersect_details{best_idx(b)};
        end
        tradeoff.best_combinations{k-1} = best_combos;
        tradeoff.best_intersections{k-1} = best_inters;
    end
    
    % 绘制 trade-off 曲线
    figure('Name', 'Channel Intersection Trade-off', 'NumberTitle', 'off');
    hold on;
    
    % 主曲线：max / min / mean / median
    h1 = plot(tradeoff.num_datasets, tradeoff.max_intersection, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Max');
    h2 = plot(tradeoff.num_datasets, tradeoff.min_intersection, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Min');
    h3 = plot(tradeoff.num_datasets, tradeoff.mean_intersection, 'g-^', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Mean');
    h4 = plot(tradeoff.num_datasets, tradeoff.median_intersection, 'm-d', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Median');
    
    % 添加 mean ± std 阴影区域（如果 std > 0）
    upper = tradeoff.mean_intersection + tradeoff.std_intersection;
    lower = tradeoff.mean_intersection - tradeoff.std_intersection;
    lower(lower < 0) = 0;
    x_fill = [tradeoff.num_datasets; flipud(tradeoff.num_datasets)];
    y_fill = [upper; flipud(lower)];
    fill(x_fill, y_fill, [0.5 0.8 0.5], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Mean \\\pm STD');
    
    hold off;
    xlabel('Number of Datasets (k)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Intersection Size (channels)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Channel Intersection Trade-off\nDatasets: %s', strjoin(valid_datasets, ', ')), 'FontSize', 11, "Interpreter","none");
    legend([h1, h2, h3, h4], 'Location', 'best', 'FontSize', 10);
    grid on;
    xlim([1.5, N+0.5]);
    ylim([min(tradeoff.min_intersection)-1, max(tradeoff.max_intersection)+1]);
    
    % 打印摘要
    fprintf("\n========================================\n");
    fprintf("  Channel Intersection Trade-off Summary\n");
    fprintf("========================================\n");
    fprintf("Datasets: %s\n", strjoin(valid_datasets, ", "));
    fprintf("Total valid datasets: %d\n\n", N);
    
    fprintf("k |  Max |  Min | Mean | Median |  Std | Combos | Best Combinations\n");
    fprintf("--+------+------+------+--------+------+--------+------------------\n");
    for i = 1:length(tradeoff.num_datasets)
        k = tradeoff.num_datasets(i);
        fprintf("%2d| %4d | %4d | %4.1f | %4d   | %4.1f | %4d   | ", ...
            k, tradeoff.max_intersection(i), tradeoff.min_intersection(i), ...
            tradeoff.mean_intersection(i), tradeoff.median_intersection(i), ...
            tradeoff.std_intersection(i), tradeoff.num_combinations(i));
        for b = 1:length(tradeoff.best_combinations{i})
            fprintf("[%s] ", strjoin(tradeoff.best_combinations{i}{b}, "+"));
        end
        fprintf("\n");
    end
    fprintf("========================================\n\n");
end

%% 用户测试代码（运行文件时不会自动执行，可在命令行手动复制粘贴）
[intersect_layout, union_layout, all_layouts] = channel_summary(["KUL_preprocessed","DTU_preprocessed","KUL-AV-GC_preprocessed","PKU-NBD_preprocessed"]);
disp("Intersection of all datasets:");
disp(intersect_layout);
disp("Number of intersection channels");
disp(length(intersect_layout));
disp("Union of all datasets:");
disp(union_layout);
disp("Number of union channels");
disp(length(union_layout));
% 
% % Trade-off 示例
tradeoff = channel_intersection_tradeoff(["KUL_preprocessed","DTU_preprocessed","KUL-AV-GC_preprocessed","PKU-NBD_preprocessed"]);
