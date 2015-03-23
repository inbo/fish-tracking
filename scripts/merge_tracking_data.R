library(plyr)
source("scripts/functions.R")
#dir = "~/Google Drive/LifeWatch INBO/Data management/Fish tracking/Raw data/"
dir = "~/Projects/fish-tracking/data/example-files/"
outputfile = "fish_tracking.csv"


mergedContent = merge_files(dir)
f = file(outputfile, "w+") # open the existing file and truncate it
write.csv(mergedContent, f, sep=",", eol="\n")