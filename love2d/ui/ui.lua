--[[
	
	UI
	by RedPolygon
	
	This file adds the needed elements and their behaviors to the UI
	
--]]

local net = require "net"
GUI = require "ui/gui"

GUIs = {}

local buttonY = love.graphics.getHeight() * 0.8
local buttonWidth = love.graphics.getWidth() / 5
local buttonHeight = love.graphics.getHeight() * 0.2

-- Initialize GUI
for i = 0, 3 do
	GUIs[i] = GUI()
end

-- UI Elements
local buttons = {}

buttons.start = GUIs[0]:addChild("button", {
	id = "start",
	x = buttonWidth * 0,
	y = buttonY,
	w = buttonWidth,
	h = buttonHeight,
	border = {255,255,255},
	objects = {
		{"text", {
			text = "START",
		}}
	},
	on = {
		click = function()
			net.start()
		end
	}
})

buttons.calibrateSensors = GUIs[0]:addChild("button", {
	id = "calibrateSensors",
	x = buttonWidth * 1,
	y = buttonY,
	w = buttonWidth,
	h = buttonHeight,
	border = {255,255,255},
	objects = {
		{"text",{
			text = "CALIBRATE SENSORS",
		}}
	},
	on = {
		click = function()
			log("calibrate sensors")
		end
	}
})

buttons.mode = GUIs[0]:addChild("button", {
	id = "mode",
	x = buttonWidth * 2,
	y = buttonY,
	w = buttonWidth * 0.75,
	h = buttonHeight,
	border = {255,255,255},
	objects = {
		{"text",{
			id = "title",
			text = "MODE (0)",
		}},
	},
	on = {
		click = function()
			log("mode")
		end
	}
})

buttons.modeUp = buttons.mode:addChild("button", {
	id = "modeUp",
	x = buttonWidth * 0.75,
	y = 0,
	w = buttonWidth * 0.25,
	h = buttonHeight * 0.5,
	border = {255,255,255},
	objects = {
		{"text",{
			text = "+",
		}}
	},
	on = {
		click = function()
			setMode( mode+1 )
		end
	}
})

buttons.modeDown = buttons.mode:addChild("button", {
	id = "modeDown",
	x = buttonWidth * 0.75,
	y = buttonHeight * 0.5,
	w = buttonWidth * 0.25,
	h = buttonHeight * 0.5,
	border = {255,255,255},
	objects = {
		{"text",{
			text = "-",
		}}
	},
	on = {
		click = function()
			setMode( mode-1 )
		end
	}
})

buttons.takeOff = GUIs[1]:addChild("button", {
	id = "takeOff",
	x = buttonWidth * 3,
	y = buttonY,
	w = buttonWidth,
	h = buttonHeight,
	border = {255,255,255},
	objects = {
		{"text",{
			text = "TAKE OFF",
		}}
	},
	on = {
		click = function()
			log("Take off")
		end
	}
})

buttons.land = GUIs[1]:addChild("button", {
	id = "land",
	x = buttonWidth * 4,
	y = buttonY,
	w = buttonWidth,
	h = buttonHeight,
	border = {255,255,255},
	objects = {
		{"text",{
			text = "LAND",
		}}
	},
	on = {
		click = function()
			log("land")
		end
	}
})

GUIs[1]:addChild(buttons.start)
GUIs[1]:addChild(buttons.calibrateSensors)
GUIs[1]:addChild(buttons.mode)

GUIs[2]:addChild(buttons.start)
GUIs[2]:addChild(buttons.calibrateSensors)
GUIs[2]:addChild(buttons.mode)
GUIs[2]:addChild(buttons.takeOff)
GUIs[2]:addChild(buttons.land)