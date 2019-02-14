function [h_fig, eval_stats] = plot_modsel_confmat(all_evals_info, cfg)
%PLOT_MODSEL_CONFMAT plots model selection confusion matrix across
% different exp. designs that were evaluated. 
%
% Usage:
%   [h_fig, eval_stats] = plot_modsel_confmat(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_design x 1 cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_bgax [axis handle, optional] : Background axis handle into
%           which to plot. If empty, a new figure and axes are created.
%       .design_labels [n_design x 1 cell array of strings] : Design labels. 
%       .model_labels [n_models x 1 cell array of strings] : Model labels.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_stats [n_design x 1 struct array]
%       .n_models [int] : Number of models in evaluation.
%       .n_exp [int] : Number of simulated experiments.
%       .conf_matrix [n_models x n_models] : Confusion matrix with the rows
%           indexing true models and columns indexing fitted models.


%% Process all design evaluation files and collect model selection confusion matrices
n_design_evals = numel(all_evals_info);
eval_stats(n_design_evals) = struct(...
    'n_models', [],...
    'n_exp', [],...
    'conf_matrix', []);

for i_eval = 1 : n_design_evals
    % Get current eval info
    eval_info = all_evals_info{i_eval};

    % Get problem size variables
    curr_n_models = numel(eval_info.model_space); % Number of models
    curr_n_exp = eval_info.sim_run.n_exp; % Number of experiments simulated per model

    % Extract model selection confusion matrix for evaluated design
    conf_matrix = eval_info.results_eval.outputs.loss_info.confusion_matrix;
    
    eval_stats(i_eval).n_models =  curr_n_models;
    eval_stats(i_eval).n_exp =  curr_n_exp;
    eval_stats(i_eval).conf_matrix =  conf_matrix;
end

% Validate inputs
all_n_exp = [eval_stats.n_exp];
if any(diff(all_n_exp))
    warning('Number of experiments inconsistent between evaluation results.')
end

all_n_models = [eval_stats.n_models];
if any(diff(all_n_models))
    error('Number of models inconsistent between evaluation results. Unable to plot comparison.')
else
    n_models = all_n_models(1);
end


%%  Plot model selection confusion matrices
% Configuration
model_labels = cfg.model_labels;
design_labels = cfg.design_labels;

% If the axes handle is given use it, otherwise create a new figure
if isfield(cfg, 'h_bgax') && ishandle(cfg.h_bgax)
    h_bgax = cfg.h_bgax;
    h_fig = get(h_bgax, 'Parent');
else
    h_fig = figure('Color', 'w');
    movegui(h_fig, 'center')
    h_bgax = axes( 'Position', [0, 0, 1, 1],...
        'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0, 1], 'YLim', [0, 1] ) ;
end

% Calculate the offsets of the subplots (relative to the figure) and the
% widths and heights (in figure coordinates)
bg_x = h_bgax.Position(1);
bg_y = h_bgax.Position(2);
bg_w = h_bgax.Position(3);
bg_h = h_bgax.Position(4);
margin_left = 0.01;
margin_right = 0.05;
margin_bottom = 0;
margin_top = 0.01;
x_offset = bg_x + margin_left*bg_w;
y_offset = bg_y + margin_bottom*bg_h;
inner_w = (1-margin_left-margin_right)*bg_w;
inner_h = (1-margin_bottom-margin_top)*bg_h;
ax_w = inner_w / n_design_evals;
ax_h = inner_h;

% Plotting
for i_eval = 1 : n_design_evals
    curr_eval_stats = eval_stats(i_eval);
    conf_matrix = curr_eval_stats.conf_matrix;
    n_exp = curr_eval_stats.n_exp;

    % Create axis
    ax_x = x_offset + (i_eval-1) * ax_w;
    ax_y = y_offset;
    h_ax = axes('OuterPosition',[ax_x, ax_y, ax_w, ax_h],...
        'Position', [ax_x+0.1*ax_w, ax_y+0*ax_h, 0.9*ax_w, 1*ax_h]);
    
    % Plot confmat
    imagesc(conf_matrix./n_exp, [0, 1]);
    axis image
    set(h_ax, 'XTick', [], 'YTick', [])
        
    title(design_labels{i_eval})

end

colormap(cbrewer('seq', 'Reds', 64, 'pchip'))

end



