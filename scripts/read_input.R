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
    if (colnames(data)[2] == "Receiver") {
      colnames(data)[1] <- "Date.and.Time"
      outdata <- data[, c("Date.and.Time", "Receiver","Station.Name", "Transmitter")]
      colnames(outdata) <- c("Date.Time", "Receiver.id", "Receiver.Name", "Transmitter.id")
    }
  }
  return(outdata)
}