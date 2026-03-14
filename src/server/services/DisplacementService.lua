-- DisplacementService.lua
-- Handles ALL player displacement: wind hits, ocean falls, boundary violations,
-- and teleport home. This is the ONLY module permitted to call teleportHome().
-- No other script may teleport a player directly.
--
-- Depends on: ZoneService, EconomyService

local BaseService        = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local WindConfig         = require(game.ReplicatedStorage.AlohaShared.config.WindConfig)
local RemoteEvents       = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)

local DisplacementService = BaseService.new("DisplacementService")

-- Config: all tunable numbers live here — never buried in function bodies below
local CFG = {
  OCEAN_DELAY      = 5,    -- seconds of wonder window before teleport
  SPAWN_INVINCIBLE = 3,    -- seconds of invincibility on arrival
  SPAWN_POSITION   = CFrame.new(0, 184, 0),  -- top of SolarisIsland + character height offset
  WIND             = WindConfig,
}

-- Per-player runtime state, keyed by UserId
-- Initialised on PlayerAdded, cleaned up on PlayerRemoving
local playerState = {}

-- Sets up per-player state tracking. Called before start().
function DisplacementService:init()
  -- Nothing to initialise yet — state is created reactively in start()
end

-- Connects player lifecycle events to manage state entries.
function DisplacementService:start()
  local Players = game:GetService("Players")

  Players.PlayerAdded:Connect(function(player)
    playerState[player.UserId] = {
      windHits         = 0,
      firstHitTime     = 0,
      invincible       = false,
      invincibleUntil  = 0,
      isBeingDisplaced = false,
    }
    self.log.debug("state created for", player.Name)
  end)

  Players.PlayerRemoving:Connect(function(player)
    playerState[player.UserId] = nil
    self.log.debug("state removed for", player.Name)
  end)
end

-- Called when a Wind Blaster hits this player.
-- firerTeam: string factionId of the player who fired
-- TODO: implement in Milestone 1, Story — Wind Blaster gadget
function DisplacementService.onWindHit(player, firerTeam)
  -- stub
end

-- Called when a player's character touches the ocean surface.
-- Starts a wonder window (CFG.OCEAN_DELAY seconds) then teleports home.
-- Fires OceanContact remote immediately so UnderwaterFX can react (Story 4).
function DisplacementService.onOceanContact(player)
  local state = playerState[player.UserId]
  if not state or state.isBeingDisplaced then return end
  state.isBeingDisplaced = true

  RemoteEvents.OceanContact:FireClient(player)

  task.delay(CFG.OCEAN_DELAY, function()
    if not player.Parent then return end  -- player left during delay
    DisplacementService.teleportHome(player)
  end)
end

-- Called when a player falls below the world boundary (KillPlane contact).
-- No wonder window — teleport is immediate.
function DisplacementService.onBelowWorldBoundary(player)
  local state = playerState[player.UserId]
  if not state or state.isBeingDisplaced then return end
  state.isBeingDisplaced = true
  DisplacementService.teleportHome(player)
end

-- Teleports player to their faction's home spawn and grants spawn invincibility.
-- This is the ONLY function permitted to move a player's CFrame. No other script teleports.
-- ZoneService will route to the correct faction spawn in Milestone 4 — for now uses CFG.SPAWN_POSITION.
function DisplacementService.teleportHome(player)
  local character = player.Character
  if not character then return end

  local hrp = character:FindFirstChild("HumanoidRootPart")
  if not hrp then return end

  hrp.CFrame = CFG.SPAWN_POSITION

  DisplacementService.grantInvincibility(player, CFG.SPAWN_INVINCIBLE)

  -- Notify client to play spawn shimmer VFX (wired in Story 5)
  RemoteEvents.DisplacementOccurred:FireClient(player)

  -- Reset displacement flag after a short buffer so re-entry can be detected
  task.delay(0.5, function()
    local state = playerState[player.UserId]
    if state then state.isBeingDisplaced = false end
  end)

  print("[DisplacementService] teleportHome:", player.Name)
end

-- Grants invincibility to a player for duration seconds, then clears it.
-- Used by GadgetService to skip push/loot logic during the spawn window.
function DisplacementService.grantInvincibility(player, duration)
  local state = playerState[player.UserId]
  if not state then return end
  state.invincible      = true
  state.invincibleUntil = os.clock() + duration
  task.delay(duration, function()
    local s = playerState[player.UserId]
    if s then s.invincible = false end
  end)
end

-- Returns true if the player is currently within their spawn invincibility window.
-- Used by GadgetService and DisplacementService to skip push/loot logic.
function DisplacementService.isInvincible(player)
  local state = playerState[player.UserId]
  if not state then return false end
  return state.invincible and os.clock() < state.invincibleUntil
end

return DisplacementService
