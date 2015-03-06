from unittest import TestCase, SkipTest
from consolidate_data import Validator, FileParser

class TestValidator(TestCase):
    def setUp(self):
        self.validator = Validator()

    def test_validateDateTime(self):
        dt = "2015-01-20 10:00:00"
        self.assertTrue(self.validator.validateDateTime(dt))
        dt = "20/01/2015 10:00:00"
        self.assertFalse(self.validator.validateDateTime(dt))
        dt = "2015-01-35 10:00:00"
        self.assertFalse(self.validator.validateDateTime(dt))
        dt = "2015-01-30 10-00-00"
        self.assertFalse(self.validator.validateDateTime(dt))

    def test_validateTransmitter(self):
        transmitter = "A69-1601-19439"
        self.assertTrue(self.validator.validateTransmitterId(transmitter))
        transmitter = "VR2W-4942028"
        self.assertFalse(self.validator.validateTransmitterId(transmitter))

    def test_validateReceiverId(self):
        receiver = "VR2W-112299"
        self.assertTrue(self.validator.validateReceiverId(receiver))
        receiver = "A69-1601-19439"
        self.assertFalse(self.validator.validateReceiverId(receiver))

class TestFileParser(TestCase):
    def setUp(self):
        self.fp = FileParser(delimiter=',', datetimeindex=0, receiveridindex=1, transmitteridindex=2, receivercodeindex=3)

    def test_parseLine(self):
        line = '2015-01-20 10:00:40,VR2W-112299,A69-1601-19439,tbjs'
        result = {'datetime': '2015-01-20 10:00:40', 'receiverid': 'VR2W-112299', 'transmitterid': 'A69-1601-19439', 'receivercode': 'tbjs'}
        self.assertDictEqual(self.fp.parseLine(line), result)
        line = '2015-01-20 10:00:40,A69-1601-19439,VR2W-112299,tbjs'
        self.assertFalse(self.fp.parseLine(line))