data <- read.csv("/home/mich/Desktop/outputs/output_jsoup.csv")
mutationScores <- read.csv("/home/mich/Desktop/PBR20M2/python_scripts/mutationScoresGathered.csv")
projects <- readLines("/home/mich/Desktop/PBR20M2/projects.csv")

classMetric <- data[(data$MethodSignature==""),]
classMetric <- classMetric[!sapply(classMetric, function(x) all(is.na(x)))]
classMetric$Project <- as.character(classMetric$Project)

for (project in projects) {
  classMetric$Project[grepl(project, classMetric$Project)] <- project
}

classMetric <- transform(classMetric, PackagePath=paste(Package, Class, sep="."))

outputDf <- merge(classMetric, mutationScores, by = "PackagePath")

outputDf$MutationScore[outputDf$MutationScore > 0.5] <- 1
outputDf$MutationScore[outputDf$MutationScore <= 0.5] <- 0

outputDf <- outputDf[ , -which(names(outputDf) %in% c("PackagePath", "Project.x", "Package", 
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