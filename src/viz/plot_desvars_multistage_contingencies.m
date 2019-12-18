function [h_fig, eval_desvars] = plot_desvars_multistage_contingencies(all_evals_info, cfg)
%PLOT_DESVARS_MULTISTAGE_CONTINGENCIES plots values of design variables for a
%multi-stage multi-cue experiment.
%
% Usage:
%   [h_fig, eval_desvars] = plot_desvars_multistage_contingencies(all_evals_info, cfg)
%
% Args:
%   all_evals_info [n_design x 1 cell array] : Cell array of structs which
%       have been produced by the `run_design_evaluation` function.
%   cfg [struct] : Configuration variables for the plot.
%       .h_bgax [axis handle, optional] : Background axis handle into
%           which to plot. If empty, a new figure and axes are created.
%       .design_labels [n_design x 1 cell array of strings] : Design labels.
%       .cue_labels [n_design x 1 cell array of cell arrays] :
%           Each inner cell array hold n_cues strings with cue labels.
%
% Returns:
%   h_fig [handle] : Handle to the figure that was used for plotting.
%   eval_desvars [n_design x 1 struct array]
%       .n_cues [int] : Number of cues.
%       .n_stages [int] : Number of stages.
%       .dim_names [cell array of str] : Names of dimensions in prob_
%           matrices.
%       .prob_cs [n_cues x n_stages array] : Probability of cue
%           presentation for each stage.
%       .prob_cond_us_cs [n_cues x n_stages array] : Conditional
%           probability of the US given a cue.
%       .prob_joint_us_cs [n_cues x n_stages array] : Joint probability of
%           the US and the cue.


%% Process all design evaluation files and collect design variables
n_design_evals = numel(all_evals_info);
eval_desvars(n_design_evals) = struct(...
    'n_cues', [],...
    'n_stages', [],...
    'dim_names', [],...
    'prob_cs', [],...
    'prob_cond_us_cs', [],...
    'prob_joint_us_cs', []);

for i_eval = 1 : n_design_evals
    % Get current eval info
    eval_info = all_evals_info{i_eval};
    exp_design_func = eval_info.exp_design.exp_design_func;
    
    % Get design variables
    switch exp_design_func
        case 'exp_backward_blocking'
            n_cues = 3;
            n_stages = 2;
            prob_cs = nan(n_cues, n_stages);
            prob_cond_us_cs = nan(n_cues, n_stages);
            
            prob_cs(1,1) = 0; % p(A)_1
            prob_cs(2,1) = 0; % p(B)_1
            prob_cs(3,1) = 1; % p(AB)_1
            prob_cond_us_cs(1,1) = 0; % p(US|A)_1
            prob_cond_us_cs(2,1) = 0; % p(US|B)_1
            prob_cond_us_cs(3,1) = 1; % p(US|AB)_1
            prob_cs(1,2) = 1; % p(A)_2
            prob_cs(2,2) = 0; % p(B)_2
            prob_cs(3,2) = 0; % p(AB)_2
            prob_cond_us_cs(1,2) = 1; % p(US|A)_2
            prob_cond_us_cs(2,2) = 0; % p(US|B)_2
            prob_cond_us_cs(3,2) = 0; % p(US|AB)_2
            
            prob_joint_us_cs = prob_cond_us_cs .* prob_cs; % p(US,CS)
            
        case 'exp_twostage_twocuecmpnd'
            n_cues = 3;
            n_stages = 2;
            prob_cs = nan(n_cues, n_stages);
            prob_cond_us_cs = nan(n_cues, n_stages);
            desvars = eval_info.exp_design.desvars;
            
            prob_cs(1,1) = desvars.probA_1; % p(A)_1
            prob_cs(2,1) = desvars.probB_1; % p(B)_1
            prob_cs(3,1) = 1 - (desvars.probA_1+desvars.probB_1); % p(AB)_1
            prob_cond_us_cs(1,1) = desvars.probUS_A_1; % p(US|A)_1
            prob_cond_us_cs(2,1) = desvars.probUS_B_1; % p(US|B)_1
            prob_cond_us_cs(3,1) = desvars.probUS_AB_1; % p(US|AB)_1
            prob_cs(1,2) = desvars.probA_2; % p(A)_2
            prob_cs(2,2) = desvars.probB_2; % p(B)_2
            prob_cs(3,2) = 1 - (desvars.probA_2+desvars.probB_2); % p(AB)_2
            prob_cond_us_cs(1,2) = desvars.probUS_A_2; % p(US|A)_2
            prob_cond_us_cs(2,2) = desvars.probUS_B_2; % p(US|B)_2
            prob_cond_us_cs(3,2) = desvars.probUS_AB_2; % p(US|AB)_2
            
            prob_joint_us_cs = prob_cond_us_cs .* prob_cs; % p(US,CS)
            
        case 'exp_twostage_twocueonly'
            n_cues = 2;
            n_stages = 2;
            prob_cs = nan(n_cues, n_stages);
            prob_cond_us_cs = nan(n_cues, n_stages);
            desvars = eval_info.exp_design.desvars;
            
            prob_cs(1,1) = desvars.probA_1; % p(A)_1
            prob_cs(2,1) = 1 - desvars.probA_1; % p(B)_1
            prob_cond_us_cs(1,1) = desvars.probUS_A_1; % p(US|A)_1
            prob_cond_us_cs(2,1) = desvars.probUS_B_1; % p(US|B)_1
            prob_cs(1,2) = desvars.probA_2; % p(A)_2
            prob_cs(2,2) = 1 - desvars.probA_2; % p(B)_2
            prob_cond_us_cs(1,2) = desvars.probUS_A_2; % p(US|A)_2
            prob_cond_us_cs(2,2) = desvars.probUS_B_2; % p(US|B)_2
            
            prob_joint_us_cs = prob_cond_us_cs .* prob_cs; % p(US,CS)
    end

    eval_desvars(i_eval).n_cues = n_cues;
    eval_desvars(i_eval).n_stages = n_stages;
    eval_desvars(i_eval).dim_names = {'cs', 'stage'};
    eval_desvars(i_eval).prob_cs = prob_cs;
    eval_desvars(i_eval).prob_cond_us_cs = prob_cond_us_cs;
    eval_desvars(i_eval).prob_joint_us_cs = prob_joint_us_cs;

end

%%  Plot design variables
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
margin_right = 0;
margin_bottom = 0.27;
margin_top = 0.2;
x_offset = bg_x + margin_left*bg_w;
y_offset = bg_y + margin_bottom*bg_h;
inner_w = (1-margin_left-margin_right)*bg_w;
inner_h = (1-margin_bottom-margin_top)*bg_h;
ax_w = inner_w / n_design_evals;
ax_h = inner_h;

% Plotting
for i_eval = 1 : n_design_evals
    curr_desvars = eval_desvars(i_eval);
    n_cues = curr_desvars.n_cues;
    n_stages = curr_desvars.n_stages;
    % Create x-tick positions by shifting ticks of each stage by one
    x_ticks = [1:n_stages*n_cues] + repelem([0:n_stages-1], n_cues);
        
    % Create axis
    ax_x = x_offset + (i_eval-1) * ax_w;
    ax_y = y_offset;
    h_ax = axes('OuterPosition',[ax_x, ax_y, ax_w, ax_h],...
        'Position', [ax_x+0.1*ax_w, ax_y+0*ax_h, 0.9*ax_w, 1*ax_h]);
    
    hold on
    
    h_bar1 = bar(x_ticks, curr_desvars.prob_cs(:), 0.7,...
        'FaceColor', [0.94 0.94 0.94], 'LineWidth', 1.5);
    h_bar2 = bar(x_ticks, curr_desvars.prob_joint_us_cs(:), 0.4,...
        'FaceColor', [0.3 0.3 0.3]);
    
    ylim([0, 1])
    xlim([0, x_ticks(end)+0.8])
    
    if i_eval == 1 % If this is the leftmost plot show the ylabel
        ylabel('Probability')
    else % Otherwise, remove the ticks
        set(h_ax, 'YTickLabel', [])
    end
    
    
    xlabel('Cue')
    set(h_ax, 'XTick', x_ticks,...
        'XTickLabel', repmat(cfg.cue_labels{i_eval}, 1, n_stages),...
        'TickDir', 'out')
    
    set(h_ax, 'TickDir', 'out')
    grid(h_ax, 'on')
    
    % Plot title if this is one of the top row subplots
    h_title = title(sprintf('Design: %s', cfg.design_labels{i_eval}));
    % Move the title up to make room for the stage annotation
    title_pos = get(h_title, 'Position');
    set(h_title,'Position',title_pos + [0 0.1 0],...
        'FontSize', 11)
    
    % Plot stage label and divider
    for i_stage = 1 : n_stages
        ax_x_label = (n_cues+1)/2 + (i_stage-1)*(n_cues+1);
        ax_y_label = 1.08;
        str = sprintf('Stage %d', i_stage);
                text(ax_x_label, ax_y_label, str,... 
                    'HorizontalAlignment', 'center',...
                    'FontSize', 10)
        
        % If it's not the last stage, create a divider
        if i_stage < n_stages
            vline(i_stage*(n_cues+1), 'k--')
        end
    end
        
    hold off
    set(gca, 'FontSize', 11)
    h_x_ticks = get(gca, 'XAxis');
    set(h_x_ticks, 'FontSize', 11);
end


% Legend
w_legend = 0.33*inner_w;
h_legend = 0.08*bg_h;
x_legend = x_offset + 0.5*inner_w - 0.5*w_legend;
y_legend = bg_y + 0.03*bg_h;

legend([h_bar1, h_bar2], {'CS', 'CS & US'},...
    'Orientation', 'horizontal',...
    'Position', [x_legend, y_legend, w_legend, h_legend]);



end
