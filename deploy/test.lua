require "arduino"
require "helpers"
require "kalman"

init_arduino()
-- Get enough initial readings
for i = 1, 100, 1 do update_readings() end

local al, ar, af, l, r, f, cnt, kl, kr, kf

kl = Kalman()
kr = Kalman()
kf = Kalman()

cnt = 0
while true do
	-- Non blocking update reading
	if update_readings() then
		al = get_analog(3)
		ar = get_analog(1)
		af = get_analog(2)

		l = kl:step(0, al)
		r = kr:step(0, ar)
		f = kf:step(0, af)
	end

	if cnt % 3 == 0 and cnt > 30 then
		print(al .. "\t" .. l .. "\t" .. af .. "\t" .. f .. "\t" .. ar .. "\t"  .. r)
	end

	cnt = cnt + 1
	if cnt > 3000 then break end
end

os.execute("arduino_reset")