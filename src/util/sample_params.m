function param_samples = sample_params(param_distr)
%sample_params samples parameter values from a structure with
%parameter distributions/values
%
% sample_params traverses the param_distr structure recursively
% (depth-first) and replaces all the sampling distributions (function
% handles) with samples and leaves constant values in place.
%
% Usage:
%   param_samples = sample_params(param_distr)
%
% Arguments:
%   param_distr [struct] : structure containing:
%       - fields with constant parameter values
%       - fields with function handles to parameter sampling distribution
%       - fields with a nested parameter structure (visited recursively)
%
% Returns:
%   param_samples [struct] : same as the param_distr structure, but with all the
%       function handles replaced by a sample value from the function


% Recursively find parameter distributions and sample from them or use
% constant parameter values if they are found
fields = fieldnames(param_distr);

for i_field = 1 : length(fields)
    field_value = param_distr.(fields{i_field});
    if isstruct(field_value) % Recurse if the field is itself a structure
        param_samples.(fields{i_field}) = sample_params(field_value);
    elseif isa(field_value, 'function_handle') % If the field is a probability distr. sample from it
        param_samples.(fields{i_field}) = field_value();
    elseif isnumeric(field_value) % Use constant parameter value (recursion termination)
        param_samples.(fields{i_field}) = field_value;
    elseif ischar(field_value) % If the field is a string, try to convert it to a function handle
        distr_func = str2func(field_value);
        param_samples.(fields{i_field}) = distr_func();     
    else
        error('Unsupported type of parameter.')
    end
    
end
    
end


