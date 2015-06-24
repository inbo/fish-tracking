from boto.dynamodb2.table import Table, HashKey, RangeKey, GlobalAllIndex
from boto.dynamodb2.types import STRING
from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2 import connect_to_region
import sys


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


def create(mode):
    if mode == 'local':
        conn = connectLocal()
    else:
        raise RuntimeError('Unknown mode: {0}.\nShould be \'local\' or \'remote\''.format(mode))
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
        connection=conn
    )

def delete(mode):
    if mode == 'local':
        conn = connectLocal()
    else:
        raise RuntimeError('Unknown mode: {0}.\nShould be \'local\' or \'remote\''.format(mode))
    conn = connectLocal()
    intervals = Table('intervals', connection=conn)
    intervals.delete()


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print """usage: ./manage_table <action> <connection mode>
        action:            "create": create a new intervals table
                           "delete": delete the intervals table

        connection mode:   "local": connect to local dynamodb
                           "remote": connect to remote dynamodb
        """
        sys.exit(-1)

    action = sys.argv[1]
    mode = sys.argv[2]
    if action == "create":
        create(mode)
    elif action == "delete":
        delete(mode)
    else:
        raise RuntimeError('Unknown action \'{0}\'.\nShould be \'create\' or \'delete\''.format(action))
