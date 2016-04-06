## Basic usage

The package contains a command line interface script. Run `python ft_cli.py --help` to get documentation about the
required arguments. 

* Parse the data files and return all detections in a single format. (`python ft_cli.py parse`). Also station names are
replaced if a `station_names` file is set.
* Aggregate (`python ft_cli.py aggregate`) aggregates all parsed detections into time frames. 
