-- VehicleService.lua
-- Manages vehicle ownership, spawning, mounting, dismount, hover physics, and input.
-- Server-authoritative — clients send intent via RemoteEvents, server validates and applies.
--
-- Mount state is driven entirely by the Seat.Occupant watcher set up in spawnVehicle.
-- Both natural sitting (character walks into seat) and explicit mount (E key → VehicleMountRequest)
-- are handled by the same watcher, so _mounted[player] is always in sync with the actual seat.
--
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
  SPAWN_OFFSET    = Vector3.new(0, 4, 8),
  REMOTE_COOLDOWN = 0.3,
  ASCEND_ACCEL    = 8,    -- extra upward acceleration (studs/s²) when ascending
  ACCEL_BLEND     = 0.10, -- velocity lerp rate toward target when input held
  DECEL_BLEND     = 0.15, -- velocity lerp rate toward zero when coasting
}

-- ── Internal state ────────────────────────────────────────────────────────────
local _vehicles           = {}  -- [player] = Model | nil
local _mounted            = {}  -- [player] = boolean
local _lastRemote         = {}  -- [player] = tick()
local _physicsConnections = {}  -- [player] = Heartbeat RBXScriptConnection
local _seatConnections    = {}  -- [player] = Seat.Occupant RBXScriptConnection
local _vehicleTypes       = {}  -- [player] = vehicleId string
local _inputDir           = {}  -- [player] = Vector3  raw world-space direction (-1..1 per axis)
local _movesReceived      = {}  -- [player] = number  (throttles first-move debug log)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function rateLimitOk(player)
  local now  = tick()
  local last = _lastRemote[player] or 0
  if (now - last) < CONFIG.REMOTE_COOLDOWN then return false end
  _lastRemote[player] = now
  return true
end

local function factionColourFor(player)
  local factionId = FactionService.getPlayerFaction and FactionService.getPlayerFaction(player)
  if factionId then
    local faction = FactionConfig.factions[factionId]
    if faction and faction.primaryColor then return faction.primaryColor end
  end
  return Color3.fromRGB(255, 165, 80)
end

local function _buildPlaceholderBike(player, spawnCFrame)
  local colour = factionColourFor(player)

  local model = Instance.new("Model")
  model.Name = "HoverBike_" .. player.Name

  local root = Instance.new("Part")
  root.Name       = "RootPart"
  root.Size       = Vector3.new(8, 3, 16)
  root.Color      = colour
  root.Material   = Enum.Material.SmoothPlastic
  root.Anchored   = true
  root.CastShadow = true
  root.Parent     = model

  local podL = Instance.new("Part")
  podL.Name     = "Pod_L"
  podL.Shape    = Enum.PartType.Cylinder
  podL.Size     = Vector3.new(4, 3, 3)
  podL.Color    = Color3.fromRGB(60, 60, 60)
  podL.Material = Enum.Material.SmoothPlastic
  podL.Anchored = true
  podL.Parent   = model

  local podR = Instance.new("Part")
  podR.Name     = "Pod_R"
  podR.Shape    = Enum.PartType.Cylinder
  podR.Size     = Vector3.new(4, 3, 3)
  podR.Color    = Color3.fromRGB(60, 60, 60)
  podR.Material = Enum.Material.SmoothPlastic
  podR.Anchored = true
  podR.Parent   = model

  local seat = Instance.new("Seat")
  seat.Name     = "Seat"
  seat.Size     = Vector3.new(2, 1, 2)
  seat.Color    = Color3.fromRGB(40, 40, 40)
  seat.Anchored = true
  seat.Parent   = model

  local attach = Instance.new("Attachment")
  attach.Name   = "ThrusterAttach"
  attach.Parent = root

  model.PrimaryPart = root
  model.Parent      = workspace
  model:PivotTo(spawnCFrame)

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

  root.Anchored = false
  podL.Anchored = false
  podR.Anchored = false
  seat.Anchored = false

  CollectionService:AddTag(model, "AlohaVehicle")
  return model
end

local function spawnCFrameFor(player)
  local char = player.Character
  local hrp  = char and char:FindFirstChild("HumanoidRootPart")
  if not hrp then return CFrame.new(0, 10, 0) end
  local lookUnit = hrp.CFrame.LookVector
  local offset   = lookUnit * CONFIG.SPAWN_OFFSET.Z + Vector3.new(0, CONFIG.SPAWN_OFFSET.Y, 0)
  return CFrame.new(hrp.Position + offset) * CFrame.Angles(0, math.atan2(-lookUnit.X, -lookUnit.Z), 0)
end

local function _startPhysicsLoop(player, vehicle, vehicleId)
  local cfg            = VehicleConfig[vehicleId]
  local root           = vehicle:FindFirstChild("RootPart")
  local thrusterAttach = root and root:FindFirstChild("ThrusterAttach")
  if not root or not thrusterAttach then
    warn("[VehicleService] _startPhysicsLoop: missing RootPart or ThrusterAttach for", player.Name)
    return
  end

  -- VectorForce handles vertical only: gravity feedforward + hover PD + bob + ascend input.
  -- Horizontal movement is applied via AssemblyLinearVelocity (direct, guaranteed to work).
  local vectorForce = Instance.new("VectorForce")
  vectorForce.Attachment0         = thrusterAttach
  vectorForce.RelativeTo          = Enum.ActuatorRelativeTo.World
  vectorForce.ApplyAtCenterOfMass = true
  vectorForce.Force               = Vector3.zero
  vectorForce.Parent              = root

  local alignOrientation = Instance.new("AlignOrientation")
  alignOrientation.Mode            = Enum.OrientationAlignmentMode.OneAttachment
  alignOrientation.Attachment0     = thrusterAttach
  alignOrientation.RigidityEnabled = false
  alignOrientation.Responsiveness  = 10
  alignOrientation.CFrame          = CFrame.identity
  alignOrientation.Parent          = root

  local rayParams = RaycastParams.new()
  rayParams.FilterType = Enum.RaycastFilterType.Exclude
  rayParams.FilterDescendantsInstances = { vehicle }

  local conn = RunService.Heartbeat:Connect(function()
    if not root or not root.Parent then return end

    -- 1. Altitude hold — P controller
    local rayOrigin    = root.Position
    local rayDirection = Vector3.new(0, -(cfg.HOVER_HEIGHT + 2), 0)
    local rayResult    = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    local dist         = rayResult and rayResult.Distance or (cfg.HOVER_HEIGHT + 2)
    local hoverError   = cfg.HOVER_HEIGHT - dist
    local hoverForceY  = cfg.HOVER_FORCE * hoverError * 8

    -- 2. Idle bob
    local bobForce = math.sin(tick() * cfg.BOB_FREQUENCY * math.pi * 2) * cfg.BOB_AMPLITUDE * cfg.HOVER_FORCE

    -- 3. Vertical VectorForce: gravity + hover PD + bob + ascend
    local mass        = root.AssemblyMass
    local gravityComp = mass * workspace.Gravity
    local dir         = _inputDir[player] or Vector3.zero

    vectorForce.Force = Vector3.new(
      0,
      gravityComp + hoverForceY + bobForce + dir.Y * CONFIG.ASCEND_ACCEL * mass,
      0
    )

    -- 4. Horizontal: direct velocity control (lerp toward target speed)
    local curVel   = root.AssemblyLinearVelocity
    local targetX  = dir.X * cfg.MAX_SPEED
    local targetZ  = dir.Z * cfg.MAX_SPEED
    local hasInput = math.abs(dir.X) > 0.01 or math.abs(dir.Z) > 0.01
    local blend    = hasInput and CONFIG.ACCEL_BLEND or CONFIG.DECEL_BLEND

    local newVelX = curVel.X + (targetX - curVel.X) * blend
    local newVelZ = curVel.Z + (targetZ - curVel.Z) * blend

    local horizSq = newVelX * newVelX + newVelZ * newVelZ
    if horizSq > cfg.MAX_SPEED * cfg.MAX_SPEED then
      local s = cfg.MAX_SPEED / math.sqrt(horizSq)
      newVelX = newVelX * s
      newVelZ = newVelZ * s
    end

    root.AssemblyLinearVelocity = Vector3.new(newVelX, curVel.Y, newVelZ)

    -- 5. Cosmetic tilt proportional to velocity
    local vel = root.AssemblyLinearVelocity
    alignOrientation.CFrame = CFrame.Angles(
      -vel.Z * cfg.TILT_FACTOR,
       0,
       vel.X * cfg.TILT_FACTOR
    )
  end)

  _physicsConnections[player] = conn
end

-- Sets up the bidirectional Seat.Occupant watcher for a spawned vehicle.
-- Handles both natural sitting (walk into seat) and explicit mount (seat:Sit).
-- This is the single source of truth for _mounted[player].
local function _watchSeat(player, vehicle)
  local seat = vehicle:FindFirstChild("Seat")
  if not seat then
    warn("[VehicleService] _watchSeat: no Seat found in vehicle for", player.Name)
    return
  end

  if _seatConnections[player] then
    _seatConnections[player]:Disconnect()
  end

  _seatConnections[player] = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
    local occ = seat.Occupant

    if occ then
      -- ── Sit-down ──────────────────────────────────────────────────────────
      local sittingPlayer = Players:GetPlayerFromCharacter(occ.Parent)
      if sittingPlayer == player and not _mounted[player] then
        _mounted[player]  = true
        _inputDir[player] = nil
        local root = vehicle:FindFirstChild("RootPart") or vehicle.PrimaryPart
        RemoteEvents.VehicleMountConfirm:FireClient(player, true, root)
        warn("[VehicleService] ▶ MOUNTED:", player.Name,
             "| _mounted =", tostring(_mounted[player]))
      end

    else
      -- ── Stand-up / eject ──────────────────────────────────────────────────
      if _mounted[player] then
        _mounted[player]  = nil   -- clear FIRST to prevent any re-entry
        _inputDir[player] = nil

        -- Reposition character above vehicle so they land on top, not inside it
        local root = vehicle:FindFirstChild("RootPart")
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and root then
          hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
        end

        RemoteEvents.VehicleMountConfirm:FireClient(player, false, nil)
        warn("[VehicleService] ■ DISMOUNTED (seat vacated):", player.Name,
             "| _mounted =", tostring(_mounted[player]))
      end
    end
  end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Spawns the vehicle model and starts physics.  Does NOT auto-mount.
-- The seat watcher handles mount state when the player sits (naturally or via mountPlayer).
function VehicleService.spawnVehicle(player, vehicleId)
  if _vehicles[player] then
    warn("[VehicleService] spawnVehicle: player already has a vehicle, ignoring.", player.Name)
    return nil
  end
  if type(vehicleId) ~= "string" or not VehicleConfig[vehicleId] then
    warn("[VehicleService] spawnVehicle: unknown vehicleId:", tostring(vehicleId))
    return nil
  end

  local model = _buildPlaceholderBike(player, spawnCFrameFor(player))
  _vehicles[player]     = model
  _vehicleTypes[player] = vehicleId

  _startPhysicsLoop(player, model, vehicleId)
  _watchSeat(player, model)  -- bidirectional watcher, persists for vehicle lifetime

  warn("[VehicleService] ◆ SPAWNED vehicle for", player.Name, "(", vehicleId, ")",
       "| Press E to mount")
  return model
end

-- Force-seats the player in their vehicle via seat:Sit().
-- The _watchSeat listener handles _mounted and VehicleMountConfirm — nothing else needed here.
function VehicleService.mountPlayer(player)
  local vehicle = _vehicles[player]
  if not vehicle then
    warn("[VehicleService] mountPlayer: no vehicle for", player.Name)
    return
  end
  if _mounted[player] then
    warn("[VehicleService] mountPlayer: already mounted, ignoring.", player.Name)
    return
  end

  local seat = vehicle:FindFirstChild("Seat")
  if not seat then
    warn("[VehicleService] mountPlayer: vehicle has no Seat for", player.Name)
    return
  end
  if seat.Occupant then
    warn("[VehicleService] mountPlayer: seat already occupied for", player.Name)
    return
  end

  local char     = player.Character
  local humanoid = char and char:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    warn("[VehicleService] mountPlayer: no humanoid for", player.Name)
    return
  end

  warn("[VehicleService] → seat:Sit called for", player.Name)
  seat:Sit(humanoid)
  -- _watchSeat fires on Occupant change → sets _mounted = true → fires VehicleMountConfirm
end

-- Explicit server-side dismount (G key).
-- Clears _mounted BEFORE ejecting so the seat watcher is a no-op when it fires.
function VehicleService.dismountPlayer(player)
  if not _mounted[player] then
    warn("[VehicleService] dismountPlayer: not mounted, ignoring.", player.Name)
    return
  end

  warn("[VehicleService] ■ DISMOUNTING (explicit):", player.Name)
  _mounted[player]  = nil   -- clear FIRST — prevents watcher recursion
  _inputDir[player] = nil

  local vehicle = _vehicles[player]
  if vehicle then
    local seat = vehicle:FindFirstChild("Seat")
    if seat and seat.Occupant then
      seat.Disabled = true   -- ejects occupant; watcher fires but _mounted is nil → no-op
      seat.Disabled = false
    end

    local root = vehicle:FindFirstChild("RootPart")
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and root then
      hrp.CFrame = root.CFrame + Vector3.new(0, 5, 0)
    end
  end

  RemoteEvents.VehicleMountConfirm:FireClient(player, false, nil)
  warn("[VehicleService] ■ DISMOUNT done:", player.Name)
end

function VehicleService.getVehicle(player)
  return _vehicles[player]
end

function VehicleService.isMounted(player)
  return _mounted[player] == true
end

function VehicleService.destroyVehicle(player)
  if _physicsConnections[player] then
    _physicsConnections[player]:Disconnect()
    _physicsConnections[player] = nil
  end
  if _seatConnections[player] then
    _seatConnections[player]:Disconnect()
    _seatConnections[player] = nil
  end

  -- If mounted, tell the client before destroying
  if _mounted[player] then
    _mounted[player]  = nil
    _inputDir[player] = nil
    RemoteEvents.VehicleMountConfirm:FireClient(player, false, nil)
  end

  local vehicle = _vehicles[player]
  if vehicle then
    vehicle:Destroy()
    _vehicles[player]      = nil
    _vehicleTypes[player]  = nil
    _inputDir[player]      = nil
    _movesReceived[player] = nil
    warn("[VehicleService] ✕ DESTROYED vehicle for", player.Name)
  end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function VehicleService:init()
end

function VehicleService:start()
  local RE = RemoteEvents

  -- F key: spawn only (no auto-mount)
  RE.VehicleSpawnRequest.OnServerEvent:Connect(function(player, vehicleId)
    if not rateLimitOk(player) then return end
    if type(vehicleId) ~= "string" then return end
    VehicleService.spawnVehicle(player, vehicleId)
  end)

  -- E key (when not mounted): force-sit player in their vehicle
  RE.VehicleMountRequest.OnServerEvent:Connect(function(player)
    if not rateLimitOk(player) then return end
    VehicleService.mountPlayer(player)
  end)

  -- G key: explicit dismount
  RE.VehicleDismountRequest.OnServerEvent:Connect(function(player)
    if not rateLimitOk(player) then return end
    VehicleService.dismountPlayer(player)
  end)

  -- Move input: no time-based rate limit (client throttles to 20 Hz); magnitude guard is anti-exploit.
  RE.VehicleMoveRequest.OnServerEvent:Connect(function(player, inputVector)
    if not _mounted[player] then return end
    if typeof(inputVector) ~= "Vector3" then return end
    if inputVector.Magnitude > 1.5 then return end

    _inputDir[player] = inputVector

    local n = (_movesReceived[player] or 0) + 1
    _movesReceived[player] = n
    if n <= 3 then
      warn("[VehicleService] ✓ MoveRequest accepted:", player.Name, tostring(inputVector))
    end
  end)

  Players.PlayerRemoving:Connect(function(player)
    VehicleService.destroyVehicle(player)
    _lastRemote[player] = nil
  end)

  VehicleService.log.info("VehicleService started")
end

return VehicleService
