-- VehicleService.lua
-- Manages vehicle ownership, spawning, mounting, and dismount.
-- Server-authoritative — clients request via RemoteEvents, server validates and executes.
--
-- Story 1: spawn / mount / dismount / destroy. No physics, no input, no recall.
-- Depends on: VehicleConfig, FactionService (optional — for faction colour)

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local BaseService    = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents   = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local VehicleConfig  = require(game.ReplicatedStorage.AlohaShared.config.VehicleConfig)
local FactionConfig  = require(game.ReplicatedStorage.AlohaShared.config.FactionConfig)

-- Optional dependency — guards in awardCoins-style; won't crash if not yet bootstrapped.
local FactionService = require(script.Parent.FactionService)

local VehicleService = BaseService.new("VehicleService")

local CONFIG = {
  SPAWN_OFFSET    = Vector3.new(0, 4, 8),  -- relative to player HRP, in HRP's look direction
  REMOTE_COOLDOWN = 0.3,                    -- seconds between accepted remote calls per player
}

-- ── Internal state ────────────────────────────────────────────────────────────
local _vehicles   = {}  -- [player] = Model | nil
local _mounted    = {}  -- [player] = boolean
local _lastRemote = {}  -- [player] = tick()

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function rateLimitOk(player)
  local now  = tick()
  local last = _lastRemote[player] or 0
  if (now - last) < CONFIG.REMOTE_COOLDOWN then return false end
  _lastRemote[player] = now
  return true
end

-- Returns the faction primary colour for a player, or a warm-orange fallback.
local function factionColourFor(player)
  local factionId = FactionService.getPlayerFaction and FactionService.getPlayerFaction(player)
  if factionId then
    local faction = FactionConfig.factions[factionId]
    if faction and faction.primaryColor then
      return faction.primaryColor
    end
  end
  return Color3.fromRGB(255, 165, 80)  -- fallback: warm orange
end

-- Builds a procedural placeholder hover-bike model for `player`.
-- Returns the Model (not yet parented — caller does that).
local function _buildPlaceholderBike(player, spawnCFrame)
  local colour = factionColourFor(player)

  local model = Instance.new("Model")
  model.Name = "HoverBike_" .. player.Name

  -- RootPart — main body
  local root = Instance.new("Part")
  root.Name     = "RootPart"
  root.Size     = Vector3.new(8, 3, 16)
  root.Color    = colour
  root.Material = Enum.Material.SmoothPlastic
  root.Anchored = true        -- anchored until physics (Story 2) takes over
  root.CastShadow = true
  root.Parent   = model

  -- Engine pod — left
  local podL = Instance.new("Part")
  podL.Name     = "Pod_L"
  podL.Shape    = Enum.PartType.Cylinder
  podL.Size     = Vector3.new(4, 3, 3)   -- Cylinder: X=length, Y/Z=diameter (r=1.5)
  podL.Color    = Color3.fromRGB(60, 60, 60)
  podL.Material = Enum.Material.Metal
  podL.Anchored = true
  podL.Parent   = model

  -- Engine pod — right
  local podR = Instance.new("Part")
  podR.Name     = "Pod_R"
  podR.Shape    = Enum.PartType.Cylinder
  podR.Size     = Vector3.new(4, 3, 3)
  podR.Color    = Color3.fromRGB(60, 60, 60)
  podR.Material = Enum.Material.Metal
  podR.Anchored = true
  podR.Parent   = model

  -- Seat
  local seat = Instance.new("Seat")
  seat.Name     = "Seat"
  seat.Size     = Vector3.new(2, 1, 2)
  seat.Color    = Color3.fromRGB(40, 40, 40)
  seat.Anchored = true
  seat.Parent   = model

  -- Thruster attachment (used by Story 2 for VectorForce)
  local attach = Instance.new("Attachment")
  attach.Name   = "ThrusterAttach"
  attach.Parent = root

  -- Set PrimaryPart before pivoting so relative offsets work
  model.PrimaryPart = root

  -- Parent to workspace and pivot to spawn position
  model.Parent = workspace
  model:PivotTo(spawnCFrame)

  -- Now position parts relative to root's world CFrame
  local rootCF = root.CFrame
  podL.CFrame  = rootCF * CFrame.new(-4, -1, 0)
  podR.CFrame  = rootCF * CFrame.new( 4, -1, 0)
  seat.CFrame  = rootCF * CFrame.new( 0,  1.5, -2)

  -- Weld parts to root so the model moves as one piece
  local function weld(part)
    local w = Instance.new("WeldConstraint")
    w.Part0  = root
    w.Part1  = part
    w.Parent = root
  end
  weld(podL)
  weld(podR)
  weld(seat)

  -- Now safe to unanchor; WeldConstraints keep geometry together
  root.Anchored = false
  podL.Anchored = false
  podR.Anchored = false
  seat.Anchored = false

  CollectionService:AddTag(model, "AlohaVehicle")

  return model
end

-- Returns the world CFrame at which to spawn a vehicle for `player`.
local function spawnCFrameFor(player)
  local char = player.Character
  local hrp  = char and char:FindFirstChild("HumanoidRootPart")
  if not hrp then
    -- Fallback: world origin if character isn't loaded yet
    return CFrame.new(0, 10, 0)
  end
  -- Project CONFIG.SPAWN_OFFSET along the HRP's look direction
  local lookUnit = hrp.CFrame.LookVector
  local offset   = lookUnit * CONFIG.SPAWN_OFFSET.Z
                 + Vector3.new(0, CONFIG.SPAWN_OFFSET.Y, 0)
  return CFrame.new(hrp.Position + offset) * CFrame.Angles(0, math.atan2(-lookUnit.X, -lookUnit.Z), 0)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Spawn a vehicle for a player. One vehicle per player at a time.
-- vehicleId must be a key in VehicleConfig; unknown ids are rejected.
-- Returns the spawned Model, or nil if rejected.
function VehicleService.spawnVehicle(player, vehicleId)
  if _vehicles[player] then
    VehicleService.log.debug("spawnVehicle: player already has a vehicle", player.Name)
    return nil
  end

  if type(vehicleId) ~= "string" or not VehicleConfig[vehicleId] then
    warn("[VehicleService] spawnVehicle: unknown vehicleId:", tostring(vehicleId))
    return nil
  end

  local cf    = spawnCFrameFor(player)
  local model = _buildPlaceholderBike(player, cf)
  _vehicles[player] = model

  VehicleService.log.info("spawnVehicle:", player.Name, vehicleId)
  return model
end

-- Seat the player in their vehicle via Seat:Sit(humanoid).
function VehicleService.mountPlayer(player, vehicle)
  local char     = player.Character
  local humanoid = char and char:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    warn("[VehicleService] mountPlayer: no humanoid for", player.Name)
    return
  end

  local seat = vehicle:FindFirstChild("Seat")
  if not seat then
    warn("[VehicleService] mountPlayer: vehicle has no Seat part")
    return
  end

  seat:Sit(humanoid)
  _mounted[player] = true
  VehicleService.log.info("mountPlayer:", player.Name)
end

-- Eject the player from their vehicle. Does NOT destroy the vehicle.
-- Repositions character 3 studs above the vehicle root.
function VehicleService.dismountPlayer(player)
  local vehicle = _vehicles[player]
  if vehicle then
    local root = vehicle:FindFirstChild("RootPart")
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and root then
      hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
    end
  end
  _mounted[player] = nil
  VehicleService.log.info("dismountPlayer:", player.Name)
end

-- Returns the vehicle Model currently owned by this player, or nil.
function VehicleService.getVehicle(player)
  return _vehicles[player]
end

-- Returns true if the player is currently seated in their vehicle.
function VehicleService.isMounted(player)
  return _mounted[player] == true
end

-- Destroy a player's vehicle.
-- Calls dismountPlayer first if they are mounted.
-- Removes the model from workspace and clears internal state.
function VehicleService.destroyVehicle(player)
  if _mounted[player] then
    VehicleService.dismountPlayer(player)
  end

  local vehicle = _vehicles[player]
  if vehicle then
    vehicle:Destroy()
    _vehicles[player] = nil
    VehicleService.log.info("destroyVehicle:", player.Name)
  end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function VehicleService:init()
end

function VehicleService:start()
  local RE = RemoteEvents

  RE.VehicleSpawnRequest.OnServerEvent:Connect(function(player, vehicleId)
    if not rateLimitOk(player) then return end

    if type(vehicleId) ~= "string" then return end

    local vehicle = VehicleService.spawnVehicle(player, vehicleId)
    if vehicle then
      VehicleService.mountPlayer(player, vehicle)
    end
  end)

  RE.VehicleDismountRequest.OnServerEvent:Connect(function(player)
    if not rateLimitOk(player) then return end
    VehicleService.dismountPlayer(player)
  end)

  Players.PlayerRemoving:Connect(function(player)
    VehicleService.destroyVehicle(player)
    _lastRemote[player] = nil
  end)

  VehicleService.log.info("VehicleService started")
end

return VehicleService
