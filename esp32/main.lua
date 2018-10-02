--[[
	
	The main drone file
	by RedPolygon
	
--]]

-- CONSTANTS

local socket = require "socket" -- Luasocket

local MAC = "24:0A:C4:9B:3B:0C"

local motorPins = {
	{pin = pio.GPIO5}, {pin = pio.GPIO18},
	{pin = pio.GPIO19}, {pin = pio.GPIO21},
}





-- HELPER FUNCTIONS

function log(...)
	print(...)
end

function stringify(t)
	local s = "{"
	for k, v in pairs(t) do
		local key = (type(k) == "number" and "["..k.."]" or k)
		if type(v) == "table" then
			s = s .. key..' = '..stringify(v)..', '
		else
			s = s .. key..' = "'..tostring(v)..'", '
		end
	end
	return s .. "}"
end





-- NETWORK FUNCTIONS

local responses = {}

function responses.start()
	-- Start PWM
	for i = 1, #motorPins do
		motorPins[i].pwm:start()
	end
	
	return stringify({
		type = "start",
		message = "true"
	})
end

function responses.stop()
	-- Stop PWM
	for i = 1, #motorPins do
		motorPins[i].pwm:stop()
	end
	
	return stringify({
		type = "stop",
		message = "true"
	})
end

-- Controller sends motor values, respond with sensor values
function responses.fly(data)
	-- Set motors
	for i = 1, #motorPins do
		motorPins[i].pwm:setduty(data.motors[i])
	end
	
	-- Read sensors
	
	-- Return
end

function receive(socket, data, port, ip)
	log( "UDP Receive from " .. ip .. " at port " .. port .. ":", data )
	data = loadstring("return " .. data)()
	log( data.option )
	
	if responses[data.option] then
		local success, response = pcall( responses[data.option], data, socket, port, ip )
		if response then
			socket:send( port, ip, response )
		end
	else
		socket:send( port, ip, stringify({ err = "No such function" }) )
	end
end





-- PROGRAM FUNCTIONS

function main()
	local data = udp:receivce() -- Receive
	if not data then return end -- Nothing received, stop
	
	-- Get controller ip and port to respond to
	local ip, port = udp:getpeername()
	
	-- Get data
	log( "RECEIVE\tip: "..ip.."\tport: "..port.."\tdata: "..data )
	data = loadstring("return " .. data)()
	
	-- Get response
	local response = {}
	
	if responses[data.option] then
		_, response = pcall( responses[data.option], data, ip, port )
	else
		response = stringify({ err = "No such function" })
	end
	
	-- Return
	if response and response ~= {} then
		log( "RESPOND\t"..response )
		udp:sendto( response, ip, port )
	end
end





-- START

log("STARTED")

-- Create wifi network
net.wf.setup( net.wf.mode.AP, "esp32-drone", "whitecat" )
net.wf.start()

-- Setup UDP
udp = socket.udp()
udp:setsockname( "*", "5000" )
udp:settimeout(0)

-- Setup PWM
for i = 1, #motorPins do
	-- pwm.attach( pin, freq (Hz), duty [0-1] )
	motorPins[i].pwm = pwm.attach( motorPins[1].pin, 1000, 0 )
end

-- Start main loop
local loop = tmr.attach( tmr.TMR0, 10000, main )
loop:start()