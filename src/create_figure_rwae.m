%% Create figure with results for scenario with RW learning rate estimation

%% Imports 
addpath(genpath(fullfile('.'))); % Add the src folder and subfolders
% Add graphical utility tools
addpath(fullfile('..', 'external', 'altmany-export_fig'))
addpath(fullfile('..', 'external', 'errorbar_groups'))
addpath(fullfile('..', 'external', 'hline_vline'))
addpath(fullfile('..', 'external', 'iosr-toolbox-4bff1bb'))


%% Scenario-specific configuration
DESIGN_EVAL_FILEPATHS = {
    % Evaluation under the LA prior
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-ref_prior-la',...
        'rwae_eval_design-ref_prior-la.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-vaopt_prior-la',...
        'rwae_eval_design-vaopt_prior-la.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-laopt_prior-la',...
        'rwae_eval_design-laopt_prior-la.mat');
    % Evaluation under the MA prior
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-ref_prior-ma',...
        'rwae_eval_design-ref_prior-ma.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-vaopt_prior-ma',...
        'rwae_eval_design-vaopt_prior-ma.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-maopt_prior-ma',...
        'rwae_eval_design-maopt_prior-ma.mat');
    % Evaluation under the HA prior
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-ref_prior-ha',...
        'rwae_eval_design-ref_prior-ha.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-vaopt_prior-ha',...
        'rwae_eval_design-vaopt_prior-ha.mat'),...
    fullfile('..', 'results', 'rwae',...
        'rwae_eval_design-haopt_prior-ha',...
        'rwae_eval_design-haopt_prior-ha.mat')
    };
[n_prior, n_des] = size(DESIGN_EVAL_FILEPATHS);
PRIOR_LABELS = {'LA', 'MA', 'HA'};
DESIGN_LABELS = {'REF', 'VA-OPT', 'PA-OPT'};
CUE_LABELS = {'A'};

FIGURES_PATH = fullfile('..', 'results_figures', 'rwae');

% Create folder for figures if it doesn't exist
if ~exist(FIGURES_PATH,'dir'), mkdir(FIGURES_PATH); end;

%% Load data into a cell array
all_evals_info = cell(n_prior, n_des);
for i_prior = 1 : n_prior
    for i_des = 1 : n_des
        S = load(DESIGN_EVAL_FILEPATHS{i_prior, i_des});
        all_evals_info{i_prior, i_des} = S.sim_info;
    end
end

%% Set up figure to plot into
h_fig = figure('Color', 'w', 'Units', 'pixels',...
    'Position', [0, 0, 1200, 1200*10/19]);
movegui(h_fig, 'center')

%% Plot estimation error under different priors and designs
% Configure
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.design_colors = {
    [255,153,85]./255,...
    [117,112,179]./255,...
    [10,194,76]./255};
cfg.prior_labels = PRIOR_LABELS;
cfg.legend_position = [0.0733 0.8010 0.0875 0.1345];

% Create axis to draw into
h_ax = axes(h_fig, 'OuterPosition', [0, 0.5, 0.45, 0.5]);
cfg.h_ax = h_ax;

% Plot
[~, stats_err] = plot_prior_des_err(all_evals_info, cfg);

% Add panel label
addABCs(h_ax, [-0.04; 0.03], 20, 'A');

%% Plot difference in estimation error between designs (under various prirors)
% Configure
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.design_pairs = { % Superiority of d1 over d2 will be visualized
    [2, 1];
    [3, 1];
    [3, 2]}; 
cfg.design_pair_colors = {
    [255, 255, 153]./255,...
    [56, 108, 176]./255,...
    [240, 2, 127]./255};
cfg.prior_labels = PRIOR_LABELS;
cfg.cles_opts = struct('method', 'brute', 'nboot', 1000, 'alpha', 0.05);
cfg.legend_position = [0.1088 0.1428 0.1542 0.0981];

% Create axis to draw into
h_ax = axes(h_fig, 'OuterPosition', [0, 0, 0.45, 0.5]);
cfg.h_ax = h_ax;

% Plot
[~, stats_errdiff] = plot_estimerr_diff(all_evals_info, cfg);

% Add panel label
addABCs(h_ax, [-0.04; 0.03], 20, 'B');

%% Plot average model outputs and design variables (contingencies)
% Configure
cfg = struct();
cfg.design_labels = DESIGN_LABELS;
cfg.prior_labels = PRIOR_LABELS;
cfg.prior_selection = [1, 2, 3];
cfg.cue_labels = CUE_LABELS;
cfg.cue_colors = {
    [228,26,28]./255};
cfg.contingency_colors = {
    [0,0,0]./255};
cfg.linestyle_output = '-';
cfg.linestyle_contingency = ':';
cfg.x_ticks = [30:30:120];
cfg.input_patterns = {[1]};
cfg.normalize_data = false;

% Create background axis to draw into
h_bgax = axes(h_fig, 'Position', [0.45, 0, 0.55, 1],...
    'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1]);
cfg.h_bgax = h_bgax;

% Plot
[~, stats_modout] = plot_modout_periodic(all_evals_info, cfg);

% Add panel label
addABCs(h_bgax, [0; -0.008], 20, 'C');

%% Save figure in various formats to disk
filepath = fullfile(FIGURES_PATH, 'figure_rwae');

% Save in vector formats
export_fig(h_fig, filepath, '-eps', '-pdf', '-nocrop', '-q101', '-painters')

% Save in bitmap formats
export_fig(h_fig, filepath, '-png', '-tiff', '-nocrop', '-m3.75')



