-- UnderwaterFX.lua
-- Applies client-side visual and audio effects when the player enters the ocean.
-- Listens for OceanContact (server→client) and DisplacementOccurred (server→client).
-- Pure cosmetic — never fires RemoteEvents, never reads/writes game state.
--
-- Depends on: RemoteEvents

local BaseService  = require(game.ReplicatedStorage.AlohaShared.classes.BaseService)
local RemoteEvents = require(game.ReplicatedStorage.AlohaShared.RemoteEvents)
local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local UnderwaterFX = BaseService.new("UnderwaterFX")

-- Config — tune freely before baking
local CFG = {
  TINT_COLOR         = Color3.fromRGB(0, 160, 195),  -- slightly warmer than default Roblox water
  TINT_ALPHA         = 0.55,                          -- overlay transparency when fully visible
  TINT_IN_TIME       = 0.4,                           -- seconds to fade tint in
  TINT_OUT_TIME      = 0.3,                           -- seconds to fade tint out on return
  LABEL_DELAY        = 4.0,                           -- seconds after ocean contact before label appears
  CAMERA_ROLL_DEG    = 5,                             -- degrees of Z-axis camera roll
  CAMERA_ROLL_TIME   = 0.5,                           -- seconds to reach max roll
  CAMERA_RETURN_TIME = 2.0,                           -- seconds to return camera to upright
  BUBBLE_SOUND_ID    = "rbxassetid://131070686",      -- placeholder bubble sound
}

-- UI references — created in init(), used in start()
local tealOverlay    -- Frame: full-screen teal tint
local shimmerOverlay -- Frame: full-screen gold flash on arrival
local currentLabel   -- TextLabel: "↑ Current pulling you home…"
local homeLabel      -- TextLabel: "✦ Home" on arrival
local labelTask      -- pending task.delay handle for the current label

function UnderwaterFX:init()
  local player    = Players.LocalPlayer
  local playerGui = player:WaitForChild("PlayerGui")

  local gui = Instance.new("ScreenGui")
  gui.Name              = "UnderwaterFXGui"
  gui.ResetOnSpawn      = false
  gui.IgnoreGuiInset    = true
  gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
  gui.Parent            = playerGui

  tealOverlay = Instance.new("Frame")
  tealOverlay.Name                   = "TealOverlay"
  tealOverlay.Size                   = UDim2.new(1, 0, 1, 0)
  tealOverlay.BackgroundColor3       = CFG.TINT_COLOR
  tealOverlay.BackgroundTransparency = 1   -- starts invisible
  tealOverlay.BorderSizePixel        = 0
  tealOverlay.ZIndex                 = 10
  tealOverlay.Parent                 = gui

  shimmerOverlay = Instance.new("Frame")
  shimmerOverlay.Name                   = "ShimmerOverlay"
  shimmerOverlay.Size                   = UDim2.new(1, 0, 1, 0)
  shimmerOverlay.BackgroundColor3       = Color3.fromRGB(255, 220, 80)
  shimmerOverlay.BackgroundTransparency = 1
  shimmerOverlay.BorderSizePixel        = 0
  shimmerOverlay.ZIndex                 = 11
  shimmerOverlay.Parent                 = gui

  currentLabel = Instance.new("TextLabel")
  currentLabel.Name                   = "CurrentLabel"
  currentLabel.Size                   = UDim2.new(0.5, 0, 0.05, 0)
  currentLabel.Position               = UDim2.new(0.25, 0, 0.88, 0)
  currentLabel.BackgroundTransparency = 1
  currentLabel.Text                   = "↑ Current pulling you home…"
  currentLabel.TextColor3             = Color3.new(1, 1, 1)
  currentLabel.TextScaled             = true
  currentLabel.Font                   = Enum.Font.GothamBold
  currentLabel.TextTransparency       = 1   -- starts invisible
  currentLabel.ZIndex                 = 12
  currentLabel.Parent                 = gui

  homeLabel = Instance.new("TextLabel")
  homeLabel.Name                   = "HomeLabel"
  homeLabel.Size                   = UDim2.new(0.3, 0, 0.06, 0)
  homeLabel.Position               = UDim2.new(0.35, 0, 0.45, 0)
  homeLabel.BackgroundTransparency = 1
  homeLabel.Text                   = "✦ Home"
  homeLabel.TextColor3             = Color3.fromRGB(255, 240, 120)
  homeLabel.TextScaled             = true
  homeLabel.Font                   = Enum.Font.GothamBold
  homeLabel.TextTransparency       = 1
  homeLabel.ZIndex                 = 13
  homeLabel.Parent                 = gui
end

function UnderwaterFX:start()
  local camera = workspace.CurrentCamera

  local bubbleSound = Instance.new("Sound")
  bubbleSound.SoundId = CFG.BUBBLE_SOUND_ID
  bubbleSound.Volume  = 0.6
  bubbleSound.Looped  = false
  bubbleSound.Parent  = camera

  local function tween(obj, props, duration)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
  end

  local function clearEffects()
    tween(tealOverlay, { BackgroundTransparency = 1 }, CFG.TINT_OUT_TIME)
    tween(currentLabel, { TextTransparency = 1 }, 0.2)
    if labelTask then
      task.cancel(labelTask)
      labelTask = nil
    end
  end

  -- OceanContact: server confirms the player entered the water
  RemoteEvents.OceanContact.OnClientEvent:Connect(function()
    -- 1. Teal tint
    tween(tealOverlay, { BackgroundTransparency = CFG.TINT_ALPHA }, CFG.TINT_IN_TIME)

    -- 2. Bubble sound
    bubbleSound:Play()

    -- 3. Gentle camera roll then return — purely cosmetic
    local rollRad = math.rad(CFG.CAMERA_ROLL_DEG)
    tween(camera, { CFrame = camera.CFrame * CFrame.Angles(0, 0, rollRad) }, CFG.CAMERA_ROLL_TIME)
    task.delay(CFG.CAMERA_ROLL_TIME, function()
      tween(camera, { CFrame = camera.CFrame * CFrame.Angles(0, 0, -rollRad) }, CFG.CAMERA_RETURN_TIME)
    end)

    -- 4. Schedule "current pulling you home" label
    labelTask = task.delay(CFG.LABEL_DELAY, function()
      tween(currentLabel, { TextTransparency = 0 }, 0.4)
    end)
  end)

  -- DisplacementOccurred: server confirms teleport home
  RemoteEvents.DisplacementOccurred.OnClientEvent:Connect(function()
    clearEffects()

    -- Gold shimmer flash
    tween(shimmerOverlay, { BackgroundTransparency = 0.45 }, 0.15)
    task.delay(0.15, function()
      tween(shimmerOverlay, { BackgroundTransparency = 1 }, 0.6)
    end)

    -- Chime sound
    local chime = Instance.new("Sound")
    chime.SoundId = "rbxassetid://172268609"  -- placeholder chime
    chime.Volume  = 0.7
    chime.Parent  = camera
    chime:Play()
    game:GetService("Debris"):AddItem(chime, 3)

    -- "✦ Home" label — fade in, then out
    tween(homeLabel, { TextTransparency = 0 }, 0.15)
    task.delay(1.5, function()
      tween(homeLabel, { TextTransparency = 1 }, 0.5)
    end)
  end)
end

return UnderwaterFX
