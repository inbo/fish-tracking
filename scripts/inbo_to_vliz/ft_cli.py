from fish_tracking import Aggregator
import click
import sys
import os
import pandas as pd

@click.group()
def fish_tracking():
    pass

@click.command()
@click.argument('DIRECTORY', type=click.Path(exists=True))
@click.option('--minutes', default=60, help='maximum number of minutes in interval (default: 60)')
@click.option('--st_mapping', default='./data/station_names.md', help='points to the station names mapping file. If given, old stations names will be replaced by new ones.')
@click.option('--debug/--no-debug', default=False)
def aggregate(directory, minutes, st_mapping, debug):
    """Create aggregated detections file based on data in DIRECTORY"""
    agg = Aggregator()
    detection_dataframes = []
    for fname in os.listdir(directory):
        if fname.split('.')[-1] == 'csv':
            if debug:
                print fname
            tmpdetections = agg.parse_detections(os.path.join(directory, fname), station_mapping=st_mapping)
            detection_dataframes.append(tmpdetections)
    detections = pd.concat(detection_dataframes)
    intervals = agg.aggregate(detections, minutes_delta=minutes, time_format='iso')
    print intervals.to_csv(index=False)

@click.command()
@click.argument('DIRECTORY', type=click.Path(exists=True))
@click.option('--st_mapping', default='./data/station_names.csv', help='points to the station names mapping file. If given, old stations names will be replaced by new ones.')
@click.option('--debug/--no-debug', default=False)
def parse(directory, st_mapping, debug):
    """Create consolidated detections file based on data in DIRECTORY but do not aggregate time frames"""
    agg = Aggregator(logging=debug)
    detection_dataframes = []
    for fname in os.listdir(directory):
        if fname.split('.')[-1] == 'csv':
            if debug:
                print fname
            tmpdetections = agg.parse_detections(os.path.join(directory, fname), station_mapping=st_mapping)
            detection_dataframes.append(tmpdetections)
    detections = pd.concat(detection_dataframes)
    print detections.to_csv(index=False)

fish_tracking.add_command(aggregate)
fish_tracking.add_command(parse)

if __name__ == '__main__':
    fish_tracking()