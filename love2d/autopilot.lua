-- CONSTANTS

local autopilot = {}





-- FUNCTIONS

function calculateAngleControls(controls)
	local current = attitude.orientation.rotation.pos
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
	local current = attitude.orientation.position.spd
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
	local current = attitude.orientation.position.pos
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





-- RETURN

return autopilot