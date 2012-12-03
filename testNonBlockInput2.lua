require "nonBlockInput"

local i = 0
while true do
	local cmd = nonBlockInput.getLine()
	if cmd ~= nil then print(cmd) end
	if cmd == 'quit' then break end
	io.write(i .. '            \r')
	io.flush()
	i = i + 1
end
