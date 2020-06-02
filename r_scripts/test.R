library(paradox)
library(mlr3)
library(mlr3learners)
library(mlr3tuning)
library(mlr3learners.randomforest)
library(here)

cleanData <- read.csv(here("cleanData.csv"))
row.has.na <- apply(cleanData, 1, function(x){any(is.na(x))})
cleanData <- cleanData[!row.has.na, ]

cleanData$ALU.x <- as.integer(as.logical(cleanData$ALU.x))
cleanData$ALU.y <- as.integer(as.logical(cleanData$ALU.y))

cleanData <- as.data.frame(sapply(cleanData, as.numeric))
cleanData$MutationScore <- as.factor(cleanData$MutationScore)



learner = lrn("classif.randomForest")
resampling = rsmp("holdout")
measures = msr("classif.ce")
tune_ps = ParamSet$new(list(
  ParamLgl$new(id = "replace", default = TRUE)
))
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

resampling_outer = rsmp("cv", folds = 3)
rr = resample(task = TaskClassif$new(id = "tests", backend = cleanData, target = "MutationScore"), learner = at, resampling = resampling_outer)

print(rr$aggregate())

