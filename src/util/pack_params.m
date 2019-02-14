function packed_params = pack_params(unpacked_params)
%PACK_PARAMS flattens a structure with (nested) parameters into a vector
%(recursive depth-first search)

packed_params = [];
fields = fieldnames(unpacked_params);
% Recursively find parameter values (depth first)
for i_field = 1 : length(fields)
    field_value = unpacked_params.(fields{i_field});
    if isstruct(field_value) % Recurse if the field is itself a structure
        packed_params = vertcat(packed_params, pack_params(field_value));
    else % Add the field value to packed params if it is not a structure (recursion termination)
        packed_params = vertcat(packed_params, field_value);
    end
end

end

