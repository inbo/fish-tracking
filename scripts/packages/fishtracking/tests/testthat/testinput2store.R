test_that("read_input can parse INBO detection files.", {
	print(getwd())
  example_inbo_file = "example-files/VR2W_INBO_example.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_inbo_file)
  expect_equal(colnames(data), header)
  expect_equal(length(data$Date.Time), 20)
  expect_equal(data[1, "Date.Time"], "05/11/2014 06:15")
  expect_equal(data[1, "Receiver.id"], "VR2W-112296")
	expect_equal(data[1, "Receiver.Name"], "Haven SA Braakman")
  expect_equal(data[1, "Transmitter.id"], "A69-1601-33263")
})

test_that("read_input can parse VLIZ detection files.", {
  example_vliz_file = "example-files/VR2W_VLIZ_example.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_vliz_file)
  expect_equal(colnames(data), header)
  expect_equal(length(data$Date.Time), 20)
  expect_equal(data[1, "Date.Time"], "2015-02-19 01:45:55")
  expect_equal(data[1, "Receiver.id"], "VR2W-124071")
  expect_equal(data[1, "Receiver.Name"], "Boei Iso 8s 12A")
  expect_equal(data[1, "Transmitter.id"], "A69-1601-14872")
})

test_that("read_input can parse VUE export files.", {
  example_vue_file = "example-files/VUE_export_example.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_vue_file)
  expect_equal(colnames(data), header)
  expect_equal(length(data$Date.Time), 20)
  expect_equal(data[1, "Date.Time"], "1970-03-23 01:15:27")
  expect_equal(data[1, "Receiver.id"], "VR2W-110783")
  expect_equal(data[1, "Receiver.Name"], "bpns-6-1")
  expect_equal(data[1, "Transmitter.id"], "A69-1601-19439")
})

test_that("parse_date returns standard date format for known date formats and otherwise NA", {
  datetime1 = "2014-01-01 08:00:00"
  datetime2 = "4000-12-31 08:30:13" # years don't have a logic boundary
  datetime3 = "4000-13-31 08:30:14" # months should not be larger than 
  datetime4 = "4000-12-32 08:20:14" # days should not be larger than 31
  datetime5= "01-02-2014 08:00:00" # should return "2014-02-01"
  dates = c(datetime1, datetime2, datetime3, datetime4, datetime5)
  expect_equal(parse_date(dates), c("2014-01-01 08:00:00", "4000-12-31 08:30:13", NA, NA, "2014-02-01 08:00:00"))
})

test_that("parse_station checks station names", {
	station1 = "bh-31-1" # ok
	station2 = "VR2W-294092" # this is a receiver id: not allowed
	station3 = "17 Iso 8s 18" # old station names: not allowed
	stations = c(station1, station2, station3)
	expect_equal(parse_station(stations), c("bh-31-1", NA, NA))
})

test_that("validate_data will check whether all data meets the expectations. If not, it fails", {
	dates = c("2014-01-01 08:00:00", "30-10-2010 08:30:13")
	receiverIds = c("VR2W-149332", "VR2W-29429")
	receiverNames = c("bsa-42-3", "hb-2-4")
	transmitters = c("A93-2993-29402", "A32-4294-29492")
	input_data <- data.frame("Date.Time"=dates, "Receiver.id"=receiverIds, "Receiver.Name"=receiverNames, "Transmitter.id"=transmitters)
	result = validate_data(input_data)
	expect_true(result)
	
	baddates = c("2014-01-01 08:00:00", "10-30-2013 08:30:13")
	input_data$Date.Time <- baddates
	expect_error(validate_data(input_data))
	
	badreceiverNames = c("VR2W-482942", "iso g 4920")
	input_data$Date.Time = dates
	input_data$Receiver.Name = badreceiverNames
	expect_error(validate_data(input_data))
})