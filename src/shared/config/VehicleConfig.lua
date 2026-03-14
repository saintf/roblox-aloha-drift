-- VehicleConfig.lua
-- Stats for all five hover vehicles.
-- Units: speed = studs/s, hover = studs above ground, tiltFactor = radians per stud/s
-- All values consumed by VehicleService — never hardcoded in vehicle scripts.

local VehicleConfig = {
  hoverbike = {
    MAX_SPEED     = 90,
    HOVER_HEIGHT  = 3,
    HOVER_FORCE   = 200,
    TILT_FACTOR   = 0.20,
    BOB_AMPLITUDE = 0.08,
    BOB_FREQUENCY = 2,
    EMP_HITS      = 2,    -- hits to disable
    CAPACITY      = 1,
  },
  hoverbarge = {
    MAX_SPEED     = 25,
    HOVER_HEIGHT  = 4,
    HOVER_FORCE   = 350,
    TILT_FACTOR   = 0.05,
    BOB_AMPLITUDE = 0.04,
    BOB_FREQUENCY = 1,
    EMP_HITS      = 5,
    CAPACITY      = 1,
    CARGO_HOLDS   = 4,
  },
  hoverskiff = {
    MAX_SPEED     = 70,
    HOVER_HEIGHT  = 3.5,
    HOVER_FORCE   = 190,
    TILT_FACTOR   = 0.18,
    BOB_AMPLITUDE = 0.07,
    BOB_FREQUENCY = 2,
    EMP_HITS      = 3,
    CAPACITY      = 1,
  },
  hoverquad = {
    MAX_SPEED     = 55,
    HOVER_HEIGHT  = 4,
    HOVER_FORCE   = 280,
    TILT_FACTOR   = 0.10,
    BOB_AMPLITUDE = 0.05,
    BOB_FREQUENCY = 1.5,
    EMP_HITS      = 5,
    CAPACITY      = 1,
  },
  hoversurfboard = {
    MAX_SPEED     = 38,
    HOVER_HEIGHT  = 2.5,
    HOVER_FORCE   = 160,
    TILT_FACTOR   = 0.08,
    BOB_AMPLITUDE = 0.04,
    BOB_FREQUENCY = 1.5,
    EMP_HITS      = 3,
    CAPACITY      = 1,
  },
}

return VehicleConfig
