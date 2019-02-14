function [loglik, results] = nssm_likelihood_batch(params_packed, data, nssm, param_info, params_fixed)
%nssm_likelihood_batch is the log-likelihood function for a Non-linear State-Space Model.
%
% Usage: 
%   [loglik, results] = nssm_likelihood_batch(params_packed, data, nssm, param_info[, params_fixed])
%
% Args:
%   params_packed [nParam x 1] : All model parameters packed into a vector.
%   data : Structure with input data of one subject
%       .nTrials : number of trials
%       .csInput [nTrials x nCues] : CS indicators
%       .usInput [nTrials x 1] : US indicator
%       .crOutput [nTrials x 1]: responses to CSs (i.e. CRs)
%   nssm : structure defining the non-linear state-space model
%       .evo_func_batch [func] : evolution function handle
%       .obs_func_batch [func] : observation function handle
%   param_info [nParam x 1] : model parameter structure array with fields
%       .name : name of the parameter
%       .type ['evo'|'obs'] : type of the parameter ('evo' for evolution
%           params, and 'obs' for observation params)
%   params_fixed [struct, optional] : structure containing fixed parameter
%       values
%       .evo : evolution func. parameters structure
%       .obs : observation func. parameters structure
%
% Returns:
%   loglik : log-likelihood
%   results : structure with latent variables
%       .evo : result structure of the evolution function
%       .obs : result structure of the observation function

% Get the fixed parameters if they are provided
if exist('params_fixed','var') && ~isempty(params_fixed)
  params_unpacked = params_fixed;
end

% Unpack the parameter values into correctly named fields
for iParam = 1:length(param_info)
    currParam = param_info(iParam);
    params_unpacked.(currParam.type).(currParam.name) = params_packed(iParam);
end

% Predict observations using the NSSM
results = nssm_predict_batch(data.csInput, data.usInput, nssm, params_unpacked);

% Compute the log likelihood
pointwise_logs = log(normpdf(data.crOutput, results.obs.crPred, params_unpacked.obs.sd));
isNegInfLog = isinf(pointwise_logs) & (pointwise_logs < 0);
pointwise_logs(isNegInfLog) = -1000; % Replace -Inf with -1000 to obtain a usable log-likelihood value
loglik = sum(pointwise_logs);  % log-likelihood
% TODO: find a nicer fix for infinite log-likelihoods 


end

