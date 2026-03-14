-- CoinOrbSetup.server.lua
-- ONE-SHOT SETUP: creates the CoinOrb model in Workspace.
-- Disable after first run (the orb is saved into the place file).
--
-- HOW TO USE:
--   1. In Explorer: ServerScriptService > AlohaServer > world > CoinOrbSetup
--   2. Set Disabled = false in Properties
--   3. Press Play — the orb is placed in Workspace
--   4. Press Stop, File > Save, then set Disabled = true again

local ORB_POSITION = Vector3.new(0, 185, 30)  -- on SolarisBase island surface
local ORB_SIZE     = Vector3.new(3, 3, 3)
local ORB_COLOR    = Color3.fromRGB(255, 210, 80)  -- gold

if workspace:FindFirstChild("CoinOrb") then
  workspace.CoinOrb:Destroy()
end

local model = Instance.new("Model")
model.Name = "CoinOrb"

local part = Instance.new("Part")
part.Name         = "OrbPart"
part.Shape        = Enum.PartType.Ball
part.Size         = ORB_SIZE
part.Position     = ORB_POSITION
part.Material     = Enum.Material.Neon
part.Color        = ORB_COLOR
part.Anchored     = true
part.CanCollide   = false
part.CastShadow   = false
part.Parent       = model

local light = Instance.new("PointLight")
light.Name       = "OrbLight"
light.Brightness = 3
light.Range      = 16
light.Color      = Color3.fromRGB(255, 220, 100)  -- warm gold
light.Parent     = part

local billboard = Instance.new("BillboardGui")
billboard.Name           = "OrbBillboard"
billboard.Size           = UDim2.new(0, 60, 0, 24)
billboard.StudsOffset    = Vector3.new(0, 2.5, 0)
billboard.AlwaysOnTop    = false
billboard.LightInfluence = 0
billboard.Parent         = part

local label = Instance.new("TextLabel")
label.Size                   = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text                   = "COINS"
label.TextColor3             = Color3.fromRGB(255, 230, 80)
label.Font                   = Enum.Font.GothamBold
label.TextScaled             = true
label.Parent                 = billboard

model.PrimaryPart = part
model.Parent      = workspace

print("[CoinOrbSetup] CoinOrb placed at", ORB_POSITION)
