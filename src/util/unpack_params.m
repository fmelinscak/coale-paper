function unpacked_params = unpack_params(packed_params, param_info)
%UNPACK_PARAMS take parameters in a vector and a structure with parameter
%names and creates a structure with parameter values in appropriately named
%fields (inputs from fitting_results can be used here)

unpacked_params = struct();

for i_param = 1 : length(param_info)
    param_type = param_info(i_param).type;
    param_name = param_info(i_param).name;
    param_val = packed_params(i_param);
    if ~isempty(param_type)
        unpacked_params.(param_type).(param_name) = param_val;
    else
        unpacked_params.(param_name) = param_val;
    end
end

end

