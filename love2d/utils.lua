--[[
	
	UTILS v1.0
	by RedPolygon
	
	Just some little functions that should be in standard Lua imo
	
--]]

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

-- This is just a quick small implementation,
-- for really simple purposes
-- Don't use for anything serious
function stringify(t)
	local s = "{"
	for k, v in pairs(t) do
		local key = (type(k) == "number" and "["..k.."]" or k)
		if type(v) == "table" then
			s = s .. key..'='..stringify(v)..', '
		else
			s = s .. key..'="'..tostring(v)..'", '
		end
	end
	return s .. "}"
end

function unserialize(data)
	local fn = loadstring("return " .. data)
	if fn then
		return fn()
	end
end