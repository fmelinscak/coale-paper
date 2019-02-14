
SHELL:=/bin/bash
MATLAB_EXE:=matlab -nodesktop -nosplash -wait -r
CFG_DIR:=config/
RES_DIR:=results/
CSV_DIR:=results_csvs/
FIG_DIR:=results_figures/
SCENARIOS:=rwae kru2008 lsspd2011
FIGURE_FORMATS:= eps pdf png tif

.SECONDEXPANSION: # Allows the use of function calls in prerequisite list
# See here: https://stackoverflow.com/questions/27583563/function-in-prerequisite

## all : Perform the whole build.
.PHONY : all
all :  figures csvs

## figures : Create all the figures.
.PHONY : figures
figures : $(addsuffix _figures, $(SCENARIOS))

## csvs : Create all the CSVs.
.PHONY : csvs
csvs : $(addsuffix _csv, $(SCENARIOS))

# *** Scenario recipe template ***
# The first argument for the macro is the name of the scenario
# See here for templates via eval:
# http://make.mad-scientist.net/the-eval-function/
# https://www.gnu.org/software/make/manual/make.html#Eval-Function
define SCENARIO_template

$(1)_CFG_DIR := $$(addsuffix $(1)/, $$(CFG_DIR))
$(1)_RES_DIR := $$(addsuffix $(1)/, $$(RES_DIR))

# Optimization recipe
$(1)_OPTIM_CFG_FPATHS := $$(notdir $$(wildcard $$($(1)_CFG_DIR)*_optim_*))
$(1)_OPTIM_CFG_BNAMES := $$(notdir $$(basename $$($(1)_OPTIM_CFG_FPATHS)))
$(1)_OPTIM_RES_FNAMES := $$(addsuffix .mat, $$($(1)_OPTIM_CFG_BNAMES))
$(1)_OPTIM_RES_FPATHS := $$(addprefix $$($(1)_RES_DIR), \
								$$(join $$(addsuffix /, $$($(1)_OPTIM_CFG_BNAMES)), $$($(1)_OPTIM_RES_FNAMES)))
.PHONY : $(1)_optim
$(1)_optim : $$($(1)_OPTIM_RES_FPATHS)
$$($(1)_OPTIM_RES_FPATHS): %.mat : $$($(1)_CFG_DIR)$$$$(notdir %.yaml)
	cd src &&\
	$$(MATLAB_EXE) "run_design_optimization('../$$<', true, '../$$@')"

# Evaluation recipe
$(1)_EVAL_CFG_FPATHS := $$(notdir $$(wildcard $$($(1)_CFG_DIR)*_eval_*))
$(1)_EVAL_CFG_BNAMES := $$(notdir $$(basename $$($(1)_EVAL_CFG_FPATHS)))
$(1)_EVAL_RES_FNAMES := $$(addsuffix .mat, $$($(1)_EVAL_CFG_BNAMES))
$(1)_EVAL_RES_FPATHS := $$(addprefix $$($(1)_RES_DIR), \
								$$(join $$(addsuffix /, $$($(1)_EVAL_CFG_BNAMES)), $$($(1)_EVAL_RES_FNAMES)))
.PHONY : $(1)_eval
$(1)_eval : $$($(1)_EVAL_RES_FPATHS)
$$($(1)_EVAL_RES_FPATHS): %.mat : $$($(1)_CFG_DIR)$$$$(notdir %.yaml)
	cd src &&\
	$$(MATLAB_EXE) "run_design_evaluation('../$$<', true, '../$$@')"

# Figures recipe
$(1)_FIG_DIR := $$(addsuffix $(1)/, $$(FIG_DIR))
$(1)_FIGURES_FNAMES := $$(addprefix figure_$(1).,$$(FIGURE_FORMATS))
$(1)_FIGURES_FPATHS := $$(addprefix $$($(1)_FIG_DIR), $$($(1)_FIGURES_FNAMES))

.PHONY : $(1)_figures
$(1)_figures : $$($(1)_FIGURES_FPATHS)
$$($(1)_FIGURES_FPATHS) : $(1).intermediate

.INTERMEDIATE :  $(1).intermediate
$(1).intermediate : $$($(1)_EVAL_RES_FPATHS)
	cd src &&\
	$$(MATLAB_EXE) "try; create_figure_$(1); exit(0); catch; exit(1); end;"

# CSV recipe
$(1)_CSV_FPATH := $$(CSV_DIR)eval_results_$(1).csv

.PHONY : $(1)_csv
$(1)_csv : $$($(1)_CSV_FPATH)

$$($(1)_CSV_FPATH) : $$($(1)_EVAL_RES_FPATHS)
	cd src &&\
	$$(MATLAB_EXE) "try; export_$(1)_eval_results; exit(0); catch; exit(1); end;"

endef

$(foreach s, $(SCENARIOS), $(eval $(call SCENARIO_template,$(s)))) # Create optim/eval recipes for each scenario
#$(foreach s, $(SCENARIOS), $(info $(call SCENARIO_template,$(s)))) # Displays created recipes

$(eval $(call SCENARIO_template,test)) # Create recipes for test scenario

## clean : Remove auto-generated files.
.PHONY : clean
clean: check_clean
	@echo "Cleaning..."

.PHONY : check_clean
# See here: https://stackoverflow.com/questions/47837071/making-make-clean-ask-for-confirmation
check_clean:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} == y ]

## variables : Print variables.
.PHONY : variables
variables :
	@echo SHELL: $(SHELL)
	@echo MATLAB_EXE: $(MATLAB_EXE)
	@echo CFG_DIR : $(CFG_DIR)
	@echo RES_DIR : $(RES_DIR)
	@echo FIG_DIR : $(FIG_DIR)
	@echo FIGURE_FORMATS : $(FIGURE_FORMATS)
	@echo CSV_DIR : $(CSV_DIR)
	@echo SCENARIOS : $(SCENARIOS)

.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<
	@echo ' {SCENARIO}_optim : run the optimizations for the given scenario'
	@echo ' {SCENARIO}_eval : run the evaluations for the given scenario'
	@echo ' {SCENARIO}_figures : create the figures for the given scenario'
	@echo ' {SCENARIO}_csv : create CSV with evaluation results for the given scenario'
	@echo Available scenarios : $(SCENARIOS)
