function [filtered, artifacts] = apply_mwf(data, weights)
[channels, time] = size(data);
nb_weights = size(weights, 1);
tau = (nb_weights - channels) / (2 * channels);
mean_data = mean(data, 2);
data_centered = data - mean_data;

[data_s, ~] = stack_delayed(data_centered, tau);
orig_chans = (tau*channels+1):(tau+1)*channels;
artifacts = weights(orig_chans,:) * data_s;
filtered = data_centered - artifacts;
filtered = filtered + mean_data;
end