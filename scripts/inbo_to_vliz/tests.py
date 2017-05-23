import unittest
import os
import pandas as pd
from datetime import datetime
from fish_tracking import Aggregator


# Locate test files
VLIZ_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_VLIZ_example.csv'
VLIZ_2_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_VLIZ_2_example.csv'
INBO_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VR2W_INBO_example.csv'
VUE_DETECTIONS = os.path.dirname(os.path.realpath(__file__)) + '/example-files/VUE_export_example.csv'
STATION_MAPPING = os.path.dirname(os.path.realpath(__file__)) + '/example-files/station_names.csv'

class TestAggregator(unittest.TestCase):

    # Set up
    def setUp(self):
        self.agg = Aggregator(logging=True)


    # Tests

    #======================
    # Data validation
    #======================
    def test_check_station_names(self):
        test_station_names = pd.Series(['some-5', 'hba-42q'])
        self.assertTrue(self.agg.check_stationnames(test_station_names, None))

    def test_failing_station_names(self):
        test_station_names = pd.Series(['some-5', 'not ok'])
        self.assertFalse(self.agg.check_stationnames(test_station_names, None))

    # @unittest.SkipTest
    def test_parse_vliz_detections(self):
        detections = self.agg.parse_detections(VLIZ_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())
        self.assertEquals(detections['stationname'][0], 'VG-2') # station_mapping not given, so station names not translated

    def test_parse_vliz_detections_rename_stations(self):
        """If station_mapping is given, translate station names based on the mapping file"""
        detections = self.agg.parse_detections(VLIZ_DETECTIONS, station_mapping=STATION_MAPPING)
        self.assertEquals(detections['stationname'][0], 'bpns-VG2')
        # if station name is empty, map by using the receiver id
        error_record = pd.DataFrame(data={
            'Date(UTC)': ['2015-02-19'],
            'Time(UTC)': ['15:01:57'],
            'Receiver': ['VR2W-122324'],
            'Transmitter': ['A69-1601-14872'],
            'StationName': [None]
        }, index=[20])
        df = pd.read_csv(VLIZ_DETECTIONS, encoding='utf-8-sig')
        full_df = pd.concat([df, error_record])
        print 'ADDING WRONG STATION NAME'
        detections = self.agg.parse_vliz_detections(full_df, station_mapping=STATION_MAPPING)
        self.assertEquals(detections['stationname'].iloc[-1], 'ma-3')


    # @unittest.SkipTest
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

    # @unittest.SkipTest
    def test_fail_parse_vliz_2_detections(self):
        failing_data = [
            # empty data frame will fail
            {},
            # wrong date format
            {
                'Date and Time (UTC)': ['15-01-01 10:42:29'],
                'Transmitter': ['29JEQ'],
                'StationName': ['as-43'],
                'Receiver': ['VR92S']
            },
            # wrong date time format
            {
                'Date and Time (UTC)': ['2015-01-01 10h 42'],
                'Transmitter': ['29JEQ'],
                'StationName': ['as-43'],
                'Receiver': ['VR92S']
            },
            # wrong station name format
            {
                'Date and Time (UTC)': ['2015-01-01 10:32:42'],
                'Transmitter': ['29JEQ'],
                'StationName': ['VSE49293'],
                'Receiver': ['VR92S']
            },
        ]
        failing_dfs = map(lambda x: pd.DataFrame(data=x), failing_data)
        for df in failing_dfs:
            with self.assertRaises(Exception):
                self.agg.parse_vliz_detections(df)

    # @unittest.SkipTest
    def test_parse_vliz2_detections(self):
        detections = self.agg.parse_detections(VLIZ_2_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())

    # @unittest.SkipTest
    def test_parse_inbo_detections(self):
        detections = self.agg.parse_detections(INBO_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())

    # @unittest.SkipTest
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

    # @unittest.SkipTest
    def test_parse_vueexport_detections(self):
        detections = self.agg.parse_detections(VUE_DETECTIONS)
        self.assertEquals(
            sorted(list(detections.columns)),
            sorted(['timestamp', 'transmitter', 'stationname', 'receiver'])
        )
        results = detections['timestamp'].apply(lambda x: isinstance(x, datetime))
        self.assertTrue(results.all())

    # @unittest.SkipTest
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
                'station_name': ['17 Iso 8s this is not ok'],
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

    # @unittest.SkipTest
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
        self.assertEquals(record1, ['1420108210', 'vr1', '1420109400', 'id1'])
        self.assertEquals(record2, ['1420111800', 'vr1', '1420111800', 'id1'])
        # When minutes_delta=10, three resulting records are given because the delta between
        # datetime(2015, 1, 1, 10, 40, 00) and datetime(2015, 1, 1, 10, 50, 00) equals 10 minutes.
        result = self.agg.aggregate(indata, minutes_delta=10)
        self.assertEquals(len(result.index), 3)

    # @unittest.SkipTest
    def test_aggregate(self):
        """
        Now use different transmitter ids or station names. The records are no longer aggregated the way they did
        in the previous test.
        """
        indata = pd.DataFrame(
            data={
                'timestamp': [
                    datetime(2015, 1, 1, 10, 30, 10), # 1420108210
                    datetime(2015, 1, 1, 10, 50, 00), # 1420109400
                    datetime(2015, 1, 1, 10, 51, 00), # 1420109460 this one should not merge with record 1 because id1 was also detected at vr2 at 1420108800
                    datetime(2015, 1, 1, 11, 30, 00), # 1420111800
                    datetime(2015, 1, 1, 10, 40, 00)  # 1420108800
                ],
                'transmitter': ['id1', 'id2', 'id1', 'id1', 'id1'],
                'stationname': ['vr1', 'vr1', 'vr1', 'vr1', 'vr2']

            }
        )
        result = self.agg.aggregate(indata, minutes_delta=30)
        self.assertEquals(len(result.index), 5)
        expected_records = [
            ['1420108210', 'vr1', '1420108210', 'id1'],
            ['1420108800', 'vr2', '1420108800', 'id1'],
            ['1420109400', 'vr1', '1420109400', 'id2'],
            ['1420109460', 'vr1', '1420109460', 'id1'],
            ['1420111800', 'vr1', '1420111800', 'id1']
        ]
        result_sorted = result.sort('start')
        result_sorted.index = pd.Index(range(5))
        for i, row in result_sorted.iterrows():
            self.assertEquals(list(row), expected_records[i])


    # @unittest.SkipTest
    def test_aggregate_diff_locations(self):
        """
        Compare this test with test_aggregate_only_time. If we add a record that shows that we detected id1 at another
        location, at time x, where x > y and x < z, then the aggregator will not aggregate y and z.
        """
        indata = pd.DataFrame(
            data={
                'timestamp': [
                    datetime(2015, 1, 1, 10, 30, 10), # 1420108210
                    datetime(2015, 1, 1, 10, 50, 00), # 1420109400
                    datetime(2015, 1, 1, 11, 30, 00), # 1420111800
                    datetime(2015, 1, 1, 10, 40, 00), # 1420108800
                    datetime(2015, 1, 1, 10, 30, 40)  # 1420108240
                ],
                'transmitter': ['id2', 'id1', 'id1', 'id1', 'id1'],
                'stationname': ['vr1', 'vr1', 'vr1', 'vr1', 'vr2']
            }
        )
        result = self.agg.aggregate(indata, minutes_delta=30)
        result_sorted = result.sort('start')
        result_sorted.index = pd.Index(range(4))
        self.assertEquals(len(result.index), 4)
        expected_output = [
            ['1420108210', 'vr1', '1420108210', 'id2'],
            ['1420108240', 'vr2', '1420108240', 'id1'],
            ['1420108800', 'vr1', '1420109400', 'id1'],
            ['1420111800', 'vr1', '1420111800', 'id1']
        ]
        for i, row in result_sorted.iterrows():
            self.assertEquals(list(row), expected_output[i])