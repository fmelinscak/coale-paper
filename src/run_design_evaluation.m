function sim_info = run_design_evaluation(cfg_filepath, save_output, output_filepath)
%RUN_DESIGN_EVALUATION evaluates an experimental design. Optionally, it saves
%the results and the configuration to the disk. Can be called from CLI.
%
% Usage:
%   sim_info = run_design_evaluation(cfg_filepath, save_output, output_filepath)
%
% Args:
%   cfg_filepath [path] : Path to the evaluation configuration file.
%       See parse_eval_cfg for expected variables.
%   save_output [bool, default=false] : Whether to save the evaluation
%       results to disk.
%   output_filepath [path] : Full path to where the result file should be
%       saved. If not provided, configuration variables are used to form
%       the timestamped path.
%
% Returns:
%   sim_info [struct] : Configuration and results of the evaluation.
%       WARNING: if the output is not captured in a variable, function
%       assumes it is called from the CLI and exits upon completion.

try % Catch any top-level errors so the function exits with failure code
    %% Imports
    addpath(genpath(fullfile('.'))); % Add the src folder and subfolders
    addpath(fullfile('..', 'external', 'mfit')); % Add the mfit toolbox
    addpath(fullfile('..', 'external', 'get-git-info-alt')); % Add the get-git-info-alt toolbox
    addpath(fullfile('..', 'external', 'yamlmatlab')); % Add the YAML parser toolbox
    
    %% Load simulation configuration file
    cfg_eval = yaml.ReadYaml(cfg_filepath, [], 1); % Load configuration from YAML file
    sim_info = cfg_eval; % Copy input config into simulation info
    
    %% Set RNG
    rng(cfg_eval.sim_run.rng_seed);
    
    %% Obtain the information about the code and execution environment
    sim_info.execution_env.git = getGitInfoAlt('..'); % Information about the project Git repo (branch, commit, remote url)
    if isempty(sim_info.execution_env.git)
        warning('No git repository detected in ''../.git/''.')
    end
    sim_info.execution_env.matlab = struct('text', evalc('ver()'), 'toolboxes', ver()); % Information about Matlab and toolboxes
    
    %% Prepare configuration for evaluate_design
    cfg_eval_parsed = parse_eval_cfg(cfg_eval);
    sim_info.cfg_eval_parsed = cfg_eval_parsed; % Keep the parsed version of the cfg just for debugging purposes (TODO: remove)
    
    %% Evaluate experimental design
    [loss, ~, outputs] = evaluate_design(...
        cfg_eval_parsed.exp_design_func, cfg_eval_parsed.desvars,...
        cfg_eval_parsed.n_exp, cfg_eval_parsed.n_sub, ...
        cfg_eval_parsed.models_sim, cfg_eval_parsed.prior_sim,...
        cfg_eval_parsed.models_fit, cfg_eval_parsed.prior_fit,...
        cfg_eval_parsed.params_fit_fixed,...
        cfg_eval_parsed.criterion_func, cfg_eval_parsed.criterion_options,...
        cfg_eval_parsed.verbose, cfg_eval_parsed.parallel,...
        cfg_eval_parsed.nstarts);
    
    % Collect results
    results_eval = struct();
    results_eval.loss = loss;
    results_eval.outputs = outputs;
    sim_info.results_eval = results_eval;
    
    
    %% Save configuration and result variables to disk
    if exist('save_output', 'var') && save_output == true
        if exist('output_filepath', 'var') && ~isempty(output_filepath)
            results_filepath = output_filepath;
            % Determine result directory name
            results_dirname = fileparts(output_filepath);
        else
            results_path = fullfile(cfg_eval.sim_set.results_path);
            utc_time = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd_HH-mm-ss'); % Get UTC time
            file_timestamp = [char(utc_time),'UTC']; % UTC time in ISO format
            simulation_name = cfg_eval.sim_run.name;
            timestamped_sim_name = strjoin({file_timestamp, simulation_name}, '_');
            
            % Determine result directory name
            results_dirname = fullfile(results_path, timestamped_sim_name);
            
            % Determine results filepath
            results_filename = timestamped_sim_name;
            results_filepath = fullfile(results_dirname, results_filename);
        end
        
        % Create directory for results
        mkdir(results_dirname); % Warns if the folder already exists
        
        % Save results
        try
            fprintf('Saving the evaluation results...\n')
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
        
        % Copy the configuration file to results directory
        copyfile(cfg_filepath, results_dirname)
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

