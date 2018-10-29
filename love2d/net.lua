--[[
	
	NET MODULE
	by RedPolygon
	
	Provides UDP communication
	
--]]

local module = {}

local ip = "192.168.1.103"
local port = "5000"

module.udp = false

function module.start()
	module.udp = socket.udp()
	module.udp:settimeout(0)
	module.udp:setsockname("*", 5000)
	module.udp:setpeername(ip, port)
	
	module.send{
		fn = "start"
	}
end

function module.send(data)
	if not module.udp then
		log("Not connected over UDP")
		return
	end
	
	-- Add ip and port to return to
	data.ip, data.port = module.udp:getsockname()
	
	module.udp:send( stringify(data) )
end

function module.receive(callback)
	if not module.udp then return end
	
	repeat
		local data, msg = module.udp:receive()
		if data then
			callback(data)
		elseif msg ~= "timeout" then
			log("Error: "..msg)
		end
	until not data
end

return module
