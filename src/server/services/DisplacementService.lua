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
  OCEAN_DELAY      = 5,   -- seconds before teleport after ocean contact
  SPAWN_INVINCIBLE = 3,   -- seconds of invincibility granted on spawn arrival
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
      windHits        = 0,
      firstHitTime    = 0,
      invincible      = false,
      invincibleUntil = 0,
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
-- Fires OceanContact remote so the client can play underwater VFX (Story 4).
-- Teleport logic will be added in the teleportHome story.
function DisplacementService.onOceanContact(player)
  print("[DisplacementService] onOceanContact:", player.Name)
  -- Notify client to trigger underwater VFX (implemented in Story 4)
  RemoteEvents.OceanContact:FireClient(player)
end

-- Called when a player falls below the world boundary (KillPlane contact).
-- Routes to teleportHome once that is implemented.
function DisplacementService.onBelowWorldBoundary(player)
  print("[DisplacementService] onBelowWorldBoundary:", player.Name)
  -- TODO: call teleportHome(player) in Milestone 1, Story — teleportHome
end

-- Teleports player to their faction's home spawn and grants invincibility.
-- This is the single authoritative path for all player teleportation.
-- TODO: implement in Milestone 1, Story — teleportHome
function DisplacementService.teleportHome(player)
  -- stub
end

-- Returns true if the player is currently within their spawn invincibility window.
-- Used by GadgetService and DisplacementService to skip push/loot logic.
function DisplacementService.isInvincible(player)
  local state = playerState[player.UserId]
  if not state then return false end
  return state.invincible and os.clock() < state.invincibleUntil
end

return DisplacementService
