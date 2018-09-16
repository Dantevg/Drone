local module = {}

local ip = "192.168.1.103"
local port = "5000"

function module.start()
	udp = socket.udp()
	udp:settimeout(0)
	udp:setsockname("*", 5000)
	udp:setpeername(ip, port)
	udpConnected = true
end

function module.send(data)
	if not udpConnected then
		log("Not connected over UDP")
		return
	end
	
	udp:send(data)
end

function module.receive(callback)
	if not udpConnected then
		log("Not connected over UDP")
		return
	end
	
	repeat
		local data, msg = udp:receive()
		if data then
			callback(data)
		elseif msg ~= "timeout" then
			log("Error: "..msg)
		end
	until not data
end

return module
