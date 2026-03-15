-- VehicleController.lua
-- Handles client-side vehicle input, recall, beam VFX, and cooldown HUD.
-- Runs only on the local client. Server applies all forces.
--
-- Keybinds:
--   F              = spawn vehicle (server places it nearby, does NOT auto-mount)
--   E              = mount vehicle (when not mounted) / ascend (when mounted)
--   G or Space     = dismount
--   WASD           = move (camera-relative, only sent when mounted)
--   LeftShift      = descend (when mounted)
--   R (hold 0.3s)  = recall vehicle to player position
--   R2 / L2        = gamepad ascend / descend
--   Left stick     = gamepad move
--
-- Camera: left as CameraType.Custom. Roblox's built-in camera follows the
-- character who is welded to the seat.
--
-- Depends on: RemoteEvents

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris           = game:GetService("Debris")

local BaseService  = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)

local VehicleController = BaseService.new("VehicleController")

local CONFIG = {
  SEND_RATE         = 0.05,   -- seconds between VehicleMoveRequest fires (~20 Hz)
  DEADZONE          = 0.15,   -- gamepad thumbstick deadzone radius
  RECALL_HOLD_SECS  = 0.3,    -- how long R must be held to trigger recall
  RECALL_COOLDOWN   = 45,     -- must match server CONFIG.RECALL_COOLDOWN
}

-- ── State ─────────────────────────────────────────────────────────────────────
local _isMounted        = false
local _vehicleRootPart  = nil    -- set while mounted (cleared on dismount)
local _knownVehicleRoot = nil    -- persists through dismount so recall knows vehicle exists
local _lastSend         = 0
local _rKeyDownAt       = 0      -- tick() when R was pressed; 0 if not held
local _recallFiredAt    = 0      -- tick() of last recall fire (for client-side cooldown UI)

-- UI refs — set in init()
local _recallButton = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function hasVehicle()
  return _knownVehicleRoot ~= nil and _knownVehicleRoot.Parent ~= nil
end

local function recallCooldownRemaining()
  if _recallFiredAt == 0 then return 0 end
  return math.max(0, math.ceil(CONFIG.RECALL_COOLDOWN - (tick() - _recallFiredAt)))
end

local function fireRecall()
  RemoteEvents.VehicleRecallRequest:FireServer()
  _recallFiredAt = tick()
  warn("[VehicleController] ◎ RECALL request sent")
end

-- ── Input helpers ─────────────────────────────────────────────────────────────

local function keyboardInput()
  local UIS = UserInputService
  local x, z, y = 0, 0, 0
  if UIS:IsKeyDown(Enum.KeyCode.D)         then x =  1 end
  if UIS:IsKeyDown(Enum.KeyCode.A)         then x = -1 end
  if UIS:IsKeyDown(Enum.KeyCode.S)         then z =  1 end
  if UIS:IsKeyDown(Enum.KeyCode.W)         then z = -1 end
  if UIS:IsKeyDown(Enum.KeyCode.E)         then y =  1 end  -- ascend (when mounted)
  if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then y = -1 end  -- descend
  return Vector3.new(x, y, z)
end

local function gamepadInput()
  local gamepads = UserInputService:GetConnectedGamepads()
  if #gamepads == 0 then return Vector3.zero end

  local x, z, y = 0, 0, 0
  local state = UserInputService:GetGamepadState(gamepads[1])

  for _, inp in ipairs(state) do
    local kc = inp.KeyCode
    if kc == Enum.KeyCode.Thumbstick1 then
      local sx, sy = inp.Position.X, inp.Position.Y
      if math.abs(sx) > CONFIG.DEADZONE then x =  sx end
      if math.abs(sy) > CONFIG.DEADZONE then z = -sy end
    elseif kc == Enum.KeyCode.ButtonR2 then
      if inp.Position.Z > CONFIG.DEADZONE then y =  1 end
    elseif kc == Enum.KeyCode.ButtonL2 then
      if inp.Position.Z > CONFIG.DEADZONE then y = -1 end
    end
  end

  return Vector3.new(x, y, z)
end

local function buildInputVector()
  local kb  = keyboardInput()
  local gp  = gamepadInput()

  local rawX = math.clamp(kb.X + gp.X, -1, 1)
  local rawZ = math.clamp(kb.Z + gp.Z, -1, 1)
  local rawY = math.clamp(kb.Y + gp.Y, -1, 1)

  local camCF = workspace.CurrentCamera.CFrame
  local fwdXZ = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
  local rgtXZ = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

  local forward, right
  if fwdXZ.Magnitude > 0.01 then
    forward = fwdXZ.Unit
  elseif _vehicleRootPart then
    local lv = _vehicleRootPart.CFrame.LookVector
    forward  = Vector3.new(lv.X, 0, lv.Z).Unit
  else
    forward = Vector3.new(0, 0, -1)
  end
  right = rgtXZ.Magnitude > 0.01 and rgtXZ.Unit or forward:Cross(Vector3.new(0, 1, 0))

  local moveVec = (forward * -rawZ) + (right * rawX)
  if moveVec.Magnitude > 1 then moveVec = moveVec.Unit end

  return Vector3.new(moveVec.X, rawY, moveVec.Z)
end

-- ── Beam VFX ──────────────────────────────────────────────────────────────────

-- Creates the teal recall beam rising from the vehicle, plus an initial particle burst.
-- All instances are cleaned up automatically via Debris after `duration` seconds.
local function spawnRecallVFX(vehicleRoot, duration)
  if not vehicleRoot or not vehicleRoot.Parent then return end

  -- Bottom attachment at vehicle centre
  local a0 = Instance.new("Attachment")
  a0.Position = Vector3.new(0, 0, 0)
  a0.Parent   = vehicleRoot

  -- Top attachment 80 studs above in vehicle-local space (moves with vehicle during tween)
  local a1 = Instance.new("Attachment")
  a1.Position = Vector3.new(0, 80, 0)
  a1.Parent   = vehicleRoot

  local beam = Instance.new("Beam")
  beam.Attachment0  = a0
  beam.Attachment1  = a1
  beam.Color        = ColorSequence.new(Color3.fromRGB(0, 220, 200))
  beam.Width0       = 0.4
  beam.Width1       = 0
  beam.LightEmission = 1
  beam.FaceCamera   = true
  beam.Transparency = NumberSequence.new(0.2)
  beam.Parent       = vehicleRoot

  Debris:AddItem(a0,   duration)
  Debris:AddItem(a1,   duration)
  Debris:AddItem(beam, duration)

  -- Brief upward particle burst at vehicle position
  local pa = Instance.new("Attachment")
  pa.Parent = vehicleRoot

  local pe = Instance.new("ParticleEmitter")
  pe.Color        = ColorSequence.new(Color3.fromRGB(0, 220, 200))
  pe.LightEmission = 1
  pe.Size         = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.5),
    NumberSequenceKeypoint.new(1, 0),
  })
  pe.Lifetime     = NumberRange.new(0.5, 1.2)
  pe.Speed        = NumberRange.new(10, 25)
  pe.SpreadAngle  = Vector2.new(60, 60)
  pe.Parent       = pa
  pe:Emit(20)

  Debris:AddItem(pa, 2)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function VehicleController:init()
  local player    = Players.LocalPlayer
  local playerGui = player:WaitForChild("PlayerGui")

  local screenGui = Instance.new("ScreenGui")
  screenGui.Name           = "VehicleHUD"
  screenGui.ResetOnSpawn   = false
  screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  screenGui.Parent         = playerGui

  -- Recall button — doubles as cooldown indicator.
  -- Visible only when player has a vehicle and is not mounted.
  -- Keyboard: hold R for 0.3s. Mobile: tap this button.
  _recallButton = Instance.new("TextButton")
  _recallButton.Name              = "RecallButton"
  _recallButton.Size              = UDim2.new(0, 130, 0, 44)
  _recallButton.Position          = UDim2.new(0.5, -65, 1, -110)  -- bottom-centre
  _recallButton.BackgroundColor3  = Color3.fromRGB(0, 160, 140)
  _recallButton.BorderSizePixel   = 0
  _recallButton.Text              = "RECALL  [R]"
  _recallButton.TextColor3        = Color3.fromRGB(255, 255, 255)
  _recallButton.Font              = Enum.Font.GothamBold
  _recallButton.TextScaled        = true
  _recallButton.Visible           = false
  _recallButton.Parent            = screenGui

  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 10)
  corner.Parent       = _recallButton
end

function VehicleController:start()
  local RE = RemoteEvents

  -- ── Keybind handler ───────────────────────────────────────────────────────
  UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local kc = input.KeyCode

    if kc == Enum.KeyCode.F then
      RE.VehicleSpawnRequest:FireServer("hoverbike")

    elseif kc == Enum.KeyCode.E and not _isMounted then
      RE.VehicleMountRequest:FireServer()

    elseif kc == Enum.KeyCode.G and _isMounted then
      RE.VehicleDismountRequest:FireServer()

    elseif kc == Enum.KeyCode.R and not _isMounted then
      _rKeyDownAt = tick()  -- start hold timer
    end
  end)

  -- R key: fire recall only if held long enough (avoids accidental triggers)
  UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
      if _rKeyDownAt > 0 and (tick() - _rKeyDownAt) >= CONFIG.RECALL_HOLD_SECS then
        if hasVehicle() and not _isMounted and recallCooldownRemaining() == 0 then
          fireRecall()
        end
      end
      _rKeyDownAt = 0
    end
  end)

  -- Mobile recall button
  _recallButton.MouseButton1Click:Connect(function()
    if not hasVehicle() or _isMounted or recallCooldownRemaining() > 0 then return end
    fireRecall()
  end)

  -- ── Mount / dismount confirmation from server ─────────────────────────────
  RE.VehicleMountConfirm.OnClientEvent:Connect(function(isMounted, rootPart)
    _isMounted = isMounted

    if isMounted and rootPart then
      _vehicleRootPart  = rootPart
      _knownVehicleRoot = rootPart   -- persists through dismount for recall tracking
      warn("[VehicleController] ▶ MOUNTED confirmed | rootPart =", tostring(rootPart))
    else
      _vehicleRootPart = nil
      warn("[VehicleController] ■ DISMOUNTED confirmed")
      -- _knownVehicleRoot intentionally NOT cleared here:
      -- dismounting doesn't destroy the vehicle; player can still recall it
    end
  end)

  -- ── Beam VFX when recall begins ───────────────────────────────────────────
  RE.VehicleRecallStarted.OnClientEvent:Connect(function(vehicleRoot, duration)
    warn("[VehicleController] ◎ RECALL beam starting, duration =", duration)
    spawnRecallVFX(vehicleRoot, duration)
  end)

  -- ── Input send + UI update loop ───────────────────────────────────────────
  RunService.Heartbeat:Connect(function()
    -- Update recall button
    local showRecall = hasVehicle() and not _isMounted
    _recallButton.Visible = showRecall
    if showRecall then
      local cd = recallCooldownRemaining()
      local newText  = cd > 0 and ("RECALL  " .. cd .. "s") or "RECALL  [R]"
      local newColor = cd > 0 and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(0, 160, 140)
      if _recallButton.Text ~= newText then
        _recallButton.Text             = newText
        _recallButton.BackgroundColor3 = newColor
        _recallButton.Active           = cd == 0
      end
    end

    -- Send movement input to server at 20 Hz
    if not _isMounted then return end
    if not _vehicleRootPart or not _vehicleRootPart.Parent then return end

    local now = tick()
    if (now - _lastSend) < CONFIG.SEND_RATE then return end
    _lastSend = now

    RE.VehicleMoveRequest:FireServer(buildInputVector())
  end)
end

return VehicleController
