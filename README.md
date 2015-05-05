# Fish tracking analysis

Included in this repository is the `fishtracking` R package. This package allows you to load fish tracking data in a PostgreSQL database.

## Basic usage

Load the fishtracking package:

	library(fishtracking)
	
Load the RPostgreSQL and DBI package:

	library(RPostgreSQL)
	library(DBI)
	
Establish a connection with the PostgreSQL database:

	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname="fish_tracking")

Or, if your database in not running on your local computer:

	con <- dbConnect(drv, dbname="fish_tracking", host="thehost", port=5432, user="youruser", password="yourpassword")
	
To load the tracking data in this database, do:

	data <- input2store(con, "/path/to/your/data/")
	
The `data` variable will now contain all consolidated tracking data as a DataFrame. `input2store` will read all csv files in this directory and parse them. It will validate the data (more precisely, the Date.Time and Station.Name vectors), and if everything looks ok, it will write the data to the database. A table `detections` will be created (if one already exists, it will be deleted first) and all observations in the DataFrame are inserted.