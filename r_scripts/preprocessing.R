rawData <- read.csv("/home/mich/Desktop/outputs/output_jsoup.csv")
mutationScores <- read.csv("/home/mich/Desktop/PBR20M2/python_scripts/mutationScoresGathered.csv")
projects <- readLines("/home/mich/Desktop/PBR20M2/projects.csv")

# Calculate McCabe min, max, mean <-- TODO

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
