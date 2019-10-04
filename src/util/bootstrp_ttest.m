function [p_val,t_actual,t_bootsam] = bootstrp_ttest(x,y,nboot)
% Bootstrapped t-test implemented according to Algorithm 16.2 from (Efron &
% Tibshirani, 1994)

[~,~,~,stats] = ttest2(x, y, 'Vartype', 'unequal');
t_actual = stats.tstat;

mu_combined = mean([x;y]);
x_adj = x - mean(x) + mu_combined;
n_x = size(x_adj, 1);
y_adj = y - mean(y) + mu_combined;
n_y = size(y_adj, 1);

t_bootsam = nan(nboot, 1);
for i = 1 : nboot
    x_samp = randsample(x_adj, n_x, true); % Sample w/ replacement
    y_samp = randsample(y_adj, n_y, true); % Sample w/ replacement
    [~,~,~,stats] = ttest2(x_samp, y_samp, 'Vartype', 'unequal');
    t_bootsam(i) = stats.tstat;
end

p_val = mean(t_bootsam >= t_actual);

end

