-- HUDController.lua
-- Manages the main player HUD: coin counter and faction treasury panel.
-- Listens to EconomyUpdate (coins, xp, factionId) and FactionUpdate (treasury, perks).

local BaseService   = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents  = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local CoinHUD       = require(script.Parent.Parent.ui.CoinHUD)
local TreasuryHUD   = require(script.Parent.Parent.ui.TreasuryHUD)

local HUDController = BaseService.new("HUDController")

local coinLabel       -- TextLabel: personal coin count
local treasuryRefs    -- refs table from TreasuryHUD.create()
local cachedFactionId = nil

function HUDController:init()
  local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

  local hud = CoinHUD.create()
  hud.gui.Parent = playerGui
  coinLabel = hud.coinLabel

  local treasury = TreasuryHUD.create()
  treasury.gui.Parent = playerGui
  treasuryRefs = treasury
end

function HUDController:start()
  -- EconomyUpdate: (coins, xp, factionId)
  -- factionId is non-nil only on the initial load fire; nil on subsequent coin/xp updates.
  RemoteEvents.EconomyUpdate.OnClientEvent:Connect(function(coins, _xp, factionId)
    if coinLabel then
      coinLabel.Text = tostring(coins)
    end

    -- Cache faction identity on first non-nil receive and colour the swatch
    if factionId and factionId ~= cachedFactionId then
      cachedFactionId = factionId
      if treasuryRefs then
        local color = treasuryRefs.factionColors[factionId]
        local name  = treasuryRefs.factionNames[factionId]
        if color then treasuryRefs.swatch.BackgroundColor3 = color end
        if name  then treasuryRefs.factionLabel.Text = name end
      end
    end
  end)

  -- FactionUpdate: (treasury, perks) — broadcast to all faction members after each earn
  RemoteEvents.FactionUpdate.OnClientEvent:Connect(function(treasury, _perks)
    if treasuryRefs then
      treasuryRefs.treasuryLabel.Text = tostring(treasury)
    end
  end)
end

return HUDController
