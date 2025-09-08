function eeg_filtered = artifact_removal_mwf(eeg, fs, reference_channels, delay)
% artifact_removal_mwf - Remove EEG artifacts using Multi-channel Wiener Filter
%
% Inputs:
%   eeg                - EEG matrix (channels x time)
%   fs                 - Sampling frequency
%   reference_channels - Array of channel indices used as artifact reference
%   delay              - Temporal delay (e.g., 3)
%
% Output:
%   eeg_filtered       - EEG matrix after artifact removal

if nargin < 3
    reference_channels = [1,2,3,33,34,35,36,37]; % MATLAB is 1-indexed
end
if nargin < 4
    delay = 3;
end

eeg = double(eeg);  % Ensure double precision
data = eeg';
mask = get_artifact_segments(data, fs, reference_channels);
[mwf_weights, nb_shifted_channels] = compute_mwf(eeg, mask, delay);
[eeg_filtered, ~] = apply_mwf(eeg, mwf_weights);

end
