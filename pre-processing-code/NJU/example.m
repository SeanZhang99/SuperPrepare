%% 设置路径
root_path = 'E:\RAW\NJU-15class-Emotiv-AAD\exg\preprocessed_mwf';
subject_list = [2,12, 23];  % 要对比的 subject ID
midline_chans = {'Fz', 'Cz', 'Pz', 'Oz'};
temporal_chans = {'T7', 'T8', 'FT9', 'FT10'};

%% 遍历 subject
for s = 1:length(subject_list)
    subject_id = subject_list(s);
    filepath = fullfile(root_path, sprintf('S%02d.mat', subject_id));
    
    if ~isfile(filepath)
        fprintf('File not found: %s\n', filepath);
        continue
    end
    
    fprintf('Loading subject: S%02d\n', subject_id);
    load(filepath);  % 读取变量 data 和 expinfo
    
    % 获取通道索引
    [~, mid_idx] = ismember(midline_chans, data.dim.chan.eeg{1});
    [~, temp_idx] = ismember(temporal_chans, data.dim.chan.eeg{1});
    
    % 选一个典型 trial（可修改）
    trial_idx = 1;
    eeg = data.eeg{trial_idx}';
    
    t = (0:size(eeg, 2)-1) / data.fsample.eeg;
    figure('Name', sprintf('S%02d Trial %d', subject_id, trial_idx), 'Color','w');
    
    % 中轴区绘图
    subplot(2,1,1);
    plot(t, eeg(mid_idx, :)');
    title(sprintf('S%02d Midline EEG (Trial %d)', subject_id, trial_idx));
    xlabel('Time (s)');
    ylabel('Amplitude (uV)');
    legend(midline_chans, 'Location','northeastoutside');
    grid on;
    
    % 颞叶区绘图
    subplot(2,1,2);
    plot(t, eeg(temp_idx, :)');
    title(sprintf('S%02d Temporal EEG (Trial %d)', subject_id, trial_idx));
    xlabel('Time (s)');
    ylabel('Amplitude (uV)');
    legend(temporal_chans, 'Location','northeastoutside');
    grid on;
    
    % 可选保存
    % saveas(gcf, fullfile(root_path, sprintf('S%02d_T%02d_compare.png', subject_id, trial_idx)));
    % close(gcf);
end
