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

local services = {
  require(script.services.ZoneService),
  require(script.services.FactionService),
  require(script.services.EconomyService),
  require(script.services.DisplacementService),
  require(script.services.GadgetService),
  require(script.services.VehicleService),
  require(script.services.BountyService),
  require(script.services.EventScheduler),
}

for _, service in ipairs(services) do
  service:init()
end

for _, service in ipairs(services) do
  service:_start()
end
