function [loss, constraints, outputs] = evaluate_design(exp_design_func, desvars, n_exp, n_sub, ...
    models_sim, prior_sim, models_fit, prior_fit, params_fit_fixed,...
    criterion_func, criterion_opts, verbose, parallel, nstarts)
%evaluate_design evaluates the utility of an experimental design by
%simulation
%   
%   evaluate_design evaluates the utility of a design by simulating a
%   number of experiments, according to the provided design variables, 
%   model space and sampling prior and then fitting the same models but
%   using the provided analysis prior.
%   
%
% Usage:
%   [loss, constraints, outputs] = evaluate_design(exp_design_func, desvars, n_exp, n_sub, ...
%       models_sim, prior_sim, models_fit, prior_fit, params_fit_fixed, verbose, nstarts)
%
% Args:
%   exp_design_func [func] : handle of the exp. design function which is
%       called with exp_design_func(desvars)
%   desvars : structure with the values of design variables
%   n_exp [int] : the number of experiments to simulate per model
%   n_sub [int] : the number of subjects to simulate per experiment
%   models_sim [n_modsim x 1] : structure array describing models to
%       simulate.
%       .name [string]: name of the model
%       .sim_func [func] : simulation function of the model
%   prior_sim {n_modsim x 1} : cell array of sampling priors for each
%       model which are structures containing a ccombination of:
%       - fields with constant parameter values
%       - fields with function handles to parameter sampling distribution
%       - fields with a nested parameter structure (visited recursively)
%   models_fit [n_modfit x 1] : structure array describing models to
%       fit.
%       .name [string]: name of the model
%       .loglik_func [func] : log-likelihood function of the model
%   prior_fit {n_modfit x 1} : cell array of analysis priors for each
%       model
%       - each analysis prior is a structure array [n_params x 1] with structures of form:
%           .name [string] : parameter name
%           .logpdf [func] : logpdf of the parameter's prior
%           .init [num] : initial value in parameter fitting
%           .lb [num] : lower bound of the parameter
%           .ub [num] : upper bound of the parameter
%           - Note optional additional fields can be used, which are passed
%           to the likelihood function
%   params_fit_fixed {n_modfit x 1, optional}  : cell array of model parameter
%       structures with fixed parameter values
%   criterion_func [func] : handle of the design criterion function which is
%       called with criterion_func(fitting_results, criterion_opts)
%   criterion_opts [structure] : structure with options for the
%       criterion_func
%   verbose [bool, optional] : if the diagnostic text output should be verbose
%       (default: true)
%   parallel [bool, optional] : if the experiments are fitted in parallel
%       (default: false)
%   nstarts [int, optional] : how many times to restart fitting
%       (useful if combined with undefined initial parameters; 
%       if empty defaults to mfit_optimize settings.)
%      
% Returns:
%   loss : logit transformed model selection error rate
%   constraints : necessary for BayesOpt in problems with coupled
%       constraints
%   outputs : structure with additional results to output
%       .simulation_params {n_modsim x 1} : Parameters used in simulations.
%           Each cell has a structure array of size [n_sub x n_exp]
%       .data : data simulated by simulate_data function
%       .latents : latent variables resulting from the simulate_data function
%       .fitting_results {n_modsim x 1} : results of fitting models using the fit_models
%           function
%       .loss_info : Additional information about loss calculation. See
%           criterion_func function.

if ~exist('verbose', 'var') || isempty(verbose)
    verbose = true;
end

if ~exist('parallel', 'var') || isempty(parallel)
    parallel = false;
end

if ~exist('nstarts', 'var')
    nstarts = [];
end

if ~exist('criterion_opts', 'var') || isempty(criterion_opts)
    criterion_opts = struct();
end

%% Get sizes of the model spaces
n_modsim = length(models_sim); % Get the number of simulated models
n_modfit = length(models_fit); % Get the number of fitted models

%% Sample parameter values from the sampling prior
simulation_params = cell(n_modsim, 1);
for i_modsim = 1 : n_modsim
    for i_sub = 1 : n_sub
        for i_exp = 1 : n_exp
            simulation_params{i_modsim}(i_sub,i_exp) = sample_params(prior_sim{i_modsim});
        end
    end
end


%% Apply current design parameters to obtain the specific exp. design. func.
exp_design_func_specific = @() exp_design_func(desvars);

%% Simulate the data
[data, latents] = simulate_data(n_sub, n_exp, exp_design_func_specific, models_sim, simulation_params);

%% Fit the models
fitting_results = cell(n_modsim, 1);
for i_modsim = 1 : n_modsim
    fitting_results{i_modsim} = fit_models(data(:,:,i_modsim),...
        models_fit, prior_fit, params_fit_fixed,...
        verbose, parallel, nstarts);
end

%% Perform model selection
[loss, loss_info] = criterion_func(fitting_results, simulation_params, criterion_opts);

%% Collect auxiliary outputs
constraints = [];
outputs.simulation_params = simulation_params;
outputs.data = data;
outputs.latents = latents;
outputs.fitting_results = fitting_results;
outputs.loss_info = loss_info;

end

