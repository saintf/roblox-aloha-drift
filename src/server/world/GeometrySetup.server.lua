-- GeometrySetup.server.lua
-- ONE-SHOT SETUP SCRIPT — disabled by default (see GeometrySetup.server.meta.json).
--
-- HOW TO USE:
--   1. In Studio's Explorer, find ServerScriptService > AlohaServer > world > GeometrySetup
--   2. Set Disabled = false in the Properties panel
--   3. Press Play — the geometry will be created in Workspace
--   4. Press Stop, then File > Save (saves geometry into the .rbxl place file)
--   5. Set Disabled = true again — geometry now lives in the place, this script is no longer needed
--
-- DO NOT leave this script enabled in production.

local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function makePart(props)
  local p = Instance.new("Part")
  p.Name         = props.name
  p.Size         = props.size
  p.Position     = props.position
  p.Material     = props.material   or Enum.Material.SmoothPlastic
  p.Color        = props.color      or Color3.new(1, 1, 1)
  p.Transparency = props.transparency or 0
  p.Anchored     = props.anchored   ~= false   -- default true
  p.CanCollide   = props.canCollide ~= false   -- default true
  p.Parent       = workspace
  return p
end

-- ── SolarisBase Model ────────────────────────────────────────────────────────

-- Remove stale instances so re-running is safe
if workspace:FindFirstChild("SolarisBase") then
  workspace.SolarisBase:Destroy()
end

local solarisModel = Instance.new("Model")
solarisModel.Name = "SolarisBase"

local island = makePart({
  name     = "SolarisIsland",
  size     = Vector3.new(200, 6, 200),
  position = Vector3.new(0, 180, 0),
  material = Enum.Material.SmoothPlastic,
  color    = Color3.fromRGB(180, 180, 180),
})
island.Parent = solarisModel
solarisModel.PrimaryPart = island

local spawn = Instance.new("SpawnLocation")
spawn.Name      = "SolarisSpawn"
spawn.Size      = Vector3.new(6, 1, 6)
spawn.Position  = Vector3.new(0, 183, 0)
spawn.TeamColor = BrickColor.new("Bright orange")
spawn.Anchored  = true
spawn.Parent    = solarisModel

solarisModel.Parent = workspace

-- Add ZoneType / ZoneOwner attributes (read by ZoneService later)
solarisModel:SetAttribute("ZoneType",  "home")
solarisModel:SetAttribute("ZoneOwner", "solaris")

print("[GeometrySetup] SolarisBase created")

-- ── Ocean Surface ─────────────────────────────────────────────────────────────

if workspace:FindFirstChild("OceanSurface") then
  workspace.OceanSurface:Destroy()
end

local ocean = makePart({
  name         = "OceanSurface",
  size         = Vector3.new(4000, 2, 4000),
  position     = Vector3.new(0, 0, 0),
  material     = Enum.Material.Neon,
  color        = Color3.fromRGB(0, 180, 210),
  transparency = 0.4,
  canCollide   = true,
})
CollectionService:AddTag(ocean, "OceanSurface")

print("[GeometrySetup] OceanSurface created")

-- ── Kill Plane ────────────────────────────────────────────────────────────────

if workspace:FindFirstChild("KillPlane") then
  workspace.KillPlane:Destroy()
end

local killPlane = makePart({
  name         = "KillPlane",
  size         = Vector3.new(4000, 2, 4000),
  position     = Vector3.new(0, -80, 0),
  transparency = 1,
  canCollide   = false,
})
CollectionService:AddTag(killPlane, "KillPlane")

print("[GeometrySetup] KillPlane created")

-- ── Lighting / Sky / Atmosphere ───────────────────────────────────────────────

-- Sky
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.Name   = "Sky"
sky.Parent = Lighting

-- Atmosphere
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Name        = "Atmosphere"
atmo.Density     = 0.3
atmo.Offset      = 0.25
atmo.Color       = Color3.fromRGB(255, 220, 180)
atmo.Decay       = Color3.fromRGB(255, 180, 120)
atmo.Glare       = 0.2
atmo.Haze        = 2.0
atmo.Parent      = Lighting

-- Lighting properties
Lighting.Brightness          = 3
Lighting.ClockTime           = 15
Lighting.GeographicLatitude  = 20

print("[GeometrySetup] Lighting configured")
print("[GeometrySetup] Done — save the place file, then disable this script.")
