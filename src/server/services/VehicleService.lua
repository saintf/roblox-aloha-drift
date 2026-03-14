-- VehicleService.lua
-- Manages vehicle ownership, spawning, mounting, dismount, and hover physics.
-- Server-authoritative — clients request via RemoteEvents, server validates and executes.
--
-- Story 1: spawn / mount / dismount / destroy.
-- Story 2: altitude hold, idle bob, velocity tilt, max speed cap (server Heartbeat loop).
-- Depends on: VehicleConfig, FactionService (optional — for faction colour)

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local BaseService    = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents   = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local VehicleConfig  = require(game.ReplicatedStorage.AlohaShared.config.VehicleConfig)
local FactionConfig  = require(game.ReplicatedStorage.AlohaShared.config.FactionConfig)
local FactionService = require(script.Parent.FactionService)

local VehicleService = BaseService.new("VehicleService")

local CONFIG = {
  SPAWN_OFFSET    = Vector3.new(0, 4, 8),  -- relative to player HRP, in HRP's look direction
  REMOTE_COOLDOWN = 0.3,                    -- seconds between accepted remote calls per player
}

-- ── Internal state ────────────────────────────────────────────────────────────
local _vehicles           = {}  -- [player] = Model | nil
local _mounted            = {}  -- [player] = boolean
local _lastRemote         = {}  -- [player] = tick()
local _physicsConnections = {}  -- [player] = RBXScriptConnection
local _vehicleTypes       = {}  -- [player] = vehicleId string (for cfg lookup in loop)

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
  return Color3.fromRGB(255, 165, 80)
end

-- Builds a procedural placeholder hover-bike model and parents it to workspace.
-- Returns the Model with PrimaryPart set and all parts welded.
local function _buildPlaceholderBike(player, spawnCFrame)
  local colour = factionColourFor(player)

  local model = Instance.new("Model")
  model.Name = "HoverBike_" .. player.Name

  -- RootPart — main body (anchored during setup, unanchored after welds)
  local root = Instance.new("Part")
  root.Name       = "RootPart"
  root.Size       = Vector3.new(8, 3, 16)
  root.Color      = colour
  root.Material   = Enum.Material.SmoothPlastic
  root.Anchored   = true
  root.CastShadow = true
  root.Parent     = model

  -- Engine pod — left
  local podL = Instance.new("Part")
  podL.Name     = "Pod_L"
  podL.Shape    = Enum.PartType.Cylinder
  podL.Size     = Vector3.new(4, 3, 3)
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

  -- Attachment for physics constraints (Story 2)
  local attach = Instance.new("Attachment")
  attach.Name   = "ThrusterAttach"
  attach.Parent = root

  model.PrimaryPart = root
  model.Parent      = workspace
  model:PivotTo(spawnCFrame)

  -- Position parts relative to root's world CFrame, then weld
  local rootCF = root.CFrame
  podL.CFrame  = rootCF * CFrame.new(-4, -1, 0)
  podR.CFrame  = rootCF * CFrame.new( 4, -1, 0)
  seat.CFrame  = rootCF * CFrame.new( 0,  1.5, -2)

  local function weld(part)
    local w  = Instance.new("WeldConstraint")
    w.Part0  = root
    w.Part1  = part
    w.Parent = root
  end
  weld(podL)
  weld(podR)
  weld(seat)

  -- Safe to unanchor now — WeldConstraints keep geometry together
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
    return CFrame.new(0, 10, 0)
  end
  local lookUnit = hrp.CFrame.LookVector
  local offset   = lookUnit * CONFIG.SPAWN_OFFSET.Z
                 + Vector3.new(0, CONFIG.SPAWN_OFFSET.Y, 0)
  return CFrame.new(hrp.Position + offset) * CFrame.Angles(0, math.atan2(-lookUnit.X, -lookUnit.Z), 0)
end

-- Creates the VectorForce + AlignOrientation constraints and starts the
-- per-vehicle Heartbeat loop. Stores the connection in _physicsConnections.
local function _startPhysicsLoop(player, vehicle, vehicleId)
  local cfg  = VehicleConfig[vehicleId]
  local root = vehicle:FindFirstChild("RootPart")
  local thrusterAttach = root and root:FindFirstChild("ThrusterAttach")
  if not root or not thrusterAttach then
    warn("[VehicleService] _startPhysicsLoop: missing RootPart or ThrusterAttach for", player.Name)
    return
  end

  -- Upward lift force (XZ driven by Story 3 input)
  local vectorForce = Instance.new("VectorForce")
  vectorForce.Attachment0          = thrusterAttach
  vectorForce.RelativeTo           = Enum.ActuatorRelativeTo.World
  vectorForce.ApplyAtCenterOfMass  = false
  vectorForce.Force                = Vector3.zero
  vectorForce.Parent               = root

  -- Orientation alignment — Mode.OneAttachment lets us drive .CFrame directly in world space
  local alignOrientation = Instance.new("AlignOrientation")
  alignOrientation.Mode            = Enum.OrientationAlignmentMode.OneAttachment
  alignOrientation.Attachment0     = thrusterAttach
  alignOrientation.RigidityEnabled = false
  alignOrientation.Responsiveness  = 12
  alignOrientation.CFrame          = CFrame.identity
  alignOrientation.Parent          = root

  -- Exclude the vehicle itself from its own hover raycast
  local rayParams = RaycastParams.new()
  rayParams.FilterType = Enum.RaycastFilterType.Exclude
  rayParams.FilterDescendantsInstances = { vehicle }

  local conn = RunService.Heartbeat:Connect(function()
    -- Guard: vehicle may be destroyed between frames
    if not root or not root.Parent then return end

    -- 1. Altitude hold — PD controller via downward raycast
    local rayOrigin    = root.Position
    local rayDirection = Vector3.new(0, -(cfg.HOVER_HEIGHT + 2), 0)
    local rayResult    = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    local dist         = rayResult and rayResult.Distance or (cfg.HOVER_HEIGHT + 2)
    local hoverError   = cfg.HOVER_HEIGHT - dist
    local hoverForceY  = cfg.HOVER_FORCE * hoverError * 8

    -- 2. Idle bob — additive sine on Y axis
    local bobForce = math.sin(tick() * cfg.BOB_FREQUENCY * math.pi * 2) * cfg.BOB_AMPLITUDE * cfg.HOVER_FORCE

    -- 3. Apply combined vertical force:
    --    gravity feedforward cancels weight exactly; PD term + bob fine-tune altitude.
    --    Without feedforward the correction gain alone (~1600 max) can't lift vehicle mass.
    local gravityComp = root.AssemblyMass * workspace.Gravity
    vectorForce.Force = Vector3.new(0, gravityComp + hoverForceY + bobForce, 0)

    -- 4. Velocity tilt — lean toward direction of travel
    local vel = root.AssemblyLinearVelocity
    alignOrientation.CFrame = CFrame.Angles(
      -vel.Z * cfg.TILT_FACTOR,
       0,
       vel.X * cfg.TILT_FACTOR
    )

    -- 5. Max speed cap — server enforces ceiling every frame
    local speed = vel.Magnitude
    if speed > cfg.MAX_SPEED then
      root.AssemblyLinearVelocity = vel.Unit * cfg.MAX_SPEED
    end
  end)

  _physicsConnections[player] = conn
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

  _vehicles[player]     = model
  _vehicleTypes[player] = vehicleId

  _startPhysicsLoop(player, model, vehicleId)

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
-- Disconnects physics loop, dismounts if mounted, then removes the model.
function VehicleService.destroyVehicle(player)
  if _physicsConnections[player] then
    _physicsConnections[player]:Disconnect()
    _physicsConnections[player] = nil
  end

  if _mounted[player] then
    VehicleService.dismountPlayer(player)
  end

  local vehicle = _vehicles[player]
  if vehicle then
    vehicle:Destroy()
    _vehicles[player]     = nil
    _vehicleTypes[player] = nil
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
