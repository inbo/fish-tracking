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