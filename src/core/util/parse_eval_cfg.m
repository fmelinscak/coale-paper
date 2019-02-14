function cfg_out = parse_eval_cfg(cfg_in)
%PARSE_EVAL_CFG parses the configuration structure obtained by reading a
%YAML evaluation config file into a format usable by evaluate_design
%
% Usage:
%   cfg_out = parse_eval_cfg(cfg_in)
%
% Args:
%   cfg_in : The configuration structure obtained by reading the YAML
%       evaluation configuration file with yaml.YamlRead funtion.
%       The following fields are expected:
%
%       .sim_set [struct] : Info about a set of simulations
%           .name [str] : Name of the simulation set.
%           .authors [str] : Simulation set authors.
%           .description [str] : Information about the purpose of the
%               simulation.
%           .date_created [str] : Date when the simulation set was created.
%           .results_path [path] : Path where the results from the
%               simulation set are saved.
%
%       .sim_run [struct] : Information about the specific simulation.
%           .name [str] : This identifier will be used in result filenames.
%           .description [str] : Information about the purpose of the
%               simulation.
%           .date_created [str] : Date when the specific simulation was created.
%           .rng_seed [int] : Random number generator seed for the
%               simulation.
%           .n_exp [int] : Number of simulated experiments.
%           .n_sub [int] : Number of simulated subjects per experiment.
%           .verbose [bool] : Whether to print diagnostic messages.
%           .parallel [bool] : Whether to fit models to experiments in
%               parallel.
%           .nstarts [int, optional] : How many times to restart fitting
%               (useful if combined with undefined initial parameters; 
%               if empty defaults to mfit_optimize settings.)
%       
%       .exp_design [struct] : Information about the experimental design
%           being evaluated.
%           .exp_design_func [func str] : Name of the Matlab function used
%               to generate experiment stimuli from design variables.
%           .desvars [struct] : Design variables structure (input to
%               exp_design_func). See specific exp. design func. for exact
%               fields.
%
%       .model_space [struct] : Information about the model space (same
%           space used for simulation and fitting).
%       OR
%       .models_sim [struct] : Information about the simulation model
%           space.
%       .models_fit [struct] : Information about the fitting model space.
%       Note: to see necessary fields for these structures, see function
%       parse_model_space_cfg.
%
%       .design_criterion [struct] : Information about the design criterion
%           that is evaluated.
%           .criterion_func [func str] : Name of the Matlab function used
%               to calculate the criterion value from fitting results.
%           .criterion_options [struct] : Criterion func. options structure
%               (input to criterion_func). See specific criterion func. for exact
%               fields.
%
% Returns:
%   cfg_out [struct] : Configuration structure in a format that can be used
%       by evaluate_design function.
%       .n_exp [int] : Number of simulated experiments.
%       .n_sub [int] : Number of simulated subjects per experiment.
%       .verbose [bool] : Whether to print diagnostic messages.
%       .parallel [bool] : Whether to fit models to experiments in
%           parallel.
%       .nstarts [int] : How many times to restart fitting.
%       .exp_design_func [func] : Function used to generate experiment 
%           stimuli from design variables.
%       .desvars [struct] : Design variables structure (input to
%           exp_design_func). See specific exp. design func. for exact
%           fields.
%       .prior_fit [n_models x 1, cell array, optional] : fitting prior structure
%           arrays
%       .params_fit_fixed [n_models x 1, cell array, optional] : structures with
%           values of fixed parameters in fitting models
%       .models_sim [n_models x 1, struct array] : Information about the simulation model
%           space.
%       .prior_sim [n_models x 1, cell array] : Sampling prior structures.
%       .models_fit [n_models x 1, struct array] : Information about the fitting model space.
%       .prior_fit [n_models x 1, cell array] : Fitting prior structure
%           arrays.
%       .params_fit_fixed [n_models x 1, cell array] : Structures with
%           values of fixed parameters in fitting models.
%       .criterion_func [func] : 
%       .criterion_options [struct] : Criterion func. options structure
%           (input to criterion_func). See specific criterion func. for exact
%           fields.

%% Initialize result
cfg_out = struct();

%% Simulation run params
cfg_out.n_exp = cfg_in.sim_run.n_exp;
cfg_out.n_sub = cfg_in.sim_run.n_sub;
cfg_out.verbose = cfg_in.sim_run.verbose;
cfg_out.parallel = cfg_in.sim_run.parallel;
if isfield(cfg_in.sim_run, 'nstarts')
    cfg_out.nstarts = cfg_in.sim_run.nstarts;
else
    cfg_out.nstarts = [];
end

%% Exp design variables
cfg_out.exp_design_func = str2func(cfg_in.exp_design.exp_design_func);
cfg_out.desvars = cfg_in.exp_design.desvars;

%% Sampling and fitting models
if isfield(cfg_in, 'model_space') % Single model space for both sampling and fitting
    mod_space_out = parse_model_space_cfg(cfg_in.model_space);
    cfg_out.models_sim = mod_space_out.models;
    cfg_out.prior_sim = mod_space_out.prior_sim;
    cfg_out.models_fit = mod_space_out.models;
    cfg_out.prior_fit = mod_space_out.prior_fit;
    cfg_out.params_fit_fixed = mod_space_out.params_fit_fixed;
elseif all(isfield(cfg_in, {'models_sim', 'models_fit'})) % Separate model spaces for simulation and fitting
    mod_space_sim_out = parse_model_space_cfg(cfg_in.models_sim);
    cfg_out.models_sim = mod_space_sim_out.models;
    cfg_out.prior_sim = mod_space_sim_out.prior_sim;
    mod_space_fit_out = parse_model_space_cfg(cfg_in.models_fit);
    cfg_out.models_fit = mod_space_fit_out.models;
    cfg_out.prior_fit = mod_space_fit_out.prior_fit;
    cfg_out.params_fit_fixed = mod_space_fit_out.params_fit_fixed;
else
    error('Model space(s) not specified properly.')
end

%% Design criterion
cfg_out.criterion_func = str2func(cfg_in.design_criterion.criterion_func);
cfg_out.criterion_options = cfg_in.design_criterion.criterion_options;

end

