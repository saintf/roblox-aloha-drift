-- CoinOrbHandler.server.lua
-- Handles CoinOrb touch collection. Always-on.
-- Calls EconomyService.awardCoins() — no coin logic lives here.

local Players    = game:GetService("Players")

local EconomyService = require(game.ServerScriptService.AlohaServer.services.EconomyService)

local CFG = {
  COLLECT_AMOUNT = 50,          -- coins awarded per collect
  RESPAWN_DELAY  = 30,          -- seconds before orb reappears
  RATE_LIMIT     = 1,           -- minimum seconds between collects per player
  COLLECT_SOURCE = "coin_orb",
}

-- Track last collect time per player to rate-limit rapid Touched events
local lastCollect = {}  -- [UserId] = os.clock()

-- Wait for geometry to exist (CoinOrbSetup may run after this script loads)
local orbModel = workspace:WaitForChild("CoinOrb", 30)
if not orbModel then
  warn("[CoinOrbHandler] CoinOrb model not found in Workspace. Run CoinOrbSetup first.")
  return
end

local orbPart = orbModel:WaitForChild("OrbPart")

local function hideOrb()
  orbPart.Transparency = 1
  orbPart.CanCollide   = false
end

local function showOrb()
  orbPart.Transparency = 0
  orbPart.CanCollide   = false  -- always false; Touched fires regardless of CanCollide on the hitting part
end

local function respawnAfterDelay()
  task.delay(CFG.RESPAWN_DELAY, function()
    showOrb()
  end)
end

orbPart.Touched:Connect(function(hit)
  -- Ignore while orb is hidden (already collected this cycle)
  if orbPart.Transparency == 1 then return end

  local character = hit.Parent
  local player    = Players:GetPlayerFromCharacter(character)
  if not player then return end

  -- Rate limit — Touched fires many times per contact
  local now = os.clock()
  if (now - (lastCollect[player.UserId] or 0)) < CFG.RATE_LIMIT then return end
  lastCollect[player.UserId] = now

  -- Hide immediately so only one player gets it per cycle
  hideOrb()

  -- Award coins via EconomyService — the only valid path for coin transactions
  EconomyService.awardCoins(player, CFG.COLLECT_AMOUNT, CFG.COLLECT_SOURCE)

  print("[CoinOrbHandler]", player.Name, "collected", CFG.COLLECT_AMOUNT, "coins")

  respawnAfterDelay()
end)

-- Clean up rate-limit entries when players leave
Players.PlayerRemoving:Connect(function(player)
  lastCollect[player.UserId] = nil
end)

print("[CoinOrbHandler] Listening for orb touches")
