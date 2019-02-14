function [crOutput, results] = nssm_simulate_batch(csInput, usInput, nssm, params)
%nssm_simulate_batch simulates noisy CRs using a non-linear state-space model
%
% Usage: 
%   [crOutput, results] = nssm_simulate_batch(csInput, usInput, nssm, params)
%
% Args:
%   csInput [nTrials x nCues] : CS indicators
%   usInput [nTrials x 1] : US indicator
%   nssm : structure defining the non-linear state-space model
%       .evo_func_batch [func] : evolution function handle
%       .obs_func_batch [func] : observation function handle
%   params : model parameter structure
%       .evo : evolution func. parameters structure
%       .obs : observation func. parameters structure
%
% Returns:
%   crOutput [nTrials x 1] : simulated noisy CRs
%   results : results structure
%       .evo : result structure of the evolution function
%       .obs : result structure of the observation function 
 

% Generate CR predictions
results = nssm_predict_batch(csInput, usInput, nssm, params);

% Add Gaussian iid noise to the CR predictions
crOutput = results.obs.crPred + normrnd(0, params.obs.sd, size(results.obs.crPred));
results.obs.crOutput = crOutput;



end

