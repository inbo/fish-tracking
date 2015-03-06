from time import strptime
import re

class Validator:
    def validateDateTime(self, field):
        try:
            strptime(field, "%Y-%m-%d %H:%M:%S")
            return True
        except ValueError:
            return False

    def validateTransmitterId(self, field):
        if re.findall('[a-zA-Z][0-9]+-[0-9]+-[0-9]+', field):
            return True
        else:
            return False

    def validateReceiverId(self, field):
        if re.findall('VR2.*-[0-9]+', field):
            return True
        else:
            return False

class FileParser:
    def __init__(self, delimiter=',', datetimeindex=0, receiveridindex=1, transmitteridindex=2, receivercodeindex=3):
        self.delimiter = delimiter
        self.datetimeindex = datetimeindex
        self.receiveridindex = receiveridindex
        self.receivercodeindex = receivercodeindex
        self.transmitteridindex = transmitteridindex
        self.validator = Validator()

    def parseLine(self, line):
        fields = line.strip().split(self.delimiter)
        datetime = fields[self.datetimeindex]
        receiverid = fields[self.receiveridindex]
        receivercode = fields[self.receivercodeindex]
        transmitterid = fields[self.transmitteridindex]
        if self.validator.validateDateTime(datetime) and self.validator.validateTransmitterId(transmitterid) and self.validator.validateReceiverId(receiverid):
            outdata = {'datetime': datetime, 'receiverid': receiverid, 'receivercode': receivercode, 'transmitterid': transmitterid}
            return outdata
        else:
            return False

