from boto.dynamodb2.table import Table, HashKey, RangeKey, GlobalAllIndex
from boto.dynamodb2.types import NUMBER
from boto.dynamodb2.layer1 import DynamoDBConnection

DynamoDBConnection(
            aws_access_key_id='foo',
            aws_secret_access_key='bar',
            host='localhost',
            port=8000,
            is_secure=False
        )
intervals = Table.create(
    'intervals',
    schema=[
        HashKey('transmitter'),
        RangeKey('start')
    ],
    global_indexes=[
        GlobalAllIndex(
            'stopIndex',
            parts=[HashKey('transmitter'), RangeKey('stop', data_type=NUMBER)],
            throughput={'read': 1, 'write': 1}
        )
    ],
    connection=conn
)
