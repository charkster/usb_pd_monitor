#!/usr/bin/python3
from pyftdi.ftdi import Ftdi
import pyftdi.serialext
import binascii

class USB_PD_DECODE_9K:
	# fixed widths
	HEADER_NUM_NIBBLES  = 4      
	CRC_NUM_NIBBLES     = 8
	DATA_NUM_NIBBLES    = 8
	# ascii symbols from logger (selected by me, not USB spec)
	sync_1              = 'S'
	sync_2              = 'T'
	eop                 = '\r'
	beginning_of_packet = '\n'

	def __init__(self, dev='/dev/ttyUSB1', baudrate=1000000, debug=False):
		self.dev           = dev
		self.baudrate      = baudrate
		self.debug         = debug
		self.uart          = pyftdi.serialext.serial_for_url('ftdi://ftdi:2232:1/2', baudrate=1000000, bytesize=8, parity='N', stopbits=1, timeout=1)
                # use Ftdi.show_devices() to get URL
	
	def get_packet_nibble_list(self):
		self.uart.flushInput()
		self.uart.flushOutput()
		while (1):
			byte_list = []
			packet = self.uart.read_until()
			packet_nibble_list = list(packet.decode('UTF-8'))
			for char_to_strip in ['S', 'T', 'X', '\r', '\n']:
				try:
					while True: # remove all occurance in the whole list, not just the first
						packet_nibble_list.remove(char_to_strip)
				except:
					pass
			for index in range(0,len(packet_nibble_list)):
				if (packet_nibble_list[index] in ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']):
					packet_nibble_list[index] = int(packet_nibble_list[index],16)
			if (packet_nibble_list):
				self.check_num_nibbles(packet_nibble_list)
				print('[{}]'.format(', '.join(hex(x) for x in packet_nibble_list))) # print list as hex values
	
	def check_num_nibbles(self, packet_nibble_list):
		actual_num_nibbles = len(packet_nibble_list)
		expected_data_items = packet_nibble_list[3]
		expected_num_nibbles = self.HEADER_NUM_NIBBLES + expected_data_items * self.DATA_NUM_NIBBLES + self.CRC_NUM_NIBBLES
		if (actual_num_nibbles != expected_num_nibbles):
			print("ERROR, packet number of nibbles is {:d} and expected bumber of nibbles is {:d}".format(actual_num_nibbles,expected_num_nibbles))  

