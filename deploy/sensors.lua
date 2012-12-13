require "arduino"
require "helpers"
require "kalman"

init_arduino()
-- Get enough initial readings
for i = 1, 100, 1 do update_readings() end

local socket = require("socket")
local server = assert(socket.bind("*", 1987))
server:settimeout(0)

os.execute("clear")
cursor(30, 1)

local l, r, f, ll, lr, lf, dl, dr, df, cnt, kl, kr, kf

kl = Kalman()
kr = Kalman()
kf = Kalman()

cnt = 0
while true do
	-- Non blocking update reading
	if update_readings() then
		dl = irDist(kl:step(0, get_analog(3)))
		dr = irDist(kr:step(0, get_analog(1)))
		df = irDistLong(kf:step(0, get_analog(2)))
		l = math.floor(dl / 4 + 0.5)
		r = math.floor(dr / 4 + 0.5)
		f = math.floor(df / 7 + 0.5)

		if (l ~= ll or r ~= lr or f ~= lf) and cnt > 10 then
			hide_cursor()
			save_cursor()
			for i = 1, 20, 1 do
				cursor(25 - math.floor(i / 2), 40 - i * 2)
				if i > l + 1 then io.write('.') else io.write('#') end
				cursor(25 - math.floor(i / 2), 40 + i * 2)
				if i > r + 1 then io.write('.') else io.write('#') end
				cursor(4 + i, 40)
				if i < (20 - f) then io.write('.') else io.write('#') end
			end
			cursor(2, 1)
			print('l:' .. l .. '     \tf:' .. f .. '     \tr:' .. r .. '     ')
			io.flush()
			restore_cursor()
			show_cursor()
			io.flush()
			ll = l; lr = r; lf = f
			cnt = 0
		end
		cnt = cnt + 1
		if cnt > 65535 then cnt = 11 end
	end

	-- Allow other processes to get the readings
	-- not a good method as every reading is a new connection
	local client = server:accept()
	if client ~= nil then 
		client:send(dl .. '\n' .. df .. '\n' .. dr)
		client:close()
	end
end