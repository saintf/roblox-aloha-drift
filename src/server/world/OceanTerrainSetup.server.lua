-- OceanTerrainSetup.server.lua
-- Fills Terrain Water for the ocean on server start.
--
-- WORKFLOW:
--   1. BAKED = false  → terrain is regenerated every run (tweaking mode)
--   2. When happy with the result: set BAKED = true, run once in Studio,
--      save the place file (File → Save to File), commit the .rbxl.
--      The terrain is now permanent geometry — this script becomes a no-op.
--
-- All tunable values are in CFG. Tweak freely, then bake.

local CFG = {
    BAKED = false,   -- ← flip to true once you're happy, then save + commit the .rbxl

    -- Ocean volume
    CENTER_Y     = -2,      -- Y centre of the water volume (surface ends up at Y=0)
    WIDTH        = 4000,    -- X extent in studs
    DEPTH        = 100,       -- how many studs thick the water volume is
    LENGTH       = 4000,    -- Z extent in studs

    -- Optional: clear existing terrain before filling
    -- Set true while tweaking so old fills don't stack up
    CLEAR_FIRST  = true,
}

-- Early exit if already baked into the place file
if CFG.BAKED then
    print("[OceanTerrainSetup] BAKED = true — skipping terrain generation")
    return
end

local terrain = workspace.Terrain

if CFG.CLEAR_FIRST then
    -- Clear only the ocean region, not the whole world
    terrain:FillBlock(
        CFrame.new(0, CFG.CENTER_Y, 0),
        Vector3.new(CFG.WIDTH, CFG.DEPTH, CFG.LENGTH),
        Enum.Material.Air      -- fill with Air = clear
    )
end

-- Fill with Water
terrain:FillBlock(
    CFrame.new(0, CFG.CENTER_Y, 0),
    Vector3.new(CFG.WIDTH, CFG.DEPTH, CFG.LENGTH),
    Enum.Material.Water
)

print(string.format(
    "[OceanTerrainSetup] Ocean filled — %.0f × %.0f studs, surface at Y=0. Tweak CFG then set BAKED=true when done.",
    CFG.WIDTH, CFG.LENGTH
))
