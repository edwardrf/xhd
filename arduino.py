#!/usr/bin/python
import threading, time, serial

DIGITAL_MESSAGE         = 0x90 # send data for a digital pin
ANALOG_MESSAGE          = 0xE0 # send data for an analog pin (or PWM)

# PULSE_MESSAGE = 0xA0 # proposed pulseIn/Out message (SysEx)
# SHIFTOUT_MESSAGE = 0xB0 # proposed shiftOut message (SysEx)

REPORT_ANALOG_PIN       = 0xC0 # enable analog input by pin #
REPORT_DIGITAL_PORTS    = 0xD0 # enable digital input by port pair
START_SYSEX             = 0xF0 # start a MIDI SysEx message
SET_DIGITAL_PIN_MODE    = 0xF4 # set a digital pin to INPUT or OUTPUT
END_SYSEX               = 0xF7 # end a MIDI SysEx message
REPORT_VERSION          = 0xF9 # report firmware version
SYSTEM_RESET            = 0xFF # reset from MIDI

# Pin modes
MODE_INPUT                = 0
MODE_OUTPUT               = 1
MODE_ANALOG               = 2
MODE_PWM                  = 3
MODE_SERVO                = 4

def v2d(v):
    return 20.0 / ((v * 5.0 / 1024.0) - 0.2)

class Arduino(threading.Thread):

    def __init__(self, port):
        self.port = serial.Serial(port, 57600, timeout=0.02)
        self.stop = 0
        self.digital = [0] * 16
        self.analog  = [0] * 16
        self.buf = []
        threading.Thread.__init__(self)
        time.sleep(2)

    def write(self, val):
        self.buf.append(chr(val))

    def read(self):
        ch = self.port.read()
        if ch != '':
            return ord(ch)
        else:
            return 0

    def reset(self):
        self.write(SYSTEM_RESET)

    def pinMode(self, pin, mode):
        self.write(SET_DIGITAL_PIN_MODE)
        self.write(pin)
        self.write(mode)

    def reportDigital(self, pin):
        self.write(REPORT_DIGITAL_PORTS | pin >> 3)
        self.write(1)

    def reportAnalog(self, pin):
        self.write(REPORT_ANALOG_PIN | pin)
        self.write(1)

    def writeServo(self, pin, deg):
        self.write(ANALOG_MESSAGE + pin)
        self.write(deg % 128)
        self.write(deg >> 7)

    def run(self):
        i = 0
        while self.stop == 0:
            while(len(self.buf) > 0):
                print 'L', len(self.buf), 
                out = self.buf.pop(0)
                print hex(ord(out)), '\r'
                self.port.write(out)
            ch = self.read()
            #Digital message
            if ch >= 0x90 and ch <= 0x9F:
                print 'DIGITAL MESSAGE', hex(ch),
                port = 0x0F & ch
                lsb = self.read()
                msb = self.read()
                self.digital[port] = msb << 7 | lsb
                print hex(msb), hex(lsb)
            elif ch >= 0xE0 and ch <= 0xEF:
                #print 'ANALOG MESSAGE', hex(ch), 
                port = 0x0F & ch
                lsb = self.read()
                msb = self.read()
                self.analog[port] = msb << 7 | lsb
                #print hex(msb), hex(lsb), self.analog, '\r',
            elif ch != 0:
                pass
#            print " " * 80, '\r', 
#            print i, '\t', (self.analog[1]), '\t', (self.analog[2]), '\t', (self.analog[3]), '\t', v2d(self.analog[1]), '\t', v2d(self.analog[2]), '\t', v2d(self.analog[3]), '\t', 'ch=', hex(ch), '\r',
            i+=1

    def exit(self):
        self.stop = 1
