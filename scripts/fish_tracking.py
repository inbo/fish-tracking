import pandas as pd
import re
from datetime import datetime, timedelta
from time import strptime

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
        vliz_2_cols = [
            'Date and Time (UTC)',
            'Receiver',
            'Transmitter',
            'Transmitter Name',
            'Transmitter Serial',
            'Sensor Value',
            'Sensor Unit',
            'Station Name',
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
        if self.logging:
            print '{0} AGGREGATOR: reading file'.format(datetime.now().isoformat())
        df = pd.read_csv(infile, encoding='utf-8-sig')
        if self.logging:
            print '{0} AGGREGATOR: parsing file'.format(datetime.now().isoformat())
        if len(df.columns) is len(vliz_cols):
            if (df.columns == vliz_cols).all():
                return self.parse_vliz_detections(df)
        if len(df.columns) is len(vliz_2_cols):
            if (df.columns == vliz_2_cols).all():
                return self.parse_vliz_2_detections(df)
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

    def parse_vliz_2_detections(self, dataframe):
        timestamps = dataframe['Date and Time (UTC)'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        # check station name format
        if self.check_stationnames(dataframe['Station Name']):
            raise Exception('Station Name found that does not match required format')
        outdf = pd.DataFrame(
            data={
                'timestamp': timestamps,
                'transmitter': dataframe['Transmitter'],
                'stationname': dataframe['Station Name'],
                'receiver': dataframe['Receiver']
            }
        )
        return outdf

    def parse_inbo_detections(self, dataframe):
        try:
            timestamps = dataframe['Date/Time'].apply(lambda x: datetime(*strptime(x, '%d/%m/%Y %H:%M')[:6]))
        except:
            timestamps = dataframe['Date/Time'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
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


    def aggregate(self, indata, minutes_delta=30, time_format='unix'):
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
            if time_format == 'unix':
                starts.append(str(self.unix_time(group['timestamp'].min())))
                stops.append(str(self.unix_time(group['timestamp'].max())))
            elif time_format == 'iso':
                starts.append(str(group['timestamp'].min().isoformat()))
                stops.append(str(group['timestamp'].max().isoformat()))
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
