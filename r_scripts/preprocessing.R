library(pacman)
p_load(here)
p_load(dplyr)

mutationScores <- read.csv(here("mutationScoresGathered.csv"))
projects <- read.csv(here("projects.csv"))
totalData <- data.frame()

rawDataFiles <- c()
for (i in list.files(path=here("javametrics_outputs"), pattern=".csv")) {
  rawDataFiles <- c(rawDataFiles, here("javametrics_outputs", i))
}

# Merge columns project and class from 'mutationScores', to then merge with metrics
mutationScores <- transform(mutationScores, ProjectClass=paste(Project, Class, sep = "."))
mutationScores <- mutationScores[ , -which(names(mutationScores) %in% c("Project", "Class"))]

for (file in rawDataFiles) {
  print(file)
  rawData <- read.csv(file)
  # Calculate McCabe min, max, mean
  classes <- unique(rawData[3])
  classes_nonEmpty <- classes [!apply(is.na(classes) | classes == "", 1, all),]
  classes_t <- t(classes_nonEmpty)
  
  rawData <- transform(rawData, MAX_CYCLO=paste(NA, sep=""))
  rawData <- transform(rawData, MIN_CYCLO=paste(NA, sep=""))
  rawData <- transform(rawData, MEAN_CYCLO=paste(NA, sep=""))
  
  rawData$MAX_CYCLO <- as.numeric(rawData$MAX_CYCLO)
  rawData$MIN_CYCLO <- as.numeric(rawData$MIN_CYCLO)
  rawData$MEAN_CYCLO <- as.numeric(rawData$MEAN_CYCLO)
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
  for (project in projects$project) {
    classMetrics$Project[grepl(project, classMetrics$Project)] <- project
  }
  
  # add column with full package name, needed when merging
  classMetrics <- transform(classMetrics, ProjectClass=paste(Project, Class, sep="."))
  classMetrics <- classMetrics[ , -which(names(classMetrics) %in% c("Project", "Package", 
                                                                    "Class", "MethodSignature",
                                                                    "OuterClass", "AccessModifier",
                                                                    "IsStatic", "IsFinal"))]
  
  # Combine metrics for production class and test class into one row
  testMetric <- subset(classMetrics, grepl("Test", classMetrics$ProjectClass))
  prodMetric <- subset(classMetrics, !grepl("Test", classMetrics$ProjectClass))
  prodMetric <- transform(prodMetric, ProjectClass=paste(ProjectClass, "Test", sep=""))
  classMetrics <- merge(prodMetric, testMetric, by = "ProjectClass")
  
  # Merge mutation scores with metrics
  finalDataFrame <- merge(classMetrics, mutationScores, by = "ProjectClass")
  
  # Drop column ProjectClass and Project to have usable data in classification
  finalDataFrame <- finalDataFrame[ , -which(names(finalDataFrame) %in% c("ProjectClass", "Project"))]
  totalData <- rbind(totalData, finalDataFrame)
}

# Divide entries into classes
calculatedQuantiles <- quantile(totalData$MutationScore, probs = c(0.25, 0.75), na.rm = TRUE)
totalData$MutationScore[totalData$MutationScore >= calculatedQuantiles[2]] <- 1
totalData$MutationScore[totalData$MutationScore <= calculatedQuantiles[1]] <- 0
totalData <- totalData[(totalData$MutationScore == 0 | totalData$MutationScore == 1),]
names(totalData)[names(totalData) == "MutationScore"] <- "goodTest"


write.csv(totalData, "cleanData.csv", row.names = FALSE, append = TRUE)

