function [h_fig, eval_stats] = plot_modsel_acc(all_evals_info, cfg)
%PLOT_MODSEL_ACC plots model selection accuracy (per model and average)
% across different exp. designs that were evaluated. 
%
% Usage:
%   [h_fig, eval_stats] = plot_modsel_acc(all_evals_info, cfg)
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
%       .model_labels [n_models x 1 cell array of strings] : Model labels.
%       .xlab_position [x-coord y-ccord] : Position of the x-axis label.
%       .legend_position [left bottom width height; optional] : Position of
%           the in normalized figure coordinates. If ommited, the 'best'
%           location is used.
%       .show_title [bool] : Whether to display the title above the plot.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_stats [n_design x 1 struct array]
%       .n_models [int] : Number of models in evaluation.
%       .n_exp [int] : Number of simulated experiments.
%       .modsel_acc [n_models x 1] : Model selection accuracy (for each ground truth
%           model).
%       .modsel_acc_ci [n_models x 2; low, hi] : 95% CI on model selection accuracies.
%       .modsel_acc_avg [scalar] : Average model selection accuracy.
%       .modsel_acc_avg_ci [1 x 2; low, hi] : 95% CI on avg. model selection accuracy.


%% Process all design evaluation files and collect model selection accuracies
n_design_evals = numel(all_evals_info);
eval_stats(n_design_evals) = struct(...
    'n_models', [],...
    'n_exp', [],...
    'modsel_acc', [],...
    'modsel_acc_ci', [],...
    'modsel_acc_avg', [],...
    'modsel_acc_avg_ci', []);

for i_eval = 1 : n_design_evals
    % Get current eval info
    eval_info = all_evals_info{i_eval};

    % Get problem size variables
    curr_n_models = numel(eval_info.model_space); % Number of models
    curr_n_exp = eval_info.sim_run.n_exp; % Number of experiments simulated per model

    % Extract model selection accuracies for evaluated design
    adjusted_conf_matrix = eval_info.results_eval.outputs.loss_info.adjusted_conf_matrix;

    % Compute the model-wise selection accuracies and CIs for the design
    [modsel_acc, modsel_acc_ci] = binofit(diag(adjusted_conf_matrix), curr_n_exp);
    [modsel_acc_avg, modsel_acc_avg_ci] = binofit(sum(diag(adjusted_conf_matrix)),curr_n_exp*curr_n_models);
    
    eval_stats(i_eval) = struct(...
        'n_models', curr_n_models,...
        'n_exp', curr_n_exp,...
        'modsel_acc', modsel_acc,...
        'modsel_acc_ci', modsel_acc_ci,...
        'modsel_acc_avg', modsel_acc_avg,...
        'modsel_acc_avg_ci', modsel_acc_avg_ci);
end

% Validate inputs
all_n_exp = [eval_stats.n_exp];
if any(diff(all_n_exp))
    warning('Number of experiments inconsistent between evaluation results. Using average number in plot.')
    n_exp = mean(all_n_exp);
else
    n_exp = all_n_exp(1);
end

all_n_models = [eval_stats.n_models];
if any(diff(all_n_models))
    error('Number of models inconsistent between evaluation results. Unable to plot comparison.')
else
    n_models = all_n_models(1);
end

%% Arrange data for plotting
bar_input = [eval_stats.modsel_acc; nan(1, n_design_evals)]';
bar_input_avg = [nan(n_models, n_design_evals); eval_stats.modsel_acc_avg]';

lower_ci = arrayfun(@(s) s.modsel_acc_ci(:,1), eval_stats, 'UniformOutput', false);
errorbar_lower = [lower_ci{:}; nan(1, n_design_evals)]' - bar_input;

upper_ci = arrayfun(@(s) s.modsel_acc_ci(:,2), eval_stats, 'UniformOutput', false);
errorbar_upper = [upper_ci{:}; nan(1, n_design_evals)]' - bar_input;

lower_ci_avg = arrayfun(@(s) s.modsel_acc_avg_ci(1), eval_stats, 'UniformOutput', false);
errorbar_lower_avg = [nan(n_models, n_design_evals); lower_ci_avg{:}]' - bar_input_avg;

upper_ci_avg = arrayfun(@(s) s.modsel_acc_avg_ci(2), eval_stats, 'UniformOutput', false);
errorbar_upper_avg = [nan(n_models, n_design_evals); upper_ci_avg{:}]' - bar_input_avg;

%%  Plot model selection accuracies
% Configuration
design_colors_light = cellfun(...
    @(c) brighten(hsv2rgb([1 0.5 1] .* rgb2hsv(c)), 0.3),...
    cfg.design_colors,...
    'UniformOutput', false);

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
[~, hb, he] = errorbar_groups_alt(bar_input*100, errorbar_lower*100, errorbar_upper*100,...
    'FigID', h_fig,...
    'AxID', h_ax,...
    'bar_names', {cfg.model_labels{:}, '\bf     Average \newline over models'},...
    'bar_width', 0.9,...
    'errorbar_width', 0.8,...
    'optional_bar_arguments',...
        {'LineWidth',1.5},...
    'optional_errorbar_arguments',...
        {'LineStyle','none','Marker','none','LineWidth',1.5});
    
[~, hb_avg, he_avg] = errorbar_groups_alt(bar_input_avg*100, errorbar_lower_avg*100, errorbar_upper_avg*100,...
    'bar_names', {cfg.model_labels{:}, '\bf     Average \newline over models'},...
    'bar_width', 0.9,...
    'errorbar_width', 0.8,...
    'optional_bar_arguments',...
        {'LineWidth',1.5},...
    'optional_errorbar_arguments',...
        {'LineStyle','none','Marker','none','LineWidth',1.5},...
    'FigID', gcf,...
    'AxID', gca,...
    'clear_axis', false);

% Customize plot
for i_eval = 1 : n_design_evals
    set(hb(i_eval), 'FaceColor', design_colors_light{i_eval})
    set(he(i_eval), 'CapSize', 12)
    set(hb_avg(i_eval), 'FaceColor', cfg.design_colors{i_eval})
    set(he_avg(i_eval), 'CapSize', 12)
end

    
set(gca, 'TickDir', 'out')
grid(gca, 'on')
    
hLin = hline(1./n_models * 100, 'k--'); % Reference line at chance level
set(hLin, 'LineWidth', 1.5)

xlabel('True model', 'Position', cfg.xlab_position)
ylabel({'Model selection accuracy', '(with 95% CI)'})

if isfield(cfg, 'legend_position') && ~isempty(cfg.legend_position)
    legend(hb, cfg.design_labels, 'Position',  cfg.legend_position)
else
    legend(hb, cfg.design_labels, 'Location',  'best')
end

if cfg.show_title
    title(sprintf('Probability of selecting the true model\n(%d simulations per model)', n_exp))
end

set(gca, 'FontSize', 11)


end



