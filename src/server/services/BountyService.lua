-- BountyService.lua
-- Tracks active bounties on players and awards coins on bounty completion.
-- Implemented in Milestone 6.
--
-- Depends on: EconomyService

local BaseService    = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local BountyService  = BaseService.new("BountyService")

function BountyService:init()
end

function BountyService:start()
end

return BountyService
