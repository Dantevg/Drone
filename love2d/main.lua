-- CONSTANTS

local socket = require "socket"
local net = require "net"
local fly = require "fly"

local sendInterval = 10
local activateMouse = true





-- HELPER FUNCTIONS

function round(n, decimals)
	local mult = 10 ^ ( decimals or 0 )
	if n >= 0 then
		return math.floor(n * mult + 0.5) / mult
  else
  	return math.ceil(n * mult - 0.5) / mult
  end
end

function constrain( val, min, max )
	return math.max( min, math.min(max, val) )
end

function map( val, min1, max1, min2, max2 )
	return min2 + (max2 - min2) * (val - min1) / (max1 - min1)
end

function lerp( v1, v2, t )
	return v1 + t * (v2 - v1)
end

function lerpColor( rgb1, rgb2, t )
	return 
		lerp( rgb1[1], rgb2[1], t ),
		lerp( rgb1[2], rgb2[2], t ),
		lerp( rgb1[3], rgb2[3], t )
end

function log(msg)
	table.insert( messages, 1, {text = (msg or "nil"), time = love.timer.getTime()} )
end

function stringify(t)
	local s = "{"
	for k, v in pairs(t) do
		local key = (type(k) == "number" and "["..k.."]" or k)
		if type(v) == "table" then
			s = s .. key..' = '..stringify(v)..', '
		else
			s = s .. key..' = "'..tostring(v)..'", '
		end
	end
	return s .. "}"
end

function roundControllerValues(values)
	values.power = values.power and constrain( round(values.power, 2), 0, 1 ) or 0
	values.yaw = values.yaw and constrain( round(values.yaw, 2), -1, 1 ) or 0
	values.pitch = values.pitch and constrain( round(values.pitch, 2), -1, 1 ) or 0
	values.roll = values.roll and constrain( round(values.roll, 2), -1, 1 ) or 0
	return values
end

function getControllerValues(touches)
	local values = {}

	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		if x < width/2 then -- Left pad
			values.power = map( y, 0, height*0.8, 1, 0 )
			values.yaw = map( x, 0, width/2, 0, 1 )
		else -- Right pad
			values.pitch = map( y, 0, height*0.8, 1, 0 )
			values.roll = map( x, width/2, width, 0, 1 )
		end
	end

	return roundControllerValues(values)
end

function getMouseControllerValues()
	if mouse.y > height*0.8 then
		controls.power = 0.5
		controls.yaw = 0
		controls.pitch = 0
		controls.roll = 0
		return controls
	end
	if mouse.x < width/2 then -- Left pad
		controls.power = map( mouse.y, 0, height*0.8, 1, 0 )
		controls.yaw = map( mouse.x, 0, width/2, -1, 1 )
		controls.pitch = 0
		controls.roll = 0
	else -- Right pad
		controls.power = 0.5
		controls.yaw = 0
		controls.pitch = map( mouse.y, 0, height*0.8, 1, -1 )
		controls.roll = map( mouse.x, width/2, width, -1, 1 )
	end

	return roundControllerValues(controls)
end

function serializeControls(controls)
	if not controls then return "nil" end
	if type(controls) ~= "table" then return controls end
	return "{power="..(controls.power or "nil")..",yaw="..(controls.yaw or "nil")..",pitch="..(controls.pitch or "nil")..",roll="..(controls.roll or "nil").."}"
end

function serializeMotorValues(values)
	if not values then return "nil" end
	
	return stringify({
		option = "fly",
		motors = {
			constrain( round(values[1] * 1023), 0, 1023 ),
			constrain( round(values[2] * 1023), 0, 1023 ),
			constrain( round(values[3] * 1023), 0, 1023 ),
			constrain( round(values[4] * 1023), 0, 1023 ),
		}
	})
end

function unserialize(data)
	local fn = loadstring("return " .. data)
	if fn then
		return fn()
	end
end





-- PROGRAM FUNCTIONS

function love.load()
	love.window.setMode( 800, 450 )
	width, height = love.graphics.getWidth(), love.graphics.getHeight()
	
	font = love.graphics.newFont( "RobotoMono-regular.ttf", 16 )
	love.graphics.setFont(font)
	
	controls = {
		power = 0.5,
		yaw = 0.5,
		pitch = 0.5,
		roll = 0.5
	}
	
	networkControls = {
		power = 0,
		yaw = 0,
		pitch = 0,
		roll = 0
	}
	
	mouse = {
		x = 0,
		y = 0
	}
	
	t = 0
	
	messages = {}
	
	mode = 0
	udpConnected = false
	active = false
	
	require "ui" -- Build the UI
end

function love.update(dt)
	-- Update messages
	for i = 1, #messages do
		if messages[#messages].time + 8 < love.timer.getTime() then
			table.remove(messages, #messages)
		end
	end

	-- Update mouse position
	if activateMouse then
		mouse.x, mouse.y = love.mouse.getPosition()
		if mouse.x ~= 0 and mouse.y ~= 0 then -- Mouse is inside window
			controls = getMouseControllerValues()
		end
	end

	-- UDP Send controls to NodeMCU
	if udpConnected then
		if active then
			t = t + dt
			
			if t > 1/sendInterval then
				t = t - (1/sendInterval)
				fly.translateControls()
				net.send( serializeMotorValues(fly.motors) )
			end
		end
		
		-- UDP Receive sensor values from NodeMCU
		net.receive(function(data)
			log( data )
			data = unserialize(data)
			if data.type == "start" and data.message == "true" then
				active = true
			end
		end)
	end
end

function love.draw()
	GUIs[mode]:draw()
	
	-- Middle line
	love.graphics.line( width/2, 0, width/2, height*0.8 )

	-- Bottom line
	love.graphics.line( 0, height*0.8, width, height*0.8 )

	-- Position dots
	love.graphics.circle( "fill", map( controls.yaw, -1,1, 0,width/2 ), map( controls.power, 1,0, 0,height*0.8 ), 10 )
	love.graphics.circle( "fill", map( controls.roll, -1,1, width/2,width ), map( controls.pitch, 1,-1, 0,height*0.8 ), 10 )

	-- Position text
	love.graphics.print( serializeControls(controls), 20, 20 )
	love.graphics.print( serializeControls(networkControls), 20, 20 + font:getHeight() )

	-- Messages
	for i = 1, #messages do
		love.graphics.setColor( 255, 255, 255, map( love.timer.getTime()-messages[i].time, 8, 4, 0, 255 ) )
		love.graphics.printf( messages[i].text, 20, 20 + (i+1)*font:getHeight(), width-40 )
	end
	love.graphics.setColor( 255, 255, 255, 255 )
end





-- CALLBACK FUNCTIONS

function love.resize(w, h)
	width, height = w, h
end

function love.touchpressed()
	controls = getControllerValues( love.touch.getTouches() )
end
function love.touchmoved()
	controls = getControllerValues( love.touch.getTouches() )
end
function love.touchreleased()
	controls = getControllerValues( love.touch.getTouches() )
end

function love.mousepressed( x, y, button )
	GUIs[mode]:event( "click", x, y, button )
end