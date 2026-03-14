-- PersistenceTest.server.lua
-- DEBUG ONLY — disable before release.
-- Prints a full DataStore data report for each player on join.
-- Verify: coins persist across sessions, schema migration fills missing keys.

local Players        = game:GetService("Players")
local EconomyService = require(game.ServerScriptService.AlohaServer.services.EconomyService)
local FactionService = require(game.ServerScriptService.AlohaServer.services.FactionService)

local function printReport(player)
  -- Give services time to finish loading this player's data
  task.wait(1)

  local data      = EconomyService.getDataDebug(player)
  local factionId = FactionService.getFaction(player)

  if not data then
    warn("[PersistenceTest] No data found for", player.Name)
    return
  end

  print("─────────────────────────────────────")
  print("[PersistenceTest] Report for:", player.Name)
  print("  Faction:       ", factionId or "unassigned")
  print("  personalCoins: ", data.personalCoins)
  print("  _schemaVersion:", data._schemaVersion)
  print("  roleXP:")
  for role, xp in pairs(data.roleXP) do
    print("    " .. role .. ": " .. tostring(xp))
  end
  print("  stats:")
  for k, v in pairs(data.stats) do
    print("    " .. k .. ": " .. tostring(v))
  end
  print("─────────────────────────────────────")
end

Players.PlayerAdded:Connect(printReport)

-- Also report anyone already in the server when this script starts (Studio Play Solo)
for _, player in ipairs(Players:GetPlayers()) do
  task.spawn(printReport, player)
end

print("[PersistenceTest] Active — disable this script before release.")
