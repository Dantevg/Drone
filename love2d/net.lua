--[[
	
	NET MODULE
	by RedPolygon
	
	Provides UDP communication
	
--]]

local module = {}

local ip = "192.168.4.1"
local port = 5000

module.udp = false

function module.start()
	module.udp = socket.udp()
	module.udp:settimeout(0)
	module.udp:setsockname( "*", 5001 )
	
	module.udp:sendto( stringify{fn="start"}, ip, port )
end

function module.send(data)
	if not module.udp then
		log("Not connected over UDP")
		return
	end
	
	module.udp:sendto( stringify(data), ip, port )
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
