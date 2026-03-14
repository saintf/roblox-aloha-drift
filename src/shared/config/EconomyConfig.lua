-- EconomyConfig.lua
-- All earning rates, spending costs, and progression thresholds.
-- Units: coins = Drift Coins, xp = XP points, minutes = real minutes

local EconomyConfig = {
  -- Earning rates (personal share — faction gets the same amount via 50/50 split)
  EARN = {
    LUMICITE_FULL_RUN    = 300,
    LUMICITE_PARTIAL_RUN = 80,
    SAFE_RAID            = 200,
    PLATFORM_CAPTURE     = 20,
    PLATFORM_PER_MINUTE  = 15,   -- faction treasury only
    WORLD_EVENT_WIN      = 150,
    HAULER_INTERCEPT     = 100,
    REPAIR_TEAMMATE      = 30,
    BOUNTY_MIN           = 50,
    BOUNTY_MAX           = 200,
  },

  -- Vehicle upgrade costs (coin path — XP path defined in XP table below)
  VEHICLE_COST = {
    TIER_2 = 800,
    TIER_3 = 2400,
    TIER_4 = 6000,
  },

  -- XP thresholds per role tier
  XP_TIER = {
    [1] = 0,
    [2] = 500,
    [3] = 1500,
    [4] = 3500,
    [5] = 8000,
  },

  -- Faction treasury perk costs
  PERK_COST = {
    SIGNAL_BUOY   = 1000,
    BOOST_PAD     = 2500,
    PARTY_CANNON  = 5000,
    HOLO_DECOY    = 10000,
  },
}

return EconomyConfig
