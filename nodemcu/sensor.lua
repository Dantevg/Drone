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

local module = {}

-- CONSTANTS

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
	mag = {
		[4] = 0.00014,
		[8] = 0.00029,
		[12] = 0.00043,
		[16] = 0.00058
	}
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
local regMag = {
	whoAmI = 0x0F,
	
	ctrl1 = 0x20,
	ctrl2 = 0x21,
	ctrl3 = 0x22,
	ctrl4 = 0x23,
	ctrl5 = 0x24,
	
	magX = {0x28,0x29},
	magY = {0x2A,0x2B},
	magZ = {0x2C,0x2D},
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
	mag = {
		[4] = 0,
		[8] = 1,
		[12] = 2,
		[16] = 3
	}
}





-- VARIABLES

module.settings = {
	calibrationReadings = 10, -- Number of sensor readings to calibrate sensors with
	calibrationInterval = 20, -- Time inbetween calibration sensor readings (in ms)
	
	-- The pins used for i2c SDA and SCL
	i2cSDA = 0,
	i2cSCL = 1,
	
	acc = {
		scale = 4, -- 2, 4, 8, 16 g
		sampleRate = 6 -- [1-6] 10, 50, 119, 238, 476, 952 Hz
	},
	
	gyro = {
		scale = 245, -- 245, 500, 2000 deg/s
		sampleRate = 6, -- [1-6] 14.9, 59.5, 119, 238, 476, 952 Hz
		bandwidth = 0 -- 0, 1, 2, 3
	},
	
	mag = {
		scale = 8, -- 4, 8, 12, 16 gauss
		sampleRate = 7, -- [0-7] 0.625, 1.25, 2.5, 5, 10, 20, 40, 80 Hz
		performanceXY = 3, -- [0-3] low power - ultra high performance
		performanceZ = 3,
		mode = 0 -- [0-2] continuous conversion, single conversion, power down
	}
}

local calibration = {
	acc = {},
	gyro = {},
	mag = {}
}

local calibrating = false





-- FUNCTIONS

-- Calibrates the sensors by taking the average noise
function module.calibrate(callback)
	calibrating = true
	local nReadings = 0
	local readings = {
		acc = {},
		gyro = {},
		mag = {}
	}
	
	-- Get n amount of readings
	local function getReading()
		nReadings = nReadings+1
		readings.acc[nReadings] = module.read("acc")
		readings.gyro[nReadings] = module.read("gyro")
		readings.mag[nReadings] = module.read("mag")
		
		if nReadings < module.settings.calibrationReadings then
			interval:start() -- Go for another round
		else
			calculateCalibrations() -- Done, continue
		end
	end
	
	local interval = tmr.create()
	interval:register( calibrationInterval, tmr.ALARM_SEMI, getReading )
	interval:start()
	
	-- Calculate average and store it
	local function calculateCalibrations()
		local totals = {}
		
		for i = 1, calibrationReadings do
			totals.acc = totals.acc + readings.acc[i]
			totals.gyro = totals.gyro + readings.gyro[i]
			totals.mag = totals.mag + readings.mag[i]
		end
		
		calibration.acc = totals.acc / calibrationReadings
		calibration.gyro = totals.gyro / calibrationReadings
		calibration.mag = totals.mag / calibrationReadings
		
		calibrating = false
		if callback then callback() end -- Done, call the callback
	end
end

-- Reads the sensor values
function module.read(sensor)
	if sensor ~= "acc" and sensor ~= "gyro" and sensor ~= "mag" then
		error("Invalid sensor type: " .. (sensor ~= nil and sensor or "nil"))
	end
	
	local sensorData = { x=0, y=0, z=0 }
	local rawData = ""
	
	-- Read 6 bytes from registers starting at x[1]
	if sensor == "acc" then
		rawData = i2cRead( addrAccGyro, regAccGyro.accX[1], 6 )
	elseif sensor == "gyro" then
		rawData = i2cRead( addrAccGyro, regAccGyro.gyroX[1], 6 )
	elseif sensor == "mag" then
		rawData = i2cRead( addrMag, regMag.magX[1], 6 )
	end
	
	-- Combine the bytes
	sensorData.x = bit.bor( bit.lshift( string.byte(rawData,1,1), 8 ), string.byte( rawData, 2, 2 ) )
	sensorData.y = bit.bor( bit.lshift( string.byte(rawData,3,3), 8 ), string.byte( rawData, 4, 4 ) )
	sensorData.z = bit.bor( bit.lshift( string.byte(rawData,5,5), 8 ), string.byte( rawData, 6, 6 ) )
	
	-- Multiply by sensitivity
	sensorData.x = sensorData.x * sensitivities[sensor][module.settings.gyro.scale]
	sensorData.y = sensorData.y * sensitivities[sensor][module.settings.gyro.scale]
	sensorData.z = sensorData.z * sensitivities[sensor][module.settings.gyro.scale]
	
	-- Subtract calibration
	sensorData.x = sensorData.x - calibration[sensor].x
	sensorData.y = sensorData.y - calibration[sensor].y
	sensorData.z = sensorData.z - calibration[sensor].z
	
	return sensor
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

-- Sets the mag's control registers
function initMag()
	local ctrl1 = 0x10 -- Default, ODR 10Hz
	-- [TCOMP][MODE1][MODE0][ODR 2][ODR 1][ODR 0][  0  ][STEST]
	-- TCOMP: Temperature compensation
	-- MODE: Power/performance mode selection
	-- STEST: Self-test
	ctrl1 = bit.bor( ctrl1, bit.lshift(module.settings.mag.performanceXY, 5) ) -- MODE
	ctrl1 = bit.bor( ctrl1, bit.lshift(module.settings.mag.sampleRate, 2) ) -- ODR
	i2cWrite( addrMag, regMag.ctrl1, ctrl1 ) -- Send
	
	local ctrl2 = 0x00
	-- [  0  ][SCL 1][SCL 0][  0  ][RBOOT][RESET][  0  ][  0  ]
	-- RBOOT: Reboot memory
	-- RESET: Reset config + user registers
	ctrl2 = bit.lshift( scales.mag[module.settings.mag.scale], 5 ) -- SCL
	i2cWrite( addrMag, regMag.ctrl2, ctrl2 ) -- Send
	
	local ctrl3 = 0x00
	-- [ I2C ][  0  ][LWPWR][  0  ][  0  ][SPIMD][MODE1][MODE0]
	-- I2C: I2C Disable
	-- LWPWR: Low power mode
	-- SPIMD: SPI mode selection
	ctrl3 = magMode -- MODE
	i2cWrite( addrMag, regMag.ctrl3, ctrl3 )
	
	local ctrl4 = 0x00
	-- [  0  ][  0  ][  0  ][  0  ][MODE1][MODE0][ BLE ][  0  ]
	-- BLE: Big/Little endian selection
	ctrl4 = bit.lshift( module.settings.mag.performanceZ, 2 ) -- MODE
	i2cWrite( addrMag, regMag.ctrl4, ctrl4 ) -- Send
end

-- Reads one byte from a register
function i2cRead(address, register, length)
	-- Send request
	i2c.start(0)
	i2c.address( 0, address, i2c.TRANSMITTER )
	i2c.write( 0, bit.bor(register, (length and 0x80 or 0)) )
	i2c.stop(0)
	
	-- Receive data
	i2c.start(0)
	i2c.address( 0, address, i2c.RECEIVER )
	local data = i2c.read(0, length or 1)
	i2c.stop(0)
	
	return data
end

-- Writes one byte to a register
function i2cWrite(address, register, data)
	i2c.start(0)
	i2c.address( 0, address, i2c.TRANSMITTER )
	i2c.write( 0, register )
	i2c.write( 0, data )
	i2c.stop(0)
end





-- START

i2c.setup( 0, module.settings.i2cSDA, module.settings.i2cSCL, i2c.SLOW ) -- Setup i2c to use the defined pins

initAcc()
initGyro()
initMag()

return module
