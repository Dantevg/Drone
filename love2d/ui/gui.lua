-- GUI framework
-- by RedPolygon

-- VARIABLES

local GUI = {}
GUI.modules = {}
GUI.version = "0.2"





-- FUNCTIONS

-- Create new main object
function GUI.new()
	local main = { calc = {} }
	main.objects = {}
	main.x, main.y = 0, 0
	main.w, main.h = love.graphics.getWidth(), love.graphics.getHeight()
	main.calc.x, main.calc.y = main.x, main.y
	return setmetatable( main, {__index = GUI} )
end

-- Add a child object
function GUI:addChild( module, data )
	if type(module) == "string" then -- Create new element and insert it
		if not GUI.modules[module] then
			error("No such module: "..module)
		end
		table.insert( self.objects, 1, GUI.modules[module]:new( self, data ) )
		local object = self.objects[1]
		object:update()
		
		-- Add specified child objects
		if data.objects then
			for i = 1, #data.objects do
				object:addChild( data.objects[1][1], data.objects[1][2] )
			end
		end
		
		object.mt = object.mt or {}
		object.mt.__index = object.mt.__index and object.mt.__index(object) or object
		object.mt.__newindex = object.mt.__newindex and object.mt.__newindex(object) or object
		return setmetatable( {}, object.mt )
		
	elseif type(module) == "table" then -- Clone existing element
		table.insert( self.objects, 1, module )
		return setmetatable( {}, {__index = self.objects[1], __newindex = self.objects[1]} )
	end
end

-- Draw child objects
function GUI:drawObjects()
	for i = #self.objects, 1, -1 do -- Reverse loop
		self.objects[i]:draw()
	end
end
GUI.draw = GUI.drawObjects

-- Execute event functions
function GUI:event( event, ... )
	for _, v in ipairs(self.objects) do
		if type( v[event] ) == "function" then
			v[event](v, ...)
		end
		if v.objects then
			v:event( event, ... )
		end
	end
end

-- Find elements by ID
function GUI:find(id)
	if type(id) == "number" then -- Find by index
		return setmetatable( {}, self.objects[id].mt )
	elseif type(id) == "string" then -- Find by id
		for _, v in ipairs(self.objects) do
			if v.id == id then
				return setmetatable( {}, v.mt )
			end
		end
		return {}
	end
end





-- LOAD MODULES

local modules = require "ui/guiModules"

for k, v in pairs(modules) do
	GUI.modules[k] = setmetatable( modules[k], {__index = GUI} )
end





-- RETURN

return setmetatable( GUI, {__call = GUI.new} )
