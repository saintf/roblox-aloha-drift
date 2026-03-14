-- TreasuryHUD.lua
-- Builds the faction treasury display ScreenGui element.
-- Designed to be parented into the same PlayerGui as CoinHUD.
-- Returns refs table for HUDController to update.

local TreasuryHUD = {}

local FACTION_COLORS = {
  solaris   = Color3.fromRGB(255, 120, 60),
  tidalwave = Color3.fromRGB(40, 180, 200),
}
local FACTION_NAMES = {
  solaris   = "Solaris",
  tidalwave = "Tidalwave",
}

function TreasuryHUD.create()
  local screenGui = Instance.new("ScreenGui")
  screenGui.Name           = "TreasuryHUD"
  screenGui.ResetOnSpawn   = false
  screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

  -- Positioned below the coin counter (coin counter: y=12, h=44 → 12+44+8=64)
  local frame = Instance.new("Frame")
  frame.Name                   = "TreasuryFrame"
  frame.Size                   = UDim2.new(0, 160, 0, 44)
  frame.Position               = UDim2.new(1, -172, 0, 64)
  frame.BackgroundColor3       = Color3.fromRGB(20, 20, 30)
  frame.BackgroundTransparency = 0.25
  frame.BorderSizePixel        = 0
  frame.Parent                 = screenGui

  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 10)
  corner.Parent       = frame

  -- Faction colour swatch — left strip, grey until faction is received
  local swatch = Instance.new("Frame")
  swatch.Name             = "FactionSwatch"
  swatch.Size             = UDim2.new(0, 6, 1, 0)
  swatch.Position         = UDim2.new(0, 0, 0, 0)
  swatch.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
  swatch.BorderSizePixel  = 0
  swatch.Parent           = frame

  local swatchCorner = Instance.new("UICorner")
  swatchCorner.CornerRadius = UDim.new(0, 10)
  swatchCorner.Parent       = swatch

  -- Faction name (small, top half)
  local factionLabel = Instance.new("TextLabel")
  factionLabel.Name                   = "FactionLabel"
  factionLabel.Size                   = UDim2.new(1, -16, 0.45, 0)
  factionLabel.Position               = UDim2.new(0, 14, 0, 2)
  factionLabel.BackgroundTransparency = 1
  factionLabel.Text                   = "..."
  factionLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
  factionLabel.TextXAlignment         = Enum.TextXAlignment.Left
  factionLabel.Font                   = Enum.Font.Gotham
  factionLabel.TextScaled             = true
  factionLabel.Parent                 = frame

  -- Treasury amount (larger, bottom half)
  local treasuryLabel = Instance.new("TextLabel")
  treasuryLabel.Name                   = "TreasuryLabel"
  treasuryLabel.Size                   = UDim2.new(1, -16, 0.5, 0)
  treasuryLabel.Position               = UDim2.new(0, 14, 0.48, 0)
  treasuryLabel.BackgroundTransparency = 1
  treasuryLabel.Text                   = "🏦 0"
  treasuryLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
  treasuryLabel.TextXAlignment         = Enum.TextXAlignment.Left
  treasuryLabel.Font                   = Enum.Font.GothamBold
  treasuryLabel.TextScaled             = true
  treasuryLabel.Parent                 = frame

  return {
    gui           = screenGui,
    frame         = frame,
    swatch        = swatch,
    treasuryLabel = treasuryLabel,
    factionLabel  = factionLabel,
    factionColors = FACTION_COLORS,
    factionNames  = FACTION_NAMES,
  }
end

return TreasuryHUD
