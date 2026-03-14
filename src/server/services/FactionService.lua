-- FactionService.lua
-- Manages faction assignment, treasury (session memory only), and perk state.
-- Faction treasury is NEVER written to DataStore — session memory only.
--
-- Depends on: FactionConfig

local Players      = game:GetService("Players")
local BaseService  = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local FactionConfig = require(game.ReplicatedStorage.AlohaShared.config.FactionConfig)

local FactionService = BaseService.new("FactionService")

-- Session-only state
local factionTreasury = {}   -- [factionId] = number
local playerFaction   = {}   -- [UserId]    = factionId
local factionCount    = {}   -- [factionId] = number

local CFG = {
  MAX_IMBALANCE = FactionConfig.MAX_IMBALANCE,
}

-- ── Local helpers ──────────────────────────────────────────────────────────────

local function getFactionIds()
  local ids = {}
  for id in pairs(FactionConfig.factions) do
    table.insert(ids, id)
  end
  return ids
end

-- Assigns a faction to a player using balance logic.
-- Lower count wins; random if equal; force-balance if diff > MAX_IMBALANCE.
local function assignFaction(player)
  local ids = getFactionIds()

  -- Find faction(s) with the fewest members
  local minCount = math.huge
  for _, id in ipairs(ids) do
    local c = factionCount[id] or 0
    if c < minCount then minCount = c end
  end

  local candidates = {}
  for _, id in ipairs(ids) do
    if (factionCount[id] or 0) == minCount then
      table.insert(candidates, id)
    end
  end

  -- Force-balance: if any faction is over-represented, assign to the smallest
  for _, id in ipairs(ids) do
    local otherId = ids[1] == id and ids[2] or ids[1]
    if otherId and ((factionCount[id] or 0) - (factionCount[otherId] or 0)) > CFG.MAX_IMBALANCE then
      candidates = { otherId }
      break
    end
  end

  local chosen = candidates[math.random(1, #candidates)]
  playerFaction[player.UserId] = chosen
  factionCount[chosen] = (factionCount[chosen] or 0) + 1
  return chosen
end

-- Colors all non-HRP BaseParts with the faction's primaryColor.
local function applyFactionAppearance(player)
  local factionId = playerFaction[player.UserId]
  if not factionId then return end
  local faction = FactionConfig.factions[factionId]
  if not faction then return end

  local character = player.Character
  if not character then return end

  for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
      part.Color = faction.primaryColor
    end
  end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function FactionService:init()
  -- Initialise treasury and count tables for all factions
  for id in pairs(FactionConfig.factions) do
    factionTreasury[id] = 0
    factionCount[id]    = 0
  end
end

function FactionService:start()
  local function onPlayerAdded(player)
    assignFaction(player)
    print("[FactionService]", player.Name, "→", playerFaction[player.UserId])

    -- Reapply appearance each time a character loads
    player.CharacterAdded:Connect(function()
      -- Wait a frame so the character is fully parented
      task.defer(function()
        applyFactionAppearance(player)
      end)
    end)

    -- Apply now if character already exists (Play Solo race)
    if player.Character then
      applyFactionAppearance(player)
    end
  end

  Players.PlayerAdded:Connect(onPlayerAdded)

  Players.PlayerRemoving:Connect(function(player)
    local factionId = playerFaction[player.UserId]
    if factionId then
      factionCount[factionId] = math.max(0, (factionCount[factionId] or 1) - 1)
    end
    playerFaction[player.UserId] = nil
  end)

  -- Handle already-connected players (Play Solo / server start race)
  for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
  end
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Returns the factionId string for a player, or nil.
function FactionService.getPlayerFaction(player)
  return playerFaction[player.UserId]
end

-- Alias used by EconomyService (called as FactionService.getFaction)
FactionService.getFaction = FactionService.getPlayerFaction

-- Adds `amount` coins to the faction treasury for the player's faction.
function FactionService.addToTreasury(player, amount)
  local factionId = playerFaction[player.UserId]
  if not factionId then return end
  factionTreasury[factionId] = (factionTreasury[factionId] or 0) + amount
end

-- Adds `amount` coins directly to a faction treasury by factionId.
function FactionService.addToTreasuryById(factionId, amount)
  if not factionTreasury[factionId] then return end
  factionTreasury[factionId] = factionTreasury[factionId] + amount
end

-- Returns current treasury balance for a factionId.
function FactionService.getTreasury(factionId)
  return factionTreasury[factionId] or 0
end

-- Returns an array of players currently in a faction.
function FactionService.getPlayersInFaction(factionId)
  local result = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if playerFaction[player.UserId] == factionId then
      table.insert(result, player)
    end
  end
  return result
end

-- Prints treasury totals to the output (extend to fire a RemoteEvent when HUD exists).
function FactionService.broadcastTreasury()
  for id, total in pairs(factionTreasury) do
    local faction = FactionConfig.factions[id]
    print(("[FactionService] %s treasury: %d coins"):format(faction and faction.displayName or id, total))
  end
end

return FactionService
