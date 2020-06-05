library(pacman)
p_load(paradox)
p_load(mlr3)
p_load(mlr3learners)
p_load(mlr3tuning)
p_load(here)
if(!require(mlr3learners.randomforest)){
  install.packages("mlr3learners.randomforest", repos = "https://mlr3learners.github.io/mlr3learners.drat")
}
library(mlr3learners.randomforest)

learnerTypeList = c("classif.randomForest", "classif.kknn", "classif.svm")


cleanData <- read.csv(here("cleanData.csv"))
row.has.na <- apply(cleanData, 1, function(x){any(is.na(x))})
cleanData <- cleanData[!row.has.na, ]

cleanData$ALU.x <- as.integer(as.logical(cleanData$ALU.x))
cleanData$ALU.y <- as.integer(as.logical(cleanData$ALU.y))

cleanData <- as.data.frame(sapply(cleanData, as.numeric))
cleanData$goodTest <- as.factor(cleanData$goodTest)


set.seed(1337)

for(learnerType in learnerTypeList) {
  learner <- lrn(learnerType)
  resampling <- rsmp("holdout")
  measures <- msrs(c("classif.mcc", "classif.ce", "classif.precision", "classif.fbeta"))
  tune_ps <- NA
  if(learnerType == "classif.randomForest") {
    tune_ps <- ParamSet$new(list(
      ParamLgl$new(id = "replace", default = TRUE)
    ))
  } else if(learnerType == "classif.kknn") {
    tune_ps <- ParamSet$new(list(
      ParamLgl$new(id = "scale", default = TRUE)
    ))
  } else if(learnerType == "classif.svm") {
    tune_ps <- ParamSet$new(list(
      ParamLgl$new(id = "fitted", default = TRUE)
    ))
  }
  
  terminator <- term("evals", n_evals = 10)
  tuner <- tnr("random_search")
  
  at = AutoTuner$new(
    learner = learner,
    resampling = resampling,
    measures = measures,
    tune_ps = tune_ps,
    terminator = terminator,
    tuner = tuner
  )
  print(at)
  at$store_tuning_instance = TRUE
  
  resampling_outer = rsmp("cv", folds = 10)
  rr <- resample(task = TaskClassif$new(id = "tests", backend = cleanData, target = "goodTest"), learner = at, resampling = resampling_outer, store_models = TRUE)
  
  print(rr$aggregate())
  
  save(rr, file=paste("saved_models/", learnerType, ".RData"))
}


