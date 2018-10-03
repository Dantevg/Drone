-- VARIABLES

local controller = {}





-- FUNCTIONS

function controller.round(values)
	values.pos.z = values.pos.z and constrain( round(values.pos.z, 2),  0, 1 ) or 0
	values.rot.z = values.rot.z and constrain( round(values.rot.z, 2), -1, 1 ) or 0
	values.rot.y = values.rot.y and constrain( round(values.rot.y, 2), -1, 1 ) or 0
	values.rot.x = values.rot.x and constrain( round(values.rot.x, 2), -1, 1 ) or 0
	return values
end

function controller.getFromTouch(touches)
	local values = {}

	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		if x < width/2 then -- Left pad
			values.pos.z = map( y, 0, height*0.8, 1, 0 )
			values.rot.z = map( x, 0, width/2, 0, 1 )
		else -- Right pad
			values.rot.y = map( y, 0, height*0.8, 1, 0 )
			values.rot.x = map( x, width/2, width, 0, 1 )
		end
	end

	return controller.round(values)
end

function controller.getFromMouse()
	if mouse.y > height*0.8 then
		controls.pos.z = 0.5 -- Up
		controls.rot.z = 0   -- Yaw
		controls.rot.y = 0   -- Pitch
		controls.rot.x = 0   -- Roll
		return controls
	end
	if mouse.x < width/2 then -- Left pad
		controls.pos.z = map( mouse.y, 0, height*0.8, 1, 0 )
		controls.rot.z = map( mouse.x, 0, width/2, -1, 1 )
		controls.rot.y = 0
		controls.rot.x = 0
	else -- Right pad
		controls.pos.z = 0.5
		controls.rot.z = 0
		controls.rot.y = map( mouse.y, 0, height*0.8, 1, -1 )
		controls.rot.x = map( mouse.x, width/2, width, -1, 1 )
	end

	return controller.round(controls)
end

function controller.serializeMotors(values)
	if not values then return "nil" end
	
	return stringify({
		option = "fly",
		motors = {
			constrain( round(values[1][1], 2), 0, 1 ),
			constrain( round(values[1][2], 2), 0, 1 ),
			constrain( round(values[2][1], 2), 0, 1 ),
			constrain( round(values[2][2], 2), 0, 1 ),
		}
	})
end





-- RETURN

return controller