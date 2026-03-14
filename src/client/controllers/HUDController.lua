-- HUDController.lua
-- Manages the main player HUD: coins display.
-- Listens to EconomyUpdate (server→client) and updates labels.
-- This controller owns the ScreenGui — it creates it once in init().
--
-- XP data arrives in the EconomyUpdate payload but is not displayed yet —
-- that comes in the Faction Treasury HUD story (M2-S5).

local BaseService  = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
-- script.Parent = controllers, script.Parent.Parent = AlohaClient, .ui.CoinHUD = sibling folder
local CoinHUD      = require(script.Parent.Parent.ui.CoinHUD)

local HUDController = BaseService.new("HUDController")

local coinLabel  -- TextLabel reference set in init(), updated in start()

function HUDController:init()
  local hud = CoinHUD.create()
  hud.gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
  coinLabel = hud.coinLabel
end

function HUDController:start()
  RemoteEvents.EconomyUpdate.OnClientEvent:Connect(function(coins, _xp)
    -- _xp received but not displayed until M2-S5 Faction Treasury HUD
    if coinLabel then
      coinLabel.Text = tostring(coins)
    end
  end)
end

return HUDController
