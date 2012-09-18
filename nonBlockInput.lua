require 'posix'

stdin = io.open('/proc/self/fd/0', 'rb')
buf = '0'
val = 10
lv = 0
quitFlag = 0
esc = 0
hasInput = 0

CMD_UP = string.char(27) .. '[A'
CMD_DN = string.char(27) .. '[B'
CMD_RT = string.char(27) .. '[C'
CMD_LF = string.char(27) .. '[D'
CMD_QT = 'quit'

function test()
    while true do
        v = posix.rpoll(stdin, 0)
        while v > 0 or esc > 0 do
            buf = buf .. stdin:read(1)
            if buf:len() > 10 then
                buf = buf:sub(-10)
            end
            v = posix.rpoll(stdin, 0)
            if buf:sub(-1):byte() == 27 then esc = 3 end
            if esc > 0 then esc = esc - 1 end
            hasInput = 1
--            print(buf)
        end
        if quitFlag ~= 0 then return end
        if hasInput == 1 then
            cmd = buf:sub(-3)
--            print(buf:sub(-4))
            if cmd == CMD_LF then
--                print("LEFT")
                val = val - 1
                if val < 0 then val = 0 end
            elseif cmd == CMD_RT then
                val = val + 1
                if val > 20 then val = 20 end
            elseif buf:sub(-4) == CMD_QT then
                quitFlag = 1
            end
        end
        if val ~= lv then
            io.write(string.char(27) .. '[10;5H')
            for i = 0, val - 1, 1 do
                io.write("#")
            end
            for i = val - 1, 20, 1 do
                io.write(" ")
            end
            io.write("\r")
            io.flush()
            hasInput = 0;
            lv = val
        end
    end
end

os.execute("stty raw -echo -echoctl -echoe")
test()
os.execute("stty sane")
