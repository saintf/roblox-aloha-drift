-- EconomyService.lua
-- Single source of truth for all coin and XP transactions.
-- No other script may modify personalCoins or roleXP directly.
-- All DataStore writes are debounced (max 1 write per 6s per player).
--
-- Depends on: FactionService

local BaseService   = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local EconomyConfig = require(game.ReplicatedStorage.AlohaShared.config.EconomyConfig)

local EconomyService = BaseService.new("EconomyService")

local CFG = {
  SAVE_DEBOUNCE   = 6,     -- minimum seconds between DataStore writes per player
  SPLIT_RATIO     = 0.50,  -- fraction of each earning that goes to personal wallet
  SNOWBALL_CAP    = 2.0,   -- faction treasury income reduced if leading by this multiple
  SNOWBALL_REDUCE = 0.20,  -- income reduction applied to the leading faction
}

-- In-memory player data (loaded from DataStore on join)
local playerData  = {}
local lastSaved   = {}  -- UserId → os.clock() of last DataStore write

function EconomyService:init()
end

function EconomyService:start()
  -- TODO: Milestone 2 — DataStore load/save, PlayerAdded/PlayerRemoving hooks
end

-- Awards coins to a player, splitting 50/50 between personal wallet and faction treasury.
-- source: string label for logging (e.g. "safe_raid", "lumicite_delivery")
-- TODO: implement in Milestone 2
function EconomyService.awardCoins(player, amount, source)
  -- stub
end

-- Awards XP to a player for a specific role. Checks for tier unlock.
-- role: "runner"|"hauler"|"drifter"|"scrapper"|"wrenchhead"
-- TODO: implement in Milestone 2
function EconomyService.awardXP(player, role, amount)
  -- stub
end

-- Adds coins directly to a faction treasury (e.g. platform drip income).
-- Does NOT split — caller is responsible for deciding the amount.
-- TODO: implement in Milestone 2
function EconomyService.transferToFaction(factionId, amount, source)
  -- stub
end

-- Returns the current personal coin balance for a player.
function EconomyService.getCoins(player)
  local data = playerData[player.UserId]
  return data and data.personalCoins or 0
end

return EconomyService
