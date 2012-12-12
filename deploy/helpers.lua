require "socket"

function cursor(row, col)
	io.write('\27[' .. row .. ';' .. col .. 'H')
end

function hide_cursor()
	io.write('\27[?25l')
end

function show_cursor()
	io.write('\27[?25h')
end

function save_cursor()
	io.write('\27' .. '7')
end

function restore_cursor()
	io.write('\27' .. '8')
end	

function sleep(t)
	socket.select(nil, nil, t)
end

function time()
	return socket.gettime()
end

function fork(cmd)
	local tmpf = os.tmpname();
	os.execute(cmd .. " & \necho $! > " .. tmpf)
	local f = io.open(tmpf)
	local pid = f:read("*all")
	f:close()
	os.execute("rm " .. tmpf)
	return pid
end

function kill(pid)
	os.execute("kill " .. pid)
end

function irDist(reading)
    distance = 20000.0 / ((reading * 4.8828125) - 200)
    if distance < 0 then distance = 1000 end
    return distance
end

function irDistLong(reading)
    distance = 30431 * reading ^ -1.169
    if distance < 0 then distance = 1000 end
    return distance
end

function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end