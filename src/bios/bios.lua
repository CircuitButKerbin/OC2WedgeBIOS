---@diagnostic disable: lowercase-global
-- Here will be the un-minified code for the BIOS for OpenComputers
--NULL Component Address Pointer (uint128), 16 bytes
NULLPTR = "00000000-0000-0000-0000-000000000000"
constants = {
	version = "1.0.0", --BIOS version (semver)
	debugmode = true, --Enable Debugging Stuff
}
---TODO: component wrapper possibily?
-- component = {}
--Misc binary utilitys
binutils = {
	---@return table<integer> (table # = 64, integers are bits, lowest index = lsb)
	bytetobitarray = function(byte)
		local temp = {}
		for i = 0, 63 do
			temp[i + 1] = ((byte & (1 << i)) >> i)
		end
		return temp
	end,
	inttobool = function(int)
		if int == 0 then
			return false
		else
			return true
		end
	end
}
---Protected-Call wrapper
---@return any|table<any>
---@param tryMethod function
---@param failMethod function
---@param outputIsMuliple boolean
---failMethod
--Failmethod recieves (error, ...)
--... is the args passed to tryMethod
function try(tryMethod, failMethod, outputIsMuliple, ...)
	--sanity checks
	if type(tryMethod) ~= "function" then
		error("try: invalid type for tryMethod: " .. type(tryMethod) .. "Trace: " .. debug.traceback())
	end
	if type(failMethod) ~= "function" then
		error("try: invalid type for failMethod: " .. type(failMethod) .. "Trace: " .. debug.traceback())
	end

	local attempt = table.pack(pcall(tryMethod, ...))
	if attempt[1] then
		if outputIsMuliple then
			return table.remove(attempt, 1)
		else
			return attempt[2]
		end
	else
		attempt2 = table.pack(pcall(failMethod, attempt[2], ...))
		if attempt2[1] then
			if outputIsMuliple then
				return table.remove(attempt, 1)
			else
				return attempt2
			end
		else
			error("try: failMethod errored: " .. attempt2[2] .. debug.traceback())
		end
	end
end

--Wrapper for EEPROMS for better reading / writing
eepromutils = {
	_eepromaddress = "",
	---@type integer
	_eepromdatasize = 256, -- default size
	data = {
		---@type string
		_codechksm = "",
		---@type boolean
		_initalized = false,
		---@type string
		_rawdata = "",
		---@type table<integer>
		_rawbytes = {}
	},
	---@discription load's the eeproms byte array (call only once with eepromutils:load()! )
	load = function(self)
		if self.data._initalized then
			error("eeprom load() called twice Trace: " .. debug.traceback())
		end
		if self._eepromaddress == "" or self._eepromaddress == nil then
			error("eeprom load() called before EEPROM init! Trace: " .. debug.traceback())
		else
			if (self._eepromaddress == nil) or (self._eepromaddress == NULLPTR) or (self._eepromaddress == "") then
				error("eeprom:load() - Uninitalized Address! Trace: " .. debug.traceback())
			end
			local eepromcmp = component.proxy(self._eepromaddress)
			self._eepromdatasize = eepromcmp.getDataSize()
			self.data._rawdata = eepromcmp.getData()
			self.data._codechksm = eepromcmp.getChecksum()
			temp = {}
			for i = 1, self._eepromdatasize do
				if self.data._rawdata:byte(i) == nil then
					temp[i] = 0
				else
					temp[i] = self.data._rawdata:byte(i)
				end
			end

		end
		self.data._rawbytes = temp
		self.data._initalized = true
	end,
	--read a byte at the specified address
	---@param address integer (0x00 to eeprom size) location to read
	readbyte = function(self, address)
		if not self.data_initalized then
			error("readbyte() called without EEPROM init! Trace: " .. debug.traceback())
		else
			if (address) > self._eepromdatasize or (address < 0) then
				error(string.format("readbyte(): Access Violation: 0x%x - Stack: ", address) .. debug.traceback())
			else
				return self.data._rawbytes[address - 1]
			end
		end
	end,
	--write a byte to specified address
	---@param address integer (0x00 to eeprom size) location to write
	---@param byte integer (0x00 to 0xFF) byte to write
	writebyte = function(self, byte, address)
		if not self.data_initalized then
			error("writebyte() called without EEPROM init! Trace: " .. debug.traceback())
		else
			if (address) > self._eepromdatasize or (address < 0) then
				error(string.format("writebyte(): Access Violation: 0x%x - Trace: ", address) .. debug.traceback())
			else
				if (byte < 0) or (byte > 0xFF) then
					error(string.format("writebyte(): Write attempt with value larger than uint8: %d - Trace: ", byte) ..
						debug.traceback())
				end
				self.data._rawbytes[address - 1] = byte
			end
		end
	end,
	--note, all reads & writes are in litte-endian (lowest address = lowest value)
	readuint16 = function(self, address)
		local lsb = self:readbyte(address)
		local msb = self:readbyte(address + 1)
		return lsb + (msb << 8)
	end,
	readuint32 = function(self, address)
		local temp = 0
		for i = 0, 3 do
			temp = temp + (self:readbytes(address + i) << i * 8)
		end
		return temp
	end,
	readuint64 = function(self, address)
		local temp = 0
		for i = 0, 7 do
			temp = temp + (self:readbytes(address + i) << i * 8)
		end
		return temp
	end,
	writeuint16 = function(self, uint16, address)
		local lsb = uint16 & 0xFF
		local msb = ((uint16 & 0xFF00) >> 8)
		self:writebyte(lsb, address)
		self:writebyte(msb, address + 1)
	end,
	writeuint32 = function(self, uint32, address)
		for i = 0, 3 do
			self:writebyte((uint32 & (0xFF << 8 * i) >> 8 * i), address + i)
		end
	end,
	writeuint64 = function(self, uint64, address)
		for i = 0, 7 do
			self:writebyte((uint64 & (0xFF << 8 * i) >> 8 * i), address + i)
		end
	end
}
config = {
	---@type table<string>
	bootDevices = {
		NULLPTR,
		NULLPTR,
		NULLPTR,
		NULLPTR,
		NULLPTR,
		NULLPTR
	},
	booleanVars = {
		uefiBootEnabled = false,
		unmanagedUefi = false,
		legacyBootEnabled = false,
		secureBootEnabled = false,
		networkBootEnable = false
	},
	integerVars = {
		lastBootTime = 0,
		confighash = 0
	}
}
--Invoke a component with the specified method
function Boot_Invoke(address, method, ...)
	result = table.pack(pcall(component.invoke, address, method, ...))
	if result[1] then
		if #table.remove(result, 1) ~= 1 then
			return result, nil
		else
			return result[2], nil
		end
	else
		return nil, result[2]
	end
end

---@START@---
eepromutils._eepromaddress = table.pack(component.list("eeprom")())[1]
eepromutils:load()
---@CONFIG LOAD@---
for i = 0, 5 do
	local tmp = ""
	for j = 1, 16 do
		local byte = eepromutils:readbyte(j + i * 16)
		if j == 4 or j == 6 or j == 8 or j == 10 then
			tmp = tmp .. string.format("%x", byte) .. "-"
		else
			tmp = tmp .. string.format("%x", byte)
		end
		config.bootDevices[i + 1] = tmp
	end
end
config.lastBootTime       = eepromutils:readuint32(0x60)
config.confighash         = eepromutils:readuint32(0x64)
local tmp                 = {}
tmp                       = binutils.bytetobitarray(eepromutils:readbyte(0x68))
config.uefiBootEnabled        = binutils.inttobool(tmp[1])
config.legacyBootEnabled  = binutils.inttobool(tmp[2])
config.secureBootEnabled  = binutils.inttobool(tmp[3])
config.networkBootEnabled = binutils.inttobool(tmp[4])
Headless                  = true

if (component.list("gpu")() ~= nil) and (component.list("screen") ~= nil) then
	local GPUDevice = {
		---@constructor
		new = function(self, GPUAddress)
			self.colorDepth = Boot_Invoke(GPUAddress, "maxDepth")
			self.DeviceAddress = GPUAddress
			self.GraphicsCalls.DeviceAddress = GPUAddress
			return self
		end,
		colorDepth = 0,
		DeviceAddress = NULLPTR,
		GraphicsCalls = {
			DeviceAddress = NULLPTR,
			drawText = function(self, x, y, text)
				Boot_Invoke(self.DeviceAddress, "set", x, y, text)
			end,
			fillScreen = function(self, x1, y1, x2, y2, character)
				Boot_Invoke(self.DeviceAddress, "fill", x1, y1, x2, y2, character)
			end,
			setForegroundColor = function(self, color, isPallet)
				Boot_Invoke(self.DeviceAddress, "setForeground", color, isPallet)
			end,
			setBackgroundColor = function(self, color, isPallet)
				Boot_Invoke(self.DeviceAddress, "setBackground", color, isPallet)
			end,
			clearScreen = function(self)
				self:fillScreen(0, 0, 50, 16, " ")
			end,
			getMaxResolution = function(self)
				xy = Boot_Invoke(self.DeviceAddress, "maxResolution")
				return xy[1], xy[2]
			end,
			setResolution = function(self, x, y)
				xMax, yMax = self:getMaxResolution()
				if (x > xMax) or (y > yMax) then
					error("GPUDevice: setResolution exceeds maxResolution: " ..
						tostring(x) ..
						tostring(y) .. "when max is: " .. tostring(xMax) .. tostring(yMax) .. " Trace: " .. debug.traceback())
				else
					Boot_Invoke(self.DeviceAddress, "setResolution", x, y)
				end
			end
		}
	}
	local GPUAddress = component.proxy(component.list("gpu")()).address
	local ScreenAddress = component.proxy(component.list("screen")()).address
	Boot_Invoke(GPUAddress, "bind", ScreenAddress)
	mainGPUDevice = GPUDevice:new(GPUAddress)
	mainGPUDevice.GraphicsCalls:clearScreen()
	Headless = false
end

if Headless then
	goto bootStart
else
	local lowColorMode = true
	mainGPUDevice.GraphicsCalls:setResolution(50, 16)
	mainGPUDevice.GraphicsCalls:set(1, 1, "[Text mode init]")
	if mainGPUDevice.colorDepth == 1 then
		lowColorMode = true
	else
		if mainGPUDevice.colorDepth == 4 then
			local startX = 34
			local startY = 15
			for j = 0, 1 do
				for i = 0, 7 do
					local drawX = startX + (i * 2)
					local drawY = startY + j
					mainGPUDevice.GraphicsCalls:setBackgroundColor((i + 1) + (j * 8), true)
					mainGPUDevice.GraphicsCalls:setForegroundColor((i + 1) + (j * 8), true)
					mainGPUDevice.GraphicsCalls:set(drawX, drawY, "##")
				end
			end
			mainGPUDevice.GraphicsCalls:setBackgroundColor(0)
			mainGPUDevice.GraphicsCalls:setForegroundColor(0xffffff)
		else
			if mainGPUDevice.colorDepth == 8 then
				lowColorMode = false
			end
		end
	end
end

::bootStart::
local bootMode = "legacy"
if config.uefiBootEnabled and not config.legacyBootEnabled then
	bootMode = "uefi"
	if config.unmanagedUefi then
		bootMode = "uefi_unmanaged"
	end
end

for i = 1, #config.bootDevices do
	if (config.bootDevices[i] ~= NULLPTR) and (config.bootDevices[i] ~= nil) then
		local componentType = component.list()[config.bootDevices[i]] -- This should return the component's type
		if (bootMode == "uefi") and (componentType == "filesystem") then
			local bootMedium = component.proxy(config.bootDevices[i])
			--TODO: implement this
		end
		if (bootMode == "uefi_unmanaged") and (componentType == "drive") then
			local bootMedium = component.proxy(config.bootDevices[i])
			--TODO: Proper unmanagedDrive wrapper for whatever filesystems we support
		end
		if (bootMode == "legacy") and (componentType == "filesystem") then
			local bootMedium = component.proxy(config.bootDeivces[i])
			if bootMedium.exists("/boot/init.lua") then
				init = bootMedium.open("/boot/init.lua")
			else if bootMedium.exists("/init.lua") then
				init = bootMedium.open("/init.lua")
			end
			if init ~= nil then
				bootCode = bootMedium.read(init)
			end
			end
		end
	end
end

if bootCode ~= nil then
	return bootCode()
else
	if Headless then
		error("No bootable medium found... Trace: " .. debug.traceback())
	else
		mainGPUDevice.GraphicsCalls:clearScreen()
		mainGPUDevice.GraphicsCalls:set(1,1,"No bootable medium found...")
		while true do
			--#TODO: Add proper sleep method here
			computer.pullSignal(1)
		end
	end
end
