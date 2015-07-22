from fish_tracking import Aggregator
import click
import sys
import os
import pandas as pd
from boto.dynamodb2.table import Table, HashKey, RangeKey, GlobalAllIndex
from boto.dynamodb2.types import STRING
from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2 import connect_to_region

@click.group()
def fish_tracking():
    pass

@click.command()
@click.argument('directory')
@click.option('--minutes', default=60, help='maximum number of minutes in interval')
@click.option('--debug/--no-debug', default=False)
def cons(directory, minutes, debug):
    """Create consolidated detections file"""
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
    intervals = agg.aggregate(detections, minutes_delta=minutes)
    print intervals.to_csv(index=False)


def connectLocal():
    return DynamoDBConnection(
        aws_access_key_id='foo',
        aws_secret_access_key='bar',
        host='localhost',
        port=8000,
        is_secure=False
    )

def connectRemote():
    return connect_to_region('eu-west-1')


@click.command()
@click.option('--conn', default='local', help='connection type')
def create_table(conn):
    if conn == 'local':
        connection = connectLocal()
    else:
        raise RuntimeError('Unknown mode: {0}.\nShould be \'local\' or \'remote\''.format(conn))
    intervals = Table.create(
        'intervals',
        schema=[
            HashKey('transmitter'),
            RangeKey('start')
        ],
        global_indexes=[
            GlobalAllIndex(
                'stopIndex',
                parts=[HashKey('transmitter'), RangeKey('stop', data_type=STRING)],
                throughput={'read': 1, 'write': 1}
            )
        ],
        connection=connection
    )

@click.command()
@click.option('--conn', default='local', help='connection type')
def delete_table(conn):
    if conn == 'local':
        connection = connectLocal()
    else:
        raise RuntimeError('Unknown mode: {0}.\nShould be \'local\' or \'remote\''.format(conn))
    intervals = Table('intervals', connection=connection)
    intervals.delete()


fish_tracking.add_command(cons)
fish_tracking.add_command(create_table)
fish_tracking.add_command(delete_table)

if __name__ == '__main__':
    fish_tracking()