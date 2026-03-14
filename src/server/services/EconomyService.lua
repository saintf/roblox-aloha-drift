-- EconomyService.lua
-- Single source of truth for all coin and XP transactions.
-- No other script may modify personalCoins or roleXP directly.
-- All DataStore writes are debounced (max 1 write per 6s per player).
--
-- Depends on: FactionService

local BaseService      = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local EconomyConfig    = require(game.ReplicatedStorage.AlohaShared.config.EconomyConfig)
local RemoteEvents     = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local FactionService   = require(script.Parent.FactionService)
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

local EconomyService = BaseService.new("EconomyService")

local CFG = {
  SAVE_DEBOUNCE     = 6,     -- minimum seconds between DataStore writes per player
  SPLIT_RATIO       = 0.50,  -- fraction of each earning that goes to personal wallet
  SNOWBALL_CAP      = 2.0,   -- faction treasury income reduced if leading by this multiple
  SNOWBALL_REDUCE   = 0.20,  -- income reduction applied to the leading faction
  AUTOSAVE_INTERVAL = 60,    -- seconds between autosave passes
  DATASTORE_NAME    = "PlayerData_v1",
}

-- In-memory player data (loaded from DataStore on join)
local playerData  = {}
local lastSaved   = {}  -- UserId → os.clock() of last DataStore write
local playerStore = nil -- initialised in init() so a DataStore error doesn't crash the require

-- Schema for new players and for forward migration of existing saves
local DEFAULT_DATA = {
  personalCoins    = 0,
  roleXP = {
    runner     = 0,
    hauler     = 0,
    drifter    = 0,
    scrapper   = 0,
    wrenchhead = 0,
  },
  unlockedVehicles = {},
  unlockedGadgets  = {},
  gamepasses       = {},
  cosmetics        = {},
  stats = {
    totalRaids      = 0,
    totalDeliveries = 0,
    totalRepairs    = 0,
  },
  _schemaVersion = 1,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Deep-copies a table. Handles nested tables; does not handle userdata or metatables.
local function deepCopy(t)
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = type(v) == "table" and deepCopy(v) or v
  end
  return copy
end

-- Fills any missing keys in `data` from DEFAULT_DATA without resetting existing values.
-- Runs one level deep on nested tables (handles new roleXP roles, new stats fields, etc.).
local function migrate(data)
  for key, defaultValue in pairs(DEFAULT_DATA) do
    if data[key] == nil then
      data[key] = type(defaultValue) == "table" and deepCopy(defaultValue) or defaultValue
    elseif type(defaultValue) == "table" and type(data[key]) == "table" then
      for subKey, subDefault in pairs(defaultValue) do
        if data[key][subKey] == nil then
          data[key][subKey] = subDefault
        end
      end
    end
  end
  return data
end

-- Saves one player's data if the debounce window has passed.
local function savePlayer(player)
  if not playerStore then return end  -- DataStore unavailable (Studio without API access)
  local userId = player.UserId
  local data   = playerData[userId]
  if not data then return end

  local elapsed = os.clock() - (lastSaved[userId] or 0)
  if elapsed < CFG.SAVE_DEBOUNCE then return end

  local ok, err = pcall(function()
    playerStore:SetAsync(userId, data)
  end)

  if ok then
    lastSaved[userId] = os.clock()
    EconomyService.log.debug("saved data for UserId", userId)
  else
    warn("[EconomyService] Save failed for " .. tostring(userId) .. ": " .. tostring(err))
  end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function EconomyService:init()
  local ok, result = pcall(function()
    playerStore = DataStoreService:GetDataStore(CFG.DATASTORE_NAME)
  end)
  if not ok then
    warn("[EconomyService] DataStore unavailable (Studio API access may be off): " .. tostring(result))
    -- playerStore stays nil; savePlayer/loadPlayer will no-op safely
  end
end

function EconomyService:start()
  -- Load data for one player (called for both PlayerAdded and already-connected players)
  local function loadPlayer(player)
    if playerData[player.UserId] then return end  -- already loaded

    local ok, result
    if playerStore then
      ok, result = pcall(function()
        return playerStore:GetAsync(player.UserId)
      end)
    else
      ok, result = true, nil  -- no DataStore: treat as new player
    end

    local data
    if not ok then
      warn("[EconomyService] Load failed for " .. tostring(player.UserId) .. ": " .. tostring(result))
      data = deepCopy(DEFAULT_DATA)
    elseif result == nil then
      data = deepCopy(DEFAULT_DATA)
      self.log.debug("new player, using default data for", player.Name)
    else
      data = migrate(result)
      self.log.debug("loaded data for", player.Name)
    end

    playerData[player.UserId] = data
    RemoteEvents.EconomyUpdate:FireClient(player, data.personalCoins, data.roleXP)
  end

  Players.PlayerAdded:Connect(loadPlayer)

  -- Handle players already in the game when this service starts.
  -- In Play Solo the local player is present before PlayerAdded fires.
  for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(loadPlayer, player)  -- task.spawn so DataStore calls don't block the loop
  end

  -- Save and clean up when a player leaves
  Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)
    playerData[player.UserId] = nil
    lastSaved[player.UserId]  = nil
  end)

  -- Autosave loop — runs independently, one failure per player does not block others
  task.spawn(function()
    while true do
      task.wait(CFG.AUTOSAVE_INTERVAL)
      for _, player in ipairs(Players:GetPlayers()) do
        local ok, err = pcall(savePlayer, player)
        if not ok then
          warn("[EconomyService] Autosave error for " .. player.Name .. ": " .. tostring(err))
        end
      end
    end
  end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Awards coins to a player. Splits CFG.SPLIT_RATIO to personal wallet; remainder to faction treasury.
-- source: string label for logging (e.g. "safe_raid", "lumicite_delivery")
function EconomyService.awardCoins(player, amount, source)
  local data = playerData[player.UserId]
  if not data then
    warn("[EconomyService] awardCoins: no data for", player.Name)
    return
  end

  local personalShare = math.floor(amount * CFG.SPLIT_RATIO)
  local factionShare  = amount - personalShare  -- avoids floating-point drift

  data.personalCoins += personalShare
  EconomyService.log.info("awardCoins", player.Name, personalShare, "personal /", factionShare, "faction | source:", source)

  -- Route faction share to FactionService (implemented in Milestone 4)
  if FactionService.getPlayerFaction and FactionService.addToTreasury then
    local factionId = FactionService.getPlayerFaction(player)
    if factionId then
      FactionService.addToTreasury(factionId, factionShare, source)
    end
  end

  RemoteEvents.EconomyUpdate:FireClient(player, data.personalCoins, data.roleXP)
end

-- Awards XP to a player for a specific role. Logs tier unlocks.
-- role: "runner"|"hauler"|"drifter"|"scrapper"|"wrenchhead"
function EconomyService.awardXP(player, role, amount)
  local data = playerData[player.UserId]
  if not data then
    warn("[EconomyService] awardXP: no data for", player.Name)
    return
  end

  if data.roleXP[role] == nil then
    warn("[EconomyService] awardXP: unknown role:", role)
    return
  end

  local prevXP = data.roleXP[role]
  data.roleXP[role] += amount

  -- Check if this award crossed a tier threshold (scan top-down, stop at first hit)
  for tier = 5, 2, -1 do
    local threshold = EconomyConfig.XP_TIER[tier]
    if threshold and prevXP < threshold and data.roleXP[role] >= threshold then
      EconomyService.log.info("tier unlock — player:", player.Name, "role:", role, "tier:", tier)
      -- TODO: Milestone 4 — trigger unlock via UnlockService when implemented
      break
    end
  end

  EconomyService.log.debug("awardXP", player.Name, role, "+" .. tostring(amount))
  RemoteEvents.EconomyUpdate:FireClient(player, data.personalCoins, data.roleXP)
end

-- Adds coins directly to a faction treasury (e.g. platform drip income).
-- Does NOT split — caller is responsible for the amount.
function EconomyService.transferToFaction(factionId, amount, source)
  if FactionService.addToTreasury then
    FactionService.addToTreasury(factionId, amount, source)
  else
    EconomyService.log.debug("transferToFaction: FactionService.addToTreasury not yet implemented | factionId:", factionId, "amount:", amount, "source:", source)
  end
end

-- Returns the current personal coin balance for a player.
function EconomyService.getCoins(player)
  local data = playerData[player.UserId]
  return data and data.personalCoins or 0
end

return EconomyService
