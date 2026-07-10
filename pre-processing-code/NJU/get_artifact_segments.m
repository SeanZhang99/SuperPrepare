function mask = get_artifact_segments(data, fs, ref_chans)
ref = sum(data(:, ref_chans).^2, 2);
threshold = 5 * mean(ref);
mask = ref > threshold;

indices = find(mask);
window_len = round(fs / 2);
for i = 1:length(indices)
    idx = indices(i);
    start_idx = max(1, idx - window_len);
    end_idx = min(size(data,1), idx + window_len);
    mask(start_idx:end_idx) = true;
end
end

