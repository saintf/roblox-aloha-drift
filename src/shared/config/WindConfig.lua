-- WindConfig.lua
-- All Wind Blaster tuning values.
-- Units: force = studs (impulse), cooldown = seconds, cone = degrees, window = seconds
-- Edit these values during playtesting — do NOT hardcode them in GadgetService
-- or DisplacementService.

local WindConfig = {
  defender = {
    FORCE     = 28,    -- push distance in studs
    COOLDOWN  = 2.5,   -- seconds between blasts
    CONE_DEG  = 70,    -- arc width of the blast cone
    RANGE     = 12,    -- max range in studs
    LOOT_DROP = 0.20,  -- fraction of carried loot dropped per hit
    THRESHOLD = 2,     -- hits within WINDOW before teleport triggers
    WINDOW    = 20,    -- seconds the hit counter remains active
  },
  attacker = {
    FORCE     = 12,
    COOLDOWN  = 5.0,
    CONE_DEG  = 60,
    RANGE     = 10,
    LOOT_DROP = 0.15,
    THRESHOLD = 3,
    WINDOW    = 30,
  },
}

return WindConfig
