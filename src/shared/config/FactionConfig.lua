-- FactionConfig.lua
-- Faction identifiers, colours, and role defaults.
-- Add future factions (Stormveil, Bloomcraft) here when server sizes increase.

local FactionConfig = {
  factions = {
    solaris = {
      id          = "solaris",
      displayName = "Solaris",
      primaryColor   = Color3.fromRGB(255, 120, 60),   -- coral
      secondaryColor = Color3.fromRGB(255, 210, 80),   -- gold
      spawnIsland = "SolarisBase",                     -- Model name in Workspace
    },
    tidalwave = {
      id          = "tidalwave",
      displayName = "Tidalwave",
      primaryColor   = Color3.fromRGB(40, 180, 200),   -- teal
      secondaryColor = Color3.fromRGB(230, 245, 255),  -- ocean white
      spawnIsland = "TidalwaveBase",
    },
  },

  -- Maximum player count imbalance before auto-assign overrides friend join
  MAX_IMBALANCE = 1,
}

return FactionConfig
