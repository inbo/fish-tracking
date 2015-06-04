import pandas as pd
import re
from datetime import datetime
from time import strptime


class Aggregator():
    def __init__(self, logging=False):
        self.logging = logging

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
        df = pd.read_csv(infile, encoding='utf-8-sig')
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