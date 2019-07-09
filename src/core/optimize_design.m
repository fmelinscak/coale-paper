function results_optim = optimize_design(cfg_optim)
%optimize_design evaluates the utility of an experimental design by
%simulation
%   
%   evaluate_design evaluates the utility of a design by simulating a
%   number of experiments, according to the provided design variables, 
%   model space and sampling prior and then fitting the same models but
%   using the provided analysis prior.
%   
%
% Usage:
%   results_optim = optimize_design(cfg_optim)
%
% Args:
%   cfg_optim [struct] : Configuration structure
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
%       .models_sim [n_models x 1, struct array] : Information about the simulation model
%           space.
%       .prior_sim [n_models x 1, cell array] : Sampling prior structures.
%       .models_fit [n_models x 1, struct array] : Information about the fitting model space.
%       .prior_fit [n_models x 1, cell array] : Fitting prior structure
%           arrays.
%       .params_fit_fixed [n_models x 1, cell array] : Structures with
%           values of fixed parameters in fitting models.
%       .criterion_func [func] : Handle of the Matlab function used
%               to calculate the criterion value from fitting results.
%       .criterion_options [struct] : Criterion func. options structure
%           (input to criterion_func). See specific criterion func. for exact
%           fields.
%      
% Returns:
%   results_optim [BayesianOptimization object] : Object holding the
%       results of Bayesian optimization

%% Get objective function handle
    obj_func_handle = @(d) obj_func(d, cfg_optim);
    
    %% Get optimizable design variables
    n_desvars_optim = numel(cfg_optim.desvars_optim);
    desvars_optim(n_desvars_optim, 1) = optimizableVariable; % Initialize array of optimizable variables
    for i_var = 1 : n_desvars_optim
        curr_var = cfg_optim.desvars_optim{i_var};
        desvars_optim(i_var) = optimizableVariable(curr_var.name, curr_var.range, 'Type', curr_var.type);
    end
    
    %% Get Bayesian optimization options into Name-Value-pair format
    optim_opts = cfg_optim.optim_opts; % Get optimization options
    if isfield(optim_opts, 'store_user_data_trace')
        optim_opts = rmfield(optim_opts, 'store_user_data_trace'); % `store_user_data_trace` is not an option of the `bayesopt` function
    end
    optim_opt_names = fieldnames(optim_opts)';
    
    optim_opt_values = struct2cell(optim_opts)';
    optim_opt = [optim_opt_names; optim_opt_values]; % Combine names and values into a single cell array
    optim_opt = optim_opt(:); % Collate the name-value pairs (by alternating between them) into a single vector
    
    %% Run Bayesian optimization
    results_optim = bayesopt(obj_func_handle, desvars_optim, optim_opt{:});

end

function [loss, constraints, outputs] = obj_func(desvars, cfg_optim)
%obj_func is the optimizable wrapper for the 'evaluate_design' function

% Merge constant and optimizable design variables
merged_desvars = table2struct(desvars); % Add current desvar values

desvars_const = cfg_optim.desvars_const;
const_names = fieldnames(desvars_const);
for i_const = 1 : numel(const_names) % Copy the constants into merged design variables struct
    const_name = const_names{i_const};
    merged_desvars.(const_name) = ...
        desvars_const.(const_name);
end

% Determine if user data trace is stored
optim_opts = cfg_optim.optim_opts; % Get optimization options
if isfield(optim_opts, 'store_user_data_trace')
    store_user_data_trace = optim_opts.store_user_data_trace;
else
    store_user_data_trace = false; % Results of all the simulations are not stored unless requested (can result in large files and slow saving)
end

% Evaluate the design
[loss, constraints, tmp_outputs] = evaluate_design(...
    cfg_optim.exp_design_func, merged_desvars,...
    cfg_optim.eval_opts.n_exp, cfg_optim.desvars_const.n_sub, ...
    cfg_optim.models_sim, cfg_optim.prior_sim,...
    cfg_optim.models_fit, cfg_optim.prior_fit,...
    cfg_optim.params_fit_fixed,...
    cfg_optim.criterion_func, cfg_optim.criterion_options,...
    cfg_optim.eval_opts.verbose, cfg_optim.eval_opts.parallel);

% Output data trace if necessary
if store_user_data_trace
    outputs = tmp_outputs;
else
    outputs = [];
end

end