# PBR20M2
Projekt badawczo-rozwojowy w inżynierii oprogramowania 2020 - zespół PBR20M2:
- Lech Madeyski
- BartoszBoczar 238067
- michalpytka 233146
- kamil-zareba 257402

As references to my own (LM) ideas presented during the first project meeting, see:
1) Several project ideas related to code smells and/or software defects prediction, especially using and exending MLCQ data set. 
Data paper draft: http://madeyski.e-informatyka.pl/download/MadeyskiLewowski20EASE.pdf
Some of the presented ides:
- Extending MLCQ data set with defect prediction data and software defect prediction using code smells and software metrics
- Extending MLCQ data set with software metrics and code smell prediction.
- Code smell prediction employing machine learning meets emerging Java language constructs: further investigation
http://madeyski.e-informatyka.pl/download/GrodzickaEtAl20LNDECT.pdf

2) Ideas collected in cooperation with Capgemini http://madeyski.e-informatyka.pl/download/project_ideas_PBRwIO.pdf


Reproduction instructions:

As our attempt at reproduction of aforementioned package was unsuccessful, this meant that we could not improve on it either and created a separate one. Our package was created from ground up, but with some use of scripts from. All of used scripts still reference the original author. List of needed tools to recreate the process completely is as follows:
- Ubuntu 18.04
- Maven 3.6.0
- Python 3.6 with 1.0.4 package installed
- Java 1.8
- R 3.4.4 with package installed
In order to reproduce our studies you need to clone our git repository. Then you need to clone git repositories of the projects used in our studies into the folder. The full list of used projects is listed in the in our repository. However, if you prefer you can use your own projects. In order for the package to work with external projects, their names have to be added to the projects.csv as well.
In order to prepare the static code metrics, our fork of has to be used. It is available on this git repository. Instructions on how to build and use this tool are present on the repository page. After outputs from selected projects are computed, .csv files with metrics have to be put into javametrics_outputs directory.
The next step is to build all the projects. To build the project you can open terminal in the project's root folder and use the command 'mvn clean install -DskipTests'. Keep in mind that all the projects must be build successfully. You need to resolve any issues Yourselves and try to build the project again if the building process ends with failure. Once the project is built successfully you should run unit tests with the command 'mvn test -Dmaven.test.failure.ignore=true', which will also ignore failed tests.
\\
In order to generate mutation tests and execute them, the same scripts were used, as in Lightweight-Effectiveness. All of them, are being executed through our runExternalScipts.R, to stay in single environment. It is important to note, that this script will take a considerable amount of time to complete. Outcome of this script is mutationScoresGathered.csv, which holds mutation scores of all executed tests. Alternatively, if any trouble would be met while executing this script, all of the external scripts could be called individually in the following order:
- generate_script.py
- run_experiment_ALL.sh
- gatherMutations.py
In order to execute python scripts, the variable has to be set on the root of the project. Additionally the bash script has to have it's mode changed to 777, as advised previously in Lightweight-Effectiveness. Both python scripts reside in python_scripts and the bash script is an outcome of the generate_script.py.
The final step is to create the model. In order to do that you need to run the preprocessing.R script in the r_scripts folder. The script will create the file cleanData.csv containing all the data prepared for machine learning. Finally you should run basePipeline.R, which will train 3 models each with different classification algorithm: K-Neighbours, Support Vector Machines and Random Forest. Created models are saved in the folder saved_models} and can be loaded into R environment.
