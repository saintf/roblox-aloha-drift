-- BaseService.lua
-- Base class for all server-side services (and client-side controllers).
--
-- Usage:
--   local MyService = BaseService.new("MyService")
--   function MyService:init()  ... end   -- set up state, load config
--   function MyService:start() ... end   -- connect events, start loops
--
-- Rules:
--   init()  → runs first. Set up internal state. Do NOT connect events here.
--   start() → runs after all services have init'd. Connect RemoteEvents, bind Players events.
--   Never call teleportHome(), awardCoins(), etc. directly from another service's init().

local Logger = require(script.Parent.Parent.lib.Logger)

local BaseService = {}
BaseService.__index = BaseService

-- Creates a new service instance with a name and a bound logger.
-- Returns: BaseService instance
function BaseService.new(name)
  local self = setmetatable({}, BaseService)
  self.name    = name
  self.log     = Logger.forService(name)
  self._started = false
  return self
end

-- Override in subclass: set up internal state and config references.
function BaseService:init()
end

-- Override in subclass: connect RemoteEvents, start loops, bind to Players events.
function BaseService:start()
end

-- Called by init.server.lua / init.client.lua after all services are init'd.
-- Do not override this — override start() instead.
function BaseService:_start()
  assert(not self._started, self.name .. " already started")
  self:start()
  self._started = true
  self.log.info("started")
end

return BaseService
