function [data_s, nb_shifted] = stack_delayed(data, delay)
[nb_channels, time] = size(data);
nb_shifted = (2*delay + 1) * nb_channels;
data_s = zeros(nb_shifted, time);

for tau = -delay:delay
    idx_start = (tau + delay)*nb_channels + 1;
    idx_end = idx_start + nb_channels - 1;
    shifted = circshift(data, [0, tau]);
    if tau > 0
        shifted(:, 1:tau) = 0;
    elseif tau < 0
        shifted(:, end+tau+1:end) = 0;
    end
    data_s(idx_start:idx_end, :) = shifted;
end
end