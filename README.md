## Intro

This repository contains code and documentation on how to work with fish tracking data.

## Requirements

In order to use this script, you need Python 2.7 and the following packages installed:

* [click](http://click.pocoo.org/5/)
* [pandas](http://pandas.pydata.org/)

## Basic usage

The package contains a command line interface script. Run `python ft_cli.py --help` to get documentation about the
required arguments. 

* Parse the data files and return all detections in a single format. (`python ft_cli.py parse`). Also station names are
replaced if a `station_names` file is set.
* Aggregate (`python ft_cli.py aggregate`) aggregates all parsed detections into time frames. 
