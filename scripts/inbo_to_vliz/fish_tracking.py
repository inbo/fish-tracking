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

    def parse_detections(self, infile, station_mapping=None):
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
        if len(df.columns) is 1:
            df = pd.read_csv(infile, sep='\t', encoding='utf-8-sig')
        if self.logging:
            print '{0} AGGREGATOR: parsing file'.format(datetime.now().isoformat())
        if len(df.columns) is len(vliz_cols):
            if sorted(list(df.columns)) == sorted(vliz_cols):
                return self.parse_vliz_detections(df, station_mapping=station_mapping)
        if len(df.columns) is len(vliz_2_cols):
            if sorted(list(df.columns)) == sorted(vliz_2_cols):
                return self.parse_vliz_2_detections(df, station_mapping=station_mapping)
        if len(df.columns) is len(inbo_cols):
            if sorted(list(df.columns)) == sorted(inbo_cols):
                return self.parse_inbo_detections(df, station_mapping=station_mapping)
        if len(df.columns) is len(vue_export_cols):
            if sorted(list(df.columns)) == sorted(vue_export_cols):
                return self.parse_vue_export_detections(df, station_mapping=station_mapping)
        raise Exception('Unknown input format for {0}'.format(infile))

    def check_stationnames(self, inseries, station_mapping):
        if self.logging:
            print '{0} AGGREGATOR: inseries data type: {1}'.format(datetime.now().isoformat(), inseries.dtype)
        if station_mapping:
            stations = pd.read_csv(station_mapping, header=0)
            stations['old_name'].fillna(stations['receiver_id'][stations['old_name'].isnull()], inplace=True)
            inseries.replace(
                to_replace=list(stations['old_name'].apply(lambda x: str(x).strip())),
                value=list(stations['new_name'].apply(lambda x: str(x).strip())),
                inplace=True
            )
            inseries.replace(
                to_replace=list(stations['receiver_id'].apply(lambda x: str(x).strip())),
                value=list(stations['new_name'].apply(lambda x: str(x).strip())),
                inplace=True
            )
        wrong_station_names = inseries[inseries.apply(lambda x: False if re.search('^[a-zA-Z]+-[0-9a-zA-Z]+$', str(x)) else True)]
        if self.logging:
            if len(wrong_station_names) > 0:
                print '{0} wrong station names: \'{1}\''.format(len(wrong_station_names), str(wrong_station_names.unique()))
        return len(wrong_station_names) == 0

    def parse_vliz_detections(self, dataframe, station_mapping=None):
        timestamps_str = dataframe['Date(UTC)'] + ' ' + dataframe['Time(UTC)']
        try:
            timestamps = timestamps_str.apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        except:
            timestamps = timestamps_str.apply(lambda x: datetime(*strptime(x, '%d/%m/%Y %H:%M:%S')[:6]))
        # check station name format
        # first cast to string. If original series was not a string (because data was absent) NaN will be replaced by 'nan'. We'll explicitly replace those too.
        dataframe['Station Name'] = dataframe['StationName'].astype(str).replace(to_replace=['nan'], value=[None])
        # Now, where the StationName is empty (None or NaN instead of 'nan'), replace it by the Receiver
        dataframe['StationName'].fillna(dataframe['Receiver'][dataframe['StationName'].isnull()], inplace=True) # fill in empty station names with receiver ids
        if not self.check_stationnames(dataframe['StationName'], station_mapping):
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

    def parse_vliz_2_detections(self, dataframe, station_mapping=None):
        timestamps = dataframe['Date and Time (UTC)'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        # check station name format
        # first cast to string. If original series was not a string (because data was absent) NaN will be replaced by 'nan'. We'll explicitly replace those too.
        dataframe['Station Name'] = dataframe['Station Name'].astype(str).replace(to_replace=['nan'], value=[None])
        # Now, where the StationName is empty (None or NaN instead of 'nan'), replace it by the Receiver
        dataframe['Station Name'].fillna(dataframe['Receiver'][dataframe['Station Name'].isnull()], inplace=True) # fill in empty station names with receiver ids
        if not self.check_stationnames(dataframe['Station Name'], station_mapping):
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

    def parse_inbo_detections(self, dataframe, station_mapping=None):
        try:
            timestamps = dataframe['Date/Time'].apply(lambda x: datetime(*strptime(x, '%d/%m/%Y %H:%M')[:6]))
        except:
            timestamps = dataframe['Date/Time'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        transmitters = dataframe['Code Space'] + '-' + dataframe['ID'].apply(str)
        # first cast to string. If original series was not a string (because data was absent) NaN will be replaced by 'nan'. We'll explicitly replace those too.
        dataframe['Station Name'] = dataframe['Station Name'].astype(str).replace(to_replace=['nan'], value=[None])
        # Now, where the StationName is empty (None or NaN instead of 'nan'), replace it by the Receiver
        dataframe['Station Name'].fillna(dataframe['Receiver Name'][dataframe['Station Name'].isnull()], inplace=True) # fill in empty station names with receiver names
        # Or.. if that doesn't work, replace it with the Receiver serial number
        dataframe['Station Name'].fillna(dataframe['Receiver S/N'][dataframe['Station Name'].isnull()], inplace=True) # fill in empty station names with receiver serial number
        if not self.check_stationnames(dataframe['Station Name'], station_mapping):
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

    def parse_vue_export_detections(self, dataframe, station_mapping=None):
        try:
            timestamps = dataframe['date_time_utc'].apply(lambda x: datetime(*strptime(x, '%d/%m/%Y %H:%M')[:6]))
        except:
            timestamps = dataframe['date_time_utc'].apply(lambda x: datetime(*strptime(x, '%Y-%m-%d %H:%M:%S')[:6]))
        # first cast to string. If original series was not a string (because data was absent) NaN will be replaced by 'nan'. We'll explicitly replace those too.
        dataframe['station_name'] = dataframe['station_name'].astype(str).replace(to_replace=['nan'], value=[None])
        # Now, where the StationName is empty (None or NaN instead of 'nan'), replace it by the Receiver
        dataframe['station_name'].fillna(dataframe['receiver_id'][dataframe['station_name'].isnull()], inplace=True) # fill in empty station names with receiver ids
        if not self.check_stationnames(dataframe['station_name'], station_mapping):
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
