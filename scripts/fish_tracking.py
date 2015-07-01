import pandas as pd
import re
from datetime import datetime, timedelta
from time import strptime
from boto.dynamodb2.layer1 import DynamoDBConnection
from boto.dynamodb2 import connect_to_region
from boto.dynamodb2.table import Table
from boto.dynamodb2.exceptions import ValidationException
from timer import Timer

class Aggregator():
    def __init__(self, logging=False):
        self.logging = logging

    def unix_time(self, dt):
        epoch = datetime.utcfromtimestamp(0)
        delta = dt - epoch
        return int(delta.total_seconds())

    def parse_detections(self, infile):
        vliz_cols = [
            'Date(UTC)',
            'Time(UTC)',
            'Receiver',
            'Transmitter',
            'TransmitterName',
            'TransmitterSerial',
            'SensorValue',
            'SensorUnit',
            'StationName',
            'Latitude',
            'Longitude'
        ]
        inbo_cols = [
            'Date/Time',
            'Code Space',
            'ID',
            'Sensor 1',
            'Units 1',
            'Sensor 2',
            'Units 2',
            'Transmitter Name',
            'Transmitter S/N',
            'Receiver Name',
            'Receiver S/N',
            'Station Name',
            'Station Latitude',
            'Station Longitude'
        ]
        vue_export_cols = [
            'date_time_utc',
            'receiver_id',
            'transmitter_id',
            'old_station_name',
            'station_name',
            'latitude',
            'longitude'
        ]
        print '{0} AGGREGATOR: reading file'.format(datetime.now().isoformat())
        df = pd.read_csv(infile, encoding='utf-8-sig')
        print '{0} AGGREGATOR: parsing file'.format(datetime.now().isoformat())
        if len(df.columns) is len(vliz_cols):
            if (df.columns == vliz_cols).all():
                return self.parse_vliz_detections(df)
        if len(df.columns) is len(inbo_cols):
            if (df.columns == inbo_cols).all():
                return self.parse_inbo_detections(df)
        if len(df.columns) is len(vue_export_cols):
            if (df.columns == vue_export_cols).all():
                return self.parse_vue_export_detections(df)
        raise Exception('Unknown input format')

    def check_stationnames(self, inseries):
        return inseries.apply(lambda x: re.search('^[a-zA-Z]+-[0-9a-zA-Z]+$', x)).hasnans()

    def parse_vliz_detections(self, dataframe):
        timestamps_str = dataframe['Date(UTC)'] + ' ' + dataframe['Time(UTC)']
        timestamps = timestamps_str.apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        # check station name format
        if self.check_stationnames(dataframe['StationName']):
            raise Exception('StationName found that does not match required format')
        outdf = pd.DataFrame(
            data={
                'timestamp': timestamps,
                'transmitter': dataframe['Transmitter'],
                'stationname': dataframe['StationName'],
                'receiver': dataframe['Receiver']
            }
        )
        return outdf

    def parse_inbo_detections(self, dataframe):
        timestamps = dataframe['Date/Time'].apply(lambda x: datetime(*strptime(x, '%d/%m/%Y %H:%M')[:6]))
        transmitters = dataframe['Code Space'] + '-' + dataframe['ID'].apply(str)
        if self.check_stationnames(dataframe['Station Name']):
            raise Exception('Station Name found that does not match required format')
        outdf = pd.DataFrame(
            data={
                'timestamp': timestamps,
                'transmitter': transmitters,
                'stationname': dataframe['Station Name'],
                'receiver': dataframe['Receiver Name']
            }
        )
        return outdf

    def parse_vue_export_detections(self, dataframe):
        timestamps = dataframe['date_time_utc'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        if self.check_stationnames(dataframe['station_name']):
            print 'station error'
            raise Exception('station_name found that does not match required format')
        outdf = pd.DataFrame(
            data={
                'timestamp': timestamps,
                'transmitter': dataframe['transmitter_id'],
                'stationname': dataframe['station_name'],
                'receiver': dataframe['receiver_id']
            }
        )
        return outdf


    def aggregate(self, indata, minutes_delta=30):
        print '{0} AGGREGATOR: starting to aggregate detections'.format(datetime.now().isoformat())
        print '{0} AGGREGATOR:    sorting detections...'.format(datetime.now().isoformat())
        sorted_data = indata.sort(['transmitter', 'timestamp'])
        print '{0} AGGREGATOR:    calculating interval id...'.format(datetime.now().isoformat())
        sorted_data['interval_id'] = (sorted_data['timestamp'].diff() >= timedelta(minutes=minutes_delta)).cumsum()
        print '{0} AGGREGATOR:    calculating station interval id...'.format(datetime.now().isoformat())
        sorted_data['station_interval_id'] = (sorted_data['stationname'] != sorted_data['stationname'].shift()).cumsum()
        print '{0} AGGREGATOR:    performing group by...'.format(datetime.now().isoformat())
        grouped = sorted_data.groupby(['interval_id', 'station_interval_id', 'transmitter', 'stationname'])
        starts = []
        stops = []
        transmitters = []
        stationnames = []
        print '{0} AGGREGATOR:    formatting intervals...'.format(datetime.now().isoformat())
        for name, group in grouped:
            starts.append(str(self.unix_time(group['timestamp'].min())))
            stops.append(str(self.unix_time(group['timestamp'].max())))
            transmitters.append(name[2])
            stationnames.append(name[3])
        outdf = pd.DataFrame(data={
            'start': starts,
            'stop': stops,
            'transmitter': transmitters,
            'stationname': stationnames
        })
        print '{0} AGGREGATOR: aggregation done'.format(datetime.now().isoformat())
        return outdf

class DataStore():
    def _connectLocal(self):
        return DynamoDBConnection(
            aws_access_key_id='foo',
            aws_secret_access_key='bar',
            host='localhost',
            port=8000,
            is_secure=False
        )

    def _connectServer(self):
        return connect_to_region('eu-west-1')

    def __init__(self, mode='server'):
        if mode is 'server':
            self.conn = connect_to_region
        elif mode is 'local':
            self.conn = self._connectLocal()
        else:
            raise ValueError('{0} is an unknown mode. Use \'server\' or \'local\''.format(mode))
        self.intervals_table = Table('intervals', connection=self.conn)


    def _merge_elements(self, el1, el2):
        return {
            'start': sorted([el1['start'], el2['start']])[0],
            'stop': sorted([el1['stop'], el2['stop']])[1]
        }

    def _compare_elements(self, el1, el2, diffvalue):
        return el1['start'] - diffvalue <= el2['stop'] \
        and el1['stop'] + diffvalue >= el2['start'] \
        and el1['stationname'] == el2['stationname']


    def _mergeSortedElementLists(self, list1, list2, diffvalue, _log=False):
        output = {'new_elements': [], 'elements_to_delete': []}
        if len(list1) == 0:
            return output
        if len(list2) == 0:
            output['new_elements'] = list1
            return output
        i1 = -1
        i2 = -1
        max_ts = list1[-1]['stop'] + diffvalue
        if list1[i1+1]['start'] > list2[i2+1]['start']:
            i2 += 1
            element = {'list': '2', 'el': list2[i2]}
        else:
            i1 += 1
            element = {'list': '1', 'el': list1[i1]}
        if _log:
            print 'len1: {0}, len2: {1}'.format(len(list1), len(list2))
        while element['el']['start'] < max_ts and i1 < len(list1):
            if _log:
                print '   i1: {0}, i2: {1}'.format(i1, i2)
            if i1 < len(list1) - 1 and i2 < len(list2) - 1:
                if list1[i1+1]['start'] < list2[i2+1]['start']: # compare next of list1 with next of list2 and choose next element
                    i1 += 1
                    next_element = {'list': '1', 'el': list1[i1]}
                else:
                    i2 += 1
                    next_element = {'list': '2', 'el': list2[i2]}
            elif i2 < len(list2) - 1: # list 1 is exhausted, but list 2 is not
                i2 += 1
                next_element = {'list': '2', 'el': list2[i2]}
            elif i1 < len(list1) - 1: # list 2 is exhausted, but list 1 is not
                i1 += 1
                next_element = {'list': '1', 'el': list1[i1]}
            else: # list 1 and list 2 are exhausted
                if _log:
                    print 'BREAK'
                if 'isMerged' in element.keys() or element['list'] == '1':
                    # the last element is either a merged one, or a new one from list 1 and should be added
                    if _log:
                        print 'added: {0}'.format(element['el'])
                    output['new_elements'].append(element['el'])
                break

            if _log:
                print 'comparing {0} and {1}'.format(element['el'], next_element['el'])
            if self._compare_elements(element['el'], next_element['el'], diffvalue):
                if _log:
                    print '...merging {0} and {1}'.format(element['el'], next_element['el'])
                if next_element['list'] == '2':
                    remove_start = next_element['el']['start']
                else:
                    remove_start = element['el']['start']
                merged_element = self._merge_elements(element['el'], next_element['el'])
                next_element['el']['start'] = merged_element['start']
                next_element['el']['stop'] = merged_element['stop']
                next_element['isMerged'] = True
                next_element['list'] = '1'
                if not remove_start in output['elements_to_delete']:
                    output['elements_to_delete'].append(remove_start)
            else:
                if element['list'] == '1':
                    # this is an unmerged element of list 1 and should be added
                    if _log:
                        print 'added: {0}'.format(element['el'])
                    output['new_elements'].append(element['el'])
            element = next_element
        return output

    def _interval_strings_to_ints(self, interval):
        interval['start'] = int(interval['start'])
        interval['stop'] = int(interval['stop'])
        return interval

    def _interval_ints_to_strings(self, interval):
        interval['start'] = str(interval['start'])
        interval['stop'] = str(interval['stop'])
        return interval

    def saveIntervals(self, new_intervals, minutes_delta, log=False):
        intervals_df = pd.DataFrame(data=new_intervals)
        intervals_df['start'] = intervals_df['start'].astype(int)
        intervals_df['stop'] = intervals_df['stop'].astype(int)
        print '{0} DATASTORE: grouping input data'.format(datetime.now().isoformat())
        groups = intervals_df.groupby('transmitter')
        print '{0} DATASTORE: merging and inserting intervals'.format(datetime.now().isoformat())
        merging_time = 0
        writing_time = 0
        deleting_time = 0
        nr_new_groups = 0
        nr_deleted_items = 0
        for name, group in groups:
            existing_intervals = self._getTransmitterData(name)
            if log:
                print 'existing intervals: {0}'.format(str(existing_intervals))
            existing_intervals = [self._interval_strings_to_ints(x) for x in existing_intervals]
            group_intervals = group.T.to_dict().values()
            with Timer() as t:
                merge_result = self._mergeSortedElementLists(group_intervals, existing_intervals, minutes_delta * 60)
            merging_time += t.secs
            if log:
                print 'merge result: ' + str(merge_result)

            with Timer() as t:
                with self.intervals_table.batch_write() as batch:
                    for delete_start in merge_result['elements_to_delete']:
                        nr_deleted_items += 1
                        if log:
                            print 'element to delete: ' + 'transmitter: ' + name + 'start: ' + str(delete_start)
                        batch.delete_item(transmitter=name, start=str(delete_start))
            deleting_time += t.secs
            try:
                with Timer() as t:
                    with self.intervals_table.batch_write() as batch:
                        for interval in merge_result['new_elements']:
                            nr_new_groups += 1
                            if log:
                                # print 'inserting element: ' + str(interval)
                                pass
                            batch.put_item(data=self._interval_ints_to_strings(interval))
            except ValidationException, e:
                print 'could not write item {0} to the database'.format(str(self._interval_ints_to_strings(interval)))
                raise RuntimeError(e.message)
            writing_time += t.secs
        print '{0} DATASTORE: done'.format(datetime.now().isoformat())
        print 'timing results:'
        print '    merging time: {0}\n    writing time: {1}\n    deleting time: {2}\n    nr of new intervals: {3}\n    nr of items deleted: {4}'.format(merging_time, writing_time, deleting_time, nr_new_groups, nr_deleted_items)
        return True

    def _getTransmitterData(self, transmitterID):
        """
        get records stored in the intervals table by querying for a given transmitterID
        """
        results = self.intervals_table.query_2(transmitter__eq=transmitterID)
        outresults = []
        for r in results:
            outresults.append(dict(r))
        return outresults

    def getTransmitterData(self, transmitterID):
        """
        get time intervals from intervals table. Note difference with _getTransmitterData: this method
        converts start and stop to iso timestamp strings
        """
        results = self.intervals_table.query_2(transmitter__eq=transmitterID)
        outresults = []
        for r in results:
            record_dict = dict(r)
            record_dict['start'] = datetime.utcfromtimestamp(int(record_dict['start'])).isoformat()
            record_dict['stop'] = datetime.utcfromtimestamp(int(record_dict['stop'])).isoformat()
            outresults.append(record_dict)
        return outresults

    def getTransmitterIDs(self):
        results = self.intervals_table.scan(attributes=['transmitter'])
        transmitterids = set([])
        for r in results:
            transmitterids.add(r['transmitter'])
        return list(transmitterids)

