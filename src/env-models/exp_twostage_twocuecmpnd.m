function data = exp_twostage_twocuecmpnd(desvars)
%exp_twostage_twocuecmpnd generates the stimuli for a two stage design with two CS cues and their compound
%   
%   exp_twostage_twocuecmpnd randomly generates the CS and US sequence for an experiment
%   in which two cues (A, B) and their compound (AB) can appear and be
%   followed by an US. The experiment is divided into two stages. In each
%   stage the appearance of the CSs and the US is determined by set
%   probabilities, which can vary across stages.
%
%
% Usage: 
%   data = exp_twostage_twocuecmpnd(desvars)
%
% Args:
%   desvars [struct] : design variables structure
%       .nTrialsAll [2 x 1] : the number of trials for each stage
%       .probA_1 :  Prob CS A in stage 1
%       .probB_1 : Prob CS B in stage 1
%       .probUS_A_1 : Prob (US | CS A) in stage 1
%       .probUS_B_1 : % Prob (US | CS B) in stage 1
%       .probUS_AB_1 : Prob (US | CS AB) in stage 1
%       .probA_2 :  Prob CS A in stage 2
%       .probB_2 : Prob CS B in stage 2
%       .probUS_A_2 : Prob (US | CS A) in stage 2
%       .probUS_B_2 : % Prob (US | CS B) in stage 2
%       .probUS_AB_2 : Prob (US | CS AB) in stage 2
%   Note: probAB_1 = 1 - (probA_1 + probB_1), probAB_2 = 1 - (probA_2 + probB_2)  
%
% Returns:
%   data : structure with generated stimuli
%       .nTrials : total number of trials (across all stages)
%       .csInput [nTrialsAll x 2] : CS indicator 
%       .usInput [nTrialsAll x 1] : US indicator

omegaAll = [];

% First stage parameters;
omegaAll(1).csPatterns = [...
    1 0; % A
    0 1; % B
    1 1]; % AB
omegaAll(1).patternProb = ...
    [desvars.probA_1, desvars.probB_1, 1 - (desvars.probA_1 + desvars.probB_1)]; 
omegaAll(1).usProb = ...
    [desvars.probUS_A_1, desvars.probUS_B_1, desvars.probUS_AB_1]; 

% Second stage parameters
omegaAll(2).csPatterns = [...
    1 0; % A
    0 1; % B
    1 1]; % AB
omegaAll(2).patternProb = ...
    [desvars.probA_2, desvars.probB_2, 1 - (desvars.probA_2 + desvars.probB_2)]; 
omegaAll(2).usProb = ...
    [desvars.probUS_A_2, desvars.probUS_B_2, desvars.probUS_AB_2]; 

% Use stochastic conditioning to generate stimuli
desvars_stochastic = struct(...
    'nTrialsAll', desvars.nTrialsAll,...
    'omegaAll', omegaAll);
data = exp_stochastic_conditioning(desvars_stochastic);

end

