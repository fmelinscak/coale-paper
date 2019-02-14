function [cles_res, cles_ci, bootstat] = cles(sample_1, sample_2, cfg)
%CLES computes the common language effect size for two (unpaired) samples.
%
% Usage:
%   cles_res = cles(sample_1, sample_2, cfg)
%
% Args:
%   sample_1 [n_1 x 1] : Column vector with sample 1 values.
%   sample_2 [n_2 x 1] : Column vector with sample 2 values.
%   cfg [struct] :
%       .method [string] : One of the following options must be used:
%           'brute' : Uses brute force enumeration of all possible pairs
%               between sample data points. (Default)
%           'algebraic' : Uses the algebraic method of McGraw & Wong (1992,
%               Psychological Bulletin).
%       .nboot : Number of bootstrap iterations (required if requesting the
%           CI output)
%       .alpha : Alpha level for the CI calculation (default: 0.05)
%
% Returns:
%   cles_res [in [0,1]] : CLES or the probability of superiority, i.e.
%       probability that in a randomly sampled pair with a data point from each
%       sample, the sample 1 data point will be larger.
%   cles_ci [lower;upper] : Confidence interval
%   bootstat [nboot x 1] : CLES for each bootstrap sample
%
% See also:
%   https://janhove.github.io/reporting/2016/11/16/common-language-effect-sizes
%   https://github.com/janhove/janhove.github.io/blob/master/RCode/CommonLanguageEffectSizes.R


if isfield(cfg, 'method') && ~isempty(cfg.method)
    switch cfg.method
        case 'algebraic'
            cles_fnc = @cles_algeb_fnc;
        case 'brute'
            cles_fnc = @cles_brute_fnc;
        otherwise
            error('Unrecognized CLES method in cfg.method.');
    end
else
    cles_fnc = @cles_brute_fnc; % Default: brute force
end

% Compute the CLES
cles_res = cles_fnc(sample_1, sample_2);

% Compute the CLES bootstrapped CI if requested
if nargout >= 2
    if isfield(cfg, 'nboot') && isnumeric(cfg.nboot) && ~isempty(cfg.nboot)
        nboot = cfg.nboot;
    else
        error('If the cles_ci output is requested, the number of bootstrap iterations cfg.n_boot must be provided.')
    end
    if isfield(cfg, 'alpha')
        alpha = cfg.alpha;
    else
        alpha = 0.05;
    end
    [cles_ci, bootstat] = cles_bootci(nboot, cles_fnc, sample_1, sample_2, alpha);
end

end

function res = cles_brute_fnc(sample_1, sample_2)
% CLES_BRUTE_FNC computes CLES by brute force enumeration of all possible
% pairs of values from both samples.

% Get a matrix with all possible pairs between samples
[X,Y] = meshgrid(sample_1, sample_2);
pairs = [X(:) Y(:)];

% Check where s1 is bigger than s2 (count ties as half true)
s_diff = pairs(:,1) - pairs(:,2);
s1_larger = sum(s_diff > 0) + 0.5*sum(s_diff == 0);

% Return the proportion where s1 is larger
res = s1_larger./numel(s_diff);

end

function res = cles_algeb_fnc(sample_1, sample_2)
% CLES_ALGEB_FNC computes CLES by the algebraic method of
% McGraw & Wong (1992, Psychological Bulletin), i.e. assuming normality.

% Mean difference between s1 and s2
md = (mean(sample_1) - mean(sample_2));

% Standard deviation of difference
stdev = sqrt(var(sample_1) + var(sample_2));

% Probability that s1 is larger than s2
% (under the normality assumption)
% Check where s1 is bigger than s2 (count ties as half true)
res = 1 - normcdf(0, md, stdev);

end

function [cles_ci, bootstat] = cles_bootci(n_boot, cles_func, sample_1, sample_2, alpha)
% CLES_BOOTCI computes the CLES CI by basic percentile bootstrap

pct1 = 100*alpha/2;
pct2 = 100-pct1;

n1 = size(sample_1, 1);
n2 = size(sample_2, 1);
bootstat = nan(n_boot, 1);

for i_boot = 1 : n_boot
    % Get bootstrap samples
    rand_idx1 = randi(n1, n1,1);
    rand_samp1 = sample_1(rand_idx1,1);
    
    rand_idx2 = randi(n2, n2,1);
    rand_samp2 = sample_2(rand_idx2,1);
    
    % Compute CLES
    bootstat(i_boot) = cles_func(rand_samp1, rand_samp2);
end

% Compute CI
lower = prctile(bootstat,pct1,1); 
upper = prctile(bootstat,pct2,1);

% return
cles_ci =[lower;upper];

end
