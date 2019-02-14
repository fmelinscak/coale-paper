function results = evo_krw_batch(csInput, usInput, params)
%evo_krw_batch is the Kalman Rescorla-Wagner batch evolution function.
%
%   evo_krw_batch is the Kalman Rescorla-Wagner evolution function that is meant to
%   be applied in batch, i.e. for all trials at once. 
%   Model assumptions:
%   1) States (weights) evolve like a random walk (without deterministic dynamics or
%   inputs), with weights diffusing independently and with same variance
%   2) Observations (rewards) are noisy linear combinations of active stimuli
%   The model is described in:
%       Gershman, S.J. (2015).
%           "A unifying probabilistic view of associative learning."
%           PLoS computational biology, 11(11), p.e1004567.
%           https://doi.org/10.1371/journal.pcbi.1005829 
%
% Usage:
%   results = evo_krw_batch(csInput, usInput, params)
%
% Args:
%   csInput [nTrials x nCues] : CS indicator
%   usInput [nTrials x 1] : US indicator
%   params : structure containing parameters
%       .wInit [nCues x 1] : initial associative weights
%    or .wInit : common value of initial associative weights
%       .logSigmaWInit : log-variance of the initial weight distribution
%           (common value for all weights)
%       .logTauSq : log-variance of state diffusion (common value for all
%           weights)
%       .logSigmaRSq : log-variance of the observation (reward) noise
%       
% Returns:
%   results : structure wih the following fields:
%       .w [(nTrials+1) x nCues] : CS weights (together with inital ones)
%       .C [nCues x nCues x (nTrials+1)] : CS weight covariance matrix
%           (together with initial one)

%% Get parameters
[nTrials, nCues] = size(csInput);

if numel(params.wInit) == 1
    wInit = repmat(params.wInit, 1, nCues); % Use same initial weight for all cues
else
    wInit = params.wInit'; % Use separate initial weights
end

C_init = exp(params.logSigmaWInit)*eye(nCues); % Initial weight covariance matrix
tauSq = exp(params.logTauSq); % State diffusion variance
Q = tauSq*eye(nCues); % Transition noise variance (transformed to positive reals); constant over time
sigmaRSq = exp(params.logSigmaRSq); % Observation noise variance
    
%% Initialize results
% Initialize weights (states)
w = nan(nTrials+1, nCues);
w(1, :) = wInit; % Initial weights (states)

% Initialize weight covariance
C = nan(nCues, nCues, nTrials+1);
C(:, :, 1) = C_init;

%% Loop over trials
for t = 1 : nTrials
    % Get current states/inputs
    h_curr = csInput(t, :); % Get current CS features, which activate weights in reward prediction
    w_curr = w(t, :)'; % Get current weights as a column vector
    C_curr = C(:, :, t); % Get current weight covariance matrix
    us_curr = usInput(t); % Get current US value
    
    % Kalman prediction step
    w_pred = w_curr; % No mean-shift for the weight distribution evolution (only stochastic evolution)
    C_pred = C_curr + Q; % Update covariance
    
    % Compute prediction error
    rhat =  h_curr*w_pred; % Predict reward using predicted 
    delta = us_curr - rhat; % Calculate prediction error
    
    % Kalman update step
    K = (C_pred*h_curr') / (h_curr*C_pred*h_curr' + sigmaRSq);  % Kalman gain (weight-specific learning rates)
    w_updt = w_pred + K*delta; % Mean updated with prediction error
    C_updt = C_pred - K*h_curr*C_pred; % Covariance updated
    
    % Store updated weights and covariance matrix
    w(t+1, :) = w_updt;
    C(:, :, t+1) = C_updt;
end

%% Collect results
results = struct();
results.w = w;
results.C = C;


