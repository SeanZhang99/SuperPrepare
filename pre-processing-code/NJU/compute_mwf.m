function [weights, nb_shifted] = compute_mwf(data, mask, delay)
[data_s, nb_shifted] = stack_delayed(data, delay);
Ryy = cov(data_s(:, mask)');
Rnn = cov(data_s(:, ~mask)');

[V, D] = eig(Ryy, Rnn);
[d_sorted, idx] = sort(diag(D), 'descend');
V = V(:, idx);

delta = diag(V' * Ryy * V) - diag(V' * Rnn * V);
rank_w = nb_shifted - sum(delta < 0);
delta(rank_w+1:end) = 0;

eigval_mat = diag(d_sorted);
left = - (eigval_mat' \ V')';
right = - (V' \ diag(delta)')';
weights = left * right;
end