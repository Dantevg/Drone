--[[
	
	SENSOR MODULE
	by RedPolygon
	
	Sensors:
		- acc			accelerometer
		- gyro		gyroscope
		- mag			magnetometer
	
	Sensor data format (following standard conventions)
	(position / rotation):
		- x / roll		front	/ right wing down
		- y / pitch		right	/ nose up
		- z / yaw			up		/ turn left
	
--]]

-- CONSTANTS

local module = {}

-- The numbers which the sensor data needs to be multiplied with
local sensitivities = {
	acc = {
		[2] = 0.000061,
		[4] = 0.000122,
		[8] = 0.000244,
		[16] = 0.000732
	},
	gyro = {
		[245] = 0.00875,
		[500] = 0.0175,
		[2000] = 0.07
	},
}

-- I2C addresses
local addrAccGyro = 0x6B
local addrMag = 0x1E

-- Registers (in low, high pairs)
local regAccGyro = {
	whoAmI = 0x0F,
	
	ctrl1 = 0x10, -- Gyro
	ctrl2 = 0x11, -- Gyro
	ctrl3 = 0x12, -- Gyro
	
	gyroX = {0x18, 0x19},
	gyroY = {0x1A, 0x1B},
	gyroZ = {0x1C, 0x1D},
	
	ctrl4 = 0x1E,
	ctrl5 = 0x1F, -- Acc
	ctrl6 = 0x20, -- Acc
	ctrl7 = 0x21, -- Acc
	ctrl8 = 0x22,
	ctrl9 = 0x23,
	ctrl10 = 0x24,
	
	accX = {0x28, 0x29},
	accY = {0x2A, 0x2B},
	accZ = {0x2C, 0x2D},
}

local scales = {
	acc = {
		[2] = 0,
		[4] = 2,
		[8] = 3,
		[16] = 1
	},
	gyro = {
		[245] = 0,
		[500] = 1,
		[2000] = 3
	},
}





-- VARIABLES

module.settings = {
	-- The pins used for i2c SDA and SCL
	i2cSDA = i2c.I2C0,
	
	acc = {
		scale = 4, -- 2, 4, 8, 16 g
		sampleRate = 6 -- [1-6] 10, 50, 119, 238, 476, 952 Hz
	},
	
	gyro = {
		scale = 245, -- 245, 500, 2000 deg/s
		sampleRate = 6, -- [1-6] 14.9, 59.5, 119, 238, 476, 952 Hz
		bandwidth = 0 -- 0, 1, 2, 3
	},
}





-- FUNCTIONS

function module.read(sensor)
	if sensor ~= "acc" and sensor ~= "gyro" then
		error("Invalid sensor type: " .. (sensor ~= nil and sensor or "nil"))
	end
	
	local sensorData = { x=0, y=0, z=0 }
	local rawData = {}
	
	-- Read 6 bytes from registers starting at x[1]
	-- x, y, z values, 2 bytes per value
	if sensor == "acc" then
		for i = 1, 6 do
			rawData[i] = i2cRead( addrAccGyro, regAccGyro.accX[1] + (i-1) )
			rawData[i] = string.byte( rawData[i] )
		end
	elseif sensor == "gyro" then
		for i = 1, 6 do
			rawData[i] = i2cRead( addrAccGyro, regAccGyro.gyroX[1] + (i-1) )
			rawData[i] = string.byte( rawData[i] )
		end
	end
	
	-- Combine the least and most significant bit
	sensorData.x = bit.bor( bit.lshift( rawData[1], 8 ), rawData[2] )
	sensorData.y = bit.bor( bit.lshift( rawData[3], 8 ), rawData[4] )
	sensorData.z = bit.bor( bit.lshift( rawData[5], 8 ), rawData[6] )
	
	-- Divide by 2^15-1 (32767) as the sensor stores the data mapped between
	-- the min and max values of a 16-bit signed word
	-- Then multiply by sensitivity
	local sensitivity = sensitivities[sensor][module.settings[sensor].scale]
	sensorData.x = sensorData.x / 32767 * sensitivity
	sensorData.y = sensorData.y / 32767 * sensitivity
	sensorData.z = sensorData.z / 32767 * sensitivity
	
	return sensorData
end

-- Sets the acc's control registers
function initAcc()
	local ctrl6 = 0x00
	-- [ODR 2][ODR 1][ODR 0][SCL 1][SCL 0][BWMOD][BW  1][BW  0]
	-- BWMOD: Bandwidth auto or manual
	
	ctrl6 = bit.lshift( module.settings.acc.sampleRate, 5 ) -- ODR
	ctrl6 = bit.bor( ctrl6, bit.lshift(scales.acc[module.settings.acc.scale], 3) ) -- SCL
	i2cWrite( addrAccGyro, regAccGyro.ctrl6, ctrl6 ) -- Send
end

-- Sets the gyro's control registers
function initGyro()
	local ctrl1 = 0x00
	-- [ODR 2][ODR 1][ODR 0][SCL 1][SCL 0][  0  ][BW  1][BW  0]
	-- ODR: Output data rate
	-- SCL: Scale (FS)
	-- BW: Bandwidth
	
	ctrl1 = bit.lshift( module.settings.gyro.sampleRate, 5 ) -- ODR
	ctrl1 = bit.bor( ctrl1, bit.lshift(scales.gyro[module.settings.gyro.scale], 3) ) -- SCL
	ctrl1 = bit.bor( ctrl1, module.settings.gyro.bandwidth ) -- BW
	i2cWrite( addrAccGyro, regAccGyro.ctrl1, ctrl1 ) -- Send
end

function i2cRead( address, register )
	-- Send request
	comm:start()
	comm:address( address, false )
	comm:write( 0x00, register )
	-- comm:write( bit.bor(register, (length and 0x80 or 0)) )
	
	-- Receive data
	comm:start()
	comm:address( address, true )
	local data = comm:read()
	comm:stop()
	
	return data
end

function i2cWrite( address, register, data )
	comm:start()
	comm:address( address, false )
	comm:write( 0x00, register, data )
	comm:stop()
	
	local done = false
	
	-- Poll the sensor and wait for the sensor to respond
	-- The sensor will only respond then the write has finished
	while not done do
		try(function()
			comm:start()
			comm:address( address, false )
			comm:stop()
			done = true
		end)
	end
end





-- START

local comm = i2c.attach( module.settings.i2cSDA, i2c.MASTER, 10000 ) -- Setup i2c with 10kHz

initAcc()
initGyro()

return module