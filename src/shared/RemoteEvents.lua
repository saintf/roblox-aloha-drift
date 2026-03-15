-- RemoteEvents.lua
-- Creates and exposes all RemoteEvents and RemoteFunctions.
-- SERVER: this module is required in init.server.lua which triggers instance creation.
-- CLIENT: require this to get references to already-existing instances.
-- NEVER use raw string literals for remote names anywhere else in the codebase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- Remote definitions: name → class
-- Add a comment on each describing the payload shape.
local REMOTES = {
  -- Gadget activation: client requests a gadget use
  -- Payload: (gadgetId: string, targetInfo: table)
  GadgetActivate = "RemoteEvent",

  -- Displacement: server tells client to play displacement VFX
  -- Payload: (displaceType: "wind"|"ocean"|"boundary")
  DisplacementOccurred = "RemoteEvent",

  -- Ocean contact: SERVER fires to CLIENT to trigger underwater VFX
  -- (Server detects swimming via Humanoid.StateChanged — client does not send this)
  -- Payload: none
  OceanContact = "RemoteEvent",

  -- Safe crack: client requests to begin cracking a safe
  -- Payload: (safeId: string)
  SafeCrackRequest = "RemoteEvent",

  -- Safe crack: client submits their sequence attempt
  -- Payload: (attempt: {number})
  SafeCrackSubmit = "RemoteEvent",

  -- Safe crack: server sends sequence display to client (display-only, never trusted)
  -- Payload: (sequence: {number})
  ShowSequence = "RemoteEvent",

  -- Economy: server pushes updated wallet/XP to the client HUD
  -- Payload: (coins: number, xp: table)
  EconomyUpdate = "RemoteEvent",

  -- Faction: server pushes updated treasury to all faction members
  -- Payload: (treasury: number, perks: table)
  FactionUpdate = "RemoteEvent",

  -- World event: server announces a world event to all clients
  -- Payload: (eventType: string, timeRemaining: number)
  WorldEventAnnounce = "RemoteEvent",

  -- Vehicle: client requests to spawn their vehicle
  -- Payload: (vehicleId: string)
  VehicleSpawnRequest = "RemoteEvent",

  -- Vehicle: client requests to dismount from their current vehicle
  -- Payload: none
  VehicleDismountRequest = "RemoteEvent",

  -- Vehicle: client sends movement intent to server each input tick
  -- Payload: (inputVector: Vector3)
  --   inputVector.X = world-space strafe  (-1 to 1)
  --   inputVector.Z = world-space fwd/back (-1 to 1, negative = forward)
  --   inputVector.Y = ascend/descend       (-1, 0, or 1)
  VehicleMoveRequest = "RemoteEvent",

  -- Vehicle: client requests to mount (sit in) their current vehicle
  -- Payload: none
  VehicleMountRequest = "RemoteEvent",

  -- Vehicle: server confirms mount state change to client
  -- Payload: (isMounted: boolean, vehicleRootPart: BasePart | nil)
  VehicleMountConfirm = "RemoteEvent",
}

-- Create or find the container folder
local container = ReplicatedStorage:FindFirstChild("AlohaRemotes")
if not container then
  container = Instance.new("Folder")
  container.Name = "AlohaRemotes"
  container.Parent = ReplicatedStorage
end

-- Create instances for any that don't exist yet, then expose on the module table
for name, class in pairs(REMOTES) do
  if not container:FindFirstChild(name) then
    local remote = Instance.new(class)
    remote.Name = name
    remote.Parent = container
  end
  RemoteEvents[name] = container:FindFirstChild(name)
end

return RemoteEvents
