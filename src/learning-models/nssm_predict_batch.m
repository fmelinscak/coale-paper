function results = nssm_predict_batch(csInput, usInput, nssm, params)
%nssm_predict_batch predicts CRs using a non-linear state-space model
%
% Usage: 
%   results = nssm_predict_batch(csInput, usInput, nssm, params)
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
%   results : results structure
%       .evo : result structure of the evolution function
%       .obs : result structure of the observation function 

% Run model state evolution (on batch of all trials)
results.evo = nssm.evo_func_batch(csInput, usInput, params.evo);

% Run the observation function to generate CR predictions
results.obs = nssm.obs_func_batch(results.evo, csInput, usInput, params.obs);

end

