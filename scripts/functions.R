#================================
# FUNCTIONS
#================================

# This function will read the input file and parse it depending on the header format
# Returns a dataframe with the content of the file, in a standardized way. So every
# file parsed with this function, will be returned as a dataframe with the same
# columns.
read_input <- function (filename) {
  data <- read.csv(filename, sep=",", stringsAsFactors=FALSE)
  if (length(colnames(data)) == 14) {
    # inbo format. Date header should be "Date.Time"
    if (colnames(data)[1] == "Date.Time") {
      outdata <- data[, c("Date.Time", "Receiver.Name", "Station.Name")]
      colnames(outdata) <- c("Date.Time", "Receiver.id", "Receiver.Name")
      outdata$Transmitter.id <- paste(data$Code.Space, data$ID, sep="-")
    }
  } else if (length(colnames(data)) == 10) {
    # vliz format. Field 2 should be "Receiver"
    if (colnames(data)[2] == "Receiver") {
      colnames(data)[1] <- "Date.and.Time"
      outdata <- data[, c("Date.and.Time", "Receiver","Station.Name", "Transmitter")]
      colnames(outdata) <- c("Date.Time", "Receiver.id", "Receiver.Name", "Transmitter.id")
    }
  } else if (length(colnames(data)) == 11) {
    # VUE export format. Field 1 should be "DateTimeUTC"
    if (colnames(data)[1] == "DateTimeUTC") {
      outdata <- data[, c("DateTimeUTC", "Receiver", "ReceiverCode", "Transmitter")]
      colnames(outdata) <- c("Date.Time", "Receiver.id", "Receiver.Name", "Transmitter.id")
    }
  }
  return(outdata)
}



# merge the content of all files
# returns one dataframe containing all records of the input files
merge_files <- function (directory) {
  if (substr(directory, length(directory), length(directory)) != "/") {
    directory = paste(directory, "/", sep="")
  }
  csvfiles = Sys.glob(paste(directory, "*.csv", sep=""))
  contents = lapply(csvfiles, read_input)
  ldply(contents)
}
