-- CONSTANTS

local matrix = require "matrix"

local module = {}

module.motorPins = {
	1, 2,
	3, 4,
}

module.sensorInterval = 1000 -- Delay between sensor readings (in ms)





-- VARIABLES

-- FRONT LEFT (cw),	FRONT RIGHT (ccw),
-- BACK LEFT (ccw),	BACK RIGHT (cw)
module.masks = {
	power = matrix{ -- Default
		{1, 1},
		{1, 1},
	},
	yaw = matrix{ -- Turn right
		{-1, 1},
		{ 1,-1},
	},
	pitch = matrix{ -- Forward
		{-1, -1},
		{ 1,  1},
	},
	roll = matrix{ -- Right
		{1, -1},
		{1, -1},
	},
}

module.defaults = {
	calibration = matrix{
		{0, 0},
		{0, 0},
	},
}

module.motors = matrix{
	{0, 0},
	{0, 0},
}

module.orientation = {
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

module.sensors = {
	acc = {},
	gyro = {},
	mag = {},
}

-- Modes: 0 (full control), 1 (auto hover), ... (more to come)
module.mode = 0
module.calibrating = false -- false, "sensors", "motors"





-- CONTROL FUNCTIONS

function module.translateControls() -- Apply the masks
	for k, v in pairs(module.defaults) do -- Defaults
		module.motors = module.defaults[k] + 1
	end

	for k, v in pairs(module.masks) do -- Controls
		if k == "power" then
			module.motors = module.motors * (module.masks[k] * controls[k])
		else
			local scale = 0.2 * controls[k] * math.abs(controls[k])
			module.motors = module.motors * (module.masks[k] * scale + 1)
		end
	end
end





-- OTHER FUNCTIONS

-- Return rotation matrix of given axis and angle
function module.rotate( axis, a )
	if axis == "x" then -- Pitch
		return matrix{
			{1, 0, 0},
			{0, math.cos(a), -math.sin(a)},
			{0, math.sin(a), math.cos(a)},
		}
	elseif axis == "y" then -- Roll
		return matrix{
			{math.cos(a), 0, math.sin(a)},
			{0, 1, 0},
			{-math.sin(a), 0, math.cos(a)},
		}
	elseif axis == "z" then -- Yaw
		return matrix{
			{math.cos(a), -math.sin(a), 0},
			{math.sin(a), math.cos(a), 0},
			{0, 0, 1},
		}
	end
end

function module.calibrateMotors() -- TODO: make calibrating function
	
end

-- Update the sensor data and covert it
function module.orientate(sensorData)
	local pos = module.orientation.position
	local rot = module.orientation.rotation
	local interval = module.sensorInterval / 1000

	if sensorData then
		-- Set sensor data
		module.sensors.acc.acc = matrix{ sensorData.acc.x, sensorData.acc.y, sensorData.acc.z }
		module.sensors.gyro.acc = matrix{ sensorData.gyro.x, sensorData.gyro.y, sensorData.gyro.z }
	end

	-- Convert linear and angular acceleration to speed and position (relative to the drone, not the earth)
	pos.acc = module.sensors.acc
	pos.spd = pos.spd + pos.acc * interval
	pos.pos = pos.pos + pos.spd * interval

	rot.acc = module.sensors.gyro
	rot.spd = rot.spd + rot.acc * interval
	rot.pos = rot.pos + rot.spd * interval

	-- Convert linear orientation to be relative to the earth
	-- Matrix product of rotation matrix and position vector
	pos.pos = module.rotate( "x", rot.pos.x ) * pos.pos
	pos.pos = module.rotate( "y", rot.pos.y ) * pos.pos
	pos.pos = module.rotate( "z", rot.pos.z ) * pos.pos
end





-- RETURN

return module
