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

-- The default (calibration) masks to apply before steering masks
module.defaults = {
	calibration = matrix{
		{0, 0},
		{0, 0},
	},
}

-- The motor (output) values
module.motors = matrix{
	{0, 0},
	{0, 0},
}

-- The calculated and desired orientation of the drone (position and rotation)
module.orientation = {
	position = {
		acc = matrix(3,1),
		spd = matrix(3,1),
		pos = matrix(3,1),
	},
	rotation = {
		acc = matrix(3,1),
		spd = matrix(3,1),
		rot = matrix(3,1),
	},
	desired = { -- Can be either pos/rot or spd, according to mode
		position = matrix(3,1),
		rotation = matrix(3,1),
	}
}


module.calibrating = false -- false, "sensors", "motors"





-- CONTROL FUNCTIONS

-- Apply the masks to the motor values
function module.translateControls(controls)
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

function module.calculateMotors(mode, controls)
	if mode == 0 then
		module.translateControls(controls)
	elseif mode == 1 then
		-- Calculate controls based off desired speed
	elseif mode == 2 then
		-- Calculate controls based off desired position and default max speed
	end
end

function calculateControls(controls)
	local desired = matrix(3,1) -- Create new position vector
	
	-- Calculate desired position vector
	
	-- Calculate controls (difference between desired and actual position)
	local c = desired - orientation.position.pos
	
	-- Convert controls to power, yaw, pitch, roll (don't use yaw)
	controls.power = c[3][1] -- z
	controls.yaw = 0
	controls.pitch = c[1][1] -- x
	controls.roll = c[2][1] -- y
	
	return controls
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
	local sensors = { acc = {}, gyro = {} }

	if sensorData then
		-- Set sensor data
		sensors.acc.acc = matrix{ sensorData.acc.x, sensorData.acc.y, sensorData.acc.z }
		sensors.gyro.acc = matrix{ sensorData.gyro.x, sensorData.gyro.y, sensorData.gyro.z }
	end

	-- Convert linear and angular acceleration to speed and position (relative to the drone, not the earth)
	pos.acc = sensors.acc
	pos.spd = pos.spd + pos.acc * interval
	pos.pos = pos.pos + pos.spd * interval

	rot.acc = sensors.gyro
	rot.spd = rot.spd + rot.acc * interval
	rot.pos = rot.pos + rot.spd * interval

	-- Convert linear orientation to be relative to the earth
	-- Matrix product of rotation matrix and position vector
	pos.pos = module.rotate( "x", rot.pos.x ) * pos.pos
	pos.pos = module.rotate( "y", rot.pos.y ) * pos.pos
	pos.pos = module.rotate( "z", rot.pos.z ) * pos.pos
end





-- RETURN

matrix.multiply = matrix.hadamard

return module
