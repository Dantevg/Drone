-- CONSTANTS

local attitude = require "calc/attitude"
local autopilot = require "calc/autopilot"

local fly = {}

fly.motorPins = {
	1, 2,
	3, 4,
}





-- VARIABLES

-- FRONT LEFT (cw),	FRONT RIGHT (ccw),
-- BACK LEFT (ccw),	BACK RIGHT (cw)
fly.masks = {
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
fly.defaults = {
	calibration = matrix{
		{0, 0},
		{0, 0},
	},
}

-- The motor (output) values
fly.motors = matrix{
	{0, 0},
	{0, 0},
}

fly.calibrating = false -- false, "sensors", "motors"





-- FUNCTIONS

-- Apply the masks to the motor values
function fly.translateControls(controls)
	for k, v in pairs(fly.defaults) do -- Defaults
		fly.motors = fly.defaults[k] + 1
	end
	
	fly.motors = fly.motors * controls.pos.z
	
	for _, v in ipairs{"z","y","x"} do
		local scale = 0.2 * controls.rot[v] * math.abs(controls.rot[v])
		fly.motors = fly.motors * (fly.masks[v] * scale + 1)
	end
	
	networkControls = fly.motors -- Debugging
end

function fly.calculateMotors(mode, controls)
	if mode == 0 then
		fly.translateControls(controls)
	elseif mode == 1 then
		-- Calculate controls based off desired angle
		fly.translateControls( autopilot.angle(controls) )
	elseif mode == 2 then
		-- Calculate controls based off desired speed
		fly.translateControls( autopilot.speed(controls) )
	elseif mode == 3 then
		-- Calculate controls based off desired position and default max speed
		fly.translateControls( autopilot.position(controls) )
	end
end

function fly.calibrateMotors() -- TODO: make calibrating function
	
end





-- RETURN

return fly
