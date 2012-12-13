#!/usr/bin/lua

require "nonBlockInput"
require "socket"
require "helpers"
require "arduino"
require "pid"
require "regression"

CMD_UP = '\27[A'
CMD_DN = '\27[B'
CMD_LF = '\27[D'
CMD_RT = '\27[C'


local speed = 90
local steer = 90
local last_speed, last_steer
local hf = {0}

local pid = fork("lua sensors.lua")

function set_speed(spd)
	send_cmd(0xE2, spd % 128, math.floor(spd / 128))
end

function set_steer(str)
	send_cmd(0xE3, str % 128, math.floor(str / 128))
end

function init_motor_controller()
	for i = 90, 180, 1 do
		set_speed(i)
		sleep(0.01)
	end
	sleep(2.5)
	for i = 180, 0, -1 do
		set_speed(i)
		sleep(0.01)
	end
	sleep(2.5)
	set_speed(90)
	sleep(2.5)
end

-- Main event loop
function cmd_loop()
	set_speed(90)
	set_steer(90)
	i = 0
	while true do
		local cmd = nonBlockInput.getLine()
		if cmd ~= nil then
			if cmd == "quit" then break end
			if cmd == "rc" then rc_loop() end
			if cmd == "auto" then auto_loop() end
			-- MC is too dangerous, use RC and manually set up the controller instead
			-- if cmd == "mc" then init_motor_controller() end
		end
	end
end

-- Remote control event
function rc_loop()
	local at = time()
	while true do
		local ch = nonBlockInput.getChar()
		if ch == 'q' or ch == '\4' then
			break
		elseif ch == CMD_UP then
			speed = speed + 5
		elseif ch == CMD_DN then
			speed = speed - 5
		elseif ch == CMD_LF then
			steer = steer + 5
		elseif ch == CMD_RT then
			steer = steer - 5
		end

		if steer > 120 then steer = 120 end
		if steer < 60  then steer = 60  end

		if ch ~= nil then
			at = time()
		end

		local client = socket.connect("localhost", 1987)
		if client ~= nil then
			local readings = client:receive("*a")
			readings = readings:split('\n')
			local l = tonumber(readings[1])
			local f = tonumber(readings[2])
			local r = tonumber(readings[3])

			if (time() - at) > 0.1  then
				-- Auto decay of the speed and steer
				if steer > 90 then steer = steer - 1 end
				if steer < 90 then steer = steer + 1 end
				if speed > 90 then speed = speed - 1 end
				if speed < 90 then speed = speed + 1 end
				at = time()
				hide_cursor()
				save_cursor()
				cursor(32, 1)
				print("speed : " .. speed .. "     \t\tsteer : " .. steer .. '      ')
				cursor(33, 1)
				print("l : " .. string.format("%4.3f", l) .. "       \t\tf : " .. string.format("%4.3f", f) .. '     \t\tr : ' .. string.format("%4.3f", r) .. '       ')
				restore_cursor()
				show_cursor()
			end
		end
		if speed ~= last_speed then set_speed(speed); last_speed = speed end
		if steer ~= last_steer then set_steer(steer); last_steer = steer end
	end
end

function auto_loop()
	init_pid(35)
	while true do
		local ch = nonBlockInput.getChar()
		if ch == 'q' or ch == '\4' then
			set_speed(90)
			set_steer(90)
			end_pid()
			break
		elseif ch == CMD_DN then
			-- Quick break of the current action
			set_speed(90)
			set_steer(90)
			sleep(5)
		end

		local client = socket.connect("localhost", 1987)
		local readings = client:receive("*a")
		readings = readings:split('\n')
		local l = tonumber(readings[1])
		local f = tonumber(readings[2])
		local r = tonumber(readings[3])

		table.insert(hf, f)
		if table.getn(hf) > 30 then table.remove(hf, 1) end

		-- Main logic
		-- PID steer for left side wall following
		local reverse_flag = false
		local output = compute_pid(l)
		local steer = 90 - output
		local speed = 90
		-- Front distance speed
		if f > 120 then
			speed = 105
		elseif f > 90 then
			speed = 105
		elseif f > 70 then
			if l < 50 then steer = 60 end
			speed = 98
		elseif f < 40 then
			-- Reverse when it is too near, flip the steering
			speed = 70
			steer = 180 - steer
			reverse_flag = true
		else -- Else, turn right
			speed = 98
			steer = 60
		end

		local b, r = regression(hf)
		if b < -60 and r < - 0.6 then
            speed = 70 -- break when it is about to hit a wall
        end

		if steer < 60 then steer = 60 end
		if steer > 120 then steer = 120 end 

		set_speed(math.floor(speed + 0.5))
		set_steer(math.floor(steer + 0.5))
		if reverse_flag then sleep(0.2) end

		hide_cursor()
		save_cursor()
		cursor(32, 1)
		print("speed : " .. speed .. "     \t\tsteer : " .. steer .. '      ')
		cursor(33, 1)
		print("l : " .. string.format("%4.3f", l) .. "       \t\tf : " .. string.format("%4.3f", f) .. '     \t\tr : ' .. string.format("%4.3f", r) .. '       ')
		restore_cursor()
		show_cursor()
	end

end

sleep(1)
set_speed(90)
set_steer(90)
cmd_loop()
kill(pid)
os.execute("arduino_reset")