function data = exp_stochastic_conditioning(desvars)
%exp_stochastic_conditioning generates randomized CS-US sequence
%
%   exp_stochastic_conditioning generates the CS and US sequence for an experiment
%   which consists of one or more stages.
%
% Usage: 
%   data = exp_stochastic_conditioning(desvars)
%
% Args:
%   desvars [struct] : design variables structure
%       .nTrialsAll [nStages x 1] : number of trials per stage
%       .omegaAll [nStages x 1] : exp. design parameters structure for each stage
%           .csPatterns [nPatterns x nCues] : possible CS patterns (binary indicators)
%           .patternProb [nTrials x nPatterns] : trial-wise probability of a CS pattern appearing
%        or .patternProb [1 x nPatterns] : probabilities of CS patterns appearing (for the whole experiment
%           .usProb [nTrials x nPatterns] : trial-wise probability of a CS pattern being reinforced
%        or .usProb [1 x nPatterns] : probability of a CS pattern being reinforced (for the whole experiment)
%
% Returns:
%   data : structure with generated stimuli
%       .nTrials : total number of trials (across all stages)
%       .csInput [nTrialsAll x nCues] : CS indicator
%       .usInput [nTrialsAll x 1] : US indicator
% Note: the number of cues must be consistent across stages


nStages = length(desvars.omegaAll);

data = struct(...
    'nTrials', 0,...
    'csInput', [],...
    'usInput', []);

for iStage = 1 : nStages
    nTrials = desvars.nTrialsAll(iStage);
    if iscell(desvars.omegaAll)
        omega = desvars.omegaAll{iStage};
    elseif isstruct(desvars.omegaAll)
        omega = desvars.omegaAll(iStage);
    end
    
    % Generate CS pattern sequence
    if size(omega.patternProb, 1) == 1
        chosenPatternIdxs = fastrandsample(omega.patternProb, nTrials)'; % Sample patterns from a categorical distribution
    else
        chosenPatternIdxs = nan(nTrials, 1);
        for iTrial = 1 : nTrials
            chosenPatternIdxs(iTrial) = ...
                fastrandsample(omega.patternProb(iTrial,:)); % Sample pattern from a categorical distribution
        end
    end
    csInput = omega.csPatterns(chosenPatternIdxs, :);
    
    % Generate US sequence
    if size(omega.usProb, 1) == 1
        usInput = rand(nTrials, 1) < omega.usProb(1, chosenPatternIdxs)'; % Sample USs according to the pattern-conditional probabilities
    else
        usInput = nan(nTrials, 1);
        for iTrial = 1 : nTrials
            usInput(iTrial) = rand < omega.usProb(iTrial, chosenPatternIdxs(iTrial)); % Sample US according to the pattern-conditional probability
        end
        
    end
    
    % Gather results for output
    data.nTrials = data.nTrials + nTrials;
    data.csInput = [data.csInput; csInput];
    data.usInput = [data.usInput; usInput];
    
end

end

