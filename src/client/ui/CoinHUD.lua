-- CoinHUD.lua
-- Builds the coin counter ScreenGui. Returns { gui, coinLabel }.
-- Call CoinHUD.create() once on init — do not call it on every respawn.
--
-- To replace the emoji coin icon with a real asset later:
--   1. Delete the icon TextLabel
--   2. Add an ImageLabel at the same Size/Position with your asset ID

local CoinHUD = {}

function CoinHUD.create()
  local screenGui = Instance.new("ScreenGui")
  screenGui.Name           = "CoinHUD"
  screenGui.ResetOnSpawn   = false   -- survives character respawn
  screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

  -- Container: top-right, slight inset from edge
  local frame = Instance.new("Frame")
  frame.Name                   = "CoinFrame"
  frame.Size                   = UDim2.new(0, 160, 0, 44)
  frame.Position               = UDim2.new(1, -172, 0, 12)
  frame.BackgroundColor3       = Color3.fromRGB(20, 20, 30)
  frame.BackgroundTransparency = 0.25
  frame.BorderSizePixel        = 0
  frame.Parent                 = screenGui

  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 10)
  corner.Parent       = frame

  -- Coin icon — emoji placeholder, swap for ImageLabel + asset ID when ready
  local icon = Instance.new("TextLabel")
  icon.Name                   = "CoinIcon"
  icon.Size                   = UDim2.new(0, 32, 1, 0)
  icon.Position               = UDim2.new(0, 8, 0, 0)
  icon.BackgroundTransparency = 1
  icon.Text                   = "🪙"
  icon.TextScaled             = true
  icon.Parent                 = frame

  -- Coin count label — updated by HUDController on EconomyUpdate
  local label = Instance.new("TextLabel")
  label.Name                   = "CoinLabel"
  label.Size                   = UDim2.new(1, -48, 1, 0)
  label.Position               = UDim2.new(0, 44, 0, 0)
  label.BackgroundTransparency = 1
  label.Text                   = "0"
  label.TextColor3             = Color3.fromRGB(255, 220, 80)  -- gold
  label.TextXAlignment         = Enum.TextXAlignment.Left
  label.Font                   = Enum.Font.GothamBold
  label.TextScaled             = true
  label.Parent                 = frame

  return { gui = screenGui, coinLabel = label }
end

return CoinHUD
