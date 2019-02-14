function [h_fig, eval_stats] = plot_prior_des_err(all_evals_info, cfg)
%PLOT_PRIOR_DES_ERR plots absolute parameter estimation error across
%different evaluation priors and designs.
%
% Usage:
%   [h_fig, eval_stats] = plot_prior_des_err(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_prior x n_dessign cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_ax [axis handle, optional] : Handle into which to plot. If empty
%           a new figure and axis are created.
%       .prior_labels [n_prior x 1 cell array of strings] : Evaluation
%           priors labels.
%       .design_labels [n_design x 1 cell array of strings] : Design labels. 
%       .design_colors [n_design x 1 cell array of RGB vectors] : Colors 
%           associated with each design.
%       .legend_position [left bottom width height; optional] : Position of
%           the in normalized figure coordinates. If ommited, the 'best'
%           location is used.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_stats [n_prior x n_design struct array]
%       .n_exp [int] : Number of simulated experiments.
%       .signed_err [1 x n_exp] : Signed parameter estimation errors.
%       .abs_err [1 x n_exp] : Absolute parameter estimation errors.
%       

%% Process all design evaluation files and collect estimation errors
[n_prior, n_des] = size(all_evals_info);
eval_stats(n_prior, n_des) = struct(...
    'n_exp', [],...
    'signed_err', [],...
    'abs_err', []);

for i_prior = 1 : n_prior
    for i_des = 1 : n_des
        % Get current eval info
        eval_info = all_evals_info{i_prior, i_des};
        
        % Extract parameter estimation signed and absolute errors
        signed_err = ...
            eval_info.results_eval.outputs.loss_info.signed_err;
        abs_err = abs(signed_err);
        
        % Get the sample size (number of simulated experiments)
        n_exp = numel(signed_err);
        
        % Collect variables
        eval_stats(i_prior, i_des).n_exp = n_exp;
        eval_stats(i_prior, i_des).signed_err = signed_err;
        eval_stats(i_prior, i_des).abs_err = abs_err;
    end
end

% Validate inputs
all_n_exp = [eval_stats.n_exp];
if any(diff(all_n_exp(:)))
    warning('Number of experiments inconsistent between evaluation results.')
end

%% Arrange data for plotting
all_abs_err = cell(n_prior*n_des, 1);
all_prior_labels = cell(n_prior*n_des, 1);
all_des_labels = cell(n_prior*n_des, 1);


i_eval = 0;
for i_prior = 1 : n_prior
    for i_des = 1 : n_des
        i_eval = i_eval + 1;
        all_abs_err{i_eval} = eval_stats(i_prior, i_des).abs_err';
        curr_n_exp = eval_stats(i_prior, i_des).n_exp;
        all_prior_labels{i_eval} = repmat(cfg.prior_labels(i_prior),...
            curr_n_exp, 1);
        all_des_labels{i_eval} = repmat(cfg.design_labels(i_des),...
            curr_n_exp, 1);
    end
end

% Concatenate all the cells into a single column vector
all_abs_err = vertcat(all_abs_err{:});
all_prior_labels = vertcat(all_prior_labels{:});
all_des_labels = vertcat(all_des_labels{:});

% Mutate data into format necessary for iosr.statistics.boxPlot
[y,x,g] = iosr.statistics.tab2box(...
    all_prior_labels,... % x-axis
    all_abs_err,... % y-axis
    all_des_labels); % grouping variable

% The ordering of x and g is based on alphabetical sorting
% Sort the x values (priors) and the group values (designs)
order_x = cellfun(@(s) find(strcmpi(s, x)), cfg.prior_labels);
x = x(order_x);
y = y(:, order_x, :);

order_g = cellfun(@(s) find(strcmpi(s, g{1})), cfg.design_labels);
g = g{1}(order_g);
y = y(:, :, order_g);

%%  Plot model selection accuracies
% Configuration
design_colors = cfg.design_colors;
design_labels = cfg.design_labels;

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
axes(h_ax) % Set axis
h_sub = iosr.statistics.boxPlot(x,y,...
    'boxColor','none','medianColor', 'k',...
    'showScatter',true, 'scatterColor', design_colors,...
    'scatterLayer', 'bottom', 'scatterAlpha', 0.75,...
    'scatterSize', 20, 'scatterMarker', '.',...
    'symbolColor', design_colors, 'symbolMarker', '*',...
    'outlierSize', 20,...
    'xseparator',true,...
    'lineWidth', 1.5,...
    'groupLabels',g,'showLegend',false);

% Customize plot
xlabel('Evaluation prior')
ylabel('Absolute estimation error')
set(h_sub.handles.axes(1), 'TickDir', 'out')
set(gca, 'FontSize', 12)

if isfield(cfg, 'legend_position') && ~isempty(cfg.legend_position)
    h_lgnd = legend(h_sub.handles.outliers(1,1,:), design_labels,...
        'Position', cfg.legend_position);
else
    h_lgnd = legend(h_sub.handles.outliers(1,1,:), design_labels,...
        'Location', 'best');
end
title(h_lgnd, 'Design')

end
