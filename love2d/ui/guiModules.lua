-- GUI MODULES

local modules = {}





-- TEXT MODULE

modules.text = {}

function modules.text:__newindex()
	return function( t, k, v )
		self[k] = v
		if k == "text" then
			self.textElement:setf( v, self.parent.w, "center" )
		end
	end
end

function modules.text:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	self.textElement:setf( self.text, self.parent.w, self.align )
end

function modules.text:new( parent, d )
	local textElement = love.graphics.newText( love.graphics.getFont(), d.text or "" )
	textElement:setf( d.text or "", parent.w, "center" )
	return setmetatable( {
		id = d.id,
		objects = {},
		parent = parent,
		calc = {},
		textElement = textElement,
		
		x = d.x or 0,
		y = d.y or 0,
		align = d.align or "center",
		
		color = d.color or {255,255,255,255},
		
		text = d.text or "",
		
		mt = { __newindex = function(self)
			return function( t, k, v )
				self[k] = v
				self:update()
			end
		end }
	}, {__index = self} )
end

function modules.text:draw()
	local prevColor = { love.graphics.getColor() } -- Get color for resetting
	love.graphics.setColor(self.color)
	local x = self.calc.x
	local y = self.calc.y
	
	love.graphics.draw( self.textElement, x, y + (self.parent.h - self.textElement:getHeight())/2 )
	
	self:drawObjects()
	
	love.graphics.setColor(prevColor)
end





-- BUTTON MODULE

modules.button = {}

function modules.button:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	for i = 1, #self.objects do
		self.objects[i]:update()
	end
end

function modules.button:new( parent, d )
	return setmetatable( {
		id = d.id,
		objects = {},
		parent = parent,
		calc = {},
		on = d.on or {},
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or 0,
		h = d.h or 0,
		
		bg = d.bg or {0,0,0},
		fg = d.fg or {255,255,255},
		bgActive = d.bgActive or {255,255,255},
		fgActive = fgActive or {0,0,0},
		
		border = d.border or false,
		clicked = false,
	}, {__index = self} )
end

function modules.button:draw()
	local prevColor = { love.graphics.getColor() } -- Get color for resetting
	local x = self.calc.x
	local y = self.calc.y
	
	-- Background
	if self.bgActive and self.clicked then
		love.graphics.setColor( lerpColor(self.bgActive, self.bg, map( love.timer.getTime()-self.clicked, 0, 0.5, 0, 1 )) )
		love.graphics.rectangle( "fill", x, y, self.w, self.h )
	else
		love.graphics.setColor( unpack(self.bg) )
		love.graphics.rectangle( "fill", x, y, self.w, self.h )
	end
	
	-- Border
	if self.border then
		love.graphics.setColor( unpack(self.border) )
		love.graphics.rectangle( "line", x, y, self.w, self.h )
	end
	
	love.graphics.setColor(prevColor)
	
	self:drawObjects()
end

function modules.button:click( mouseX, mouseY, button )
	local x = self.calc.x
	local y = self.calc.y
	if mouseX < x or mouseX > x + self.w or mouseY < y or mouseY > y + self.h then
		return -- Outside box
	end
	self.clicked = love.timer.getTime()
	
	if self.on and self.on.click then
		self.on.click()
	end
end





-- RETURN

return modules
