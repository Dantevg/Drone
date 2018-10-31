--[[
	
	AUTOPILOT MODULE
	by RedPolygon
	
	This file contains all functions for automatic controls
	3 Main PID-controller functions for the 3 modes
	
--]]

-- CONSTANTS

local autopilot = {}

local pid = {
	{ -- X
		P = 0,
		pGain = 1,
		I = 0,
		iGain = 1,
		D = 0,
		dGain = 1,
		lastError = 0,
	},
	{ -- Y
		P = 0,
		pGain = 1,
		I = 0,
		iGain = 1,
		D = 0,
		dGain = 1,
		lastError = 0,
	},
	{ -- Z
		P = 0,
		pGain = 1,
		I = 0,
		iGain = 1,
		D = 0,
		dGain = 1,
		lastError = 0,
	},
	{ -- yaw
		P = 0,
		pGain = 1,
		I = 0,
		iGain = 1,
		D = 0,
		dGain = 1,
		lastError = 0,
	},
}





-- FUNCTIONS

function PID( current, desired, dt )
	local err = desired - current
	
	-- PID control, for 1,2,3,4:x,y,z,yaw
	for i = 1, 4 do
		pid[i].P = err[i][1]
		pid[i].I = pid[i].I + err[i][1] * dt
		pid[i].D = (err[i][1] - pid[i].lastError) / dt
		
		pid[i].lastError = err[i][1]
		pid[i].value = pid[i].P * pid[i].pGain + pid[i].I * pid[i].iGain + pid[i].D * pid[i].dGain
	end
	
	-- Return new controls
	return matrix{ {pid[1].value}, {pid[2].value}, {pid[3].value}, {pid[4].value} }
end

function autopilot.rotation( controls, orientation, dt )
	-- Copy orientation to new names,
	-- Put x,y,z (rotation) together with z (position)
	local pos = orientation.position.pos
	local rot = orientation.rotation.rot
	local current = matrix{
		{rot[1][1]}, {rot[2][1]}, {pos[3][1]}, {rot[3][1]}
	}
	local desired = matrix{
		{controls[1][1]}, {controls[2][1]}, {controls[3][1]}, {controls[4][1]}
	}
	
	return PID( current, desired, dt )
end

function autopilot.speed( controls, orientation, dt )
	-- Copy orientation to new names,
	-- Put x,y,z (position) together with z/yaw (rotation)
	local pos = orientation.position.spd
	local rot = orientation.rotation.spd
	local current = matrix{
		{pos[1][1]}, {pos[2][1]}, {pos[3][1]}, {rot[3][1]}
	}
	local desired = matrix{
		{controls[1][1]}, {controls[2][1]}, {controls[3][1]}, {controls[4][1]}
	}
	
	return PID( current, desired, dt )
end

function autopilot.position( controls, orientation, dt )
	-- Copy orientation to new names,
	-- Put x,y,z (position) together with z/yaw (rotation)
	local pos = orientation.position.pos
	local rot = orientation.rotation.rot
	local current = matrix{
		{pos[1][1]}, {pos[2][1]}, {pos[3][1]}, {rot[3][1]}
	}
	local desired = matrix{
		{controls[1][1]}, {controls[2][1]}, {controls[3][1]}, {controls[4][1]}
	}
	
	return PID( current, desired, dt )
end

--[[ function autopilot.old( controls, orientation )
	local current = orientation.position.pos
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
end ]]





-- RETURN

return autopilot