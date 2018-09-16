-- CONSTANTS

-- local sensor = require "sensor"

local bootCodes = {
	[0] = "Power-on",
	"Hardware watchdog reset",
	"Exception reset",
	"Software watchdog reset",
	"Software restart",
	"Deep-sleep wake",
	"External reset"
}

local mac = "DC:4F:22:2A:2D:DC"

local apCfg = {
	ssid = "NodeMCU",
	pwd = "esp8266"
}

local apList = {
	{
		ssid = "SSID",
		pwd = "PASSWORD"
	}
}

local motorPins = {
	1, 2,
	3, 4,
}

local sensorInterval = 1000 -- Delay between sensor readings (in ms)





-- HELPER FUNCTIONS

function log(...)
	local text = {...}
	if file.open("log.txt", "a") then
		for i = 1, #text do
			file.writeline( text[i] or "nil" )
		end
		file.close()
	end
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





-- RECEIVE FUNCTIONS

responses = {}

-- Controller connects, connection check and start PWM
function responses.start()
	pwm.start( motorPins[1] )
	pwm.start( motorPins[2] )
	pwm.start( motorPins[3] )
	pwm.start( motorPins[4] )
	
	return stringify({
		type = "start",
		message = "true"
	})
end

function responses.stop()
	for i = 1, 4 do
		pwm.setduty( motorPins[i], 0 )
		pwm.stop( motorPins[i] )
	end
	
	return stringify({
		type = "stop",
		message = "true"
	})
end

-- Controller sends motor values, respond with sensor values
function responses.fly(data)
	-- Set motors
	pwm.setduty( motorPins[1], data.motors[1] )
	pwm.setduty( motorPins[2], data.motors[2] )
	pwm.setduty( motorPins[3], data.motors[3] )
	pwm.setduty( motorPins[4], data.motors[4] )
	
	-- Read sensors
	-- local acc = sensor.read("acc", true)
	-- local gyro = sensor.read("gyro", true)
	-- local mag = sensor.read("mag", true)
	
	-- Return
	-- return stringify({
	-- 	type = "sensor",
	-- 	data.motors[1],
	-- 	data.motors[2],
	-- 	data.motors[3],
	-- 	data.motors[4]
	-- })
	
	--[[ return stringify({
		type = "sensor",
		acc = { x = acc.x, y = acc.y, z = acc.z },
		gyro = { x = gyro.x, y = gyro.y, z = gyro.z },
		mag = { x = mag.x, y = mag.y, z = mag.z },
	}) ]]
end

function responses.calibration(data, socket, port, ip)
	sensor.calibrate(function()
		socket:send( port, ip, stringify({
			type = "calibration",
			message = "true"
		}) )
	end)
end





-- CALLBACK FUNCTIONS

function receive(socket, data, port, ip)
	log( "UDP Receive from " .. ip .. " at port " .. port ..  ":", data )
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





-- START

local bootCode, extendedBootCode, v1, v2, v3, v4, v5, v6 = node.bootreason()

log("", "", "-------", "STARTED", "")
log( "Boot reason: " .. bootCodes[extendedBootCode] )
log( v1, v2, v3, v4, v5, v6 )
node.output(log)

-- Connect to wifi
wifi.setmode(wifi.STATIONAP)
wifi.sta.sethostname("NodeMCU-drone")
wifi.ap.config(apCfg) -- Setup server

-- Create UDP socket
udpSocket = net.createUDPSocket()
if not udpSocket then error("Failed to create UDP client") end
udpSocket:listen(5000)
udpSocket:on("receive", receive)
log("UDP Started")

-- Setup client
log("Searching for networks...")
wifi.sta.getap(function(list)
	for ssid,v in pairs(list) do
    local authmode, rssi, bssid, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]+)")
    for i = 1, #apList do
    	if ssid == apList[i].ssid then
    		-- Connect
    		log("Connecting to " .. ssid .. "...")
    		wifi.sta.config({ ssid = apList[i].ssid, pwd = apList[i].pwd, auto = false })
    		wifi.sta.connect(function()
    			log("Wifi connected")
  			end)
    		return
    	end
    end
  end
end)

-- Setup motor pin pwm frequencies to 500 Hz (arbitrarily chosen)
-- ( pin, clock [1-1000]Hz, duty [0-1023] )
pwm.setup( motorPins[1], 500, 0 )
pwm.setup( motorPins[2], 500, 0 )
pwm.setup( motorPins[3], 500, 0 )
pwm.setup( motorPins[4], 500, 0 )
