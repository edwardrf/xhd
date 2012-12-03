#!/usr/bin/lua

require "regression"
require "socket"

port=assert(socket.connect("localhost", 9090))
os.execute("sleep 2")

function send_cmd(...)
    fmt = string.rep("\\x%x", arg.n)
    os.execute("echo -e '" .. string.format(fmt, unpack(arg)) .. "' > /dev/ttyATH0")
end

function regression(h)
    n = table.getn(h)
    sumxy = 0
    sumx  = 0
    sumy  = 0
    sumx2 = 0
    sumy2 = 0
    for x, y in ipairs(h) do
        sumxy = sumxy + x * y
        sumx  = sumx + x
        sumy  = sumy + y
        sumx2 = sumx2 + x * x
        sumy2 = sumy2 + y * y
--        print("x, ", x, "  y, ", y)
    end
    b = (sumxy * n - sumx * sumy) / (sumx2 * n - sumx * sumx)
    
    sx = (sumx2 - sumx * sumx / n) / n
    sy = (sumy2 - sumy * sumy / n) / n
    
    r = (n * sumxy - sumx * sumy) /(((n * sumx2 - sumx * sumx) * (n * sumy2 - sumy * sumy)) ^ 0.5)
    
    return b, r
end

kp = 0.2
ki = 0.005
kd = 0.05

function pid(his, target)

    x = his[table.getn(his)]
    e = target - x
    
    i = 0
    for n, v in ipairs(his) do
        i = i + target - v
    end 
    
    p = kp * e
    i = ki * i
    d = kd * (his[table.getn(his) - 1] - x)
    
    return (p + i + d)
end


print("init firmata")
--       [RST] [REPORT Analog pins           ]  [SETUP SERVOS AND MOTOR                 ] 
send_cmd(0xff, 0xc1, 0x1, 0xc2, 0x1, 0xc3, 0x1, 0xd0, 0x1, 0xf4, 0x2, 0x4, 0xf4, 0x3, 0x4)

digital = {0}
analog  = {0}
dis     = {0}
history = {0}
left    = {0}
right   = {0}

clock = 0
cur_speed = 90;
cur_steer = 90;
print("initialize steer and speed");
send_cmd(0xE2, cur_speed % 128, math.floor(cur_speed / 128), 0xE3, cur_steer % 128, math.floor(cur_steer / 128))

-- Wait for firmata to give enough data.
os.execute("sleep 1")
print("start");

function main()
    while true do
        ch=port:receive(1)
        if ch == nil then
            print("Communication failure. Exit")
            os.exit(-1)
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
    
-- Print readings on screen
        io.write("\r") 
        for i, v in ipairs(analog) do
            distance = 20000.0 / ((v * 4.8828125) - 200)
            if distance < 0 then distance = 1000 end
            dis[i] = distance
            io.write(string.format(" %d : %06.2f   \t", i, distance))
        end
    
-- Main Logic
        -- slowing the decision making, after 9 bytes, there should be new set of sensor values
        if clock > 150 and clock % 9 == 0 then
            b = 0
            r = 0
            table.insert(history, dis[2])
            if table.getn(history) > 10 then
                table.remove(history, 1)
            -- Caclulate the current speed by finding gradiant of last 20 front distance
                b, r = regression(history)
            end
        
            table.insert(left, dis[3])
            if table.getn(left) > 30 then table.remove(left, 1) end
            table.insert(right, dis[1])
            if table.getn(right) > 30 then table.remove(right, 1) end
            
            speed = 90
            steer = 90
            -- WALL FOLLOWING
            if dis[3] < 200 then
                ctrl = pid(left, 30)
                steer = math.floor(90 - ctrl * 2)
                if steer > 120 then steer = 120 end
                if steer < 60 then steer = 60 end
                io.write(string.format("\t%06.2f\n", ctrl))
            end

            -- SPEED CONTROL
            if dis[2] > 100 then
                -- Fast
                speed = 105
            elseif dis[2] > 70 then
                -- Slow
                speed = 101
            elseif dis[2] > 30 then
                -- Turn tight corners
                speed = 98
--[[
                if dis[1] < 30 and dis[3] < 30 then
                    if dis[1] < dis[3] then
                        steer = 110
                    else
                        steer = 70
                    end
                elseif dis[1] < 30 then
                    steer = 140
                elseif dis[3] < 30 then
                    steer = 40
                else
                    if dis[1] < dis[3] then
                        steer = 140
                    else
                        steer = 40
                    end
                end
]]--
            else
                -- Reverse when it is too close
                speed = 70
                steer = 180 - steer    -- Flip the steering when reversing
            end 
    
            if b < -60 and r < - 0.6 then
                speed = 70 -- break when it is about to hit a wall
            end
    
            if clock % 45 == 0 then io.write("\tSpeed : ", speed, "   \tSteer : ", steer, "  ") end
            
            if speed ~= cur_speed then
                send_cmd(0xE2, speed % 128, math.floor(speed / 128))
                -- Wait for a second for ESC to clear stop
                cur_speed = speed
            end
            if steer ~= cur_steer then
                steer = steer - 10
                send_cmd(0xE3, steer % 128, math.floor(steer / 128))
                cur_steer = steer
            end
    
        end
        clock = clock + 1
    end
end

main()
