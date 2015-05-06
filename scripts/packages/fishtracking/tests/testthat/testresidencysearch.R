intimes <- c("10:00:00", "10:30:30", "10:35:53", "10:04:02")
indates <- paste("2015-01-01", intimes)
indates <- strptime(indates, "%Y-%m-%d %H:%M:%S")
transmitterids <- c("a1", "a1", "a1", "a2")
stationnames <- c("st1", "st1", "st2", "st2")
indata <- data.frame(
	Date.Time = indates,
	Transmitter.id = transmitterids,
	Station.Name = stationnames
)
print(typeof(indates))

test_that("residency_search will aggregate all raw detections", {
	result <- residencysearch(indata)
	expect_equal(nrow(result), 3)
	# check first row
	expect_equal(as.POSIXlt(result[[1, "Start"]]), as.POSIXlt(indates[1]))
	expect_equal(as.POSIXlt(result[[1, "End"]]), as.POSIXlt(indates[2]))
	expect_equal(as.character(result[[1, "Transmitter.id"]]), "a1")
	expect_equal(as.character(result[[1, "Station.Name"]]), "st1")
	# check second row
	expect_equal(as.POSIXlt(result[[2, "Start"]]), as.POSIXlt(indates[3]))
	expect_equal(as.POSIXlt(result[[2, "End"]]), as.POSIXlt(indates[3]))
	expect_equal(as.character(result[[2, "Transmitter.id"]]), "a1")
	expect_equal(as.character(result[[2, "Station.Name"]]), "st2")
	# check third row
	expect_equal(as.POSIXlt(result[[3, "Start"]]), as.POSIXlt(indates[4]))
	expect_equal(as.POSIXlt(result[[3, "End"]]), as.POSIXlt(indates[4]))
	expect_equal(as.character(result[[3, "Transmitter.id"]]), "a2")
	expect_equal(as.character(result[[3, "Station.Name"]]), "st2")
})

test_that("residency_search allows to set the maximum allowed absence time", {
	result <- residencysearch(indata, maxAbsence=30)
	print(result)
	# With the maxAbsence set to 30 minutes, the first two records
	# are split into separate time intervals. This results in the
	# first two intervals having start = end while in the previous
	# test, there was a difference between start and end of the first
	# interval.
	expect_equal(nrow(result), 4)
	expect_equal(result[[1, "Start"]], result[[1, "End"]])
	expect_equal(result[[2, "Start"]], result[[2, "End"]])
})