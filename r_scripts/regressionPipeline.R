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

learnerTypeList = c("regr.randomForest", "regr.kknn", "regr.svm")
#learnerTypeList = c("regr.randomForest")


cleanData <- read.csv(here("cleanData.csv"))
row.has.na <- apply(cleanData, 1, function(x){any(is.na(x))})
cleanData <- cleanData[!row.has.na, ]

cleanData$ALU.x <- as.integer(as.logical(cleanData$ALU.x))
cleanData$ALU.y <- as.integer(as.logical(cleanData$ALU.y))

cleanData <- as.data.frame(sapply(cleanData, as.numeric))
#``cleanData$MutationScore <- as.factor(cleanData$MutationScore)

dt = sort(sample(nrow(cleanData), nrow(cleanData)*.8))
trainData <- cleanData[dt,]
testData <- cleanData[-dt,]


set.seed(1337)

for(learnerType in learnerTypeList) {
  learner <- lrn(learnerType)
  resampling <- rsmp("holdout")
  measures <- msrs(c("regr.rmse", "regr.sse"))
  tune_ps <- NA
  if(learnerType == "regr.randomForest") {
    rfLearner <- learner
    learner$param_set$values = list(importance = "mse")
    tune_ps <- ParamSet$new(list(
      ParamInt$new(id = "ntree", lower = 300, upper = 800),
      ParamInt$new(id = "mtry", lower = 10, upper = 40),
      ParamInt$new(id = "nodesize", lower = 5, upper = 20)
    ))
  } else if(learnerType == "regr.kknn") {
    knnLearner <- learner
    tune_ps <- ParamSet$new(list(
      ParamInt$new(id = "k", lower = 1, upper = 20),
      ParamDbl$new(id = "distance", lower = .001, upper = 2)
    ))
  } else if(learnerType == "regr.svm") {
    learner$param_set$values = list(type = "eps-regression", kernel = "radial")
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
  #testTask = TaskRegr$new(id = "tests", backend = cleanData, target = "MutationScore")
  testTask = TaskRegr$new(id = "tests", backend = trainData, target = "MutationScore")
  rr <- resample(task = testTask, learner = at, resampling = resampling_outer, store_models = TRUE)
  
  print(rr$aggregate())
  
  # Find best of created models
  best_rmse <- Inf
  for (i in 1:10) {
    if (rr$data$learner[[i]]$tuning_result$perf["regr.rmse"] < best_rmse) {
      best_regr <- rr$data$learner[[i]]
      best_rmse <- rr$data$learner[[i]]$tuning_result$perf["regr.rmse"]
    }
  }
  write.csv(best_regr$tuning_result$perf, paste(here("performance"), "/", learnerType, ".csv", sep = ""))
  
  save(best_regr, file=paste("saved_models/", learnerType, ".RData", sep = ""))
  
  if(learnerType == "regr.randomForest") {
    print(best_regr$model$learner$importance())
    prediction = best_regr$predict(TaskRegr$new(id = "tests", backend = testData, target = "MutationScore"))
    write.csv(prediction$data, "regressionPrediction.csv")
  }
  
}


