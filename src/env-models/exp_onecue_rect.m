function data = exp_onecue_rect(desvars)
%exp_onecue_rect generates a CS-US sequence with a periodic, rectangular
%contingecy modulation.
%
% Usage: 
%   data = exp_onecue_rect(desvars)
%
% Args:
%   desvars [struct] : design variables structure
%       .nTrials : total number of trials to generate
%       .halfPeriod : number of trials that comprise one half-period
%           or
%       .halfPeriodFrac : fraction of the total number of trials that
%           comprise one half-period (in [0,1])
%       .usProbFirst : probability of the US in the first half-period
%       .usProbSecond : probability of the US in the second half-period
%
% Returns:
%   data : structure with generated stimuli
%       .nTrials : number of trials
%       .csInput [nTrials x 1] : CS indicator
%       .usInput [nTrials x 1] : US indicator

% Get design variables
nTrials = desvars.nTrials;

if isfield(desvars, 'halfPeriod') && isfield(desvars, 'halfPeriodFrac')
    error('Only halfPeriod or halfPeriodFrac can be defined, not both.')
elseif isfield(desvars, 'halfPeriod')
    halfPeriod = desvars.halfPeriod;
elseif isfield(desvars, 'halfPeriodFrac')
    halfPeriod = max(1, round(desvars.halfPeriodFrac * nTrials)); % Make sure the halfperiod is not smaller than 1 trial
end
    
usProbFirst = desvars.usProbFirst;
usProbSecond = desvars.usProbSecond;

% Determine the trial-resolved probability of US occuring
usProbOnePeriod = [... % One period of contingencies
    repmat(usProbFirst, halfPeriod, 1);
    repmat(usProbSecond, halfPeriod, 1)];
usProbLong = repmat(usProbOnePeriod, ceil(nTrials/(2*halfPeriod)), 1); % Generate the US probabilities covering all trials
usProbAdjusted = usProbLong(1:nTrials); % Take only nTrials values
usInput = rand(nTrials, 1) < usProbAdjusted; % Randomly and independently determine US occurences

% Collect output
data = struct(...
    'nTrials', nTrials,...
    'csInput', ones(nTrials, 1),... % CS is always the same
    'usInput', usInput);
    

end

