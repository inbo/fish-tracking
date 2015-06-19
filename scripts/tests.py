import unittest
import os
import pandas as pd
from datetime import datetime
from fish_tracking import Aggregator

# Locate test files
VLIZ_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_VLIZ_example.csv'
INBO_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_INBO_example.csv'
VUE_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VUE_export_example.csv'
FAILED_VLIZ_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_VLIZ_example_fail.csv'


class TestAggregator(unittest.TestCase):

    # Set up
    def setUp(self):
        self.agg = Aggregator()


    # Tests

    #======================
    # Data validation
    #======================
    def test_parse_vliz_detections(self):
        detections = self.agg.parse_detections(VLIZ_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())



    def test_fail_parse_vliz_detections(self):
        failing_data = [
            # empty data frame will fail
            {},
            # wrong date format
            {
                'Date(UTC)': ['15-01-01'],
                'Time(UTC)': ['10:42:29'],
                'Transmitter': ['29JEQ'],
                'StationName': ['as-43'],
                'Receiver': ['VR92S']
            },
            # wrong time format
            {
                'Date(UTC)': ['2015-01-01'],
                'Time(UTC)': ['10h 42'],
                'Transmitter': ['29JEQ'],
                'StationName': ['as-43'],
                'Receiver': ['VR92S']
            },
            # wrong station name format
            {
                'Date(UTC)': ['2015-01-01'],
                'Time(UTC)': ['10:32:42'],
                'Transmitter': ['29JEQ'],
                'StationName': ['VSE49293'],
                'Receiver': ['VR92S']
            },
        ]
        failing_dfs = map(lambda x: pd.DataFrame(data=x), failing_data)
        for df in failing_dfs:
            with self.assertRaises(Exception):
                self.agg.parse_vliz_detections(df)

    def test_parse_inbo_detections(self):
        detections = self.agg.parse_detections(INBO_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())

    def test_fail_parse_inbo_detections(self):
        failing_data = [
            # empty data frame will fail
            {},
            # wrong date time format
            {
                'Date/Time': ['2010/04/21 10:42:21'],
                'Code Space': ['IENQ-492'],
                'ID': ['29JEQ'],
                'Station Name': ['as-43'],
                'Receiver Name': ['VR92S']
            },
            # wrong station name format
            {
                'Date/Time': ['21/04/2010 10:42:21'],
                'Code Space': ['IENQ-492'],
                'ID': ['29JEQ'],
                'Station Name': ['as-43-4'],
                'Receiver Name': ['VR92S']
            },
        ]
        failing_dfs = map(lambda x: pd.DataFrame(data=x), failing_data)
        for df in failing_dfs:
            with self.assertRaises(Exception):
                self.agg.parse_vliz_detections(df)

    def test_parse_vueexport_detections(self):
        detections = self.agg.parse_detections(VUE_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())

    def test_fail_parse_vueexport_detections(self):
        failing_data = [
            # empty data frame will fail
            {},
            # wrong date time format
            {
                'date_time_utc': ['2010/04/21 10:42:21'],
                'transmitter_id': ['29JEQ'],
                'station_name': ['as-43'],
                'receiver_id': ['VR92S']
            },
            # wrong station name format
            {
                'date_time_utc': ['2010-04-20 10:42:21'],
                'transmitter_id': ['29JEQ'],
                'station_name': ['17 Iso 8s 18'],
                'receiver_id': ['VR92S']
            },
        ]
        failing_dfs = map(lambda x: pd.DataFrame(data=x), failing_data)
        for df in failing_dfs:
            with self.assertRaises(Exception):
                self.agg.parse_vue_export_detections(df)



    #=======================
    # Aggregation detections
    #=======================

    def test_aggregate_only_time(self):
        """
        Leave transmitter and stationname out of consideration by giving them constant values. The records are
        aggregated if the timedelta does not exceed the given limit.
        """
        indata = pd.DataFrame(
            data={
                'timestamp': [
                    datetime(2015, 1, 1, 10, 30, 10),
                    datetime(2015, 1, 1, 10, 50, 00),
                    datetime(2015, 1, 1, 11, 30, 00),
                    datetime(2015, 1, 1, 10, 40, 00)
                ],
                'transmitter': ['id1', 'id1', 'id1', 'id1'],
                'stationname': ['vr1', 'vr1', 'vr1', 'vr1']
            }
        )
        result = self.agg.aggregate(indata, minutes_delta=30)
        self.assertEquals(len(result.index), 2)
        record1 = list(result.iloc[0])
        record2 = list(result.iloc[1])
        self.assertEquals(record1, [datetime(2015, 1, 1, 10, 30, 10), 'vr1', datetime(2015, 1, 1, 10, 50, 00), 'id1'])
        self.assertEquals(record2, [datetime(2015, 1, 1, 11, 30, 00), 'vr1', datetime(2015, 1, 1, 11, 30, 00), 'id1'])
        # When minutes_delta=10, three resulting records are given because the delta between
        # datetime(2015, 1, 1, 10, 40, 00) and datetime(2015, 1, 1, 10, 50, 00) equals 10 minutes.
        result = self.agg.aggregate(indata, minutes_delta=10)
        self.assertEquals(len(result.index), 3)

    def test_aggregate(self):
        """
        Now use different transmitter ids or station names. The records are no longer aggregated the way they did
        in the previous test.
        """
        indata = pd.DataFrame(
            data={
                'timestamp': [
                    datetime(2015, 1, 1, 10, 30, 10),
                    datetime(2015, 1, 1, 10, 50, 00),
                    datetime(2015, 1, 1, 11, 30, 00),
                    datetime(2015, 1, 1, 10, 40, 00)
                ],
                'transmitter': ['id1', 'id2', 'id1', 'id1'],
                'stationname': ['vr1', 'vr1', 'vr1', 'vr2']

            }
        )
        result = self.agg.aggregate(indata, minutes_delta=30)
        self.assertEquals(len(result.index), 4)
        record1 = list(result.iloc[0])
        record2 = list(result.iloc[1])
        record3 = list(result.iloc[2])
        record4 = list(result.iloc[3])
        self.assertEquals(record1, [datetime(2015, 1, 1, 10, 30, 10), 'vr1', datetime(2015, 1, 1, 10, 30, 10), 'id1'])
        self.assertEquals(record2, [datetime(2015, 1, 1, 10, 40, 00), 'vr2', datetime(2015, 1, 1, 10, 40, 00), 'id1'])
        self.assertEquals(record3, [datetime(2015, 1, 1, 10, 50, 00), 'vr1', datetime(2015, 1, 1, 10, 50, 00), 'id2'])
        self.assertEquals(record4, [datetime(2015, 1, 1, 11, 30, 00), 'vr1', datetime(2015, 1, 1, 11, 30, 00), 'id1'])
