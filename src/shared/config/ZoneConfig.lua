-- ZoneConfig.lua
-- Zone type identifiers and tag attribute names.
-- ZoneService reads these to determine wind context, combat rules, and spawn routing.
-- Each island Model in Workspace must have these Instance Attributes set on its root:
--   Attribute "ZoneType"  → one of the ZONE_TYPE values below
--   Attribute "ZoneOwner" → factionId string (or "" for neutral/unowned)

local ZoneConfig = {
  ZONE_TYPE = {
    HOME      = "home",       -- faction spawn island — defender wind stats apply
    NEUTRAL   = "neutral",    -- no faction owns this — attacker wind stats apply
    PLATFORM  = "platform",   -- contested — owner gets defender stats on it
    FIELDS    = "fields",     -- Lumicite Fields — always attacker stats
    MARKET    = "market",     -- no combat zone — Wind Blaster disabled
    OCEAN     = "ocean",      -- below world — triggers DisplacementService
  },

  -- Attribute names to read from Model instances in Workspace
  ATTR_ZONE_TYPE  = "ZoneType",
  ATTR_ZONE_OWNER = "ZoneOwner",

  -- Y coordinate below which a player is considered in the ocean
  OCEAN_Y = 2,
}

return ZoneConfig
