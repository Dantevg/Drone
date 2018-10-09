--[[
	
	The main drone file
	by RedPolygon
	
--]]

-- CONSTANTS

local socket = require "socket" -- Luasocket
local sensor = require "sensor"

local MAC = "24:0A:C4:9B:3B:0C"

local motorPins = {
	{pin = pio.GPIO5}, {pin = pio.GPIO18},
	{pin = pio.GPIO19}, {pin = pio.GPIO21},
}





-- VARIABLES

local ip, port = nil, nil

local sensors = {}





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

function updateSensors()
	sensors = {
		acc = sensor.read("acc"),
		gyro = sensor.read("gyro")
	}
end





-- NETWORK FUNCTIONS

local responses = {}

function responses.start()
	-- Start PWM
	for i = 1, #motorPins do
		motorPins[i].pwm:start()
	end
	
	return stringify{
		type = "start",
		message = "true"
	}
end

function responses.stop()
	-- Stop PWM
	for i = 1, #motorPins do
		motorPins[i].pwm:stop()
	end
	
	return stringify{
		type = "stop",
		message = "true"
	}
end

-- Controller sends motor values
function responses.setMotors(data)
	-- Set motors
	for i = 1, #motorPins do
		motorPins[i].pwm:setduty(data.motors[i])
	end
end

function responses.getSensors()
	return stringify{
		type = "sensors",
		data = sensors
	}
end

-- Set motors and respond with sensor data
function responses.fly(data)
	responses.setMotors(data)
	return responses.getSensors()
end





-- PROGRAM FUNCTIONS

function receive(data)
	-- Get data
	local fn, err = load("return " .. data)
	if err then error(err) end
	data = fn()
	
	ip, port = data.ip, data.port
	
	log( "RECEIVE\tip: "..data.ip.."\tport: "..data.port.."\tdata: "..data.data )
	
	-- Get response
	local response = {}
	
	if responses[data.fn] then
		log( "EXECUTE\t"..data.fn )
		_, response = pcall( responses[data.fn], data, ip, port )
	else
		response = stringify{ err = "No such function" }
	end
	
	-- Return
	if response and response ~= {} then
		log( "RESPOND\t"..response )
		udp:sendto( response, ip, port )
	end
end





-- START

log("STARTING DRONE SOFTWARE")

-- Create wifi network
-- log("CREATING WIFI NETWORK")
-- net.wf.setup( net.wf.mode.AP, "esp32-drone", "whitecat" )
log("CONNECTING TO WIFI NETWORK")
net.wf.setup( net.wf.mode.STA, "VFNL-48A35C", "TD1XQETY" )
net.wf.start()

while not net.connected() do
	tmr.sleepms(100)
end

log("CONNECTED")

-- Setup UDP
log("STARTING UDP SOCKET")
udp = socket.udp()
udp:setsockname( "*", "5000" )
udp:settimeout(0)

-- Setup PWM
log("INITIALIZING PWM")
for i = 1, #motorPins do
	-- pwm.attach( pin, freq (Hz), duty [0-1] )
	motorPins[i].pwm = pwm.attach( motorPins[i].pin, 1000, 0 )
end

-- Start main loop
log("STARTED")

while true do
	local data = udp:receive()
	if data then receive(data) end
	tmr.sleepms(1000) -- Sleep for 1 second (difference with tmr.delayms?)
end