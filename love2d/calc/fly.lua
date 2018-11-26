--[[
	
	FLY
	by RedPolygon
	
	The functions in this file combine the orientation and auto flying functions
	to calculate the controls based off the mode the user is in
	
--]]

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
	matrix{ -- x/forward
		{-1, -1},
		{ 1,  1},
	},
	matrix{ -- y/right
		{1, -1},
		{1, -1},
	},
	matrix{ -- z/yaw/turn right
		{-1, 1},
		{ 1,-1},
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

function fly.reset()
	-- Reset desired orientation
	attitude.orientation.desired = { position = {}, rotation = {} }
	
	-- TODO: Reset PID
end

-- Apply the masks to the motor values
function fly.translateControls(controls)
	-- Defaults
	for k, v in pairs(fly.defaults) do
		fly.motors = fly.defaults[k] + 1
	end
	
	local power = (controls[3][1] + 1) / 2
	local pitch = controls[1][1]
	local roll = controls[2][1]
	local yaw = controls[4][1]
	
	-- Controls: z/up, x/pitch, y/roll, z/yaw
	fly.motors[1][1] = power - pitch + roll - yaw
	fly.motors[1][2] = power - pitch - roll + yaw
	fly.motors[2][1] = power + pitch + roll + yaw
	fly.motors[2][2] = power + pitch - roll - yaw
	
	-- fly.motors = fly.motors * controls[4][1]
	
	-- for i = 1, #fly.masks do
	-- 	local mask = fly.masks[i]
	-- 	local scale = 0.2 * controls[i][1] * math.abs(controls[i][1])
	-- 	fly.motors = fly.motors * (mask * scale + 1)
	-- end
	
	networkControls = fly.motors -- Debugging
end

function fly.calculateMotors( mode, controls, dt )
	if mode == 0 then
		fly.translateControls(controls)
	elseif mode == 1 then
		-- Calculate controls based off desired rotation
		fly.translateControls( autopilot.rotation( controls, attitude.orientation, dt ) )
	elseif mode == 2 then
		-- Calculate controls based off desired speed
		fly.translateControls( autopilot.speed( controls, attitude.orientation, dt ) )
	elseif mode == 3 then
		-- Calculate controls based off desired position
		fly.translateControls( autopilot.position( controls, attitude.orientation, dt ) )
	end
end

function fly.calibrateMotors() -- TODO: make calibrating function
	
end

fly.orientate = attitude.orientate





-- RETURN

return fly
