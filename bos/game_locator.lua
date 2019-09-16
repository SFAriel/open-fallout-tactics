local ffi = require("ffi")
local IS_WINDOWS = ffi.os == "Windows"
local WindowsRegistry = IS_WINDOWS and require("ffi.winreg")

local FOT_REGISTRY_KEYS = {
  {
    path = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 38420",
    key = "InstallLocation"
  }
}

local GameLocator = {}

local function locationIsValid(path)
  if not path then
    return false
  end

  return true
end

function GameLocator.getAbsolutePath()
  if not IS_WINDOWS then return end

  for _, registry in pairs(FOT_REGISTRY_KEYS) do
    local location, err = WindowsRegistry.queryKey(registry.path, registry.key)

    if locationIsValid(location) then
      return location
    end
  end
end

return GameLocator
