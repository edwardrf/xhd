require "nonBlockInput"

nonBlockInput.ttyRaw()

CMD_UP = '\27[A'
CMD_DN = '\27[B'
CMD_LF = '\27[D'
CMD_RT = '\27[C'

local val = 10
local lv = 0

while true do
    local ch = nonBlockInput.getChar()
    if ch == 'q' or ch == '\4' then --q or ctrl+d end the program
        break
    elseif ch == CMD_LF then
        if val > 0 then val = val - 1 end
    elseif ch == CMD_RT then
        if val < 20 then val = val + 1 end
    elseif ch ~= nil then
        print(ch:byte())
    end
    if val ~= lv then
        io.write('\27[10;5H')
        for i = 0, val - 1, 1 do
            io.write("#")
        end
        for i = val - 1, 20, 1 do
            io.write(" ")
        end
        io.flush()
        lv = val
    end
end

nonBlockInput.ttySane()