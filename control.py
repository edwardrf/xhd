#!/usr/bin/python
import sys, tty, termios, arduino, time

BUF_SIZE = 10
ESC = chr(27)

CMD_UP    = ESC + '[A'
CMD_DOWN  = ESC + '[B'
CMD_RIGHT = ESC + '[C'
CMD_LEFT  = ESC + '[D'
CMD_QUIT  = 'quit'

buf = '';

# Prepare reading and writing of the terminal
if len(sys.argv) < 2:
    print "Please provie input file"

ard = arduino.Arduino(sys.argv[1])
ard.reset()

ard.reportAnalog(1)
ard.reportAnalog(2)
ard.reportAnalog(3)
ard.reportDigital(3)
ard.pinMode(2, arduino.MODE_SERVO)
ard.pinMode(3, arduino.MODE_SERVO)
time.sleep(1)
print 'start'
ard.start()

# Main loop, 
fd = sys.stdin.fileno()
old_settings = termios.tcgetattr(fd)

try:
    tty.setraw(sys.stdin.fileno())
    ch = ''
    pos = 90
    speed = 90
    
    while(ch != chr(4)):
        ch = sys.stdin.read(1)
        buf += ch
        if(len(buf) > BUF_SIZE):
            buf = buf[1:]

        if(buf.endswith(CMD_UP)):
            print 'UP\r'
            speed += 5
            if speed > 180:
                speed = 180
            ard.writeServo(2, speed)
        elif(buf.endswith(CMD_DOWN)):
            print 'DN\r'
            speed -= 5
            if speed < 0 :
                speed = 0
            ard.writeServo(2, speed)
        elif(buf.endswith(CMD_LEFT)):
            print 'LF\r'
            if pos <= 100:
                pos += 10
            else:
                pos += 5
                
            if pos > 125:
                pos = 125
            ard.writeServo(3, pos)
        elif(buf.endswith(CMD_RIGHT)):
            print 'RT\r'
            
            if pos >= 80:
                pos -= 10
            else:
                pos -= 5
            
            if pos < 55:
                pos = 55

            ard.writeServo(3, pos)
        elif(buf.endswith(CMD_QUIT)):
            print 'bye!\r'
            break
        else:
            pass

finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
    ard.exit()
