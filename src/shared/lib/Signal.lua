-- Signal.lua
-- Lightweight typed signal for decoupled service-to-service communication.
-- Prefer this over direct function calls between services for one-to-many notifications.
--
-- Usage:
--   local onPlayerDisplaced = Signal.new()
--   onPlayerDisplaced:Connect(function(player, reason) ... end)
--   onPlayerDisplaced:Fire(player, "wind")
--   onPlayerDisplaced:Destroy()  -- clean up when no longer needed

local Signal = {}
Signal.__index = Signal

-- Creates a new Signal backed by a BindableEvent.
-- Returns: Signal instance
function Signal.new()
  local self  = setmetatable({}, Signal)
  self._bindable = Instance.new("BindableEvent")
  self._event    = self._bindable.Event
  return self
end

-- Connects a callback function. Returns an RBXScriptConnection with :Disconnect().
function Signal:Connect(callback)
  return self._event:Connect(callback)
end

-- Fires the signal, passing any arguments to all connected callbacks.
function Signal:Fire(...)
  self._bindable:Fire(...)
end

-- Destroys the underlying BindableEvent. All connections are severed.
function Signal:Destroy()
  self._bindable:Destroy()
end

return Signal
