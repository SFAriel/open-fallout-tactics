local ffi = require("ffi")
local Registry = ffi.abi("win") and require("ffi.win.reg") or require("ffi.posix.reg")

local FOT_REGISTRY_KEYS = {
  {
    path = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Steam App 38420",
    key = "InstallLocation"
  }
}

local GameLocator = {}

function GameLocator.getAbsolutePath()
  for _, registry in pairs(FOT_REGISTRY_KEYS) do
    local location, err = Registry.queryKey(registry.path, registry.key)

    if location then
      return location
    end
  end
end

return GameLocator
