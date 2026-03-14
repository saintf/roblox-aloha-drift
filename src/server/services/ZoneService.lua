-- ZoneService.lua
-- Tracks which zone each player is in and exposes zone queries to other services.
-- Reads ZoneType and ZoneOwner attributes from island Model instances in Workspace.
-- Implemented in Milestone 1.
--
-- Depends on: (none)

local BaseService = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local ZoneService = BaseService.new("ZoneService")

function ZoneService:init()
end

function ZoneService:start()
end

return ZoneService
