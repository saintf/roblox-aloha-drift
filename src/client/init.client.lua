-- init.client.lua
-- Client entry point. Bootstraps all controllers in dependency order.
-- Same rule as server: init() all first, then start() all.
--
-- Controllers are the client-side equivalent of services.
-- They handle input, local VFX, and HUD updates.
-- They NEVER modify game state directly — they fire RemoteEvents to request server actions.

local controllerPaths = {
  script.controllers.HUDController,
  script.controllers.GadgetHUD,
  script.controllers.UnderwaterFX,
  script.controllers.VehicleController,
}

-- Require each controller individually so one failure doesn't abort the rest
local controllers = {}
for _, path in ipairs(controllerPaths) do
  local ok, result = pcall(require, path)
  if ok then
    table.insert(controllers, result)
  else
    warn("[init.client] Failed to require controller '" .. tostring(path) .. "': " .. tostring(result))
  end
end

for _, controller in ipairs(controllers) do
  local ok, err = pcall(function() controller:init() end)
  if not ok then
    warn("[init.client] Error in " .. tostring(controller.name) .. ":init() — " .. tostring(err))
  end
end

for _, controller in ipairs(controllers) do
  local ok, err = pcall(function() controller:_start() end)
  if not ok then
    warn("[init.client] Error in " .. tostring(controller.name) .. ":_start() — " .. tostring(err))
  end
end
