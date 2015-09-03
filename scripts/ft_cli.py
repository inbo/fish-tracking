from fish_tracking import Aggregator
import click
import sys
import os
import pandas as pd

@click.group()
def fish_tracking():
    pass

@click.command()
@click.argument('directory')
@click.option('--minutes', default=60, help='maximum number of minutes in interval (default: 60)')
@click.option('--debug/--no-debug', default=False)
def cons(directory, minutes, debug):
    """Create consolidated detections file by aggregating all data files in DIRECTORY"""
    if not os.path.exists(directory):
        print 'Folder {0} does not exist'.format(directory)
        sys.exit(-1)
    agg = Aggregator()
    detection_dataframes = []
    for fname in os.listdir(directory):
        if fname.split('.')[-1] == 'csv':
            if debug:
                print fname
            tmpdetections = agg.parse_detections(os.path.join(directory, fname))
            detection_dataframes.append(tmpdetections)
    detections = pd.concat(detection_dataframes)
    # print detections
    intervals = agg.aggregate(detections, minutes_delta=minutes, time_format='iso')
    print intervals.to_csv(index=False)


fish_tracking.add_command(cons)

if __name__ == '__main__':
    fish_tracking()