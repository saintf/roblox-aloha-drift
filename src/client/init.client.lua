-- init.client.lua
-- Client entry point. Bootstraps all controllers in dependency order.
-- Same rule as server: init() all first, then start() all.
--
-- Controllers are the client-side equivalent of services.
-- They handle input, local VFX, and HUD updates.
-- They NEVER modify game state directly — they fire RemoteEvents to request server actions.

local controllers = {
  require(script.controllers.HUDController),
  require(script.controllers.GadgetHUD),
  require(script.controllers.UnderwaterFX),
  require(script.controllers.VehicleController),
}

for _, controller in ipairs(controllers) do
  controller:init()
end

for _, controller in ipairs(controllers) do
  controller:_start()
end
