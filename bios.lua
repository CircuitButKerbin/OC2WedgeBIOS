--improved bios for Opencomputers
--Built apon the Orignal OC2 Bios

local init
do
  function sleep(timeout)
    checkArg(1, timeout, "number", "nil")
    local deadline = computer.uptime() + (timeout or 0)
    repeat
      computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
  end

  local component_invoke = component.invoke
  local function _binv(address, method, ...)
    --do a protected call to the component_invoke function, and return the result
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
      return nil, result[2]
    else
      return table.unpack(result, 2, result.n)
    end
  end

    -- backwards compatibility, may remove later
    local eeprom = component.list("eeprom")()
    computer.getBootAddress = function()
      return _binv(eeprom, "getData")
    end
    computer.setBootAddress = function(address)
      return _binv(eeprom, "setData", address)
    end

  do
    local screen = component.list("screen")()
    local gpu = component.list("gpu")()
    if gpu and screen then
      _binv(gpu, "bind", screen)
      _binv(gpu, "setBackground", 0x0000ff)
      _binv(gpu, "setForeground", 0xffffff)
      --print the boot message
      _binv(gpu, "setResolution", 50, 16)
      _binv(gpu, "fill", 1, 1, 50, 16, " ")
      _binv(gpu, "set", 1, 2, "    /==/")
      _binv(gpu, "set", 1, 3 ,"   /--/|  Wedge Microsystems")
      _binv(gpu, "set", 1, 4, "  /--/ |   WGD-ADV-BIOS")
      _binv(gpu, "set", 1, 5, " /==/==|")
      _binv(gpu, "set", 1, 7, "            [#########################]")
      _binv(gpu, "set", 1, 8, "            [<RAM Capacity : 00512kB >]")
      _binv(gpu, "set", 1, 9, "            [<Processor    : Bintel6 >]")
      _binv(gpu, "set", 1, 10,"            [<Architechure : Lua 5.3 >]")
      _binv(gpu, "set", 1, 11,"            [<BIOS Version : 1.0.0   >]")
      _binv(gpu, "set", 1, 12,"            [<BIOS Config  : Legacy  >]")
      _binv(gpu, "set", 1, 13,"            [#########################]")
      _binv(gpu, "set", 1, 16," Press F2 to enter BIOS setup utiliy ... ")
      sleep(5)
    end
  end 

  --attempt to load init.lua from the boot medium
  local function tryLoadFrom(address)
    --invoke the medium, and try to open init.lua
    local handle, reason = _binv(address, "open", "/init.lua")
    if not handle then
      return nil, reason
    end
    local buffer = ""
    repeat
      local data, reason = _binv(address, "read", handle, math.huge)
      if not data and reason then
        return nil, reason
      end
      buffer = buffer .. (data or "")
    until not data
    _binv(address, "close", handle)
    return load(buffer, "=init")
  end


  local reason
  if computer.getBootAddress() then
    init, reason = tryLoadFrom(computer.getBootAddress())
  end

  -- if boot medium is not present, try to find another one
  if not init then
    computer.setBootAddress()
    --for every component that is a filesystem, try to load from it
    for address in component.list("filesystem") do
      init, reason = tryLoadFrom(address)
      if init then
        computer.setBootAddress(address)
        break
      end
    end
  end

  --boot failure:
  if not init then
    error("No bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
  end
  computer.beep(1000, 0.2)
  
end
return init()
