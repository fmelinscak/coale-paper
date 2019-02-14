function [loss, loss_info] = loss_modsel_err(fitting_results, ~, options)
%LOSS_MODSEL_ERR calculates the loss as model selection error. 
%
% Usage:
%   [loss, loss_info] = loss_modsel_err(fitting_results, ~[, options])
%
% Args:
%   fitting_results {n_modsim x 1} : Results of fitting models using the fit_models
%           function.
%   options [struct, optional] : 
%       .criterion [str] : Criterion name. Expected values: {'aic', 'bic'}.
%           Default: 'bic'. 
%       .do_logodds [bool]. Whether to transform model selection error from
%           the probability scale to the logodds scale. Default: true.
%
% Returns:
%   loss [double] : Loss value.
%   loss_info [struct] : Additional information about loss calculation.
%       .confusion_matrix [n_modsim x n_modfit] : Confusion matrix with
%           rows indexing true models, and columns indexinf fitted models.
%       .avg_acc [prob] : Accuracy of model selection (averaged over
%           models).
%       .avg_err [prob] : Error of model selection (averaged over models).
%       Following fields are computed only for log-odds loss:
%       .is_loss_adjusted [bool] : Did loss need to be adjusted? (case of
%           accuracy = 1 or 0)
%       .adjusted_conf_matrix [n_modsim x n_modfit] : Adjusted confusion
%           matrix. (Added or subtracted half of an observation from the
%           diagonal.)
%       .adjusted_avg_acc [prob] : Accuracy of model selection (averaged
%           over models) computed from adjusted confusion matrix.
%       .adjusted_avg_err [prob] : Error of model selection (averaged
%           over models) computed from adjusted confusion matrix.
%       

%% Parse input options
% Create parser
opt_parser = inputParser;
default_criterion = 'bic';
expected_criteria = {'aic', 'bic'};
default_do_logodds = true;

opt_parser.addParameter('criterion', default_criterion,...
    @(x) any(validatestring(x, expected_criteria)));
opt_parser.addParameter('do_logodds', default_do_logodds);

% Parse inputs and get results
if ~exist('options', 'var') || isempty(options)
    opt_parser.parse(struct());
else
    opt_parser.parse(options);
end

criterion = opt_parser.Results.criterion;
do_logodds = opt_parser.Results.do_logodds;


%% Determine number of simulated and fitted models and the number of experiments per simulated model
n_modsim = numel(fitting_results);
[n_exp, n_modfit] = size(fitting_results{1});


%% Perform model selection
confusion_matrix = zeros(n_modsim, n_modfit);

for i_exp = 1 : n_exp
    for i_modsim = 1 : n_modsim
        curr_confusion_row_evidence = nan(1, n_modfit);
        for i_modfit = 1 : n_modfit
            curr_confusion_row_evidence(1, i_modfit) = ...
                mean(fitting_results{i_modsim}(i_exp, i_modfit).(criterion));
        end
        
        [~, i_winning_model] = min(curr_confusion_row_evidence);
        confusion_matrix(i_modsim, i_winning_model) = ...
            confusion_matrix(i_modsim, i_winning_model) + 1;       
    end
end


%% Calculate design utility
% Loss: model selection error averaged over models (on logit scale)
avg_acc = mean(diag(confusion_matrix) ./ sum(confusion_matrix, 2));
avg_err = 1 - avg_acc;

% Optional: transform the error to the log-odds scale (making sure to avoid
% infinities)
if do_logodds
    is_loss_adjusted = false;
    adjusted_conf_matrix = confusion_matrix;
    if avg_err == 0 % No elements off-diagonal in the confusion matrix
        adjusted_conf_matrix(1,1) = adjusted_conf_matrix(1,1) - 0.5; % Subtract half an observation from the diagonal
        is_loss_adjusted = true;
    elseif avg_err == 1 % All elements off-diagonal in the confusion matrix
        adjusted_conf_matrix(1,1) = adjusted_conf_matrix(1,1) + 0.5; % Add half an observation to the diagonal
        is_loss_adjusted = true;
    end
    
    adjusted_avg_acc = mean(diag(adjusted_conf_matrix) ./ sum(confusion_matrix, 2));
    adjusted_avg_err = 1 - adjusted_avg_acc;
    loss = log(adjusted_avg_err ./ (1 - adjusted_avg_err));
else % If not transforming to log-odds
    loss = avg_err;
    is_loss_adjusted = [];
    adjusted_conf_matrix = [];
    adjusted_avg_acc = [];
    adjusted_avg_err = [];
end


% Collect other information about design quality
loss_info.confusion_matrix = confusion_matrix;
loss_info.avg_acc = avg_acc;
loss_info.avg_err = avg_err;
loss_info.is_loss_adjusted = is_loss_adjusted;
loss_info.adjusted_conf_matrix = adjusted_conf_matrix;
loss_info.adjusted_avg_acc = adjusted_avg_acc;
loss_info.adjusted_avg_err = adjusted_avg_err;


end

