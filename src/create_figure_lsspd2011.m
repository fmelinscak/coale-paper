%% Create figure with results for scenario based on Li et al. (2011)

%% Imports 
addpath(genpath(fullfile('.'))); % Add the src folder and subfolders
% Add graphical utility tools
addpath(fullfile('..', 'external', 'altmany-export_fig'))
addpath(fullfile('..', 'external', 'cbrewer'))
addpath(fullfile('..', 'external', 'errorbar_groups'))
addpath(fullfile('..', 'external', 'GridLegend'))
addpath(fullfile('..', 'external', 'hline_vline'))

%% Scenario-specific configuration
DESIGN_EVAL_FILEPATHS = {
    fullfile('..', 'results', 'lsspd2011',...
        'lsspd2011_eval_design-ref_prior-point',...
        'lsspd2011_eval_design-ref_prior-point.mat'),...
    fullfile('..', 'results', 'lsspd2011',...
        'lsspd2011_eval_design-vagueopt_prior-point',...
        'lsspd2011_eval_design-vagueopt_prior-point.mat'),...
    fullfile('..', 'results', 'lsspd2011',...
        'lsspd2011_eval_design-pointopt_prior-point',...
        'lsspd2011_eval_design-pointopt_prior-point.mat')};

n_design_evals = numel(DESIGN_EVAL_FILEPATHS);
DESIGN_LABELS = {'REF', 'VP-OPT', 'PP-OPT'};
CUE_LABELS = {...
    {'A', 'B'},...
    {'A', 'B'},...
    {'A', 'B'}};
MODEL_LABELS = {'RW(V)', 'RWPH(V)', 'RWPH(\alpha)', 'RWPH(V+\alpha)'};

FIGURES_PATH = fullfile('..', 'results_figures', 'lsspd2011');

% Create folder for figures if it doesn't exist
if ~exist(FIGURES_PATH,'dir'), mkdir(FIGURES_PATH); end;

%% Load data into a cell array
all_evals_info = cell(n_design_evals, 1);
for i_eval = 1 : n_design_evals
    S = load(DESIGN_EVAL_FILEPATHS{i_eval});
    all_evals_info{i_eval} = S.sim_info;
end

%% Set up figure to plot into
h_fig = figure('Color', 'w', 'Units', 'pixels',...
    'Position', [0, 0, 1200, 1200*10/19]);
movegui(h_fig, 'center')

%% Plot model selection accuracy
%Configuration
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.design_colors = {
    [255,153,85]./255,...
    [117,112,179]./255,...
    [10,194,76]./255};
cfg.model_labels = MODEL_LABELS;
cfg.xlab_position = [6.5, -12];
cfg.legend_position = [0.31 0.58 0.08 0.09];
cfg.show_title = false;
cfg.design_pairs = { % Odds ratio of d1 over d2 will be computed
    [2, 1];
    [3, 1];
    [3, 2]}; 

% Create axis to draw into
h_ax = axes(h_fig, 'OuterPosition', [0, 0.5, 0.45, 0.5]);
cfg.h_ax = h_ax;

% Plot
[~, stats_acc, stats_or] = plot_modsel_acc(all_evals_info, cfg);

% Add panel label
addABCs(h_ax, [-0.05; 0.02], 20, 'A');

%% Plot model selection confusion matrices
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.model_labels = MODEL_LABELS;

% Create background axis to draw into
h_bgax = axes(h_fig, 'Position', [0.1, 0.58, 0.15, 0.13],...
    ...'XColor', 'none', 'YColor', 'none', ...
    'Box', 'on',...
    'XTick', [], 'YTick', [],...
    'XLim', [0, 1], 'YLim', [0, 1]);
cfg.h_bgax = h_bgax;

[~, stats_confmat] = plot_modsel_confmat(all_evals_info, cfg);

%% Plot design variables
% Configuration
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.cue_labels = CUE_LABELS;

% Create background axis to draw into
h_bgax = axes(h_fig, 'Position', [0, 0, 0.45, 0.5],...
    'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1]);
cfg.h_bgax = h_bgax;

% Plot
[~, stats_desvars] = plot_desvars_multistage_contingencies(all_evals_info, cfg);

% Add panel label
addABCs(h_bgax, [0.02; 0], 20, 'B');

%% Plot average model outputs
% Configuration
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.model_pair = [1, 4];
cfg.model_labels = MODEL_LABELS(cfg.model_pair);
cfg.cue_labels = CUE_LABELS{1}; % Assumes the same cue labels are used in both designs
cfg.cue_colors = {
    [228,26,28]./255,...
    [55,126,184]./255};
cfg.linestyle_truemod = '-';
cfg.linestyle_altmod = '--';
cfg.x_ticks = [30:30:120];
cfg.n_trials_stage = [60, 60];
cfg.input_patterns = {[1 0], [0 1]};
cfg.bic_pos = repmat(struct('x', 60, 'y', 0.5),... 
    n_design_evals, length(MODEL_LABELS)); % Default positions for BIC annotation
cfg.bic_pos(1,1) = struct('x', 30, 'y', 0.45);
cfg.bic_pos(1,2) = struct('x', 90, 'y', 0.85);
cfg.bic_pos(2,1) = struct('x', 30, 'y', 0.40);
cfg.bic_pos(2,2) = struct('x', 90, 'y', 0.40);
cfg.bic_pos(3,1) = struct('x', 30, 'y', 0.85);
cfg.bic_pos(3,2) = struct('x', 30, 'y', 0.30);

% Create background axis to draw into
h_bgax = axes(h_fig, 'Position', [0.45, 0, 0.55, 1],...
    'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1]);
cfg.h_bgax = h_bgax;

% Plot
[~, stats_modout] = plot_modout(all_evals_info, cfg);

% Add panel label
addABCs(h_bgax, [0.03; -0.015], 20, 'C');

%% Save figure in various formats to disk
filepath = fullfile(FIGURES_PATH, 'figure_lsspd2011');

% Save in vector formats
export_fig(h_fig, filepath, '-eps', '-pdf', '-nocrop', '-q101', '-painters')

% Save in bitmap formats
export_fig(h_fig, filepath, '-png', '-tiff', '-nocrop', '-m3.75')
