function [h_fig, eval_stats] = plot_estimerr_diff(all_evals_info, cfg)
%PLOT_ESTIMERR_DIFF plots probability of design superiority (CLES) for
%different pairs of designs and under different evaluation priors.
%
% Usage:
%   [h_fig, eval_stats] = plot_estimerr_diff(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_design x 1 cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_ax [axis handle, optional] : Handle into which to plot. If empty
%           a new figure and axis are created.
%       .design_labels [n_design x 1 cell array of strings] : Design labels. 
%       .design_colors [n_design x 1 cell array of RGB vectors] : Colors 
%           associated with each design.
%       .legend_position [left bottom width height; optional] : Position of
%           the in normalized figure coordinates. If ommited, the 'best'
%           location is used.
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_stats [n_prior x n_design_pair struct array]
%       .n_exp [2 x 1] : Number of simulated experiments for both designs.
%       .abs_err [2 x 1 cell] : Absolute parameter estimation errors for
%           both designs.
%       .prob_d1_superior [in [0,1]] : Probability that the first design is
%           superior (i.e. has lower abs. err.).
%       .prob_ci [lower;upper] : Confidence interval on the prob. of
%           superiority.
%       .bootstats [n_boot x 1] : Probability of superiority for all the
%           bootstrap samples.


%% Process all design evaluation files and compute design pair differences in estimation errors
n_prior = size(all_evals_info, 1);
design_pairs = cfg.design_pairs;
n_des_pairs = size(design_pairs);
eval_stats(n_prior, n_des_pairs) = struct(...
    'n_exp', [],...
    'abs_err', [],...
    'prob_d1_superior', [],...
    'prob_ci', [],...
    'bootstats', []);

for i_prior = 1 : n_prior
    for i_pair = 1 : n_des_pairs
        
        % Initialize results for the pair
        abs_err = cell(2,1);
        n_exp = cell(2,1);
        % Iterate over both designs
        for i_des = 1 : 2
            % Get design index
            idx_des = design_pairs{i_pair}(i_des);
             
            % Get current eval info
            eval_info = all_evals_info{i_prior, idx_des};
            
            % Extract parameter estimation signed and absolute errors
            signed_err = ...
                eval_info.results_eval.outputs.loss_info.signed_err;
            abs_err{i_des} = abs(signed_err);
            
            % Get the sample size (number of simulated experiments)
            n_exp{i_des} = numel(signed_err);
        end
        
        % Compute the effect size
        [prob_d1_superior, prob_ci, bootstats] = ...
            cles(abs_err{2}', abs_err{1}', cfg.cles_opts); % The two samples are reversed because the design is superior when its error is smaller
        
        % Collect results
        eval_stats(i_prior,i_pair).n_exp = n_exp;
        eval_stats(i_prior,i_pair).abs_err = abs_err;
        eval_stats(i_prior,i_pair).prob_d1_superior = prob_d1_superior;
        eval_stats(i_prior,i_pair).prob_ci = prob_ci;
        eval_stats(i_prior,i_pair).bootstats = bootstats;
    end
end

%% Arrange data for plotting
bar_input = arrayfun(@(s) s.prob_d1_superior, eval_stats)';

lower_ci = arrayfun(@(s) s.prob_ci(1), eval_stats)';
errorbar_lower = lower_ci - bar_input;

upper_ci = arrayfun(@(s) s.prob_ci(2), eval_stats)';
errorbar_upper = upper_ci - bar_input;


%%  Plot model selection accuracies
% Configuration
prior_labels = cfg.prior_labels;
design_labels = cfg.design_labels;
design_pair_labels = cellfun(@(idxs) sprintf('%s vs. %s', design_labels{idxs(1)}, design_labels{idxs(2)}),...
    cfg.design_pairs, 'UniformOutput', false);
design_pair_colors = cfg.design_pair_colors;

% If the axes handle is given use it, otherwise create a new figure
if isfield(cfg, 'h_ax') && ishandle(cfg.h_ax)
    h_ax = cfg.h_ax;
    h_fig = get(h_ax, 'Parent');
else
    h_fig = figure('Color', 'w', 'Units', 'pixels','Position', [0 0 540 316]);
    movegui(h_fig, 'center')
    h_ax = gca;
end

% Plotting
[~, hb, ~] = errorbar_groups_alt(bar_input*100, errorbar_lower*100, errorbar_upper*100,...
    'FigID', h_fig,...
    'AxID', h_ax,...
    'bar_names', prior_labels,...
    'bar_width', 0.9,...
    'bar_colors', cell2mat(design_pair_colors'),...
    'errorbar_width', 0.8,...
    'optional_bar_arguments',...
        {'LineWidth',1.5},...
    'optional_errorbar_arguments',...
        {'LineStyle','none','Marker','none','LineWidth',1.5, 'CapSize', 12});

set(gca, 'TickDir', 'out')
grid(gca, 'on')
set(gca, 'FontSize', 12)
    
hLin = hline(50, 'k--'); % Reference line at 'no effect' level
set(hLin, 'LineWidth', 1.5)

xlabel('Evaluation prior')
ylabel({'Probability of first design',  'superiority [%]'})

if isfield(cfg, 'legend_position') && ~isempty(cfg.legend_position)
    legend(hb, design_pair_labels, 'Position',  cfg.legend_position)
else
    legend(hb, design_pair_labels, 'Location',  'best')
end


end
