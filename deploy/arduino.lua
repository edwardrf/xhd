local port
local digital = {0}
local analog = {0}

function send_cmd(...)
    fmt = string.rep("\\x%x", arg.n)
    os.execute("echo -e '" .. string.format(fmt, unpack(arg)) .. "' > /dev/ttyATH0")
end

function init_arduino()
	port = assert(socket.connect("localhost", 9090))
    port:settimeout(0.05)
	os.execute("sleep 1")
	--       [RST] [REPORT Analog pins           ]  [SETUP SERVOS AND MOTOR                 ] 
	send_cmd(0xff, 0xc1, 0x1, 0xc2, 0x1, 0xc3, 0x1, 0xd0, 0x1, 0xf4, 0x2, 0x4, 0xf4, 0x3, 0x4)
end

function update_readings()
    ch=port:receive(1)
    if ch == nil then
        return nil
    end
    ch = ch:byte()
-- print(ch)
-- Digital message
    if ch >= 0x90 and ch <= 0x9F then
        p   = ch % 16
        lsb = port:receive(1):byte()
        msb = port:receive(1):byte()
        digital[p] = msb * 128 + lsb
-- Analog message
    elseif ch >= 0xE0 and ch <= 0xEF then
        p   = ch % 16
        lsb = port:receive(1):byte()
        msb = port:receive(1):byte()
        analog[p] = msb * 128 + lsb
    end
    return true
end

function get_digital(i)
	return digital[i]
end

function get_analog(i)
	return analog[i]
end