-- VehicleService.lua
-- Manages vehicle spawning, ownership, stats, and EMP state.
-- Implemented in Milestone 3.
--
-- Depends on: EconomyService

local BaseService    = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local VehicleService = BaseService.new("VehicleService")

function VehicleService:init()
end

function VehicleService:start()
end

return VehicleService
