function sim_info = run_design_optimization(cfg_filepath, save_output, output_filepath)
%RUN_DESIGN_OPTIMIZATION optimizes an experimental design. Optionally, it saves
%the results and the configuration to the disk. Can be called from CLI.
%
% Usage:
%   sim_info = run_design_optimization(cfg_filepath, save_output, output_filepath)
%
% Args:
%   cfg_filepath [path] : Path to the optimization configuration file.
%       See parse_optim_cfg for expected variables.
%   save_output [bool, default=false] : Whether to save the optimization
%       results to disk.
%   output_filepath [path] : Full path to where the result file should be
%       saved. If not provided, configuration variables are used to form
%       the timestamped path.
%
% Returns:
%   sim_info [struct] : Configuration and results of the optimization.
%       WARNING: if the output is not captured in a variable, function
%       assumes it is called from the CLI and exits upon completion.

try % Catch any top-level errors so the function exits with failure code
    %% Imports
    addpath(genpath(fullfile('.'))); % Add the src folder and subfolders
    addpath(fullfile('..', 'external', 'mfit')); % Add the mfit toolbox
    addpath(fullfile('..', 'external', 'get-git-info-alt')); % Add the get-git-info-alt toolbox
    addpath(fullfile('..', 'external', 'yamlmatlab')); % Add the YAML parser toolbox
    
    %% Load simulation configuration file
    cfg_optim = yaml.ReadYaml(cfg_filepath, [], 1); % Load configuration from YAML file
    sim_info = cfg_optim; % Copy input config into simulation info
    
    %% Set RNG
    rng(cfg_optim.sim_run.rng_seed);
    
    %% Obtain the information about the code and execution environment
    sim_info.execution_env.git = getGitInfoAlt('..'); % Information about the project Git repo (branch, commit, remote url)
    if isempty(sim_info.execution_env.git)
        warning('No git repository detected in ''../.git/''.')
    end
    sim_info.execution_env.matlab = struct('text', evalc('ver()'), 'toolboxes', ver()); % Information about Matlab and toolboxes
    
    %% Prepare configuration
    cfg_optim_parsed = parse_optim_cfg(cfg_optim);
    sim_info.cfg_optim_parsed = cfg_optim_parsed; % Keep the parsed version of the cfg just for debugging purposes (TODO: remove)
    
    %% Get objective function handle
    obj_func_handle = @(d) obj_func(d, cfg_optim_parsed);
    
    %% Get optimizable design variables
    n_desvars_optim = numel(cfg_optim.exp_design.desvars_optim);
    desvars_optim(n_desvars_optim, 1) = optimizableVariable; % Initialize array of optimizable variables
    for i_var = 1 : n_desvars_optim
        curr_var = cfg_optim.exp_design.desvars_optim{i_var};
        desvars_optim(i_var) = optimizableVariable(curr_var.name, curr_var.range, 'Type', curr_var.type);
    end
    
    %% Get Bayesian optimization options into Name-Value-pair format
    optim_opts = cfg_optim_parsed.optim_opts; % Get optimization options
    if isfield(optim_opts, 'store_user_data_trace')
        optim_opts = rmfield(optim_opts, 'store_user_data_trace'); % `store_user_data_trace` is not an option of the `bayesopt` function
    end
    optim_opt_names = fieldnames(optim_opts)';
    
    optim_opt_values = struct2cell(optim_opts)';
    optim_opt = [optim_opt_names; optim_opt_values]; % Combine names and values into a single cell array
    optim_opt = optim_opt(:); % Collate the name-value pairs (by alternating between them) into a single vector
    
    %% Run Bayesian optimization
    results_optim = bayesopt(obj_func_handle, desvars_optim, optim_opt{:});
    
    %% Collect results
    sim_info_boptobj = sim_info;
    sim_info_boptobj.results_optim = results_optim;
        
    % Get reduced optimization results without the 'UserDataTrace' from bayesopt (i.e.
    % design evaluation details)
    results_optim_reduced = struct();
    fields = fieldnames(results_optim);
    n_fields = length(fields);
    for i_field = 1 : n_fields
        field_name = fields{i_field};
        if ~strcmp(field_name, 'UserDataTrace') % Do not save the UserDataTrace in the reduced version of results, as it may be large
            results_optim_reduced.(field_name) = results_optim.(field_name);
        end
    end
    
    % Create sim_info with reduced optimization results
    sim_info.results_optim = results_optim_reduced;
    
    %% Save configuration and result variables to disk
    if exist('save_output', 'var') && save_output == true
        if exist('output_filepath', 'var') && ~isempty(output_filepath)
            % Determine result directory name
            [results_dirname, results_filename, ~] =...
                fileparts(output_filepath);
            % Determine results filepath (without extension)
            results_filepath = fullfile(results_dirname, results_filename);
        else
            results_path = fullfile(cfg_optim.sim_set.results_path);
            utc_time = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd_HH-mm-ss'); % Get UTC time
            file_timestamp = [char(utc_time),'UTC']; % UTC time in ISO format
            simulation_name = cfg_optim.sim_run.name;
            timestamped_sim_name = strjoin({file_timestamp, simulation_name}, '_');
            
            % Determine result directory name
            results_dirname = fullfile(results_path, timestamped_sim_name);
            
            % Determine results filepath (without extension)
            results_filename = timestamped_sim_name;
            results_filepath = fullfile(results_dirname, results_filename);
        end
        
        % Create directory for results
        mkdir(results_dirname); % Warns if the folder already exists
        
        % Copy the configuration file to results directory
        copyfile(cfg_filepath, results_dirname)

        % Save reduced results
        try
            fprintf('Saving the optimization results (reduced)...\n')
            tic
            lastwarn('') % Clear last warning message
            save(results_filepath, 'sim_info', '-v7') % v7 format is limited to 2 GB files
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnMsg)
                error(warnId, warnMsg); % Raise warning to error and throw it
            end
            toc
        catch
            warning('Saving to v7 .mat was not successful, trying with the slower and bigger v7.3 format.')
            tic
            save(results_filepath, 'sim_info', '-v7.3') % v7.3 can result in large files and slow saving
            toc
        end
        
        % Save full results
        try
            fprintf('Saving the optimization results (full)...\n')
            tic
            lastwarn('') % Clear last warning message
            save([results_filepath, '_boptobj'], 'sim_info_boptobj', '-v7') % v7 format is limited to 2 GB files
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnMsg)
                error(warnId, warnMsg); % Raise warning to error and throw it
            end
            toc
        catch
            warning('Saving to v7 .mat was not successful, trying with the slower and bigger v7.3 format.')
            tic
            save([results_filepath, '_boptobj'], 'sim_info_boptobj', '-v7.3') % v7.3 can result in large files and slow saving
            toc
        end
        
    end
    
    % Exit with success code (if no output arguments, i.e. function is
    % assumed to be executed with the CLI)
    if nargout == 0
        exit(0);
    end
catch ME 
    % Exit with failure code (if no output arguments, i.e. function is
    % assumed to be executed with the CLI)
    if nargout == 0
        fprintf(getReport(ME)); % Print the error message
        exit(1); % Exit with failure code
    else % Otherwise rethrow exception 
        rethrow(ME);
    end
end

end

function [loss, constraints, outputs] = obj_func(desvars, cfg_optim)
%obj_func is the optimizable wrapper for the 'evaluate_design' function

% Merge constant and optimizable design variables
merged_desvars = table2struct(desvars); % Add current desvar values

desvars_const = cfg_optim.desvars_const;
const_names = fieldnames(desvars_const);
for i_const = 1 : numel(const_names) % Copy the constants into merged design variables struct
    const_name = const_names{i_const};
    merged_desvars.(const_name) = ...
        desvars_const.(const_name);
end

% Determine if user data trace is stored
optim_opts = cfg_optim.optim_opts; % Get optimization options
if isfield(optim_opts, 'store_user_data_trace')
    store_user_data_trace = optim_opts.store_user_data_trace;
else
    store_user_data_trace = false; % Results of all the simulations are not stored unless requested (can result in large files and slow saving)
end

% Evaluate the design
[loss, constraints, tmp_outputs] = evaluate_design(...
    cfg_optim.exp_design_func, merged_desvars,...
    cfg_optim.eval_opts.n_exp, cfg_optim.desvars_const.n_sub, ...
    cfg_optim.models_sim, cfg_optim.prior_sim,...
    cfg_optim.models_fit, cfg_optim.prior_fit,...
    cfg_optim.params_fit_fixed,...
    cfg_optim.criterion_func, cfg_optim.criterion_options,...
    cfg_optim.eval_opts.verbose, cfg_optim.eval_opts.parallel);

% Output data trace if necessary
if store_user_data_trace
    outputs = tmp_outputs;
else
    outputs = [];
end

end



