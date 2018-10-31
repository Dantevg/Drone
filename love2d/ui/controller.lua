--[[
	
	COMTROLLER MODULE
	by RedPolygon
	
	These functions calculate the controller values out of touch/mouse positions
	
	Controller values (position/rotation) (4x1 matrix): (-1 to 1)
		x (forward/pitch)
		y (right/roll)
		z (up)
		z (yaw)
	
--]]

-- VARIABLES

local controller = {}





-- FUNCTIONS

function controller.round(values)
	return values:loop(function(v)
		return constrain( round(v, 2), -1, 1 )
	end)
end

function controller.getFromTouch(touches)
	local controls = matrix(4,1)

	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		if x < width/2 then -- Left pad
			controls[3][1] = map( y, 0, height*0.8, 1, -1 ) -- z/up
			controls[4][1] = map( x, 0, width/2, -1, 1 ) -- z/yaw
		else -- Right pad
			controls[1][1] = map( y, 0, height*0.8, 1, -1 ) -- x/roll/forward
			controls[2][1] = map( x, width/2, width, -1, 1 ) -- y/pitch/right
		end
	end

	return controller.round(controls)
end

function controller.getFromMouse()
	local controls = matrix(4,1)
	
	-- Calculate controls
	if mouse.y > height*0.8 then -- Outside controller area
		return controls -- Leave the matrix empty
	end
	if mouse.x < width/2 then -- Left pad
		controls[3][1] = map( mouse.y, 0, height*0.8, 1, -1 ) -- z/up
		controls[4][1] = map( mouse.x, 0, width/2, -1, 1 ) -- z/yaw
	else -- Right pad
		controls[1][1] = map( mouse.y, 0, height*0.8, 1, -1 ) -- x/roll/forward
		controls[2][1] = map( mouse.x, width/2, width, -1, 1 ) -- y/pitch/right
	end
	
	return controller.round(controls)
end

function controller.serializeMotors(values)
	if not values then return "nil" end
	
	return {
		option = "fly",
		motors = {
			constrain( round(values[1][1], 2), 0, 1 ),
			constrain( round(values[1][2], 2), 0, 1 ),
			constrain( round(values[2][1], 2), 0, 1 ),
			constrain( round(values[2][2], 2), 0, 1 ),
		}
	}
end





-- RETURN

return controller