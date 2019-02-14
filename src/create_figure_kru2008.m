%% Create figure with results for scenario based on Kruschke (2008)

%% Imports 
addpath(genpath(fullfile('.'))); % Add the src folder and subfolders
% Add graphical utility tools
addpath(fullfile('..', 'external', 'altmany-export_fig'))
addpath(fullfile('..', 'external', 'errorbar_groups'))
addpath(fullfile('..', 'external', 'GridLegend'))
addpath(fullfile('..', 'external', 'hline_vline'))


%% Scenario-specific configuration
DESIGN_EVAL_FILEPATHS = {
    fullfile('..', 'results', 'kru2008',...
        'kru2008_eval_design-bb_prior-point',...
        'kru2008_eval_design-bb_prior-point.mat'),...
    fullfile('..', 'results', 'kru2008',...
        'kru2008_eval_design-vagueopt_prior-point',...
        'kru2008_eval_design-vagueopt_prior-point.mat'),...
    fullfile('..', 'results', 'kru2008',...
        'kru2008_eval_design-pointopt_prior-point',...
        'kru2008_eval_design-pointopt_prior-point.mat')};
n_design_evals = numel(DESIGN_EVAL_FILEPATHS);
DESIGN_LABELS = {'REF', 'VP-OPT', 'PP-OPT'};
CUE_LABELS = {...
    {'A', 'B', 'AB'},...
    {'A', 'B', 'AB'},...
    {'A', 'B', 'AB'}};
MODEL_LABELS = {'RW', 'KRW'};

FIGURES_PATH = fullfile('..', 'results_figures', 'kru2008');

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
% Configuration
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.design_colors = {
    [255,153,85]./255,...
    [117,112,179]./255,...
    [10,194,76]./255};
cfg.model_labels = MODEL_LABELS;
cfg.xlab_position = [3.5 -12];
cfg.legend_position = [0.2979    0.6152    0.0800    0.0839];
cfg.show_title = false;

% Create axis to draw into
h_ax = axes(h_fig, 'OuterPosition', [0, 0.5, 0.45, 0.5]);
cfg.h_ax = h_ax;

% Plot
[~, stats_acc] = plot_modsel_acc(all_evals_info, cfg);

% Add panel label
addABCs(h_ax, [-0.05; 0.02], 20, 'A');

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
cfg.model_pair = [1, 2];
cfg.model_labels = MODEL_LABELS(cfg.model_pair);
cfg.cue_labels = CUE_LABELS{1}; % Assumes the same cue labels are used in both designs
cfg.cue_colors = {
    [228,26,28]./255,...
    [55,126,184]./255,...
    [152,78,163]./255};
cfg.linestyle_truemod = '-';
cfg.linestyle_altmod = '--';
cfg.x_ticks = [30:30:120];
cfg.n_trials_stage = [60, 60];
cfg.input_patterns = {[1 0], [0 1], [1 1]};

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
filepath = fullfile(FIGURES_PATH, 'figure_kru2008');

% Save in vector formats
export_fig(h_fig, filepath, '-eps', '-pdf', '-nocrop', '-q101', '-painters')

% Save in bitmap formats
export_fig(h_fig, filepath, '-png', '-tiff', '-nocrop', '-m3.75')

