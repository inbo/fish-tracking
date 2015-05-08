# Fish tracking analysis

Included in this repository is the [`fishtracking` R package](./scripts/packages/fishtracking). This package allows you to load fish tracking data in a PostgreSQL database.

## Basic usage

Load the fishtracking package:

	> library(fishtracking)
	
Load the RPostgreSQL and DBI package:

	> library(RPostgreSQL)
	> library(DBI)
	
Establish a connection with the PostgreSQL database:

	> drv <- dbDriver("PostgreSQL")
	> con <- dbConnect(drv, dbname="fish_tracking")

Or, if your database in not running on your local computer:

	> con <- dbConnect(drv, dbname="fish_tracking", host="thehost", port=5432, user="youruser", password="yourpassword")
	
To load the tracking data in this database, do:

	> data <- input2store(con, "/path/to/your/data/")
	> head(data)
	            Date.Time Receiver.id Station.Name Transmitter.id
	1 2015-03-23 01:15:27 VR2W-110783      bpns-S4 A69-1601-19439
	2 2015-09-04 19:18:20 VR2W-112299        ws-18 A69-1601-13631
	3 2015-09-04 22:08:00 VR2W-112299        ws-18 A69-1601-13631
	4 2015-09-05 17:22:38 VR2W-112299        ws-18 A69-1601-13631
	5 2015-09-05 17:33:35 VR2W-112299        ws-18 A69-1601-13631
	6 2015-09-06 03:09:52 VR2W-112299        ws-18 A69-1601-13631

The `data` variable will now contain all consolidated tracking data as a DataFrame. `input2store` will read all csv files in this directory and parse them. It will validate the data (more precisely, the Date.Time and Station.Name vectors), and if everything looks ok, it will write the data to the database. A table `detections` will be created (if one already exists, it will be deleted first) and all observations in the DataFrame are inserted.

## Perform residency search (aggregate data)

To aggregate the detection data by performing residency search, do:

    > intervals <- residencysearch(data)
    > head(intervals)
                    Start                 End Transmitter.id Station.Name
	1 2015-03-23 01:15:27 2015-03-23 01:15:27  A69-1601-19439     bpns-S4
	2 2015-09-04 19:18:20 2015-09-04 19:18:20  A69-1601-13631       ws-18
	3 2015-09-04 22:08:00 2015-09-04 22:08:00  A69-1601-13631       ws-18
	4 2015-09-05 17:22:38 2015-09-05 17:33:35  A69-1601-13631       ws-18
	5 2015-09-06 03:09:52 2015-09-06 03:09:52  A69-1601-13631       ws-18

You can write the intervals to the database too:

	> aggdata2store(con, intervals)
	
If you would experience the following error: `unable to find an inherited method for function ‘dbWriteTable’ for signature ‘"PostgreSQLConnection", "character", "tbl_df"’`, you should cast `intervals` to a data frame explicitly.

	> aggdata2store(con, as.data.frame(intervals))

