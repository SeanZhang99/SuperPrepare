function eeg_out = interpolate_artifacts(eeg, threshold)
% interpolate_artifacts - Linearly interpolates large EEG spikes
%
% Inputs:
%   eeg       - EEG matrix (channels x time)
%   threshold - Amplitude threshold for artifact detection (e.g., 500 uV)
%
% Outputs:
%   eeg_out   - EEG after interpolation

eeg_out = eeg;
[num_channels, num_samples] = size(eeg);

for ch = 1:num_channels
    artifact_indices = abs(eeg(ch, :)) > threshold;
    concat = [0, artifact_indices, 0];
    diff_mask = diff(concat);
    start_indices = find(diff_mask == 1);
    stop_indices = find(diff_mask == -1);
    
    for i = 1:length(start_indices)
        start_idx = start_indices(i);
        stop_idx = stop_indices(i);
        if stop_idx - start_idx > 1
            % Linear interpolation between start and stop
            y_start = eeg(ch, start_idx);
            y_end = eeg(ch, stop_idx);
            eeg_out(ch, start_idx+1:stop_idx-1) = linspace(y_start, y_end, stop_idx - start_idx - 1);
        end
    end
end

end
