function [data, latents] = simulate_data(nSubjects, nExperiments, exp_design_func, models, allOpts)
%simulate_data generates model-predicted CRs according to the given design
%   
%   simulate_data generates the CS and US sequence for multiple
%   experiments with multiple subjects each. The sequences are generated
%   according to the exp_design_func function handle. Thereafter, the given
%   models are used to predict noisy CRs (optional).
%   
%
% Usage: [data, latents] = simulate_data(nSubjects, nExperiments, exp_design_func, models, allOpts)
%
% Args:
%   nSubjects : number of subjects per experiments to simulate
%   nExperiments : number of experiments to simulate
%   exp_design_func [func] : function that generates stimuli for a single
%       subject
%   models [nModels x 1] (optional) : structure array describing models to
%       simulate. If models are not provided or are empty, function simulates only
%       stimuli, not the CRs.
%       .name [string]: name of the model
%       .sim_func [func] : simulation function of the model
%   allOpts {nModels x 1} (optional) : cell arrays of options structure
%       arrays of size [nSubjects x nExperiments], with each structure
%       describing the parameters of the model for the particular dataset
%       (see the model's sim_func for fields)
%       
% Returns:
%   data [nSubjects x nExperiments x nModels]: structure array  with generated stimuli
%       .nTrials : number of trials
%       .csInput [nTrials x nCues] : CS indicator 
%       .usInput [nTrials x 1] : US indicator
%       .crOutput [nTrials x 1] (optional) : responses to CSs (i.e. CRs)
%   latents [nSubjects x nExperiments x nModels] (optional) : 
%       structure array  with latent variables

if nargin < 4 || isempty(models) % Only simulate stimuli
    nModels = 0;
    data(nSubjects, nExperiments) = struct(...
        'nTrials', nan,...
        'csInput', [],...
        'usInput', []);
    latents = [];
else % Simulate both stimuli and responses
    nModels = length(models);
    data(nSubjects, nExperiments, nModels) = struct(...
        'nTrials', nan,...
        'csInput', [],...
        'usInput', [],...
        'crOutput', []);
    
    latents(nSubjects, nExperiments, nModels) = struct(...
        'evo', [],...
        'obs', []);
end
    


for iExp = 1 : nExperiments
    for iSub = 1 : nSubjects
        stimuliData = exp_design_func(); % Generate sequence of stimuli
        
        if nModels > 0 % If simulating model responses
            for iModel = 1 : nModels
                tmpData = stimuliData;
                model = models(iModel);
                opts = allOpts{iModel}(iSub, iExp);
                
                [tmpData.crOutput, results] = ...
                    model.sim_func(tmpData.csInput, tmpData.usInput, opts);
                
                data(iSub, iExp, iModel) = tmpData;
                latents(iSub, iExp, iModel) = results;
                
                
            end
        else % If simulating only stimuli
            data(iSub, iExp) = stimuliData;
        end
    end
end

end

