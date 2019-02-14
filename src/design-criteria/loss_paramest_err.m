function [loss, loss_info] = loss_paramest_err(fitting_results, simulation_params, options)
%LOSS_PARAMEST_ERR calculates the loss as the parameter estimation error
%
% Usage:
%   [loss, loss_info] = loss_paramest_err(fitting_results, simulation_params[, options])
%
% Args:
%   fitting_results {cell array of size 1} : Results of fitting the model 
%       using the fit_models function.
%   simulation_params {cell array of size 1} : Parameters used in simulations.
%       The cell has a structure array of size [n_sub x n_exp]
%   options [struct, optional] : 
%       .param_name [str] : Name of the target parameter.
%       .param_type [str, required if model is NSSM] : Parameter type.
%           Expected values. {'obs', 'evo'}.
%       .error_type [str] : Type of estimation error. Expected values: 
%           {'sqr', 'abs'}. Default: 'sqr'. 
%
% Returns:
%   loss [double] : Loss value calculated as param error averaged over
%       subjects and experiments.
%   loss_info [struct] : Additional information about loss calculation.
%       .signed_err [double, n_sub x n_exp] : Individual parameter errors.
%       

%% Parse input options
% Create parser
opt_parser = inputParser;
default_param_name = '';
expected_param_names = {fitting_results{1}(1).param.name};
default_param_type = '';
expected_param_types = {'', 'obs', 'evo'};
default_error_type = 'sqr';
expected_error_types = {'sqr', 'abs'};

opt_parser.addParameter('param_name', default_param_name,...
    @(x) any(validatestring(x, expected_param_names)));
opt_parser.addParameter('param_type', default_param_type,...
    @(x) any(validatestring(x, expected_param_types)));
opt_parser.addParameter('error_type', default_error_type,...
    @(x) any(validatestring(x, expected_error_types)));

% Parse inputs and get results
if ~exist('options', 'var') || isempty(options)
    opt_parser.parse(struct());
else
    opt_parser.parse(options);
end

param_name = opt_parser.Results.param_name;
if isempty(param_name)
    error('Parameter name must be given in criterion options.')
end
param_type = opt_parser.Results.param_type;
error_type = opt_parser.Results.error_type;

% In parameter estimation there is only one simulation/fitting model
fitting_results = fitting_results{1}; % fitting_results is now [n_exp x 1] struct array
simulation_params = simulation_params{1}; % 

%% Calculate parameter estimation error for each subject in each experiment
% Determine number of experiments and subjects per experiment
[n_sub, n_exp] = size(simulation_params);

% Get true parameter values
if ~isempty(param_type) % NSSM param
    field_path = {param_type, param_name};
else % Not NSSM param
    field_path = {param_name};
end
true_param_vals = arrayfun(@(s) getfield(s, field_path{:}), simulation_params);

% Get estimated parameter values
idx_param = find(strcmpi({fitting_results(1).param.name}, param_name)); % Index of the param in the vector of estimated values
estim_param_vals = nan(n_sub, n_exp);
for i_exp = 1 : n_exp
    estim_param_vals(:, i_exp) = fitting_results(i_exp).x(:, idx_param); % Get estimated param values for all subjs in an exp
end

% Calculate error averaged across subjects and experiments
signed_err = estim_param_vals - true_param_vals; % Signed estimation error
switch error_type
    case 'sqr' % Square error
        fit_err = signed_err.^2;
    case 'abs' % Absolute error
        fit_err = abs(signed_err);
end
loss = mean(fit_err(:)); % Average over subjects and experiments

% Collect other information about design quality
loss_info.signed_err = signed_err;

end

