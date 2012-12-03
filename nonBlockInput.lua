require 'posix'

module(..., package.seeall)

local stdin = io.open('/proc/self/fd/0', 'rb')
local initFlag = false

function ttyRaw()
    os.execute("stty raw -echo -echoctl -echoe")
    initFlag = true
end

function ttySane()
    os.execute("stty sane")
    initFlag = false
end

function ttyClear()
    os.execute("clear")
end

function getChar()
    if initFlag == false then ttyRaw() end
    local v = posix.rpoll(stdin, 0)
    if v > 0 then
        local ch = stdin:read(1)
        -- Check escape sequences
        if(ch:byte() == 27) then
            local buf = ch
            ch = stdin:read(1)
            buf = buf .. ch
            -- CSI  ESC + [ + ?
            if ch == '[' then
                ch = stdin:read(1)
                buf = buf .. ch
                if ch == 'O' or ch == 'P' then
                    buf = buf .. stdin:read(1)
                elseif ch >= '0' and ch <= '9' then
                    repeat
                        ch = stdin:read(1)
                        buf = buf .. ch
                    until ch == '~'
                end
            end
            return buf
        end
        return ch
    else
        return nil
    end
end

function getLine()
    if initFlag == true then ttySane() end
    local v = posix.rpoll(stdin, 0)
    if v == 0 then return nil end
    local buf = ''
    local ch = nil
    while true do
        local ch = stdin:read(1)
        if ch == '\10' then break end
        buf = buf .. ch
    end
    return buf
end


