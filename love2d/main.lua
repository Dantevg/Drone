--[[
	
	MAIN DRONE CONTROLLER FILE
	by RedPolygon
	
	This main file gets called by Love2d
	It loads all modules, passes all needed events to the correct recipient,
	coordinates the drawing and provides the backbone of the controller program
	
--]]

-- CONSTANTS

require "utils"
matrix = require "matrix"
socket = require "socket"
local net = require "net"
local fly = require "calc/fly"
local controller = require "ui/controller"

local sendInterval = 10
local activateMouse = true





-- HELPER FUNCTIONS

function log(msg)
	table.insert( messages, 1, {text = (msg or "nil"), time = love.timer.getTime()} )
end

function setMode(newMode)
	mode = newMode % 4 -- Set mode
	GUIs[0]:find("mode"):find("title").text = "MODE ("..mode..")" -- Set mode button title
	fly.reset()
end





-- PROGRAM FUNCTIONS

function love.load()
	love.window.setMode( 800, 450 )
	width, height = love.graphics.getWidth(), love.graphics.getHeight()
	
	-- Size 16 for desktop/laptop, size 32 for mobile (high-dpi)
	font = love.graphics.newFont( "RobotoMono-Regular.ttf", 16 )
	love.graphics.setFont(font)
	
	controls = matrix(4,1)
	
	networkControls = {}
	
	mouse = {
		x = 0,
		y = 0
	}
	
	t = 0
	
	messages = {}
	
	-- Modes: 0 (full control), 1 (rotation control), 2 (speed control), 3 (position control)
	mode = 0
	active = false
	
	require "ui/ui" -- Build the UI
	matrix.multiply = matrix.hadamard
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
			controls = controller.getFromMouse()
		end
	end
	
	-- Update motors
	fly.calculateMotors( mode, controls, dt )
	
	-- UDP Send controls to NodeMCU
	if active then
		t = t + dt
		
		if t > 1/sendInterval then
			t = t - (1/sendInterval)
			net.send( controller.serializeMotors(fly.motors) )
		end
	end
	
	-- UDP Receive values from NodeMCU
	net.receive(function(response)
		log(response)
		response = unserialize(response)
		if response.type == "start" and response.data == "true" then
			active = true
		elseif response.type == "sensors" then
			-- fly.orientate(response)
		end
	end)
end

function love.draw()
	GUIs[mode]:draw()
	
	love.graphics.setColor( 255, 255, 255, 255 )
	
	-- Middle line
	love.graphics.line( width/2, 0, width/2, height*0.8 )

	-- Bottom line
	love.graphics.line( 0, height*0.8, width, height*0.8 )

	-- Position dots
	local power	= map( controls[3][1], 1, -1, 0,height*0.8 )
	local yaw		= map( controls[4][1], -1,1, 0,width/2 )
	local pitch	= map( controls[1][1], 1,-1, 0,height*0.8 )
	local roll	= map( controls[2][1], -1,1, width/2,width )
	
	love.graphics.circle( "fill", yaw, power, 10 )
	love.graphics.circle( "fill", roll, pitch, 10 )

	-- Position text
	love.graphics.print( tostring(controls), 20 + width/2, 20 )
	love.graphics.print( tostring(networkControls), 20, 20 )

	-- Messages
	for i = 1, #messages do
		love.graphics.setColor( 255,255,255, map( love.timer.getTime()-messages[i].time, 8, 4, 0, 255 ) )
		love.graphics.printf( tostring(messages[i].text), 20, 20 + (i+2)*font:getHeight(), width-40 )
	end
	love.graphics.setColor( 255, 255, 255, 255 )
end





-- CALLBACK FUNCTIONS

function love.resize(w, h)
	width, height = w, h
end

function love.touchpressed()
	controls = controller.getFromTouch( love.touch.getTouches() )
end
function love.touchmoved()
	controls = controller.getFromTouch( love.touch.getTouches() )
end
function love.touchreleased()
	controls = controller.getFromTouch( love.touch.getTouches() )
end

function love.mousepressed( x, y, button )
	GUIs[mode]:event( "click", x, y, button )
end