function results = fit_models(data, models, params, params_fixed, verbose, parallel, nstarts)
%fit_models fits multiple models to multiple experiments.
%   
%   fit_models fits multiple given models, to data of multiple experiments.
%   The Maximum A Posteriori (MAP) estimate of model parameters is returned
%   as the results. The MAP estimate is obtained by using the given priors
%   for the model parameters. Under flat priors, MAP estimate is equal to
%   the maximum likelihood (ML) estimate.
%   
%
% Usage: results = fit_models(data, models, params[, params_fixed, verbose, parallel, nstarts])
%
% Args:
%   data [nSubjects x nExperiments]: structure array  with stimuli and
%       response data
%       .nTrials : number of trials
%       .csInput [nTrials x nCues] : CS indicator 
%       .usInput [nTrials x 1] : US indicator
%       .crOutput [nTrials x 1] (optional) : responses to CSs (i.e. CRs)
%   models [nModels x 1] : structure array describing models to
%       fit.
%       .name [string]: name of the model
%       .loglik_func [func] : log-likelihood function of the model
%   params {nModels x 1}  : cell arrays of parameter structure arrays of 
%       size [nModelParams x 1, with fields
%           .name [string] : name of the parameter (must be valid fieldname)
%           .logpdf [func] : log-prior of the parameter
%           .lb : lower bound of the parameter
%           .ub : upper bound of the parameter
%           .init : initial value of the parameter (if not provided, then
%           sampled from Unif(lb, ub))
%   params_fixed {nModels x 1, optional}  : cell arrays of model parameter structures
%       with fixed parameter values
%   verbose [bool, optional] : if the diagnostic text output should be verbose
%   (default: true)
%   parallel [bool, optional] : if experiments should be fitted in
%       parallel (default: false)
%   nstarts [int, optional] : how many times to restart fitting
%       (useful if combined with undefined initial parameters; 
%       if empty defaults to mfit_optimize settings.)
%       
% Returns:
%   results [nExperiments x nModels] : 
%       structure array with results (see mfit_optimize for fields)

if ~exist('params_fixed', 'var')
    params_fixed = [];
end

if ~exist('verbose', 'var') || isempty(verbose)
    verbose = true;
end

if ~exist('parallel', 'var') || isempty(verbose) || parallel == false
    max_parfor_workers = 0; % Serial execution
elseif parallel == true
    max_parfor_workers = Inf; % Use as many workers as possible in parallel
end

if ~exist('nstarts', 'var')
    nstarts = [];
end

[~, nExperiments] = size(data);
nModels = length(models);

for iModel = 1 : nModels  
    currModel = models(iModel);
    currParams = params{iModel};
    currParamsFixed = params_fixed{iModel};
    
    parfor (iExp = 1 : nExperiments, max_parfor_workers)
        currData = data(:, iExp);
        if verbose
            fprintf('Fitting model %s to exp. %d ...\n', currModel.name, iExp)
        end
        % Fit model
        loglik_func = ... % Get log-likelihood function
            @(x, data) currModel.loglik_func(x, data, currParams, currParamsFixed);   
        
        currResults = mfit_optimize(loglik_func, currParams, currData, nstarts, verbose); 
       
        results(iExp, iModel) = currResults;
    end
        
end

end

