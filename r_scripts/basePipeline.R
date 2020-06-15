library(pacman)
p_load(paradox)
p_load(mlr3)
p_load(mlr3learners)
p_load(mlr3tuning)
p_load(here)
p_load(mlr3filters)
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
    rfLearner <- learner
    learner$param_set$values = list(importance = "accuracy")
    tune_ps <- ParamSet$new(list(
      ParamInt$new(id = "ntree", lower = 300, upper = 800),
      ParamInt$new(id = "mtry", lower = 10, upper = 40),
      ParamInt$new(id = "nodesize", lower = 5, upper = 20)
    ))
  } else if(learnerType == "classif.kknn") {
    knnLearner <- learner
    tune_ps <- ParamSet$new(list(
      ParamInt$new(id = "k", lower = 1, upper = 20),
      ParamDbl$new(id = "distance", lower = .001, upper = 2)
    ))
  } else if(learnerType == "classif.svm") {
    learner$param_set$values = list(type = "C-classification", kernel = "radial")
    svmLearner <- learner
    tune_ps <- ParamSet$new(list(
      ParamDbl$new(id = "cachesize", lower = 20, upper = 150),
      ParamDbl$new(id = "cost", lower = 30, upper = 80),
      ParamDbl$new(id = "gamma", lower = 0.00001, upper = 0.001)
    ))
  }
  
  terminator <- term("evals", n_evals = 10)
  tuner <- tnr("grid_search")
  
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
  testTask = TaskClassif$new(id = "tests", backend = cleanData, target = "goodTest")
  rr <- resample(task = testTask, learner = at, resampling = resampling_outer, store_models = TRUE)
  
  print(rr$aggregate())
  
  # Find best of created models
  best_mcc <- 0
  for (i in 1:10) {
    if (rr$data$learner[[i]]$tuning_result$perf["classif.mcc"] > best_mcc) {
      best_classif <- rr$data$learner[[i]]
      best_mcc <- rr$data$learner[[i]]$tuning_result$perf["classif.mcc"]
    }
  }
  write.csv(best_classif$tuning_result$perf, paste(here("performance"), "/", learnerType, ".csv", sep = ""))
  
  save(best_classif, file=paste("saved_models/", learnerType, ".RData"))
  
  if(learnerType == "classif.randomForest") {
    print(best_classif$model$learner$importance())
  }
}


