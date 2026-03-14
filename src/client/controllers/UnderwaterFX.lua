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
}

-- UI references — created in init(), used in start()
local tealOverlay    -- Frame: full-screen teal tint
local shimmerOverlay -- Frame: full-screen gold flash on arrival
local currentLabel   -- Frame: arrow image + "Current pulling you home…" text
local homeLabel      -- Frame: house image + "Home" text
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

  currentLabel = Instance.new("Frame")
  currentLabel.Name                   = "CurrentLabel"
  currentLabel.Size                   = UDim2.new(0.5, 0, 0.06, 0)
  currentLabel.Position               = UDim2.new(0.25, 0, 0.87, 0)
  currentLabel.BackgroundTransparency = 1
  currentLabel.BorderSizePixel        = 0
  currentLabel.ZIndex                 = 12
  currentLabel.Parent                 = gui

  local currentArrow = Instance.new("ImageLabel")
  currentArrow.Name                   = "CurrentArrow"
  currentArrow.Size                   = UDim2.new(0, 36, 1, 0)
  currentArrow.Position               = UDim2.new(0, 0, 0, 0)
  currentArrow.BackgroundTransparency = 1
  currentArrow.Image                  = "rbxassetid://85641268841502"
  currentArrow.ScaleType              = Enum.ScaleType.Fit
  currentArrow.ImageTransparency      = 1   -- starts invisible
  currentArrow.ZIndex                 = 12
  currentArrow.Parent                 = currentLabel

  local currentText = Instance.new("TextLabel")
  currentText.Name                   = "CurrentText"
  currentText.Size                   = UDim2.new(1, -44, 1, 0)
  currentText.Position               = UDim2.new(0, 44, 0, 0)
  currentText.BackgroundTransparency = 1
  currentText.Text                   = "Current pulling you home…"
  currentText.TextColor3             = Color3.new(1, 1, 1)
  currentText.TextScaled             = true
  currentText.Font                   = Enum.Font.GothamBold
  currentText.TextTransparency       = 1   -- starts invisible
  currentText.TextXAlignment         = Enum.TextXAlignment.Left
  currentText.ZIndex                 = 12
  currentText.Parent                 = currentLabel

  homeLabel = Instance.new("Frame")
  homeLabel.Name                   = "HomeLabel"
  homeLabel.Size                   = UDim2.new(0.3, 0, 0.08, 0)
  homeLabel.Position               = UDim2.new(0.35, 0, 0.44, 0)
  homeLabel.BackgroundTransparency = 1
  homeLabel.BorderSizePixel        = 0
  homeLabel.ZIndex                 = 13
  homeLabel.Parent                 = gui

  local homeIcon = Instance.new("ImageLabel")
  homeIcon.Name                   = "HomeIcon"
  homeIcon.Size                   = UDim2.new(0, 48, 1, 0)
  homeIcon.Position               = UDim2.new(0, 0, 0, 0)
  homeIcon.BackgroundTransparency = 1
  homeIcon.Image                  = "rbxassetid://99701014154548"
  homeIcon.ScaleType              = Enum.ScaleType.Fit
  homeIcon.ImageTransparency      = 1   -- starts invisible
  homeIcon.ZIndex                 = 13
  homeIcon.Parent                 = homeLabel

  local homeText = Instance.new("TextLabel")
  homeText.Name                   = "HomeText"
  homeText.Size                   = UDim2.new(1, -56, 1, 0)
  homeText.Position               = UDim2.new(0, 56, 0, 0)
  homeText.BackgroundTransparency = 1
  homeText.Text                   = "Home"
  homeText.TextColor3             = Color3.fromRGB(255, 240, 120)
  homeText.TextScaled             = true
  homeText.Font                   = Enum.Font.GothamBold
  homeText.TextTransparency       = 1   -- starts invisible
  homeText.TextXAlignment         = Enum.TextXAlignment.Left
  homeText.ZIndex                 = 13
  homeText.Parent                 = homeLabel
end

function UnderwaterFX:start()
  local camera = workspace.CurrentCamera

  local function tween(obj, props, duration)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
  end

  local function clearEffects()
    tween(tealOverlay, { BackgroundTransparency = 1 }, CFG.TINT_OUT_TIME)
    tween(currentLabel:FindFirstChild("CurrentArrow"), { ImageTransparency = 1 }, 0.2)
    tween(currentLabel:FindFirstChild("CurrentText"),  { TextTransparency = 1 }, 0.2)
    if labelTask then
      task.cancel(labelTask)
      labelTask = nil
    end
  end

  -- OceanContact: server confirms the player entered the water
  RemoteEvents.OceanContact.OnClientEvent:Connect(function()
    -- 1. Teal tint
    tween(tealOverlay, { BackgroundTransparency = CFG.TINT_ALPHA }, CFG.TINT_IN_TIME)

    -- 2. Gentle camera roll then return — purely cosmetic
    local rollRad = math.rad(CFG.CAMERA_ROLL_DEG)
    tween(camera, { CFrame = camera.CFrame * CFrame.Angles(0, 0, rollRad) }, CFG.CAMERA_ROLL_TIME)
    task.delay(CFG.CAMERA_ROLL_TIME, function()
      tween(camera, { CFrame = camera.CFrame * CFrame.Angles(0, 0, -rollRad) }, CFG.CAMERA_RETURN_TIME)
    end)

    -- 4. Schedule "current pulling you home" label
    labelTask = task.delay(CFG.LABEL_DELAY, function()
      tween(currentLabel:FindFirstChild("CurrentArrow"), { ImageTransparency = 0 }, 0.4)
      tween(currentLabel:FindFirstChild("CurrentText"),  { TextTransparency = 0 }, 0.4)
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

    -- TODO: arrival chime — swap in a real asset ID when available
    -- local chime = Instance.new("Sound")
    -- chime.SoundId = "rbxassetid://TODO"
    -- chime.Volume  = 0.7
    -- chime.Parent  = camera
    -- chime:Play()
    -- game:GetService("Debris"):AddItem(chime, 3)

    -- Home label — fade in icon and text together, then out
    tween(homeLabel:FindFirstChild("HomeIcon"), { ImageTransparency = 0 }, 0.15)
    tween(homeLabel:FindFirstChild("HomeText"), { TextTransparency = 0 }, 0.15)
    task.delay(1.5, function()
      tween(homeLabel:FindFirstChild("HomeIcon"), { ImageTransparency = 1 }, 0.5)
      tween(homeLabel:FindFirstChild("HomeText"), { TextTransparency = 1 }, 0.5)
    end)
  end)
end

return UnderwaterFX
