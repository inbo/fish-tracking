test_that("read_input can parse INBO detection files.", {
  example_inbo_file = "example-files/VR2W_122340_20141010_1.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_inbo_file)
  record1 = c("2014-10-08 17:53:10","A69-1601-26451","VR2W-122340","")
  expect_that(colnames(data), equals(header))
  expect_that(length(data$Date.Time), equals(526))
  expect_that(data[1, "Date.Time"], equals("2014-10-08 17:53:10"))
  expect_that(data[1, "Receiver.id"], equals("VR2W-122340"))
  expect_that(data[1, "Transmitter.id"], equals("A69-1601-26451"))
})

test_that("read_input can parse VLIZ detection files.", {
  example_vliz_file = "example-files/VR2W_123816_20141209_1.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_vliz_file)
  expect_that(colnames(data), equals(header))
  expect_that(length(data$Date.Time), equals(28))
  expect_that(data[1, "Date.Time"], equals("2014-11-16 09:35:56"))
  expect_that(data[1, "Receiver.id"], equals("VR2W-123816"))
  expect_that(data[1, "Transmitter.id"], equals("A69-1601-14854"))
})

test_that("read_input can parse VUE export files.", {
  example_vue_file = "example-files/VUE_export_20150226_head.csv"
  header = c("Date.Time","Receiver.id","Receiver.Name","Transmitter.id")
  data = read_input(example_vue_file)
  expect_that(colnames(data), equals(header))
  expect_that(length(data$Date.Time), equals(19))
  expect_that(data[1, "Date.Time"], equals("1970-03-23 01:15:27"))
  expect_that(data[1, "Receiver.id"], equals("VR2W-110783"))
  expect_that(data[1, "Transmitter.id"], equals("A69-1601-19439"))
})
