#================================
# MAIN FUNCTIONS
#================================

#' Residency Search
#' @description Aggregate input data by performing residency search
#' @details Raw detection data can contain a lot of detections
#' when a fish is not migrating and staying near a receiver.
#' These detections can be aggregated by calculating the time
#' interval during which a fish was located at a certain receiver.
#' Time intervals have a start time and end time. Creating these
#' time intervals based on the raw detections is called residency
#' search.
#' 
#' @param detections The data frame containing raw detection data
#' @param maxAbsence The maximum number of minutes that a fish is
#' allowed to be absent from a receiver. In other words, if the next
#' detection exceeds this limit, a new time interval will be created.
#' @return Aggregated data as a data frame containing the columns
#' "Transmitter.id", "Station.Name", "Start" and "End".
#' @examples
#' \dontrun{
#' inputdata <- input2store(dbConnection, "/path/to/raw/data/")
#' residencysearch(inputdata)
#' }
#' @export
#' @import dplyr
residencysearch <- function(detections, maxAbsence=59) {
	d <- detections[order(detections$Transmitter.id, detections$Date.Time), ]
	timediffs <- diff(d$Date.Time)
	units(timediffs) <- "mins"
	timediff <- c(0, as.numeric(timediffs))
	stationdiffs <- c(0, diff(as.factor(d$Station.Name)))
	transmitterdiffs <- c(1, diff(as.factor(d$Transmitter.id)))
	d$newInterval <- timediff > maxAbsence | stationdiffs != 0 | transmitterdiffs != 0
	intervalids <- c()
	a <- 0
	for (i in d$newInterval) {
		if (i) {
			a <- a+1
		}
		intervalids <- c(intervalids, a)
	}
	d$intervalid <- intervalids
	d$Date.Time <- as.numeric(d$Date.Time)
	intervals <- d %>%
		group_by(intervalid) %>%
		summarise(
			Start = min(Date.Time),
			End = max(Date.Time),
			Transmitter.id = unique(Transmitter.id),
			Station.Name = unique(Station.Name)
		) %>%
		select(Start = Start, End = End, Transmitter.id = Transmitter.id, Station.Name = Station.Name)
	intervals$Start <- as.POSIXct(intervals$Start, origin="1970-01-01")
	intervals$End <- as.POSIXct(intervals$End, origin="1970-01-01")
	return(as.data.frame(intervals))
}


#' Aggregated data to data store
#' @description Migrate the aggregated data to the data store
#' @details This functions writes the aggregated data created
#' with residencysearch() to the data store.
#' 
#' @param dbConnection a DBI database connection
#' @param aggData a data frame containing aggregated data
#' @return Nothing
#' @examples
#' \dontrun{aggdata2store(dbConnection, aggData)}
#' @export
#' @importFrom DBI dbWriteTable
aggdata2store <- function(dbConnection, aggData) {
	dbWriteTable(dbConnection, "timeintervals", aggData, overwrite=TRUE, append=FALSE)
}