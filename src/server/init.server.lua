-- init.server.lua
-- Server entry point. Requires and starts all services in dependency order.
--
-- Rule: init() ALL services first, then start() ALL services.
-- This guarantees that when start() runs, every service is already initialised,
-- so cross-service calls inside start() are safe.
--
-- Dependency order (no service should be listed before its dependencies):
--   1. ZoneService      — no dependencies
--   2. FactionService   — no dependencies
--   3. EconomyService   — depends on FactionService
--   4. DisplacementService — depends on ZoneService, EconomyService
--   5. GadgetService    — depends on DisplacementService, ZoneService
--   6. VehicleService   — depends on EconomyService
--   7. BountyService    — depends on EconomyService
--   8. EventScheduler   — depends on EconomyService, FactionService

local servicePaths = {
  script.services.ZoneService,
  script.services.FactionService,
  script.services.EconomyService,
  script.services.DisplacementService,
  script.services.GadgetService,
  script.services.VehicleService,
  script.services.BountyService,
  script.services.EventScheduler,
}

-- Require each service individually so one failure doesn't abort the rest
local services = {}
for _, path in ipairs(servicePaths) do
  local ok, result = pcall(require, path)
  if ok then
    table.insert(services, result)
  else
    warn("[init.server] Failed to require service '" .. tostring(path) .. "': " .. tostring(result))
  end
end

for _, service in ipairs(services) do
  local ok, err = pcall(function() service:init() end)
  if not ok then
    warn("[init.server] Error in " .. tostring(service.name) .. ":init() — " .. tostring(err))
  end
end

for _, service in ipairs(services) do
  local ok, err = pcall(function() service:_start() end)
  if not ok then
    warn("[init.server] Error in " .. tostring(service.name) .. ":_start() — " .. tostring(err))
  end
end
