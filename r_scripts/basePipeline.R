library("randomForest")


cleanData <- read.csv(here("cleanData.csv"))
row.has.na <- apply(cleanData, 1, function(x){any(is.na(x))})
cleanData <- cleanData[!row.has.na, ]
cleanData$MutationScore <- as.factor(cleanData$MutationScore)

set.seed(1337)
ind = sample(2, nrow(cleanData), replace = TRUE, prob=c(0.7, 0.3))
trainData = cleanData[ind==1,]
testData = cleanData[ind==2,]

#print(sum(row.has.na))
rF = randomForest(MutationScore~., data=trainData, ntree=500, proximity=T)
print(rF)

out <- predict(rF, testData, predict.all = TRUE)
#print(out)