function mod_space_out = parse_model_space_cfg(mod_space_in)
%PARSE_MODEL_SPACE_CFG parses the model space configuration structure obtained 
%by reading a YAML config file into a format usable by evaluate_design
%
% Usage:
%   mod_space_out = parse_model_space_cfg(mod_space_in)
%
% Args:
%   mod_space_in [n_models x 1, cell array] : each cell is a model
%       structure with following fields
%       .name [str] : model name
%       .type [str] : model type ['generic'|'nssm']
%       .sim_func [str, for 'generic'] : name of the simulation function
%           (only necessary for sampling model spaces)
%       .loglik_func [str, for 'generic'] : name of the log-likelihood
%           function (only necessary for fitting model spaces)
%       .evo_func [str, for 'nssm'] : name of the evolution function
%       .obs_func [str, for 'nssm'] : name of the observation function
%       .prior_sim [struct, optional] : sampling prior structure (only
%           necessary for sampling model spaces)
%       .prior_fit [n_param x 1 cell array of struct, optional] : 
%           fitting prior structure for all params (only necessary for
%           fitting model spaces)
%       .params_fit_fixed [struct, optional] : values of fixed parameters (only
%           necessary for fitting model spaces)
%
% Returns:
%   mod_space_out [struct] :
%       .models [n_models x 1, struct array] : model information structures
%       .prior_sim [n_models x 1, cell array, optional] : sampling prior structures
%       .prior_fit [n_models x 1, cell array, optional] : fitting prior structure
%           arrays
%       .params_fit_fixed [n_models x 1, cell array, optional] : structures with
%           values of fixed parameters in fitting models

n_model = length(mod_space_in);
for i_mod = 1 : n_model
    %% Get model specification
    model_out = struct(); % Initialize parsed model specification
    model_in = mod_space_in{i_mod};
    
    % Copy name and type of model
    model_out.name = model_in.name;
    model_out.type = model_in.type;
    
    % Get simulation and/or log-likelihood functions
    switch model_in.type
        case 'generic' % Generic model defined with a simulation and log-likelihood functions
            if isfield(model_in, 'sim_func') && ~isempty(model_in.sim_func)
                model_out.sim_func = str2func(model_in.sim_func);
            end
            if isfield(model_in, 'loglik_func') && ~isempty(model_in.loglik_func)
                model_out.loglik_func = str2func(model_in.loglik_func);
            end
        case 'nssm' % Non-linear State-Space Model defined with an evolution and observation functions
            nssm = struct();
            nssm.evo_func_batch = str2func(model_in.evo_func);
            nssm.obs_func_batch = str2func(model_in.obs_func);
            model_out.sim_func = @(csInput, usInput, params) nssm_simulate_batch(csInput, usInput, nssm, params);
            model_out.loglik_func = @(params_packed, data, param_info, params_fixed)...
                nssm_likelihood_batch(params_packed, data, nssm, param_info, params_fixed);
    end
    
    % Add model to the parsed models structure array
    mod_space_out.models(i_mod) = model_out;
    
    %% Get sampling prior
    if isfield(model_in, 'prior_sim') && ~isempty(model_in.prior_sim)
        mod_space_out.prior_sim{i_mod} = model_in.prior_sim;
    end
    
    % Get fitting prior into a structure array
    if isfield(model_in, 'prior_fit') && ~isempty(model_in.prior_fit)
        n_params = numel(model_in.prior_fit);
        for i_param = 1 : n_params
            param_prior_fit = model_in.prior_fit{i_param};
            % Transform the logpdf to a function handle
            param_prior_fit.logpdf = str2func(param_prior_fit.logpdf);
            % If lower bound is a string (e.g. 'Inf' or 'NaN')
            if ischar(param_prior_fit.lb)
                param_prior_fit.lb = str2double(param_prior_fit.lb);
            end
            % If upper bound is a string (e.g. 'Inf' or 'NaN')
            if ischar(param_prior_fit.ub)
                param_prior_fit.ub = str2double(param_prior_fit.ub);
            end
            mod_space_out.prior_fit{i_mod}(i_param) = param_prior_fit;
        end
    end
      
    % Get values of fixed parameters in the fitting model
    if isfield(model_in, 'params_fit_fixed') && ~isempty(model_in.params_fit_fixed)
        mod_space_out.params_fit_fixed{i_mod} = model_in.params_fit_fixed;
    else
        mod_space_out.params_fit_fixed{i_mod} = [];
    end
end


end

