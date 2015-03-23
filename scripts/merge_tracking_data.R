library(plyr)
source("scripts/functions.R")
dir = ""
outputfile = "fish_tracking.csv"


mergedContent = merge_files(dir)
f = file(outputfile, "w+") # open the existing file and truncate it
write.csv(mergedContent, f, sep=",", eol="\n")
close(f)