function [h_fig, eval_modout] = plot_modout_periodic(all_evals_info, cfg)
%PLOT_MODOUT_PERIODIC plots model responses to the single cue periodic
%design and the contingency trace.
%
% Usage:
%   [h_fig, eval_modout] = plot_modout_periodic(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_design x 1 cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_bgax [axis handle, optional] : Background axis handle into
%           which to plot. If empty, a new figure and axes are created.
%       .input_patterns [1 x n_patterns cell array] : Each cell holds a row
%           vector of length n_features indicating the values of each feature   
%       .prior_selection [1 x n_prior_sel] : Array of indices of priors
%           selected for visualization.
%       .prior_labels [n_prior x 1 cell array of strings] : All prior labels. 
%       .design_labels [n_design x 1 cell array of strings] : Design labels.
%       .cue_colors [n_patterns x 1 cell array of RGB vectors] : Colors 
%           associated with each input pattern.
%       .cont_linecolors [cell array with one RGB vector] : Color of the
%           contingency trace.
%       .linestyle_output [LineStyle string] : Line style for the response
%           trace.
%       .linestyle_cont [LineStyle string] : Line style for the contingency
%           trace.
%       .x_ticks [1 x n_tick array] : Positions of x-ticks in trials.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_modout [n_design x 1 struct array]
%       .n_exp [int] : Number of simulated experiments.
%       .n_trials [int] : Number of simulated trials per experiment.
%       .us_prob_trace [n_trials x 1] : P(US|CS) trial-resolved trace.
%       .modout_all [n_trials x n_patterns x n_exp] : Trial-resolved 
%           response trace.
%       .modout_avg [n_trials x n_patterns] : Trial-resolved response 
%           trace average.


%% Process all design evaluation files and collect model outputs and
% design variables
input_patterns = cfg.input_patterns;
n_input_pats = numel(input_patterns);
[n_prior, n_des] = size(all_evals_info);
eval_modout(n_prior, n_des) = struct(...
    'n_exp', [],...
    'n_trials', [],...
    'us_prob_trace', [],...
    'modout_all', [],...
    'modout_avg', []);


for i_prior = 1 : n_prior
    for i_des = 1 : n_des
        % Get current eval info
        eval_info = all_evals_info{i_prior, i_des};
        fitting_results = eval_info.results_eval.outputs.fitting_results;
        model_space = eval_info.model_space;
        n_exp = eval_info.sim_run.n_exp; % Number of experiments simulated per model
        n_trials = eval_info.results_eval.outputs.data(1).nTrials;
        
        % Get design variables
        desvars = eval_info.exp_design.desvars;
        if isfield(desvars, 'halfPeriod')
            half_period = desvars.halfPeriod;
        elseif isfield(desvars, 'halfPeriodFrac')
            half_period = max(1, round(desvars.halfPeriodFrac * n_trials)); % Make sure the halfperiod is not smaller than 1 trial
        end
        us_prob_first = desvars.usProbFirst;
        us_prob_second = desvars.usProbSecond;
        
        % Get contingency trace

        us_prob_one_period = [... % One period of contingencies
            repmat(us_prob_first, half_period, 1);
            repmat(us_prob_second, half_period, 1)];
        us_prob_long = repmat(us_prob_one_period,...
            ceil(n_trials/(2*half_period)), 1); % Generate the US probabilities covering all trials
        us_prob_trace = us_prob_long(1:n_trials); % Take only n_trials values
        
        % Initialize inputs for all trials
        input_pat_trialwise = cellfun(...
            @(pat) repmat(pat, n_trials, 1),...
            input_patterns, ...
            'UniformOutput', false);
  
        % Initialize outputs results for all input patterns
        modout_all = nan(n_trials, n_input_pats, n_exp); % All model outputs

        % Calculate outputs for given input patterns and true-fitted model
        % combinations
        for i_exp = 1 : n_exp
            curr_fitting_results = fitting_results{1}(i_exp, 1);
            
            % Get latent variables and params of the fitted model
            latents = curr_fitting_results.latents;
            params = unpack_params(curr_fitting_results.x,...
                curr_fitting_results.param);
            
            % If fixed params exist, merge them to fitted parameters
            if isfield(model_space{1}, 'params_fit_fixed') ...
                    && isstruct(model_space{1}.params_fit_fixed)
                params = merge_params(...
                    params, model_space{1}.params_fit_fixed);
            end
            
            % Get observation function of the fitted model
            obs_func_batch = ...
                str2func(eval_info.model_space{1}.obs_func);
            
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
            modout_all(:, :, i_exp) =  modout_exp;
            
        end
        
        % Average responses over experiments using a trim mean
        modout_avg = trimmean(modout_all, 10, 3);
        
        % Store results
        eval_modout(i_prior, i_des).n_exp = n_exp;
        eval_modout(i_prior, i_des).n_trials = n_trials;
        eval_modout(i_prior, i_des).us_prob_trace = us_prob_trace;
        eval_modout(i_prior, i_des).modout_all = modout_all;
        eval_modout(i_prior, i_des).modout_avg = modout_avg;
    end
end

%%  Plot average model outputs
% Configuration
prior_selection = cfg.prior_selection;
n_prior_sel = numel(prior_selection);
cue_linecolors = cfg.cue_colors;
cont_linecolors = cfg.contingency_colors;
linestyle_output = cfg.linestyle_output;
linestyle_contingency = cfg.linestyle_contingency;
x_ticks = cfg.x_ticks;
prior_labels = cfg.prior_labels;
design_labels = cfg.design_labels;


if isfield(cfg, 'normalize_data') && islogical(cfg.normalize_data)
    normalize_data = cfg.normalize_data;
else
    normalize_data = true;
end
 
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
margin_left = 0.08;
margin_right = 0.01;
margin_bottom = 0.15;
margin_top = 0.05;
x_offset = bg_x + margin_left*bg_w;
y_offset = bg_y + margin_bottom*bg_h;
inner_w = (1-margin_left-margin_right)*bg_w;
inner_h = (1-margin_bottom-margin_top)*bg_h;
ax_w = inner_w / n_prior_sel;
ax_h = inner_h / n_des;

% Plotting
% Iterate over all designs (rows)
for i_des = 1 : n_des
    % Plot subplots for all selected evaluation priors (columns)
    for i_prior = 1 : n_prior_sel
        i_prior_orig = prior_selection(i_prior);
        
        % Get data for plotting
        curr_us_prob_trace = eval_modout(i_prior_orig, i_des).us_prob_trace;
        curr_modout_avg = eval_modout(i_prior_orig, i_des).modout_avg;
        curr_n_trials = eval_modout(i_prior_orig, i_des).n_trials;
        
        % Create axis
        ax_x = x_offset + (i_prior-1) * ax_w;
        ax_y = y_offset + (n_des - i_des) * ax_h;
        h_ax = axes('OuterPosition',[ax_x, ax_y, ax_w, ax_h],...
            'Position', [ax_x+0.05*ax_w, ax_y+0.05*ax_h, 0.9*ax_w, 0.9*ax_h]);

        hold on
        % Plot the contingency trace
        h_cont = plot(curr_us_prob_trace, ...
            'LineStyle', linestyle_contingency, 'LineWidth', 1.5);
        set(h_cont, {'Color'}, cont_linecolors');
        
        % Plot the fitted response of the model
        h_out = plot(curr_modout_avg, ...
            'LineStyle', linestyle_output, 'LineWidth', 1.5);
        set(h_out, {'Color'}, cue_linecolors');
         
        % Normalize responses to [0, 1] interval
        if normalize_data
            response_data = arrayfun(@(c) c.YData, h_ax.Children,...
                'UniformOutput', false);
            max_y = max(cellfun(@(c) max(c), response_data));
            min_y = min(cellfun(@(c) min(c), response_data));
            norm_response_data = cellfun(@(r) (r-min_y)./(max_y-min_y),...
                response_data, 'UniformOutput', false);
            set(h_ax.Children, {'YData'}, norm_response_data)
        end
          
        % Subplot customization
        xlim([0, curr_n_trials])
        set(h_ax, 'XTick', x_ticks)
        ylim([-0.01, 1])
        set(h_ax, 'TickDir', 'out')

    
        % Plot design label and ylabel if this is the first plot in the row
        if i_prior == 1
            des_str = sprintf('Design: %s', design_labels{i_des});
            x_header = 0.03;
            y_header = (ax_y+0.05*ax_h-bg_y+ax_h/2)/bg_h;
            text(h_bgax, x_header, y_header, des_str, ...
                'Rotation', 90,...
                'HorizontalAlignment', 'center',...
                'FontWeight', 'bold',...
                'FontSize', 12) ;
%             ylabel({'\rm\fontsize{8}Response [a.u.]/', 'P(US|CS)'})
        else
            set(h_ax, 'YTickLabel', {})
        end
        
        % Plot xlabel and x_ticks if it's the last row
        if i_des == n_des
            xlabel('Trial')
        else % Otherwise delete x-tick labels
            set(h_ax, 'XTickLabel', {})
        end   
        
        % Plot title if this is one of the top row subplots
        if i_des == 1
            str = sprintf('Evaluation prior: %s', prior_labels{i_prior_orig});
            x_header = (ax_x+0.05*ax_w-bg_x+ax_w/2)/bg_w;
            y_header = 0.97;
            text(h_bgax, x_header, y_header, str, ...
                'HorizontalAlignment', 'center',...
                'FontWeight', 'bold',...
                'FontSize', 12) ;
        end
          
        hold off
        
        set(gca, 'FontSize', 11)
    end
end

% Legend
w_legend = 0.33*inner_w;
h_legend = 0.05*bg_h;
x_legend = x_offset + 0.5*inner_w - 0.5*w_legend;
y_legend = bg_y + 0.03*bg_h;

legend([h_cont, h_out], {'P(US|CS)', 'Response [a.u]'},...
    'Orientation', 'horizontal',...
    'Position', [x_legend, y_legend, w_legend, h_legend]);

end
