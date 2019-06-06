function [h_fig, eval_modout] = plot_modout(all_evals_info, cfg)
%PLOT_MODOUT plots responses of a pair of models for all the designs and
%under both models assumed true for evaluation.
%
% Usage:
%   [h_fig, eval_modout] = plot_modout(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_design x 1 cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_bgax [axis handle, optional] : Background axis handle into
%           which to plot. If empty, a new figure and axes are created.
%       .input_patterns [1 x n_patterns cell array] : Each cell holds a row
%           vector of length n_features indicating the values of each feature   
%       .model_pair [1 x 2] : Indices of two models selected for
%           visualization.
%       .model_labels [n_prior x 1 cell array of strings] : Labels of
%           selected models.
%       .design_labels [n_design x 1 cell array of strings] : Design labels.
%       .cue_labels [n_patterns x 1 cell array of strings] : Cue labels.
%       .cue_colors [n_patterns x 1 cell array of RGB vectors] : Colors 
%           associated with each input pattern.
%       .linestyle_truemod [LineStyle string] : Line style for the response
%           trace of the fitted true model.
%       .linestyle_truemod [LineStyle string] : Line style for the response
%           trace of the fitted alternative model
%       .n_trials_stage [1 x n_stage array] : Number of trials for each
%           stage.
%       .x_ticks [1 x n_tick array] : Positions of x-ticks in trials.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_modout [n_design x 1 struct array]
%       .n_exp [int] : Number of simulated experiments.
%       .n_trials [int] : Number of simulated trials per experiment.
%       .modout_all [n_trials x n_patterns x n_exp] : Trial-resolved 
%           response trace.
%       .modout_avg [n_trials x n_patterns] : Trial-resolved response 
%           trace average.


%% Process all design evaluation files and collect model outputs
n_design_evals = numel(all_evals_info);
input_patterns = cfg.input_patterns;
n_input_pats = numel(input_patterns);
eval_modout(n_design_evals) = struct(...
    'n_exp', [],...
    'n_trials', [],...
    'modout_all', [],...
    'modout_avg', [],...
    'bic_avg', [],...
    'bic_diff_true_alt_avg', [],...
    'bic_diff_true_alt_sem', []);

for i_eval = 1 : n_design_evals
    % Get current eval info
    eval_info = all_evals_info{i_eval};
    fitting_results = eval_info.results_eval.outputs.fitting_results;
    model_space = eval_info.model_space;
    n_exp = eval_info.sim_run.n_exp; % Number of experiments simulated per model
    n_trials = eval_info.results_eval.outputs.data(1).nTrials;
    
    % Calculate outputs for given input patterns and true-fitted model
    % combinations (and the BICs)
    input_pat_trialwise = cellfun(...
        @(pat) repmat(pat, n_trials, 1),...
        input_patterns, ...
        'UniformOutput', false);
    modout_all = cell(2, 2); % All model outputs
    modout_avg = cell(2, 2); % Outputs averaged over exprmnts
    
    bic_all = cell(2, 2); % All model BICs
    bic_avg = nan(2, 2); % Model BICs averaged over experiments
    bic_std = nan(2, 2); % SEM of the BICs (over experiments)
    bic_diff_true_alt_avg = nan(1, 2); % Diff. avg. between the true and
                                       % alternative model BIC 
                                       % (under both ground truth models)
    bic_diff_true_alt_sem = nan(1, 2); % Std. err. of the mean difference
    
    for i_model_sim_pair = 1 : 2 % True model
        for i_model_fit_pair = 1 : 2 % Alternative model
            % Get original model indices
            i_model_sim = cfg.model_pair(i_model_sim_pair);
            i_model_fit = cfg.model_pair(i_model_fit_pair);
            
            % Initialize outputs results for all input patterns
            modout_all{i_model_sim_pair, i_model_fit_pair} = ...
                nan(n_trials, n_input_pats, n_exp);
            
            % Initialize model BIC for all experiments
            bic_all{i_model_sim_pair, i_model_fit_pair} = ...
                nan(1, n_exp);
            
            % Loop over experiments
            for i_exp = 1 : n_exp
                curr_fitting_results = ...
                    fitting_results{i_model_sim}(i_exp, i_model_fit);
                
                % Get latent variables and params of the fitted model
                latents = curr_fitting_results.latents;
                params = unpack_params(curr_fitting_results.x,...
                    curr_fitting_results.param);
                
                % If fixed params exist, merge them to fitted parameters
                if isfield(model_space{i_model_fit}, 'params_fit_fixed') ...
                        && isstruct(model_space{i_model_fit}.params_fit_fixed)
                    params = merge_params(...
                        params, model_space{i_model_fit}.params_fit_fixed);
                end
                
                % Get observation function of the fitted model
                obs_func_batch = ...
                    str2func(eval_info.model_space{i_model_fit}.obs_func);
                
                % Compute what outputs would be observed for each cue on each
                % trial
                modout_exp = nan(n_trials, n_input_pats);
                for i_pat = 1 : n_input_pats
                    curr_input_pat = input_pat_trialwise{i_pat};
                    obs_func_out = obs_func_batch(...
                        latents.evo, curr_input_pat, [], params.obs);
                    modout_exp(:, i_pat) = obs_func_out.crPred;
                end
                
                % Store outputs of the experiment
                modout_all{i_model_sim_pair, i_model_fit_pair}(:, :, i_exp) =...
                    modout_exp;
                
                % Get model BIC of the experiment
                bic_all{i_model_sim_pair, i_model_fit_pair}(i_exp) = ...
                    curr_fitting_results.bic;
                
            end
            
            % Average responses over experiments using a trim mean
            modout_avg{i_model_sim_pair, i_model_fit_pair} =...
                trimmean(modout_all{i_model_sim_pair, i_model_fit_pair}, 10, 3);
            
            % Summarize BICs over experiments
            bic_avg(i_model_sim_pair, i_model_fit_pair) = ...
                mean(bic_all{i_model_sim_pair, i_model_fit_pair});
            bic_std(i_model_sim_pair, i_model_fit_pair) = ...
                std(bic_all{i_model_sim_pair, i_model_fit_pair});         
        end
        
        % Summarize BIC difference betweeen the true and alternative model
        if i_model_sim_pair == 1
            bic_diff_true_alt_avg(1) = bic_avg(1,1) - bic_avg(1,2);
            bic_diff_true_alt_sem(1) = ...
                sqrt((bic_std(1,1).^2 + bic_std(1,2).^2)/n_exp);
        else
            bic_diff_true_alt_avg(2) = bic_avg(2,2) - bic_avg(2,1);
            bic_diff_true_alt_sem(2) = ...
                sqrt((bic_std(2,2).^2 + bic_std(2,1).^2)/n_exp);
        end
    end
    
    eval_modout(i_eval).n_exp = n_exp;
    eval_modout(i_eval).n_trials = n_trials;
    eval_modout(i_eval).modout_all = modout_all;
    eval_modout(i_eval).modout_avg = modout_avg;
    eval_modout(i_eval).bic_all = bic_all;
    eval_modout(i_eval).bic_avg = bic_avg;
    eval_modout(i_eval).bic_diff_true_alt_avg = bic_diff_true_alt_avg;
    eval_modout(i_eval).bic_diff_true_alt_sem = bic_diff_true_alt_sem;
end

%%  Plot average model outputs
% Configuration
cue_linecolors = cfg.cue_colors;
linestyle_truemod = cfg.linestyle_truemod;
linestyle_altmod = cfg.linestyle_altmod;
x_ticks = cfg.x_ticks;
model_labels = cfg.model_labels;
design_labels = cfg.design_labels;
cue_labels = cfg.cue_labels;
n_trials_stage = cfg.n_trials_stage;
n_stages = numel(n_trials_stage);
bic_pos = cfg.bic_pos;

% If the axes handle is given use it, otherwise create a new figure
if isfield(cfg, 'h_bgax') && ishandle(cfg.h_bgax)
    h_bgax = cfg.h_bgax;
    h_fig = get(h_bgax, 'Parent');
else
    h_fig = figure('Color', 'w',...
        'Units', 'pixels',...
        'Position', [0 0 851.6129  775.4601]);
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
margin_left = 0.08;
margin_right = 0;
margin_bottom = 0.2;
margin_top = 0.05;
x_offset = bg_x + margin_left*bg_w;
y_offset = bg_y + margin_bottom*bg_h;
inner_w = (1-margin_left-margin_right)*bg_w;
inner_h = (1-margin_bottom-margin_top)*bg_h;
ax_w = inner_w / 2;
ax_h = inner_h / n_design_evals;

% Iterate over all designs
for i_eval = 1 : n_design_evals
    % Get data for plotting
    curr_modout_avg = eval_modout(i_eval).modout_avg;
    curr_n_trials = eval_modout(i_eval).n_trials;
    curr_bic_diff_true_alt_avg = eval_modout(i_eval).bic_diff_true_alt_avg;
    curr_bic_diff_true_alt_sem = eval_modout(i_eval).bic_diff_true_alt_sem;
    
    % Plot two subplots for each model being assumed true
    for i_model_sim_pair = 1 : 2
        if i_model_sim_pair == 1
            i_model_true = 1;
            i_model_alt = 2;
        else
            i_model_true = 2;
            i_model_alt = 1;
        end
%         h_sub = subplot(n_design_evals, 2, (i_eval-1)*2 + i_model_sim_pair);
        
        % Create axis
        ax_x = x_offset + (i_model_sim_pair-1) * ax_w;
        ax_y = y_offset + (n_design_evals - i_eval) * ax_h;
        h_ax = axes('OuterPosition',[ax_x, ax_y, ax_w, ax_h],...
            'Position', [ax_x+0.05*ax_w, ax_y+0.05*ax_h, 0.9*ax_w, 0.9*ax_h]);

        hold on
        % Plot the fitted response of the true model
        h_true = plot(curr_modout_avg{i_model_sim_pair,i_model_true}, ...
            'LineStyle', linestyle_truemod, 'LineWidth', 1.5);
        set(h_true, {'Color'}, cue_linecolors');
        
        % Plot the fitted response of the alternative model
        h_alt = plot(curr_modout_avg{i_model_sim_pair,i_model_alt},...
            'LineStyle', linestyle_altmod, 'LineWidth', 1.5);
        set(h_alt, {'Color'}, cue_linecolors');
        
        % Normalize responses to [0, 1] interval
        response_data = arrayfun(@(c) c.YData, h_ax.Children,...
            'UniformOutput', false);
        max_y = max(cellfun(@(c) max(c), response_data));
        min_y = min(cellfun(@(c) min(c), response_data));
        norm_response_data = cellfun(@(r) (r-min_y)./(max_y-min_y),...
            response_data, 'UniformOutput', false);
        set(h_ax.Children, {'YData'}, norm_response_data)
        
        
        % Subplot customization
        xlim([0, curr_n_trials])
        set(h_ax, 'XTick', x_ticks)
        ylim([0, 1])
        set(h_ax, 'YTick', [])
        set(h_ax, 'TickDir', 'out')
        
        % Plot stage label and divider
        for i_stage = 1 : n_stages
            % Plot the stage label only if this is one of the top row subplots
            if i_eval == 1
                ax_x = sum(n_trials_stage(1:i_stage-1)) + n_trials_stage(i_stage)/2;
                ax_y = 1.08;
                str = sprintf('Stage %d', i_stage);
                text(ax_x, ax_y, str,... 
                    'HorizontalAlignment', 'center',...
                    'FontSize', 10)
            end
            
            % If it's not the last stage, create a divider
            if i_stage < n_stages
                vline(sum(n_trials_stage(1:i_stage)), 'k--')
            end
        end
        
        % Display BIC summary
        ax_x = bic_pos(i_eval, i_model_sim_pair).x;
        ax_y = bic_pos(i_eval, i_model_sim_pair).y;
        str = sprintf('\\DeltaBIC = %.1f \\pm %.1f', ...
            curr_bic_diff_true_alt_avg(i_model_sim_pair),...
            curr_bic_diff_true_alt_sem(i_model_sim_pair));
            
        text(ax_x, ax_y, str,... 
                    'HorizontalAlignment', 'center',...
                    'FontSize', 9)

        % Plot design label and ylabel if this is the first plot in the row
        if i_model_sim_pair == 1 
            des_str = sprintf('\\bf\\fontsize{12}Design: %s', design_labels{i_eval});
            ylabel({des_str, '\rm\fontsize{12}Response [a.u.]'})
        end
        
        % Plot xlabel and x_ticks if it's the last row
        if i_eval == n_design_evals
            xlabel('Trial', 'FontSize', 10)
        else % Otherwise delete x-tick labels
            set(h_ax, 'XTickLabel', {})
        end
        
        % Plot title if this is one of the top row subplots
        if i_eval == 1
            str = sprintf('True model: %s', model_labels{i_model_sim_pair});
            h_title = title(str);
            % Move the title up to make room for the stage annotation
            title_pos = get(h_title, 'Position');
            set(h_title,'Position',title_pos + [0 0.1 0],...
                'FontSize', 12)
        end
        
        set(h_ax, 'FontSize', 12)
        hold off
    end
end

% Legend
h_lgnd = gridlegend_alt(h_ax,...
    strcat({'CS '}, cue_labels),...
    {'True\newlinemodel', 'Alternative\newline   model'},...
    'Alignment', {'center', 'center'},...
    'FontSize', 10,...
    'Box', 'on');

set(h_lgnd, 'Units', 'normalized')
w_legend = h_lgnd.Position(3);
h_legend = h_lgnd.Position(4);
x_legend = x_offset + 0.5*inner_w - 0.5*w_legend;
y_legend = bg_y + 0.01*bg_h;

set(h_lgnd, 'Position', [x_legend, y_legend, w_legend, h_legend])
end
