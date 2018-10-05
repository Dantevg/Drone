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
	z = matrix{ -- Turn right
		{-1, 1},
		{ 1,-1},
	},
	y = matrix{ -- Forward
		{-1, -1},
		{ 1,  1},
	},
	x = matrix{ -- Right
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
	
	module.motors = module.motors * controls.pos.z
	
	for _, v in ipairs{"z","y","x"} do
		local scale = 0.2 * controls.rot[v] * math.abs(controls.rot[v])
		module.motors = module.motors * (module.masks[v] * scale + 1)
	end
	
	networkControls = module.motors
end

function module.calculateMotors(mode, controls)
	if mode == 0 then
		module.translateControls(controls)
	elseif mode == 1 then
		-- Calculate controls based off desired angle
		module.translateControls( calculateAngleControls(controls) )
	elseif mode == 2 then
		-- Calculate controls based off desired speed
		module.translateControls( calculateSpeedControls(controls) )
	elseif mode == 3 then
		-- Calculate controls based off desired position and default max speed
		module.translateControls( calculatePositionControls(controls) )
	end
end

function calculateAngleControls(controls)
	local current = module.orientation.rotation.pos
	local desired = matrix{ {controls.rot.x}, {controls.rot.y}, {controls.pos.z} }
	
	local c = {
		pos = {
			z = 0
		},
		rot = {
			x = 0,
			y = 0,
			z = 0,
		}
	}
	
	if current.x < desired[1] then
		c.rot.x = 0.1
	end
	if current.y < desired[2] then
		c.rot.y = 0.1
	end
	if current.z < desired[3] then
		c.pos.z = 0.1
	end
	
	return c
end

function calculateSpeedControls(controls)
	local current = module.orientation.position.spd
	local desired = matrix{ {controls.rot.x}, {controls.rot.y}, {controls.pos.z} }
	
	local c = {
		pos = {
			z = 0
		},
		rot = {
			x = 0,
			y = 0,
			z = 0,
		}
	}
	
	if current.x < desired[1] then
		c.rot.x = 0.1
	end
	if current.y < desired[2] then
		c.rot.y = 0.1
	end
	if current.z < desired[3] then
		c.pos.z = 0.1
	end
	
	return c
end

function calculatePositionControls(controls)
	local current = module.orientation.position.pos
	local desired = matrix{ {controls.rot.x}, {controls.rot.y}, {controls.pos.z} }
	
	local c = {
		pos = {
			z = 0
		},
		rot = {
			x = 0,
			y = 0,
			z = 0,
		}
	}
	
	if current.x < desired[1] then
		c.rot.x = 0.1
	end
	if current.y < desired[2] then
		c.rot.y = 0.1
	end
	if current.z < desired[3] then
		c.pos.z = 0.1
	end
	
	return c
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
	
	module.orientation.position = pos
	module.orientation.rotation = rot
end





-- RETURN

matrix.multiply = matrix.hadamard

return module
