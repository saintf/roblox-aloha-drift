-- OceanContactHandler.server.lua
-- Detects ocean and kill-plane contact for all player characters.
-- Routes to DisplacementService — does NOT handle teleport logic itself.
--
-- Geometry requirements (created by GeometrySetup.server.lua):
--   OceanSurface — tagged "OceanSurface"
--   KillPlane    — tagged "KillPlane"

local CollectionService   = game:GetService("CollectionService")
local Players             = game:GetService("Players")

-- script.Parent = world folder, script.Parent.Parent = AlohaServer
local DisplacementService = require(script.Parent.Parent.services.DisplacementService)

-- Rate limit: ignore repeat triggers within this window (seconds).
-- Touched fires dozens of times per collision — the cooldown collapses them to one call.
local CONTACT_COOLDOWN = 3.0

-- Per-player cooldown timestamps, keyed by UserId
local lastContact = {}

local function onPartTouched(triggerType, part)
  local character = part.Parent
  if not character then return end

  local player = Players:GetPlayerFromCharacter(character)
  if not player then return end

  local now = tick()
  local last = lastContact[player.UserId] or 0
  if (now - last) < CONTACT_COOLDOWN then return end
  lastContact[player.UserId] = now

  if triggerType == "ocean" then
    DisplacementService.onOceanContact(player)
  elseif triggerType == "boundary" then
    DisplacementService.onBelowWorldBoundary(player)
  end
end

-- Wire up all parts tagged OceanSurface
for _, part in ipairs(CollectionService:GetTagged("OceanSurface")) do
  part.Touched:Connect(function(hit) onPartTouched("ocean", hit) end)
end

-- Wire up all parts tagged KillPlane
for _, part in ipairs(CollectionService:GetTagged("KillPlane")) do
  part.Touched:Connect(function(hit) onPartTouched("boundary", hit) end)
end

-- Clean up cooldown state when players leave
Players.PlayerRemoving:Connect(function(player)
  lastContact[player.UserId] = nil
end)
