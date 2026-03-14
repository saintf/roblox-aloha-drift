-- OceanContactHandler.server.lua
-- Detects when a player enters Terrain Water (swimming state) or falls below
-- the world boundary (kill plane). Routes to DisplacementService.
--
-- Detection method:
--   Ocean    → Humanoid.StateChanged fires Enum.HumanoidStateType.Swimming
--   KillPlane → Part.Touched (unchanged — KillPlane is still a regular Part)
--
-- This script does NO teleport logic. It only calls DisplacementService.

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- script.Parent = world folder, script.Parent.Parent = AlohaServer
local DisplacementService = require(script.Parent.Parent.services.DisplacementService)

-- Rate limit: ignore repeat triggers within this window (seconds).
-- Humanoid.StateChanged can fire rapidly when bobbing at the water surface.
local CONTACT_COOLDOWN = 3.0

local lastContact = {} -- keyed by UserId

local function onOceanEntered(player)
  local now = tick()
  local last = lastContact[player.UserId] or 0
  if (now - last) < CONTACT_COOLDOWN then return end
  lastContact[player.UserId] = now

  DisplacementService.onOceanContact(player)
end

local function onBoundaryHit(player)
  -- No cooldown needed — falling below Y=-80 is unambiguous
  DisplacementService.onBelowWorldBoundary(player)
end

-- Wire Humanoid.StateChanged on a character to detect swimming
local function wireCharacter(player, character)
  local humanoid = character:WaitForChild("Humanoid", 5)
  if not humanoid then return end

  humanoid.StateChanged:Connect(function(_old, new)
    if new == Enum.HumanoidStateType.Swimming then
      onOceanEntered(player)
    end
  end)
end

-- Wire up all future players
Players.PlayerAdded:Connect(function(player)
  if player.Character then
    wireCharacter(player, player.Character)
  end
  player.CharacterAdded:Connect(function(character)
    wireCharacter(player, character)
  end)
end)

-- Wire up players already in-game when this script loads (Studio Play mode)
for _, player in ipairs(Players:GetPlayers()) do
  if player.Character then
    wireCharacter(player, player.Character)
  end
  player.CharacterAdded:Connect(function(character)
    wireCharacter(player, character)
  end)
end

-- Kill plane detection — still Part.Touched since KillPlane is a regular Part
for _, part in ipairs(CollectionService:GetTagged("KillPlane")) do
  part.Touched:Connect(function(hit)
    local character = hit.Parent
    if not character then return end
    local player = Players:GetPlayerFromCharacter(character)
    if player then onBoundaryHit(player) end
  end)
end

-- Clean up cooldown state when players leave
Players.PlayerRemoving:Connect(function(player)
  lastContact[player.UserId] = nil
end)
