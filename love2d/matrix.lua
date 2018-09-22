-- Matrix module
-- by RedPolygon

-- INITIALIZE

local matrix = {}
local mt = {}





-- FUNCTIONS

function matrix.new( rows, cols )
	local m = {}
	
	if type(rows) == "table" then -- Filled matrix
		m = rows
	else -- Empty matrix
		for row = 1, rows do
			m[row] = {}
			for col = 1, cols do
				m[row][col] = 0
			end
		end
	end
	
	return setmetatable( m, mt )
end

-- Create a new matrix out of 2 matrices
function matrix.loop( m1, m2, fn )
	if not fn then
		fn = m2
		m2 = nil
	end
	
	local m = {}
	
	for row = 1, #m1 do
		m[row] = {}
		for col = 1, #m1[row] do
			m[row][col] = fn( m1[row][col], (m2 and m2[row][col]) )
		end
	end
	
	return setmetatable( m, mt )
end

-- Fill the given matrix with n or using a function(row,col)
-- This function modifies the matrix, instead of returning a new one
function matrix.fill( m, n )
	for row = 1, #m do
		for col = 1, #m[row] do
			m[row][col] = (type(n) == "function" and n(row,col) or n)
		end
	end
end

function matrix.add( m1, m2 )
	if type(m2) == "number" then
		return matrix.loop( m1, function(a)
			return a + m2
		end)
	else
		return matrix.loop( m1, m2, function(a,b)
			return a + b
		end)
	end
end

function matrix.sub( m1, m2 )
	if type(m2) == "number" then
		return matrix.loop( m1, function(a)
			return a - m2
		end)
	else
		return matrix.loop( m1, m2, function(a,b)
			return a - b
		end)
	end
end

function matrix.mul( m1, m2 )
	if type(m2) == "number" then
		return matrix.scale( m1, m2 )
	else
		return matrix.loop( m1, m2, function(a,b)
			return a * b
		end)
	end
end

function matrix.div( m1, m2 )
	if type(m2) == "number" then
		return matrix.scale( m1, 1/m2 )
	else
		return matrix.loop( m1, m2, function(a,b)
			return a / b
		end)
	end
end

function matrix.scale( m1, amount )
	return matrix.loop( m1, function(a)
		return a * amount
	end)
end

-- Matrix product
function matrix.product( m1, m2 )
	if #m1 ~= #m2[1] then
		error("Width of a not equal to height of b")
	end
	
	local m = {}
	
	if #m1 > #m2 then
		m1, m2 = m2, m1 -- Swap values
	end
	
	for row = 1, #m1 do
		m[row] = {}
		for col = 1, #m2[row] do
			local sum = 0
			for i = 1, #m2 do
				sum = sum + m1[row][i] * m2[i][col]
			end
			m[row][col] = sum
		end
	end
	
	return setmetatable( m, mt )
end

function matrix.transpose(m)
	local new = {}
	
	for row = 1, #m[1] do
		new[row] = {}
		for col = 1, #m do
			new[row][col] = m[col][row]
		end
	end
	
	return setmetatable( new, mt )
end

function matrix.equals( m1, m2 )
	-- Check type and length
	if type(m1) ~= "table" or type(m2) ~= "table" or #m1 ~= #m2 or #m1[1] ~= #m2[1] then
		return false
	end
	
	-- Check each cell
	for row = 1, #m1 do
		for col = 1, #m1[row] do
			if m1[row][col] ~= m2[row][col] then return false end
		end
	end
	
	return true
end

function matrix.tostring(m)
	local str = "Matrix ("..#m.." x "..#m[1]..")\n"
	
	for row = 1, #m do
		for col = 1, #m[row] do
			str = str .. m[row][col] .. "  "
		end
		str = str .. "\n"
	end
	
	return str
end





-- METAMETHODS

mt.__index = matrix

mt.__add = matrix.add
mt.__sub = matrix.sub

mt.__mul = matrix.mul
mt.__div = matrix.div

mt.__unm = function( m )
	return matrix.scale( m, -1 )
end

mt.__eq = matrix.equals

mt.__tostring = matrix.tostring





-- RETURN

return setmetatable( matrix, {__call = function(_,...) return matrix.new(...) end} )