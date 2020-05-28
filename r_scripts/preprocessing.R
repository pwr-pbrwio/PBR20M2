rawData <- read.csv("/home/mich/Desktop/outputs/output_jsoup.csv")
mutationScores <- read.csv("/home/mich/Desktop/PBR20M2/python_scripts/mutationScoresGathered.csv")
projects <- readLines("/home/mich/Desktop/PBR20M2/projects.csv")

# Calculate McCabe min, max, mean
library(dplyr)
classes <- unique(rawData[3])
classes_nonEmpty <- classes [!apply(is.na(classes) | classes == "", 1, all),]
classes_t <- t(classes_nonEmpty)

rawData <- transform(rawData, MAX_CYCLO=paste(NA, sep=""))
rawData <- transform(rawData, MIN_CYCLO=paste(NA, sep=""))
rawData <- transform(rawData, MEAN_CYCLO=paste(NA, sep=""))
for(i in classes_t) {
  single_class_col = filter(rawData, Class == i)
  cyclo_column <- single_class_col["CYCLO"]
  cyclo_column_non_empty <- cyclo_column[!apply(is.na(cyclo_column) | cyclo_column == "", 1, all),]
  
  # Compute MAX_CYCLO
  rawData[rawData$MethodSignature == "" & rawData$Class == i, "MAX_CYCLO"] <- max(cyclo_column_non_empty)
  
  # Compute MIN_CYCLO
  rawData[rawData$MethodSignature == "" & rawData$Class == i, "MIN_CYCLO"] <- min(cyclo_column_non_empty)

  # Compute MEAN_CYCLO
  rawData[rawData$MethodSignature == "" & rawData$Class == i, "MEAN_CYCLO"] <- mean(cyclo_column_non_empty)
}
rawData[rawData == "-Inf"] <-NA
rawData[rawData == "Inf"] <-NA
rawData[rawData == NaN] <-NA


classMetrics <- rawData[(rawData$MethodSignature==""),] # select data for classes only
classMetrics <- classMetrics[!sapply(classMetrics, function(x) all(is.na(x)))] # drop all rows without any values (columns with method metrics)
classMetrics$Project <- as.character(classMetrics$Project) # cast Project column to character

# change project absolute path to project name
for (project in projects) {
  classMetrics$Project[grepl(project, classMetrics$Project)] <- project
}

# add column with full package name, needed when merging
classMetrics <- transform(classMetrics, PackagePath=paste(Package, Class, sep="."))
classMetrics <- classMetrics[ , -which(names(classMetrics) %in% c("Project", "Package", 
                                                                        "Class", "MethodSignature",
                                                                        "OuterClass", "AccessModifier",
                                                                        "IsStatic", "IsFinal"))]

# Combine metrics for production class and test class into one row
testMetric <- subset(classMetrics, grepl("Test", classMetrics$PackagePath))
prodMetric <- subset(classMetrics, !grepl("Test", classMetrics$PackagePath))
prodMetric <- transform(prodMetric, PackagePath=paste(PackagePath, "Test", sep=""))
classMetrics <- merge(prodMetric, testMetric, by = "PackagePath")

# Merge mutation scores with metrics
finalDataFrame <- merge(classMetrics, mutationScores, by = "PackagePath")

# Divide entries into classes
finalDataFrame$MutationScore[finalDataFrame$MutationScore > 0.5] <- 1
finalDataFrame$MutationScore[finalDataFrame$MutationScore <= 0.5] <- 0

# Drop column PackagePath and Project to have usable data in classification
finalDataFrame <- finalDataFrame[ , -which(names(finalDataFrame) %in% c("PackagePath", "Project"))]
