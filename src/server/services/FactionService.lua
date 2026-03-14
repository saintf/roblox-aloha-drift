-- FactionService.lua
-- Manages faction assignment, treasury (session memory only), and perk state.
-- Faction treasury is NEVER written to DataStore — session memory only.
-- Implemented in Milestone 4.
--
-- Depends on: (none)

local BaseService     = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local FactionService  = BaseService.new("FactionService")

function FactionService:init()
end

function FactionService:start()
end

return FactionService
