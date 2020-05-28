data <- read.csv("H:\\Programy\\InteliJ\\outputs\\output_jsoup.csv")
mutationScores <- read.csv("G:\\Studyja\\2 Stopien\\1 Semestr\\Projekt badawczo rozwojowy\\PBR20M2\\python_scripts\\mutationScoresGathered.csv")
projects <- readLines("G:\\Studyja\\2 Stopien\\1 Semestr\\Projekt badawczo rozwojowy\\PBR20M2\\projects.csv")

# Add Max, Min and Mean Cyclo Metric
library(dplyr)
classes <- unique(data[3])
classes_nonEmpty <- classes # [!apply(is.na(classes) | classes == "", 1, all),]
classes_t <- t(classes_nonEmpty)
joined_max <- c()
joined_min <- c()
joined_mean <- c()
for(i in classes_t) {
  single_class_col = filter(data, Class == i)
  cyclo_column <- single_class_col["CYCLO"]
  cyclo_column_non_empty <- cyclo_column[!apply(is.na(cyclo_column) | cyclo_column == "", 1, all),]
  
  # Compute MAX_CYCLO
  max_cyclo <- max(cyclo_column_non_empty)
  max_cyclo_col_part <- ifelse(single_class_col$MethodSignature == "", max_cyclo, NA)
  joined_max <- c(joined_max, max_cyclo_col_part)
  
  # Compute MIN_CYCLO
  min_cyclo <- min(cyclo_column_non_empty)
  min_cyclo_col_part <- ifelse(single_class_col$MethodSignature == "", min_cyclo, NA)
  joined_min <- c(joined_min, min_cyclo_col_part)
  
  # Compute MEAN_CYCLO
  mean_cyclo <- mean(cyclo_column_non_empty)
  mean_cyclo_col_part <- ifelse(single_class_col$MethodSignature == "", mean_cyclo, NA)
  joined_mean <- c(joined_mean, mean_cyclo_col_part)
}
joined_max[joined_max == "-Inf"] <-NA
joined_min[joined_min == "Inf"] <-NA
data$MAX_CYCLO <- joined_max
data$MIN_CYCLO <- joined_min
data$MEAN_CYCLO <- joined_mean


classMetric <- data[(data$MethodSignature==""),]
classMetric <- classMetric[!sapply(classMetric, function(x) all(is.na(x)))]
classMetric$Project <- as.character(classMetric$Project)

for (project in projects) {
  classMetric$Project[grepl(project, classMetric$Project)] <- project
}

classMetric <- transform(classMetric, Test=paste(Package, Class, sep="."))

testMetric <- subset(classMetric, grepl("Test", classMetric$Test))

outputDf <- merge(classMetric, mutationScores, by = "Test")

outputDf$MutationScore[outputDf$MutationScore > 0.5] <- 1
outputDf$MutationScore[outputDf$MutationScore <= 0.5] <- 0

outputDf <- outputDf[ , -which(names(outputDf) %in% c("Test", "Project.x", "Package", 
                                               "Class", "MethodSignature",
                                               "OuterClass", "AccessModifier",
                                               "Project.y"))]

library("randomForest")
set.seed(1337)
ind = sample(2, nrow(outputDf), replace = TRUE, prob=c(0.7, 0.3))
trainData = outputDf[ind==1,]
testData = outputDf[ind==2,]
rF = randomForest(MutationScore~., data=trainData, ntree=100, proximity=T)
plot(rF)