%% Export to CSV results of scenario with RW learning rate estimation

%% Imports 
addpath(genpath(fullfile('.'))); % Add the src folder and subfolders

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
SCENARIO_LABEL = 'RWAE';
PRIOR_LABELS = {'LA', 'MA', 'HA'};
DESIGN_LABELS = {'REF', 'VA-OPT', 'PA-OPT'};

RESULTS_PATH = fullfile('..', 'results_csvs');
RESULTS_FPATH = fullfile(RESULTS_PATH, 'eval_results_rwae.csv');

% Create folder for results if it doesn't exist
if ~exist(RESULTS_PATH,'dir'), mkdir(RESULTS_PATH); end;


%% Extract evaluation-wise results
clear('records')
i_records = 0;

for i_prior = 1 : n_prior
    for i_des = 1 : n_des
        
        S = load(DESIGN_EVAL_FILEPATHS{i_prior, i_des});
        sim_info = S.sim_info;
        n_exp = sim_info.sim_run.n_exp; % Number of simulations (each simulation has a sub-simulation for each of the candidate models)
        
        % Get relevant information into records structure
        for i_exp = 1 : n_exp
            i_records = i_records + 1;
            fitting_results = sim_info.results_eval.outputs.fitting_results{1}(i_exp);
            ground_truth = sim_info.results_eval.outputs.simulation_params{1}(i_exp);
            
            r = struct(); % Temporary record variable
            % Get variables for table row
            r.scenario = SCENARIO_LABEL;
            r.eval_prior = PRIOR_LABELS{i_prior};
            r.design  = DESIGN_LABELS{i_des};
            r.simulation_idx  = i_exp;
            r.true_alpha_val = ground_truth.evo.alphaInit; % True value of the learning rate
            
            % Get experiment-wise learning rate estimated value and error
            param_names = {fitting_results.param.name};
            idx_param_alpha = find(strcmp('alphaInit', param_names));
            r.estim_alpha_val = fitting_results.x(idx_param_alpha);
            r.alpha_estim_abs_err = abs(r.true_alpha_val - r.estim_alpha_val);
            
            % Store record
            records(i_records) = r;
        end
    end
end

%% Store records into a table and to disk in CSV format
eval_result_table = struct2table(records);
writetable(eval_result_table, RESULTS_FPATH) 


