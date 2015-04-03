# Scripts

[merge_tracking_data.R](merge_tracking_data.R) will merge all tracking data and write the output to a single file. This script uses the functions in [functions.R](functions.R).

# Run the script

Before you run the script, assure that:

- All data is in a single folder
- Edit the [merge_tracking_data.R](merge_tracking_data.R) script, and [set the variable `dir`](https://github.com/LifeWatchINBO/fish-tracking/blob/master/scripts/merge_tracking_data.R#L3) to the folder name in which the data is located.
- Modify the `outputfile` if needed.

Run [merge_tracking_data.R](merge_tracking_data.R) either by sourcing it in RStudio, or from the command line.

# Run the tests

Run [run_tests.R](run_tests.R) to test the parser in [functions.R](functions.R).