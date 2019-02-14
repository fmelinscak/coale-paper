function merged_params = merge_params(varargin)
%MERGE_PARAMS takes evolution/observation function parameter structures 
%and merges them into a single parameter structure (e.g., merging
%structures with fitted and fixed parameters)

merged_params = struct();

for p_struct_cell = varargin
    p_struct = p_struct_cell{1};
    for fieldname_lvl1_cell = fieldnames(p_struct)'
        fieldname_lvl1 = fieldname_lvl1_cell{1};
        if ismember(fieldname_lvl1, {'obs', 'evo'})
            for fieldname_lvl2_cell = fieldnames(p_struct.(fieldname_lvl1))'
                fieldname_lvl2 = fieldname_lvl2_cell{1};
                merged_params.(fieldname_lvl1).(fieldname_lvl2) = ...
                    p_struct.(fieldname_lvl1).(fieldname_lvl2);
            end
        else
            merged_params.(fieldname_lvl1) = ...
                p_struct.(fieldname_lvl1);
        end        
    end
end


end

