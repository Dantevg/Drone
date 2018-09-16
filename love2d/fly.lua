-- CONSTANTS

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

module.defaults = {
	calibration = {
		0, 0,
		0, 0,
	}
}

module.motors = {
	0, 0,
	0, 0,
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
	local n = 0
	for k, v in pairs(module.defaults) do -- Defaults
		module.motors[1] = module.defaults[k][1] + 1
		module.motors[2] = module.defaults[k][2] + 1
		module.motors[3] = module.defaults[k][3] + 1
		module.motors[4] = module.defaults[k][4] + 1
	end
	
	for k, v in pairs(module.masks) do -- Controls
		if k == "power" then
			module.motors[1] = module.motors[1] * (module.masks[k][1] * controls[k])
			module.motors[2] = module.motors[2] * (module.masks[k][2] * controls[k])
			module.motors[3] = module.motors[3] * (module.masks[k][3] * controls[k])
			module.motors[4] = module.motors[4] * (module.masks[k][4] * controls[k])
		else
			module.motors[1] = module.motors[1] * (module.masks[k][1] * 0.2 * controls[k]^2 + 1)
			module.motors[2] = module.motors[2] * (module.masks[k][2] * 0.2 * controls[k]^2 + 1)
			module.motors[3] = module.motors[3] * (module.masks[k][3] * 0.2 * controls[k]^2 + 1)
			module.motors[4] = module.motors[4] * (module.masks[k][4] * 0.2 * controls[k]^2 + 1)
		end
	end
end





-- OTHER FUNCTIONS

function module.calibrateMotors() -- TODO: make calibrating function
	
	
end

-- Update the sensor data and covert it
function module.updateOrientation()
	-- Convert linear and angular acceleration to speed and position (relative to the drone, not the earth)
	module.orientation.position.acc = sensors.acc
	module.orientation.position.spd = vector.add( orientation.position.spd, vector.scale(orientation.position.acc, sensorInterval/1000) )
	module.orientation.position.pos = vector.add( orientation.position.pos, vector.scale(orientation.position.spd, sensorInterval/1000) )
	
	module.orientation.rotation.acc = sensors.gyro
	module.orientation.rotation.spd = vector.add( orientation.rotation.spd, vector.scale(orientation.rotation.acc, sensorInterval/1000) )
	module.orientation.rotation.pos = vector.add( orientation.rotation.pos, vector.scale(orientation.rotation.spd, sensorInterval/1000) )
end





-- RETURN

return module
