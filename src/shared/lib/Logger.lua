-- Logger.lua
-- Structured logging with service context and level filtering.
--
-- Usage:
--   local log = Logger.forService("MyService")
--   log.debug("hit counter:", n)   -- suppressed in production
--   log.info("player joined")
--   log.warn("unexpected nil for userId:", id)
--   log.error("DataStore write failed:", err)

local Logger = {}

local LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

-- Change to LEVELS.INFO before public release to suppress debug output
local MIN_LEVEL = LEVELS.DEBUG

local function formatMsg(service, level, ...)
  local parts = { string.format("[%s][%s]", level, service) }
  for _, v in ipairs({ ... }) do
    table.insert(parts, tostring(v))
  end
  return table.concat(parts, " ")
end

-- Returns a logger bound to a specific service name.
-- Returns: table with .debug, .info, .warn, .error functions
function Logger.forService(serviceName)
  return {
    debug = function(...)
      if MIN_LEVEL <= LEVELS.DEBUG then
        print(formatMsg(serviceName, "DEBUG", ...))
      end
    end,
    info = function(...)
      if MIN_LEVEL <= LEVELS.INFO then
        print(formatMsg(serviceName, "INFO", ...))
      end
    end,
    warn = function(...)
      if MIN_LEVEL <= LEVELS.WARN then
        warn(formatMsg(serviceName, "WARN", ...))
      end
    end,
    error = function(...)
      if MIN_LEVEL <= LEVELS.ERROR then
        error(formatMsg(serviceName, "ERROR", ...), 2)
      end
    end,
  }
end

return Logger
