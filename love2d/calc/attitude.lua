--[[
	
	ATTUTIDE MODULE
	by RedPolygon
	
	This file contains all functions nessessary to orientate the drone
	
--]]

-- CONSTANTS

local attitude = {}





-- VARIABLES

-- The calculated and desired orientation of the drone (position and rotation)
attitude.orientation = {
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





-- FUNCTIONS

-- Return rotation matrix of given axis and angle
function attitude.rotate( axis, a )
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

-- Update the sensor data and covert it
function attitude.orientate(sensorData)
	local prevAltitude = attitude.orientation.position[3]
	
	local pos = attitude.orientation.position
	local rot = attitude.orientation.rotation
	local interval = love.timer.getTime() - (attitude.previousSensor or 0 )
	local sensors = { acc = {}, gyro = {} }
	
	attitude.previousSensor = love.timer.getTime()

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
	pos.pos = attitude.rotate( "x", rot.pos.x ) * pos.pos
	pos.pos = attitude.rotate( "y", rot.pos.y ) * pos.pos
	pos.pos = attitude.rotate( "z", rot.pos.z ) * pos.pos
	
	attitude.orientation.position = pos
	attitude.orientation.rotation = rot
	
	return attitude.orientation.position.pos[3], prevAltitude
end





-- RETURN

return attitude