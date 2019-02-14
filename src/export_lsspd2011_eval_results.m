%% Export to CSV results of scenario based on Li et al. (2011)

%% Imports 
addpath(genpath(fullfile('.'))); % Add the src folder and subfolders

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
SCENARIO_LABEL = 'LSSPD2011';
DESIGN_LABELS = {'REF', 'VP-OPT', 'PP-OPT'};
MODEL_LABELS = {'RW(V)', 'RWPH(V)', 'RWPH(\alpha)', 'RWPH(V+\alpha)'};

RESULTS_PATH = fullfile('..', 'results_csvs');
RESULTS_FPATH = fullfile(RESULTS_PATH, 'eval_results_lsspd2011.csv');

% Create folder for results if it doesn't exist
if ~exist(RESULTS_PATH,'dir'), mkdir(RESULTS_PATH); end;


%% Extract evaluation-wise results
n_models = numel(MODEL_LABELS);
clear('records')
i_records = 0;
for i_eval = 1 : n_design_evals
    S = load(DESIGN_EVAL_FILEPATHS{i_eval});
    sim_info = S.sim_info;
    n_exp = sim_info.sim_run.n_exp; % Number of simulations (each simulation has a sub-simulation for each of the candidate models)
    
    
    % Get relevant information into records structure
    for i_exp = 1 : n_exp
        for i_mdl_true = 1 : n_models
            i_records = i_records + 1;
            fitting_results = sim_info.results_eval.outputs.fitting_results{i_mdl_true};
            
            r = struct(); % Temporary record variable
            % Get variables for table row
            r.scenario = SCENARIO_LABEL;
            r.design  = DESIGN_LABELS{i_eval};
            r.simulation_idx  = i_exp;
            r.true_model_idx = i_mdl_true;
            r.true_model = MODEL_LABELS{i_mdl_true};
            
            % Get model-wise goodness of fit (BIC)
            model_bics = [fitting_results(i_exp, :).bic];
            for i_mdl_fit = 1 : n_models
                r.(sprintf('bic_model_%d', i_mdl_fit)) = model_bics(i_mdl_fit);
            end
            [~,r.selected_model_idx] = min(model_bics);
            r.selected_model = MODEL_LABELS{r.selected_model_idx};
            r.model_recovered = (r.true_model_idx == r.selected_model_idx);
            
            % Store record
            records(i_records) = r;
        end
    end
end

%% Store records into a table and to disk in CSV format
eval_result_table = struct2table(records);
writetable(eval_result_table, RESULTS_FPATH) 


