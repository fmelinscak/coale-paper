function cfg_out = parse_optim_cfg(cfg_in)
%PARSE_OPTIM_CFG parses the configuration structure obtained by reading a
%YAML optimization config file into a format usable by
%run_design_optimization
%
% Usage:
%   cfg_out = parse_optim_cfg(cfg_in)
%
% Args:
%   cfg_in : The configuration structure obtained by reading the YAML
%       optimization configuration file with yaml.YamlRead funtion.
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
%       
%       .exp_design [struct] : Information about the experimental design
%           being evaluated.
%           .exp_design_func [func str] : Name of the Matlab function used
%               to generate experiment stimuli from design variables.
%           .desvars_const [struct] : Constant design variables values. See
%               exp. design func. for variable names.
%               .n_sub [int, required] : Number of simulated subjects per
%                   experiment, per simulation model.
%           .desvars_optim [cell array of struct] : Optimizable design 
%               variables. See optimizableVariable class for description. See
%               exp. design func. for variable names.
%       
%       .eval_opts [struct] : Design evaluation options
%           .n_exp [int] : Number of simulated experiments per design
%               evaluation and per simulation model.
%           .verbose [bool] : Whether to print diagnostic messages.
%           .parallel [bool] : Whether to fit models to experiments in
%               parallel.
%           .nstarts [int, optional] : How many times to restart fitting
%               (useful if combined with undefined initial parameters; 
%               if empty defaults to mfit_optimize settings.)
%
%       .optim_opts [struct] : Optimization options (see 'bayesopt' Matlab
%           function for details).
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
%       by run_design_optimization function.
%       .eval_opts [struct] : Design evaluation options
%           .n_exp [int] : Number of simulated experiments per design
%               evaluation and per simulation model.
%           .verbose [bool] : Whether to print diagnostic messages.
%           .parallel [bool] : Whether to fit models to experiments in
%               parallel.
%           .nstarts [int] : How many times to restart fitting.
%       .optim_opts [struct] : Optimization options (see 'bayesopt' Matlab
%           function for details).
%       .exp_design_func [func] : Function used to generate experiment 
%       .desvars_const [struct] : Constant design variables values. See
%           exp. design func. for variable names.
%           .n_sub [int, required] : Number of simulated subjects per
%               experiment, per simulation model.
%       .desvars_optim [cell array of struct] : Optimizable design 
%           variables. See optimizableVariable class for description. See
%           exp. design func. for variable names.
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

%% Design evaluation options
cfg_out.eval_opts = cfg_in.eval_opts;
if ~isfield(cfg_out.eval_opts, 'nstarts')
    cfg_out.eval_opts.nstarts = [];
end

%% Optimization options
cfg_out.optim_opts = cfg_in.optim_opts;

% Check if MaxTime is empty or 'Inf'
if isfield(cfg_out.optim_opts, 'MaxTime')
    if isempty(cfg_out.optim_opts.MaxTime)
        cfg_out.optim_opts.MaxTime = Inf; % Defaults to unlimited time if empty
    elseif strcmpi(cfg_out.optim_opts.MaxTime, 'Inf')
        cfg_out.optim_opts.MaxTime = Inf; % Parse string to Inf
    end
end

% Translate strings into function handles for OutputFcn cell array
if isfield(cfg_out.optim_opts, 'OutputFcn') && ~isempty(cfg_out.optim_opts.OutputFcn)
    cfg_out.optim_opts.OutputFcn = cellfun(@(s) str2func(s),...
        cfg_out.optim_opts.OutputFcn, 'UniformOutput', false);
end
% Translate strings into function handles for PlotFcn cell array
if isfield(cfg_out.optim_opts, 'PlotFcn') && ~isempty(cfg_out.optim_opts.PlotFcn)
    cfg_out.optim_opts.PlotFcn = cellfun(@(s) str2func(s),...
        cfg_out.optim_opts.PlotFcn, 'UniformOutput', false);
end

% Translate string into function handle for XConstraintFcn
if isfield(cfg_out.optim_opts, 'XConstraintFcn') && ~isempty(cfg_out.optim_opts.XConstraintFcn)
    cfg_out.optim_opts.XConstraintFcn = str2func(cfg_out.optim_opts.XConstraintFcn);
end

%% Exp design variables and constants
cfg_out.exp_design_func = str2func(cfg_in.exp_design.exp_design_func);
cfg_out.desvars_const = cfg_in.exp_design.desvars_const;
cfg_out.desvars_optim = cfg_in.exp_design.desvars_optim;

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

