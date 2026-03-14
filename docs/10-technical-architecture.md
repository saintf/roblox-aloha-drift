# Aloha Drift — Technical Architecture

## Guiding Principles
1. **Server-authoritative** — clients request actions, servers validate and execute. Never trust the client with numbers.
2. **One module per system** — DisplacementService, EconomyService, GadgetService, VehicleService. Single responsibility, easy to test.
3. **Config tables at the top** — all tunable numbers in named tables, never buried in logic.
4. **Build foundation first** — DisplacementService before vehicles, EconomyService before rewards.

---

## Service Architecture

```
ServerScriptService/
  Services/
    DisplacementService.lua   ← Build FIRST
    EconomyService.lua        ← Build SECOND  
    GadgetService.lua
    VehicleService.lua
    FactionService.lua
    EventScheduler.lua
    ZoneService.lua           ← Territory detection
    BountyService.lua

ReplicatedStorage/
  RemoteEvents/
    GadgetActivate            ← client → server request
    DisplacementOccurred      ← server → client VFX trigger
    OceanContact              ← client → server (ocean Touched)
    SafeCrackRequest          ← client → server
    SafeCrackSubmit           ← client → server
    ShowSequence              ← server → client (display only)
    EconomyUpdate             ← server → client (coin/XP display)
    FactionUpdate             ← server → client (treasury display)
    WorldEventAnnounce        ← server → all clients

StarterPlayerScripts/
  LocalScripts/
    VehicleController.lua     ← input handling only, no physics state
    UnderwaterFX.lua
    HUDController.lua
    GadgetHUD.lua

ModuleScripts/ (shared)
  Config/
    WindConfig.lua
    VehicleConfig.lua
    EconomyConfig.lua
    ZoneConfig.lua
```

---

## Core Services

### DisplacementService *(build first)*
Centralises ALL teleport and loot-loss logic. Every displacement trigger routes here.

```lua
-- Key functions:
DisplacementService.onWindHit(player, firerTeam)
DisplacementService.onOceanContact(player)
DisplacementService.onBelowWorldBoundary(player)
DisplacementService.teleportHome(player)
DisplacementService.returnAllLoot(player)
DisplacementService.grantInvincibility(player, duration)
DisplacementService.isInvincible(player) → boolean
```

### EconomyService *(build second)*
All coin and XP transactions. Single source of truth for all earnings.

```lua
-- Key functions:
EconomyService.awardCoins(player, amount, source)
  -- splits 50/50 to personal wallet and faction treasury
  -- fires EconomyUpdate RemoteEvent to client
  -- saves to DataStore (debounced, max 1 write per 6s per player)

EconomyService.awardXP(player, role, amount)
  -- adds to roleXP[role]
  -- checks for tier unlock
  -- fires XP notification to client

EconomyService.transferToFaction(factionId, amount, source)
  -- adds to in-memory faction treasury
  -- checks snowball prevention (2× cap rule)
  -- fires FactionUpdate to all faction members
```

### ZoneService *(required by Displacement and Gadget)*
Territory detection — determines which zone a world position belongs to.

```lua
-- Zone tags: each island has an invisible Part with attribute "ZoneOwner" = factionId
-- and "ZoneType" = "home" | "neutral" | "platform" | "fields" | "ocean"

ZoneService.getZone(worldPosition) → { owner: factionId|nil, type: string }
ZoneService.isEnemyTerritory(player) → boolean
ZoneService.getWindConfig(firingPlayer) → WIND.defender | WIND.attacker
```

### VehicleService
Manages vehicle spawning, recall, EMP stun state, and cargo.

```lua
VehicleService.spawnVehicle(player, vehicleId)
VehicleService.recallVehicle(player)          ← 45s cooldown
VehicleService.stunVehicle(vehicle, duration) ← used by EMP
VehicleService.isStunned(vehicle) → boolean
VehicleService.addCargo(vehicle, crystalStack)
VehicleService.spillCargo(vehicle)            ← called on barge destroy
```

### GadgetService
Validates and executes all gadget activations.

```lua
GadgetService.activate(player, gadgetId, targetInfo)
  -- 1. Validate cooldown
  -- 2. Validate player state (mounted/dismounted)
  -- 3. Validate target (range, faction, line-of-sight)
  -- 4. Execute effect
  -- 5. Update cooldown timestamp
  -- 6. Fire client VFX event
```

### EventScheduler
Server-side timed world events.

```lua
-- Runs on a 20-minute loop
-- Fires WorldEventAnnounce to all clients
-- Spawns Event Island crystals
-- Tracks which faction deposits first
-- Awards treasury payout to winner
```

---

## Vehicle Physics Pattern

```lua
-- In VehicleService or a vehicle ModuleScript
-- Uses VectorForce + AlignOrientation constraints

local VEHICLE_CONFIG = {
  hoverbike = {
    hoverHeight  = 3,
    hoverForce   = 200,
    tiltFactor   = 0.20,
    maxSpeed     = 90,
    bobAmplitude = 0.08,
    bobFrequency = 2,
  },
  -- ... other vehicles
}

-- Heartbeat loop (server-side, per active vehicle):
game:GetService("RunService").Heartbeat:Connect(function()
  local cfg = VEHICLE_CONFIG[vehicleType]
  
  -- Altitude hold (PD controller)
  local ray = workspace:Raycast(root.Position, Vector3.new(0, -(cfg.hoverHeight + 2), 0))
  local dist = ray and ray.Distance or (cfg.hoverHeight + 2)
  local error = cfg.hoverHeight - dist
  vectorForce.Force = Vector3.new(0, cfg.hoverForce * error * 8, 0)
  
  -- Idle bob
  local bob = math.sin(tick() * cfg.bobFrequency) * cfg.bobAmplitude
  -- applied as additional Y offset in force calculation
  
  -- Tilt toward velocity
  local vel = root.AssemblyLinearVelocity
  alignOrientation.CFrame = CFrame.Angles(
    -vel.Z * cfg.tiltFactor,
    0,
    vel.X * cfg.tiltFactor
  )
end)
```

---

## Safe Crack Minigame (server-authoritative)

```lua
-- Entirely server-side generation and validation

RE.SafeCrackRequest.OnServerEvent:Connect(function(player, safeObj)
  -- Validate distance (player within 10 studs of safe)
  -- Validate player has Lockpick equipped
  -- Validate safe not already being cracked
  -- Generate 4-step sequence server-side
  local seq = {}
  for i = 1, 4 do seq[i] = math.random(1, 4) end
  -- Store sequence in server state (NOT sent in full to client)
  -- Send display hint to client only
  RE.ShowSequence:FireClient(player, seq)
  -- Start 15s timeout
end)

RE.SafeCrackSubmit.OnServerEvent:Connect(function(player, attempt)
  -- Validate player still within 10 studs
  -- Validate within 15s timeout
  -- Compare attempt to stored sequence
  -- If correct: award coins, broadcast "safe cracked" to faction
  -- If incorrect: fire failure VFX, reset (lockpick not consumed)
end)

-- Interruption check (runs on Heartbeat during active crack):
-- If any rival player gets within 10 studs of the cracking player → reset sequence
```

---

## DataStore Pattern

```lua
-- Debounced saves (max 1 write per 6 seconds per player)
-- Load on PlayerAdded, save on PlayerRemoving + periodic autosave every 60s

local DataStoreService = game:GetService("DataStoreService")
local playerStore = DataStoreService:GetDataStore("PlayerData_v1")

-- On PlayerAdded:
local data = playerStore:GetAsync(player.UserId) or DEFAULT_DATA
-- Validate and migrate schema if needed

-- On PlayerRemoving:
playerStore:SetAsync(player.UserId, playerData[player.UserId])

-- Autosave loop (every 60s):
for _, player in ipairs(Players:GetPlayers()) do
  pcall(function()
    playerStore:SetAsync(player.UserId, playerData[player.UserId])
  end)
end
```

> **Schema versioning:** Use `"PlayerData_v1"` as the DataStore name. When breaking schema changes are needed, increment to `"PlayerData_v2"` and write a migration function.

---

## RemoteEvent Security Rules

1. **Never trust client-reported positions** — always calculate server-side
2. **Never trust client-reported coin amounts** — server calculates all rewards
3. **Rate-limit all RemoteEvents** — reject if same player fires >10x per second
4. **Validate every parameter** — check types, ranges, and game state before acting
5. **Log suspicious activity** — repeated invalid requests should trigger a flag

---

## Anti-Cheat Foundations

Build from day one:
- **Speed check:** If player's velocity exceeds `maxSpeed * 1.3` server-side, flag + clamp
- **Position validation:** If player teleports more than 50 studs per tick without a server-initiated CFrame, flag
- **Economy validation:** All coin/XP grants go through EconomyService — no direct DataStore writes from any other script
- **Cooldown authority:** Server maintains all cooldown timestamps — client UI is display-only

---

## Development Build Order

See `10-development-roadmap.md` for the full sprint breakdown.

Short version:
1. `DisplacementService` + ocean fall + home teleport
2. `EconomyService` + DataStore + basic HUD
3. Hover vehicle physics (one vehicle, hover-bike)
4. `ZoneService` + map skeleton (placeholder islands)
5. Wind Blaster gadget (uses all three above)
6. Safe crack minigame
7. Crystal hauling loop
8. Full gadget suite
9. Faction perks + world events
10. Polish, balance, monetisation hooks
