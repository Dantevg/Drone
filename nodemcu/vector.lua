-- Vector module
local module = {}

function module.add(v1, v2)
	v1 = v1 or {x=0,y=0,z=0}
	v2 = v2 or {x=0,y=0,z=0}
	return {
		x = v1.x + v2.x,
		y = v1.y + v2.y,
		z = v1.z + v2.z,
	}
end

function module.sub(v1, v2)
	v1 = v1 or {x=0,y=0,z=0}
	v2 = v2 or {x=0,y=0,z=0}
	return {
		x = v1.x - v2.x,
		y = v1.y - v2.y,
		z = v1.z - v2.z,
	}
end

function module.mult(v1, v2)
	v1 = v1 or {x=1,y=1,z=1}
	v2 = v2 or {x=1,y=1,z=1}
	return {
		x = v1.x * v2.x,
		y = v1.y * v2.y,
		z = v1.z * v2.z,
	}
end

function module.scale(v1, amount)
	v1 = v1 or {x=0,y=0,z=0}
	amount = amount or 1
	return {
		x = v1.x * amount,
		y = v1.y * amount,
		z = v1.z * amount,
	}
end

return module