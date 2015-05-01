# Input formats

This file documents the different formats that can be obtained from the hardware (receivers). Depending on the settings on the field laptop and on the time when the file was generated, these formats differ.

## VLIZ format (2013 - ...)

| field name | description | data type | example |
| ---------- | ----------- | --------- | ------- |
| Date(UTC) | date of the detection | date as 'yyyy-mm-dd' | 2014-11-16 |
| Time(UTC) | time of the detection | time as 'hh:mm:ss' | 09:35:56 |
| Receiver | id of the receiver. only 1 different value per file | text | VR2W-123816 |
| Transmitter | id of the detected transmitter | text | A69-1601-14854 |
| TransmitterName | name of the detected transmitter |  |  |
| TransmitterSerial |  |  |  |
| SensorValue |  |  |  |
| SensorUnit |  |  |  |
| StationName | name of the location | text | WN-2 |
| Latitude | position of the receiver (lat) |  |  |
| Longitude | position of the receiver (long) |  |  |

## INBO format (2013 - ...)

| field name | description | data type | example |
| ---------- | ----------- | --------- | ------- |
| Date/Time | date and time of the detection | date time as 'yyyy-mm-dd hh:mm:dd' | 2014-10-08 17:53:10 |
| Code Space | first part of the detected transmitter code | text | A69-1601 |
| ID | second part of the detected transmitter code | text | 26451 |
| Sensor 1 |  |  |  |
| Units 1 |  |  |  |
| Sensor 2 |  |  |  |
| Units 2 |  |  |  |
| Transmitter Name |  |  |  |
| Transmitter S/N |  |  |  |
| Receiver Name | id of the receiver. only 1 different value per file | text | VR2W-122340 |
| Receiver S/N | serial number of the receiver | number | 122340 |
| Station Name | name of the receiver |  |  |
| Station Latitude | position of the receiver (lat) |  |  |
| Station Longitude | position of the receiver (long) |  |  |
