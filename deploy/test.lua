require "helpers"

local pid = fork("lua ../sleep.lua")
print(pid)
sleep(1)
kill(pid)
print("After one")