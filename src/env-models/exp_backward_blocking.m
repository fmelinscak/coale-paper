function data = exp_backward_blocking(desvars)
%exp_backward_blocking generates the stimuli for backward blocking designs
%   
%   exp_backward_blocking generates the CS and US sequence for an experiment
%   in which a compound CS AB is first reinforced, after which the single
%   CS A is reinforced.
%   I.e.:AB -> +, A -> +
%
% Usage: 
%   data = exp_backward_blocking(desvars)
%
% Args:
%   desvars [struct] : design variables structure
%       .nTrialsCompound : number of trials for reinforcement of the CS compound
%       .nTrialsSingle : number of trials for reinforcement of the single CS
%       .nCueTestTrials [optional] : number of trials per CS that are presented after
%           conditioning (without reinforcement); the CSs are presented in
%           an alternating deterministic fashion (e.g. A, B, A, B ...);
%           default: 0
% Returns:
%   data : structure with generated stimuli
%       .nTrials : number of trials
%       .csInput [nTrials x 2] : CS indicator 
%       .usInput [nTrials x 1] : US indicator

% Get design variables
nTrialsCompound = desvars.nTrialsCompound;
nTrialsSingle = desvars.nTrialsSingle;
if ~isfield(desvars, 'nCueTestTrials') || isempty(desvars.nCueTestTrials)
    nCueTestTrials = 0; % By default no test trials
else
    nCueTestTrials = desvars.nCueTestTrials;
end
    
% Design constants
nCues = 2;

% Set up design variables for stochastic conditioning
nTrialsAll = nan(2,1);
omegaAll = [];

% First stage parameters
nTrialsAll(1) = nTrialsCompound;
omegaAll(1).csPatterns = [...
    1 0; % A
    1 1]; % AB
omegaAll(1).patternProb = [0 1]; % Only AB in first stage
omegaAll(1).usProb = [0 1]; % Always reinforce AB


% Second stage parameters
nTrialsAll(2) = nTrialsSingle;
omegaAll(2).csPatterns = [...
    1 0; % A
    1 1]; % AB
omegaAll(2).patternProb = [1 0]; % Only A in second stage
omegaAll(2).usProb = [1 0]; % Always reinforce A

% Use stochastic conditioning to generate stimuli
desvars_stochastic = struct(...
    'nTrialsAll', nTrialsAll,...
    'omegaAll', omegaAll);
data = exp_stochastic_conditioning(desvars_stochastic);

% Generate test trials at the end
singleCsPatterns = eye(nCues);
testCsInput = repmat(singleCsPatterns, nCueTestTrials, 1); % Present CSs in an alternating, regular order
testUsInput = zeros(nCueTestTrials * nCues , 1); % None of the test trials are reinforced

% Append test trials
data.nTrials = data.nTrials + (nCueTestTrials * nCues);
data.csInput = [data.csInput; testCsInput];
data.usInput = [data.usInput; testUsInput];

end

