require "helpers"

local i = 0
local target
local last_input = 0
local last_time = 0
local kp, ki, kd

function init_pid(t)
	last_time = time()
	last_input = t
	target = t
	kp = 4.0
	ki = 0.8
	kd = 2.5
end

function compute_pid(input)
	local dt = time() - last_time
	local p = target - input
	local i = i + p * dt
	if i > 30 then i = 30 end
	local d = (last_input - input) / dt
	return (kp * p + ki * i + kd * d) / 10
end