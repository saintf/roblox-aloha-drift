-- VehicleController.lua
-- Handles client-side vehicle input and server communication.
-- Runs only on the local client. Server applies all forces.
--
-- Keybinds:
--   F           = spawn vehicle (server places it nearby, does NOT auto-mount)
--   E           = mount vehicle (when not mounted) / ascend (when mounted)
--   G or Space  = dismount (G sends explicit request; Space ejects via Roblox Seat default)
--   WASD        = move (camera-relative, only sent when mounted)
--   LeftShift   = descend (when mounted)
--   R2 / L2     = gamepad ascend / descend
--   Left stick  = gamepad move
--
-- Camera: left as CameraType.Custom throughout.
-- Roblox's built-in camera follows the character who is welded to the seat.
--
-- Depends on: RemoteEvents

local BaseService      = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents     = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VehicleController = BaseService.new("VehicleController")

local CONFIG = {
  SEND_RATE = 0.05,   -- seconds between VehicleMoveRequest fires (~20 Hz)
  DEADZONE  = 0.15,   -- gamepad thumbstick deadzone radius
}

-- ── State ─────────────────────────────────────────────────────────────────────
local _isMounted       = false
local _vehicleRootPart = nil   -- BasePart received from server on mount confirm
local _lastSend        = 0

-- ── Input helpers ─────────────────────────────────────────────────────────────

-- Keyboard: X=strafe, Z=fwd/back (-1=forward), Y=ascend/descend.
-- E is ascend when mounted (also used for mount-request when not mounted via InputBegan).
-- Space is intentionally omitted — Roblox Seat ejects on jump, which counts as dismount.
local function keyboardInput()
  local UIS = UserInputService
  local x, z, y = 0, 0, 0
  if UIS:IsKeyDown(Enum.KeyCode.D)         then x =  1 end
  if UIS:IsKeyDown(Enum.KeyCode.A)         then x = -1 end
  if UIS:IsKeyDown(Enum.KeyCode.S)         then z =  1 end
  if UIS:IsKeyDown(Enum.KeyCode.W)         then z = -1 end
  if UIS:IsKeyDown(Enum.KeyCode.E)         then y =  1 end  -- ascend
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
      if math.abs(sy) > CONFIG.DEADZONE then z = -sy end  -- up = forward = -Z
    elseif kc == Enum.KeyCode.ButtonR2 then
      if inp.Position.Z > CONFIG.DEADZONE then y =  1 end
    elseif kc == Enum.KeyCode.ButtonL2 then
      if inp.Position.Z > CONFIG.DEADZONE then y = -1 end
    end
  end

  return Vector3.new(x, y, z)
end

-- Camera-relative world-space direction, magnitude ≤ ~sqrt(2).
-- Falls back to vehicle heading if camera is pointing near-vertical.
local function buildInputVector()
  local kb  = keyboardInput()
  local gp  = gamepadInput()

  local rawX = math.clamp(kb.X + gp.X, -1, 1)
  local rawZ = math.clamp(kb.Z + gp.Z, -1, 1)
  local rawY = math.clamp(kb.Y + gp.Y, -1, 1)

  local camCF  = workspace.CurrentCamera.CFrame
  local fwdXZ  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
  local rgtXZ  = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

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

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function VehicleController:init()
end

function VehicleController:start()
  local RE = RemoteEvents

  -- ── Keybind handler ───────────────────────────────────────────────────────
  UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local kc = input.KeyCode

    if kc == Enum.KeyCode.F then
      -- Spawn vehicle nearby (server handles duplicate spawns gracefully)
      RE.VehicleSpawnRequest:FireServer("hoverbike")

    elseif kc == Enum.KeyCode.E and not _isMounted then
      -- Mount: force-sit in our vehicle (E is ascend when already mounted)
      RE.VehicleMountRequest:FireServer()

    elseif kc == Enum.KeyCode.G and _isMounted then
      -- Explicit dismount
      RE.VehicleDismountRequest:FireServer()
    end
  end)

  -- ── Mount / dismount confirmation from server ─────────────────────────────
  -- Camera is intentionally left as CameraType.Custom.
  -- The built-in camera follows the character who is welded to the seat.
  RE.VehicleMountConfirm.OnClientEvent:Connect(function(isMounted, rootPart)
    _isMounted       = isMounted
    _vehicleRootPart = rootPart or nil

    if isMounted then
      warn("[VehicleController] ▶ MOUNTED confirmed by server | rootPart =",
           tostring(rootPart))
    else
      warn("[VehicleController] ■ DISMOUNTED confirmed by server")
    end
  end)

  -- ── Input send loop (20 Hz, only when mounted) ────────────────────────────
  RunService.Heartbeat:Connect(function()
    if not _isMounted then return end
    if not _vehicleRootPart or not _vehicleRootPart.Parent then return end

    local now = tick()
    if (now - _lastSend) < CONFIG.SEND_RATE then return end
    _lastSend = now

    RE.VehicleMoveRequest:FireServer(buildInputVector())
  end)
end

return VehicleController
