#================================
# HELPER FUNCTIONS
#================================

#This function will read the input file and parse it depending on the header
#format Returns a dataframe with the content of the file, in a standardized way.
#So every file parsed with this function, will be returned as a dataframe with
#the same columns.
#
#' Read tracking data file
#' @description Read a file containing tracking data and convert it to a
#' standard data frame.
#' 
#' @param filename The name of the input file to read.
#' @return The tracking data from the input file as a data frame with the
#' following columns: Date.Time, Receiver.id, Receiver.Name, Transmitter.id
#' @examples
#' read_input("VR2W_122340_20141010_1.csv")
#' @export
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
#
#' Read all tracking data in a directory
#' @description Merge all input files containing tracking data that are located in a single
#' directory
#' 
#' @param directory The directory containing all tracking data input files
#' @return All tracking data of the different input files as one data frame
#' with the columns Date.Time, Receiver.id, Receiver.Name, Transmitter.id
#' @examples
#' merge_files("/path/to/directory/")
#' @export
merge_files <- function (directory) {
  if (substr(directory, length(directory), length(directory)) != "/") {
    directory = paste(directory, "/", sep="")
  }
  csvfiles = Sys.glob(paste(directory, "*.csv", sep=""))
  contents = lapply(csvfiles, read_input)
  ldply(contents)
}


# parse date parses several known date formats and returns
# a single format yyyy-mm-dd. If the format is unknown, this
# function will raise an error to break the entire workflow
#
#' Parse a tracking data timestamp
#' @description Return a date time (as character) if the input character contains date time
#' data in a known format. Else, return NA.
#' 
#' @param dateStr A vector of strings containing date times.
#' @return A vector of parsed date times. For each parsed input string, the return
#' value is a date time as character in the format "Y-m-d H:M:S" if the input
#' string has the format "Y-m-d H:M:S" or "d-m-Y H:M:S". If not, NA is returned.
#' @examples
#' # should return c("2000-03-21 13:21:42", "1952-04-15 09:00:31", NA, NA)
#' parse_date(c("2000-03-21 13:21:42", "15-04-1952 09:00:31", "03-31-2004 03:49:23", "31-02-2004 04:29:42"))
#' @export
parse_date <- function (dateStr) {
  # check format "yyyy-mm-dd hh:mm:ss"
  result1 = strptime(dateStr, "%Y-%m-%d %H:%M:%S")
   # check format "dd-mm-yyyy hh:mm:ss"
  result2 = strptime(dateStr, "%d-%m-%Y %H:%M:%S")
  result1[is.na(result1)] <- result2[is.na(result1)]
  return(as.character(result1))
}

#' Parse stations names from input
#' @description parse_station will check whether all fields in the input vector
#' are valid station names using a regular expression. A vector of the same
#' length is returned containing the station names for valid ones, and NA
#' for invalid ones.
#' 
#' @param stations Vector containing station names
#' @return Vector containing valid station names or NA's
#' @export
parse_station <- function(stations) {
	result = grepl(".*-[0-9]*-[0-9]*", stations)
	stations[!result] <- NA
	return(stations)
}

#' Validate input tracking data
#' @description Validates a given data frame containing tracking data and returns
#' TRUE if everything is ok or an error of something is wrong
#' 
#' @param indata A data frame containing tracking data
#' @return TRUE if data is ok
#' @examples
#' validate_data(data)
#' @export
validate_data <- function(indata) {
  indata$Date.Time <- parse_date(indata$Date.Time)
  indata$Receiver.Name <- parse_station(indata$Receiver.Name)
  ok = TRUE
  if (sum(is.na(indata$Date.Time)) > 0) {
  	print(paste("invalid dates found at rows: ", paste(which(is.na(indata$Date.Time)), collapse=",")))
  	ok = FALSE
  }
  if (sum(is.na(indata$Receiver.Name)) > 0) {
  	print(paste("invalid receiver names found at rows: ", paste(which(is.na(indata$Receiver.Name)), collapse=",")))
  	ok = FALSE
  }
  return(ok)
}

#================================
# MAIN FUNCTION
#================================

#' Migrate input data to data store
#' @description Read all the tracking data in a directory, validate it and
#' write it to the data store.
#' 
#' @param directory The directory containing the tracking data
#' @return Nothing
#' @examples
#' input2store("/path/to/input/directory/")
#' @export
input2store <- function(dbConnection, directory) {
  data <- merge_files(directory)
  validatedData <- validate_data(data)
  if (validatedData) {
  	dbWriteTable(dbConnection, "detections", validatedData, overwrite=FALSE, append=TRUE)
  } else {
  	print("errors found during validation. Nothing written to database.")
  }
}
