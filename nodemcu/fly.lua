-- CONSTANTS
local sensor = require "sensor"
local vector = require "vector"

local motorPins = {
	1, 2,
	3, 4,
}

local sensorInterval = 1000 -- Delay between sensor readings (in ms)





-- VARIABLES

-- FRONT LEFT (cw),	FRONT RIGHT (ccw),
-- BACK LEFT (ccw),	BACK RIGHT (cw)
local masks = {
	power = { -- Default
		1, 1,
		1, 1,
	},
	yaw = { -- Turn right
		-1,  1,
		 1, -1,
	},
	pitch = { -- Forward
		-1, -1,
		 1,  1,
	},
	roll = { -- Right
		1, -1,
		1, -1,
	},
}

local defaults = {
	calibration = {
		0, 0,
		0, 0,
	}
}

local controls = {
	power = 0,
	yaw = 0,
	pitch = 0,
	roll = 0
}

local motors = {
	0, 0,
	0, 0,
}

local orientation = {
	position = {
		acc = {},
		spd = {},
		pos = {},
	},
	rotation = {
		acc = {},
		spd = {},
		rot = {},
	},
}

local sensors = {
	acc = {},
	gyro = {},
	mag = {},
}

-- Modes: 0 (full control), 1 (auto hover), ... (more to come)
local mode = 0
local calibrating = false -- false, "sensors", "motors"





-- CONTROL FUNCTIONS

function serializeControls()
	return "{power:" .. controls.power .. ", yaw: " .. controls.yaw .. ", pitch: " .. controls.pitch .. ", roll: " .. controls.roll .. "}"
end

function translateControls() -- Apply the masks
	local n = 0
	for k, v in pairs(defaults) do -- Defaults
		motors[1] = defaults[k][1]
		motors[2] = defaults[k][2]
		motors[3] = defaults[k][3]
		motors[4] = defaults[k][4]
		n = n+1
	end
	
	for k, v in pairs(masks) do -- Controls
		motors[1] = masks[k][1] * controls[k][1]
		motors[2] = masks[k][2] * controls[k][2]
		motors[3] = masks[k][3] * controls[k][3]
		motors[4] = masks[k][4] * controls[k][4]
		n = n+1
	end
	
	-- Take the average
	motors[1] = motors[1] / n
	motors[2] = motors[2] / n
	motors[3] = motors[3] / n
	motors[4] = motors[4] / n
end

function setControls() -- Set the pwm frequencies of the motors
	pwm.setduty( motorPins[1], (motors[1]+1)/2 * 1023 )
	pwm.setduty( motorPins[2], (motors[2]+1)/2 * 1023 )
	pwm.setduty( motorPins[3], (motors[3]+1)/2 * 1023 )
	pwm.setduty( motorPins[4], (motors[4]+1)/2 * 1023 )
end





-- OTHER FUNCTIONS

function calibrateMotors() -- TODO: make calibrating function
	calibrating = "motors"
	
end

-- Update the sensor data and covert it
function updateOrientation()
	-- For each sensor, read and convert
	sensors.acc = sensor.read("acc", true)
	sensors.gyro = sensor.read("gyro", true)
	sensors.mag = sensor.read("mag", true)
	
	-- Convert linear and angular acceleration to speed and position (relative to the drone, not the earth)
	orientation.position.acc = sensors.acc
	orientation.position.spd = vector.add( orientation.position.spd, vector.scale(orientation.position.acc, sensorInterval/1000) )
	orientation.position.pos = vector.add( orientation.position.pos, vector.scale(orientation.position.spd, sensorInterval/1000) )
	
	orientation.rotation.acc = sensors.gyro
	orientation.rotation.spd = vector.add( orientation.rotation.spd, vector.scale(orientation.rotation.acc, sensorInterval/1000) )
	orientation.rotation.pos = vector.add( orientation.rotation.pos, vector.scale(orientation.rotation.spd, sensorInterval/1000) )
end





-- RESPONSE FUNCTIONS

function udpResponses.controller(params) -- Got controller values, update motors
	local fn = loadstring("return " .. params)
	if fn then
		controls = fn()
	end
	
	translateControls()
	setControls()
	return serializeControls()
end

function tcpResponses.start() -- Start motors and calibrate
	pwm.start( motorPins[1] )
	pwm.start( motorPins[2] )
	pwm.start( motorPins[3] )
	pwm.start( motorPins[4] )
	sensor.calibrate(function()
		sensorTimer:alarm( sensorInterval, tmr.ALARM_AUTO, updateOrientation ) -- Start sensor readings
		if mode >= 1 then calibrateMotors() end -- Calibration for mode 1+
	end)
end

function tcpResponses.stop() -- Stop motors (use only when on ground!)
	sensorTimer:unregister() -- Stop sensor readings
	for i = 1, 4 do
		pwm.setduty( motorPins[i], 0 )
		pwm.stop( motorPins[i] )
	end
end

function tcpResponses.setMode(params) -- Set the mode
	mode = tonumber(params)
end

function udpResponses.default() -- Replace default function
	local content = {responseHeader} -- Prepend response header
	
	-- Read file
	if file.open("index.html", "r") then
		-- Opened file successfully, read it in chunks of maxSendLength
		local chunk = file.read(maxSendLength)
		while chunk do
			content[#content+1] = chunk
			chunk = file.read(maxSendLength)
		end
		file.close()
	else
		-- Opening failed, send error
		content[#content+1] = "Failed reading index.html"
	end
	
	-- Return response for sending
	return content
end





-- CALLBACK FUNCTIONS

function udpReceive(socket, data, port, ip) -- On UDP receive, respond
	local request = getRequestParams(data)
	
	log( "UDP Receive from " .. ip .. " at port " .. port ..  ":", data )
	
	socket:send( port, ip, data ) -- Send it back
	
	-- local success, response = pcall(controller, requestParams)
	-- socket:send( port, ip, response )
end





-- START

-- Create UDP socket
udpSocket = net.createUDPSocket()
if not udpSocket then error("Failed to create UDP client") end
udpSocket:listen(5000)
udpSocket:on("receive", udpReceive)

-- Setup motor pin pwm frequencies to 500 Hz (arbitrarily chosen)
pwm.setup( motorPins[1], 500, 0 )
pwm.setup( motorPins[2], 500, 0 )
pwm.setup( motorPins[3], 500, 0 )
pwm.setup( motorPins[4], 500, 0 )

local sensorTimer = tmr.create()