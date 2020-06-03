library(paradox)
library(mlr3)
library(mlr3learners)
library(mlr3tuning)
library(mlr3learners.randomforest)
library(here)

learnerTypeList = c("classif.kknn", "classif.svm", "classif.randomForest")


cleanData <- read.csv(here("cleanData.csv"))
row.has.na <- apply(cleanData, 1, function(x){any(is.na(x))})
cleanData <- cleanData[!row.has.na, ]

cleanData$ALU.x <- as.integer(as.logical(cleanData$ALU.x))
cleanData$ALU.y <- as.integer(as.logical(cleanData$ALU.y))

cleanData <- as.data.frame(sapply(cleanData, as.numeric))
cleanData$MutationScore <- as.factor(cleanData$MutationScore)


for(learnerType in learnerTypeList) {
  learner = lrn(learnerType)
  resampling = rsmp("holdout")
  measures = msr("classif.ce")
  tune_ps = NA
  if(learnerType == "classif.randomForest") {
    tune_ps = ParamSet$new(list(
      ParamLgl$new(id = "replace", default = TRUE)
    ))
  } else if(learnerType == "classif.kknn") {
    tune_ps = ParamSet$new(list(
      ParamLgl$new(id = "scale", default = TRUE)
    ))
  } else if(learnerType == "classif.svm") {
    tune_ps = ParamSet$new(list(
      ParamLgl$new(id = "fitted", default = TRUE)
    ))
  }

  terminator = term("evals", n_evals = 10)
  tuner = tnr("random_search")
  
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
  rr = resample(task = TaskClassif$new(id = "tests", backend = cleanData, target = "MutationScore"), learner = at, resampling = resampling_outer, store_models = TRUE)
  
  print(rr$aggregate())
  
  save(rr, file=paste("saved_models/", learnerType, ".RData")) 
}


