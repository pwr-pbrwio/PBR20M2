# This process takes a significant amount of time
library(pacman)
p_load(here)

pythonScripts <- here("python_scripts")
system("rm -r run_experiment_ALL.sh")
system(paste("export PYTHONPATH=$(pwd); python3 ", pythonScripts, "/generate_script.py", sep = ""))
system("chmod 777 run_experiment_ALL.sh")
system("./run_experiment_ALL.sh")
system(paste("export PYTHONPATH=$(pwd); python3 ", pythonScripts, "/gatherMutations.py", sep = ""))
