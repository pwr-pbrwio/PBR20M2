# PBR20M2
Research and Development Project in Software Engineering (Projekt badawczo-rozwojowy w inżynierii oprogramowania) 2020 - zespół PBR20M2:
- Lech Madeyski
- BartoszBoczar 238067
- michalpytka 233146

As references to my own (LM) ideas presented during the first project meeting, see:
1) Several project ideas related to code smells and/or software defects prediction, especially using and exending MLCQ data set. 
Data paper draft: http://madeyski.e-informatyka.pl/download/MadeyskiLewowski20EASE.pdf
Some of the presented ides:
- Extending MLCQ data set with defect prediction data and software defect prediction using code smells and software metrics
- Extending MLCQ data set with software metrics and code smell prediction.
- Code smell prediction employing machine learning meets emerging Java language constructs: further investigation
http://madeyski.e-informatyka.pl/download/GrodzickaEtAl20LNDECT.pdf

2) Ideas collected in cooperation with Capgemini http://madeyski.e-informatyka.pl/download/project_ideas_PBRwIO.pdf

# Reproduction

## Dependencies
+ Maven 3.6.0
+ Python 3.6 with pandas package 1.0.4
+ Java 1.8
+ R 3.5+ with pacman package
+ Additionally whole process has to be done on a unix system (created on ubuntu 18.04, as such it is the recommended one)

## Steps to reproduce

note: all steps should be executed from the root of our project

### Gathering projects

+ Clone our repository
+ Select a group of projects for the process and insert their names into projects.csv file (file is filled with projects used in the study)
+ Clone those projects and put them into /projects directory (projects used in the study are also provided)

### Generate project metrics

+ Clone our fork of JavaMetrics, select our work branch for the correct build PBR20M2
```
https://github.com/michalpytka-pwr/JavaMetrics
```
+ Follow build instructions for JavaMetrics on that repo
+ Compute using JavaMetrics metrics for all projects, names of the .csv output files are not importnat
+ Place all of the metric files into /javametrics_outputs directory (our metrics used in the study are provided in that folder initially)

### Build all projects

+ Open each of the evaluated projects root directory and use command
```
mvn clean install -DskipTests
```
+ If any issues with project building arise, they have to be repaired manually
+ Run tests for each of the projects by using
```
mvn test -Dmaven.test.failure.ignore=true
```

### Generate mutation tests

note: if all projects used in the study are used, this step will take a significant amount of time

+ Open Your R on root of our project
+ Execute script responsible for generating mutation test '/r_scripts/runExternalScripts.R'
+ Check if after this step a file 'mutationScoresGathered.csv' was created and check, if data has generated correctly (if actual test cases are listed and if their mutation scores are non zero)
+ If any problems are met on this step use the alternate step instructions

### Generate mutation tests (Alternate step)

+ Set the pythonpath for the root of our project with
```
export PYTHONPATH=$(pwd)
```
+ Run script respoinslbe for generating the process of mutation testing
```
python3 python_scripts/generate_script.py
```
+ Set mode of the generated bash script with
```
chmod 777 run_experiment_ALL.sh
```
+ Run generated bash scripts to compute mutation tests
```
./run_experiment_ALL.sh
```
+ Gather all of the outputs of mutation testing with
```
python3 python_scripts/gatherMutations.py
```

### Preprocess data and generate model

+ Open Your R on root of our project
+ Execute script responsible for preprocessing data '/r_scripts/preprocessing.R'
+ Execute script responsible for generating models '/r_scripts/basePipeline.R'

### Outcome

+ After those steps, generated models should be present in the loaded R enviroment memory under 'best_classif' and in the /saved_models direcotry. If need be the can be reloaded into R with 'load("path to the model")' command
+ To check the results for a model use
```
best_classif$tuning_result$perf
```
