require "helpers"

local i = 0
local target
local last_input = 0
local last_time = 0
local kp, ki, kd
local logfile

function init_pid(t)
	last_time = time()
	last_input = t
	target = t
	kp = 2.0
	ki = 2.4
	kd = 1.0
	local logfilename = "/tmp/log/" .. math.floor(socket.gettime()) .. ".log"
	logfile = assert(io.open(logfilename, "w"))
end

function compute_pid(input)
	local t = time()
	local dt = t - last_time
	local p = target - input
	local i = i + p * dt
	local d = (last_input - input) / dt
	logfile:write(t .. ',' .. input .. ',' .. kp * p .. ',' .. ki * i .. ',' .. kd * d .. "," .. (kp * p + ki * i + kd * d) .. '\n')
	logfile:flush()
	last_input = input
	last_time = t
	return (kp * p + ki * i + kd * d) / 10
end

function end_pid()
	logfile:close()
end