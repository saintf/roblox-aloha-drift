-- EventScheduler.lua
-- Schedules and manages rotating world events (Lumicite Surge, Faction Blitz, etc.).
-- Implemented in Milestone 7.
--
-- Depends on: EconomyService, FactionService

local BaseService      = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local EventScheduler   = BaseService.new("EventScheduler")

function EventScheduler:init()
end

function EventScheduler:start()
end

return EventScheduler
