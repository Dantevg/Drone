-- Set baud rate to 115200 (for older firware versions, like 0.9.6)
-- uart.setup(0,115200,8,0,1)

-- Run main.lua after 2 seconds
tmr.create():alarm( 2000, tmr.ALARM_SINGLE, function() dofile("main.lua") end )