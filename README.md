# Computational optimization of associative learning experiments

Code accompanying the paper "Computational optimization of associative learning experiments".
The associated Open Science Framework project with the data (simulation results) can be found at <https://osf.io/5ktaf/>.


## Getting started

To run the code you will need MATLAB 2016b or newer, with installed `Statistics and Machine Learning Toolbox` and `Parallel Computing Toolbox` (if you wish to run the computations in parallel, which is recommended).
The results and figures from the paper paper can be reproduced by manually running MATLAB scripts, but to reproduce them automatically, using the provided Makefile, you will need [GNU Make](https://www.gnu.org/software/make/) (on Windows you can obtain GNU Make via [Chocolatey](https://chocolatey.org/packages/make)).

The code was tested with two software configurations:
  - Ubuntu 16.04.1, MATLAB 2016b, BASH 4.3.46, GNU Make 4.1
  - Windows 8.1 Pro, MATLAB R2018a, Git BASH 4.4.12, GNU Make 4.2
  

## Usage

The code is set up to produce optimized designs and design evaluations from the three scenarios provided in the paper:

  - Rescorla-Wagner learning rate (alpha) estimation (label: `rwae`)
  - Model selection based on Kruschke (2008) (label: `kru2008`)
  - Model selection based on Li et al. (2011) (label: `lsspd2011`)

The configuration files for these optimizations and evaluations are provided in the `config` directory.

### Evaluating the designs from the paper

To automatically produce figures and CSVs with design evaluation results, you can use the command line interface and the provided Makefile (`make help` lists available commands).
From the root directory of the project, execute the `make all` command in your shell (or in MATLAB with the `!` prefix: `!make all`).
The Makefile will trigger the following computations:

1. **Run the evaluation** of all the designs for all three scenarios from the paper (`rwae`, `kru2008`, `lsspd`) and store the results of these evaluations in a new `results/` directory.
2. **Create the figures** from the paper and store them in a new `results_figures/` directory.
3. **Export the results** in a tabular form (CSV) in a new `results_csvs/` directory.

Under Windows, each step of the pipeline will launch its own MATLAB command line window, whereas on Linux all the MATLAB instances will be launched within the shell.
**Warning**: running the design evaluations can take several hours.
The computation will finish sooner if you have a larger number of available CPU cores.
The code will automatically scale to the maximum number of available cores (you can set this option in MATLAB under Preferences -> Parallel Computing Toolbox -> Preferred number of workers).

**Alternatively**, if you wish to just recreate the figures and export CSVs, without re-running the evaluations, you can download the evaluation results from the [OSF project](https://osf.io/5ktaf/).
The evaluation results are in `*.mat` files in directories with paths `results/{scenario}/{scenario}_eval_*/`.
If you have these evaluation results downloaded into the project root directory, you can automatically generate the figures and CSVs using the command `make figures csvs` or by manually running the MATLAB scripts named `create_figure_{scenario}.m` and `export_{scenario}_eval_results.m`, in the `src/` directory.

### Obtaining optimal designs from the paper

To optimize the designs for the three scenarios presented in the paper you need to run:
```bash
make rwae_optim kru2008_optim lsspd2011_optim
```

**Warning**: to run all the optimizations will take a few days, even on a host with a decent number of CPU cores.
The optimization results from the paper are available for download from the [OSF project](https://osf.io/5ktaf/).
The results are in `*.mat` files in directories with paths `results/{scenario}/{scenario}_optim_*/`.
In particular, the optimized values of the design variables are stored in `sim_info.results_optim.XAtMinEstimatedObjective`.

### Optimizing/evaluating custom designs

If you wish to evaluate your own designs or obtain optimized designs for a novel problem, you will need to write your own configuration files.
Configuration files are written in the human-friendly [YAML](https://yaml.org/) syntax.

The suggested workflow is as follows:

1. Evaluate any existing reference manual designs. 
For each design you will need to write an evaluating config file; for examples see `config/{scenario}/{scenario}_eval_*.yaml` files.
The design evaluation can be launched from MATLAB using the function `src/run_design_evaluation.m` (see the code for documentation).
If some of the existing manual designs already satisfy your goals (e.g., in terms of accuracy), then you can stop here.
2. If none of the reference designs satisfy the design goals, then you can proceed to design optimization.
In this step you will need to provide your optimization config file; for examples see `config/{scenario}/{scenario}_optim_*.yaml` files.
The design optimization can be launched from MATLAB using the function `src/run_design_optimization.m` (see the code for documentation).
3. Once design optimization is completed, you will find the optimized design values in the resulting `.mat` file in the field `sim_info.results_optim.XAtMinEstimatedObjective`.
You can now create a new evaluation config with these optimized design values, and run the evaluation of the optimized design in the same manner as you did for the reference designs.

If your evaluation/design problem requires additional experimental structures, models, or design criteria (loss/utility functions), please check the project structure below, to see where these extensions can be inserted.

## Project structure

```
.
|-- config/ # Eval./optim. configurations for the three scenarios (**insert new configs here**)
|   |-- kru2008/
|   |-- lsspd2011/
|   |-- rwae/
|   `-- random_seeds.txt # Manually recorded seeds used in simulations
|-- external/ # Third-party packages
|-- [results/] # Results in .mat files (only exists after running the evaluations/optimizations)
|   |-- kru2008/
|   |-- lsspd2011/
|   `-- rwae/
|-- [results_csvs/] # Eval. results in .csv files (only exists after running the export scripts)
|-- [results_figures/] # Figures from the paper (only exists after running the plotting scripts)
|-- src/ # Project source code
|   |-- core/ # Core functions for simulation, fitting, and evaluation
|   |-- design-criteria/ # Design quality criteria (**insert new loss functions here**)
|   |-- env-models/ # Experiment structures (**insert new environments here**)
|   |-- learning-models/ # Learning models (**insert new agents here**)
|   |-- util/ # Helper functions
|   |-- viz/ # Visualization functions
|   |-- create_figure_kru2008.m # Create figure for kru2008 scenario
|   |-- create_figure_lsspd2011.m # Create figure for lsspd2011 scenario
|   |-- create_figure_rwae.m # Create figure for rwae scenario
|   |-- export_kru2008_eval_results.m # Export CSV for kru2008 scenario
|   |-- export_lsspd2011_eval_results.m # Export CSV for lsspd2011 scenario
|   |-- export_rwae_eval_results.m # Export CSV for rwae scenario
|   |-- run_design_evaluation.m # Top-level function for design evaluation
|   `-- run_design_optimization.m # Top-level function for design optimization
|-- LICENSE.md
|-- Makefile # Used with GNU Make to automate the execution of scripts
`-- README.md

```

## Contact

Filip Melinscak (<filip.melinscak@uzh.ch>)

## License
[MIT](https://choosealicense.com/licenses/mit/)
