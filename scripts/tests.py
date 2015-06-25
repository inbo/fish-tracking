import unittest
import os
import pandas as pd
from datetime import datetime
from boto.dynamodb2.table import Table
from boto.dynamodb2.exceptions import ValidationException
from fish_tracking import Aggregator, DataStore


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
        self.assertEquals(record1, ['1420108210', 'vr1', '1420109400', 'id1'])
        self.assertEquals(record2, ['1420111800', 'vr1', '1420111800', 'id1'])
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
        self.assertEquals(record1, ['1420108210', 'vr1', '1420108210', 'id1'])
        self.assertEquals(record2, ['1420108800', 'vr2', '1420108800', 'id1'])
        self.assertEquals(record3, ['1420109400', 'vr1', '1420109400', 'id2'])
        self.assertEquals(record4, ['1420111800', 'vr1', '1420111800', 'id1'])

    def test_aggregate_diff_locations(self):
        """
        Compare this test with test_aggregate_only_time. If we add a record that shows that we detected id1 at another
        location, at time x, where x > y and x < z, then the aggregator will not aggregate y and z.
        """
        indata = pd.DataFrame(
            data={
                'timestamp': [
                    datetime(2015, 1, 1, 10, 30, 10),
                    datetime(2015, 1, 1, 10, 50, 00),
                    datetime(2015, 1, 1, 11, 30, 00),
                    datetime(2015, 1, 1, 10, 40, 00),
                    datetime(2015, 1, 1, 10, 30, 40)
                ],
                'transmitter': ['id1', 'id1', 'id1', 'id1', 'id1'],
                'stationname': ['vr1', 'vr1', 'vr1', 'vr1', 'vr2']
            }
        )
        result = self.agg.aggregate(indata, minutes_delta=30)
        self.assertEquals(len(result.index), 4)
        record1 = list(result.iloc[0])
        record2 = list(result.iloc[1])
        record3 = list(result.iloc[2])
        record4 = list(result.iloc[3])
        self.assertEquals(record1, ['1420108210', 'vr1', '1420108210', 'id1'])
        self.assertEquals(record2, ['1420108240', 'vr2', '1420108240', 'id1'])
        self.assertEquals(record3, ['1420108800', 'vr1', '1420109400', 'id1'])
        self.assertEquals(record4, ['1420111800', 'vr1', '1420111800', 'id1'])


class TestDataStore(unittest.TestCase):
    def tearDown(self):
        try:
            results = self.intervals_table.query_2(transmitter__eq='transm1')
            for r in results:
                r.delete()
        except RuntimeError, e:
            print e.message

    def setUp(self):
        self.ds = DataStore(mode='local')
        self.conn = self.ds._connectLocal()
        self.intervals_table = Table('intervals', connection=self.conn)

    def test_add_record(self):
        interval = {
            'start': '1435129182',
            'stop': '1435129642',
            'transmitter': 'transm1',
            'stationname': 'station1'
        }
        self.assertEquals(self.intervals_table.query_count(transmitter__eq='transm1'), 0)
        self.ds.saveIntervals([interval], 30)
        self.assertEquals(self.intervals_table.query_count(transmitter__eq='transm1'), 1)

    def test_fail_add_record(self):
        bad_interval = {
            'start': '10',
            'stop': '20'
        }
        with self.assertRaises(ValidationException):
            self.ds.saveIntervals([bad_interval], 30)


    def test_get_by_transmitter(self):
        interval = {
            'start': '1435129182000',
            'stop': '1435129642000',
            'transmitter': 'transm1',
            'stationname': 'station1'
        }
        self.assertEquals(self.intervals_table.query_count(transmitter__eq='transm1'), 0)
        self.ds.saveIntervals([interval], 30)
        results = self.ds.getTransmitterData('transm1')
        expected_results = [interval]
        for i in range(len(results)):
            self.assertDictEqual(results[i], expected_results[i])


    def test_compare_elements(self):
        item1 = {'start': 20, 'stop': 25, 'stationname': '1'}
        item2 = {'start': 30, 'stop': 35, 'stationname': '1'}
        diffvalue = 5
        result = self.ds._compare_elements(item1, item2, diffvalue)
        self.assertTrue(result, 'compare elements did not return True')
        item1['stationname'] = '4'
        result = self.ds._compare_elements(item1, item2, diffvalue)
        self.assertFalse(result, 'compare elements did not return False')
        diffvalue = 4
        result = self.ds._compare_elements(item1, item2, diffvalue)
        self.assertFalse(result, 'compare elements did not return False')


    def test_merge_elements(self):
        item1 = {'start': 20, 'stop': 25}
        item2 = {'start': 30, 'stop': 35}
        result = self.ds._merge_elements(item1, item2)
        expected = {'start': 20, 'stop': 35}
        self.assertEquals(result['start'], expected['start'])
        self.assertEquals(result['stop'], expected['stop'])


    def test_merge_sorted_elements_list(self):
        new_items = [
            {'start': 20, 'stop': 25, 'stationname': 'st1'},
            {'start': 50, 'stop': 52, 'stationname': 'st1'},
            {'start': 56, 'stop': 57, 'stationname': 'st1'},
            {'start': 60, 'stop': 61, 'stationname': 'st1'},
            {'start': 80, 'stop': 83, 'stationname': 'st4'}
        ]
        existing_items = [
            {'start': 10, 'stop': 19, 'stationname': 'st1'},
            {'start': 48, 'stop': 49, 'stationname': 'st1'},
            {'start': 53, 'stop': 55, 'stationname': 'st1'},
            {'start': 62, 'stop': 62, 'stationname': 'st2'},
            {'start': 63, 'stop': 66, 'stationname': 'st1'},
            {'start': 84, 'stop': 88, 'stationname': 'st4'}
        ]
        expected_new_items = [
            {'start': 10, 'stop': 25, 'stationname': 'st1'}, # merge from list1[0] and list2[0]
            {'start': 48, 'stop': 57, 'stationname': 'st1'}, # merge from list1[1], list2[1], list2[2] and list1[2]
            {'start': 60, 'stop': 61, 'stationname': 'st1'}, # new from list1
            {'start': 80, 'stop': 88, 'stationname': 'st4'} # merge from list1[4] and list2[5]
        ]
        expected_deleted_items = [0, 1, 2, 5]
        results = self.ds._mergeSortedElementLists(new_items, existing_items, 2)
        for i in range(len(expected_new_items)):
            self.assertDictEqual(results['new_elements'][i], expected_new_items[i])
        self.assertEquals(results['elements_to_delete'], expected_deleted_items)

    def test_merge_sorted_elements_list_stop1(self):
        # test alternative stop scenarios
        # 1. list 1 has several elements at the end that come after the last element of list 2.
        #     These should all be added to the output.
        new_items = [
            {'start': 20, 'stop': 25, 'stationname': 'st1'},
            {'start': 50, 'stop': 52, 'stationname': 'st1'},
            {'start': 56, 'stop': 57, 'stationname': 'st1'},
            {'start': 60, 'stop': 61, 'stationname': 'st1'},
            {'start': 80, 'stop': 83, 'stationname': 'st4'},
            {'start': 90, 'stop': 92, 'stationname': 'st1'},
            {'start': 95, 'stop': 99, 'stationname': 'st1'},
            {'start': 104, 'stop': 105, 'stationname': 'st1'}
        ]
        existing_items = [
            {'start': 10, 'stop': 19, 'stationname': 'st1'},
            {'start': 48, 'stop': 49, 'stationname': 'st1'},
            {'start': 53, 'stop': 55, 'stationname': 'st1'},
            {'start': 62, 'stop': 62, 'stationname': 'st2'},
            {'start': 63, 'stop': 66, 'stationname': 'st1'},
            {'start': 84, 'stop': 88, 'stationname': 'st4'}
        ]
        expected_new_items = [
            {'start': 10, 'stop': 25, 'stationname': 'st1'},
            {'start': 48, 'stop': 57, 'stationname': 'st1'},
            {'start': 60, 'stop': 61, 'stationname': 'st1'},
            {'start': 80, 'stop': 88, 'stationname': 'st4'},
            {'start': 90, 'stop': 92, 'stationname': 'st1'},
            {'start': 95, 'stop': 99, 'stationname': 'st1'},
            {'start': 104, 'stop': 105, 'stationname': 'st1'}
        ]
        expected_deleted_items = [0, 1, 2, 5]
        results = self.ds._mergeSortedElementLists(new_items, existing_items, 2)
        for i in range(len(expected_new_items)):
            self.assertDictEqual(results['new_elements'][i], expected_new_items[i])
        self.assertEquals(results['elements_to_delete'], expected_deleted_items)

    def test_merge_sorted_elements_list_stop2(self):
        # test alternative stop scenarios
        # 2. list 2 has several elements at the end that come after the last element of list 1.
        #     None of these should be added to the output.
        new_items = [
            {'start': 20, 'stop': 25, 'stationname': 'st1'},
            {'start': 50, 'stop': 52, 'stationname': 'st1'}
        ]
        existing_items = [
            {'start': 10, 'stop': 19, 'stationname': 'st1'},
            {'start': 48, 'stop': 49, 'stationname': 'st1'},
            {'start': 53, 'stop': 55, 'stationname': 'st1'},
            {'start': 62, 'stop': 62, 'stationname': 'st2'},
            {'start': 63, 'stop': 66, 'stationname': 'st1'},
            {'start': 84, 'stop': 88, 'stationname': 'st4'}
        ]
        expected_new_items = [
            {'start': 10, 'stop': 25, 'stationname': 'st1'}, # merge from list1[0] and list2[0]
            {'start': 48, 'stop': 55, 'stationname': 'st1'}, # merge from list1[1], list2[1] and list2[2]
        ]
        expected_deleted_items = [0, 1, 2]
        results = self.ds._mergeSortedElementLists(new_items, existing_items, 2)
        for i in range(len(expected_new_items)):
            self.assertDictEqual(results['new_elements'][i], expected_new_items[i])
        self.assertEquals(results['elements_to_delete'], expected_deleted_items)

    def test_merge_sorted_elements_list_empty_list2(self):
        # test alternative scenario
        # If no existing elements, all new elements should be entered
        new_items = [
            {'start': 20, 'stop': 25, 'stationname': 'st1'},
            {'start': 50, 'stop': 52, 'stationname': 'st1'}
        ]
        existing_items = []
        expected_new_items = new_items
        expected_deleted_items = []
        results = self.ds._mergeSortedElementLists(new_items, existing_items, 2)
        for i in range(len(expected_new_items)):
            self.assertDictEqual(results['new_elements'][i], expected_new_items[i])
        self.assertEquals(results['elements_to_delete'], expected_deleted_items)



    def test_insert_merged_element(self):
        """
        first enter the database with a time interval
        add a new entry that should get merged with the existing one
        check that the old element was replaced by the new one.
        """
        interval = {
            'start': '1435129182',
            'stop': '1435129642',
            'transmitter': 'transm1',
            'stationname': 'station1'
        }
        minutes_delta = 30
        self.ds.saveIntervals([interval], minutes_delta)
        new_interval = {
            'start': '1435129842',
            'stop': '1435129900',
            'transmitter': 'transm1',
            'stationname': 'station1'
        }
        self.ds.saveIntervals([new_interval], minutes_delta)
        expected_intervals = [{
            'start': '1435129182',
            'stop': '1435129900',
            'transmitter': 'transm1',
            'stationname': 'station1'
        }]
        results = self.ds.getTransmitterData('transm1')
        self.assertEquals(self.intervals_table.query_count(transmitter__eq='transm1'), 1)
        for i in range(len(expected_intervals)):
            self.assertDictEqual(results[i], expected_intervals[i])
