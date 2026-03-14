# Aloha Drift — Gadgets

## System Overview
Every player carries two gadget slots:
- **Vehicle gadget** — used while mounted on a hover vehicle
- **On-foot gadget** — used while dismounted on any island surface

Vehicle gadgets auto-deactivate on dismount. On-foot gadgets auto-holster on mount. Gadgets use cooldowns, not ammo. All effects are temporary — no gadget eliminates a player outright.

Gadgets are swapped at home base or Drift Market only — not mid-flight.

---

## Vehicle Gadgets

### EMP Burst
| Property | Value |
|---|---|
| Default role | Scrapper |
| Cooldown | 18 seconds |
| Range | 18 studs radius |
| Effect | Stuns all enemy vehicles for 4 seconds |
| Visual tell | 1-second orange charge-up glow before firing (telegraphed) |
| Counter | Dash out of range during charge-up |

### Tether Hook
| Property | Value |
|---|---|
| Unlock | Runner tier 2 |
| Cooldown | 22 seconds |
| Range | 30 studs |
| Effect | Fires grapple to hauler barge; attacker drags behind for 8s, then can steal one crystal stack |
| Visual tell | Visible cable between vehicles; "TETHERED" UI alert on target |
| Counter | Hauler hits Rocket Boost to snap cable |

### Shield Bubble
| Property | Value |
|---|---|
| Default role | Hauler, Wrenchhead |
| Cooldown | 25 seconds |
| Duration | 5 seconds |
| Range | 10-stud radius dome around vehicle |
| Effect | Deflects EMP pulses; slows ramming vehicles on contact |
| Visual | Teal dome; expires with pop effect |

### Sensor Ping
| Property | Value |
|---|---|
| Unlock | Drifter tier 2 |
| Cooldown | 30 seconds |
| Range | 120 studs |
| Effect | Reveals all enemy vehicle positions to your team's minimap for 10 seconds |
| Visual | Expanding ring pulse from vehicle |

### Rocket Booster
| Property | Value |
|---|---|
| Available | All roles (tier 1 alternative) |
| Cooldown | 15 seconds |
| Duration | 3 seconds |
| Effect | Triples thrust, ignores drag; visible exhaust trail |
| Note | Does not affect turn radius — can't out-turn with boost active |

---

## On-Foot Gadgets

### Wind Blaster *(universal — all roles always carry this)*
The Wind Blaster is the universal on-foot defensive/offensive gadget. It replaces any concept of a weapon — no projectile, no hit animation, just a cone of visible wind that physically moves players.

See `08-displacement-system.md` for full Wind Blaster balance details.

| Context | Push Force | Cooldown | Cone | Loot Drop | Threshold |
|---|---|---|---|---|---|
| Defender (home/held platform) | 28 studs | 2.5s | 70°, 12-stud range | 20% per hit | 2 hits / 20s |
| Attacker / neutral | 12 studs | 5.0s | 60°, 10-stud range | 15% per hit | 3 hits / 30s |

**Context rule:** Stats are determined by the *firing player's* location, not the target's. Standing on your own faction's home island or a platform your faction holds = defender mode.

**Friendly fire:** Never applies to teammates (server validates faction match before applying force).

**Sound:** Cartoon whoosh + boing. Faction-coloured wind burst visual.

---

### Lockpick
| Property | Value |
|---|---|
| Default role | Runner |
| Cooldown | None (minigame-gated) |
| Effect | Enables the safe crack minigame UI |
| Visual | Subtle sparkle VFX visible only to nearby players (not global alert) |
| Note | Without a Lockpick equipped, the safe interaction prompt does not appear |
| Upgrade | Tier 3 Runner: faster-tier pick (minigame sequence shows 0.5s longer) |

### Repair Beam
| Property | Value |
|---|---|
| Default role | Wrenchhead |
| Cooldown | 8 seconds |
| Range | 12 studs |
| Channel time | 3 seconds (must stand still) |
| Effect | Restores teammate vehicle boost capacity; removes stun effects; can repair base shield generator |
| XP | Wrenchhead gains 30 XP per successful repair |

### Crystal Net
| Property | Value |
|---|---|
| Unlock | Hauler tier 2 |
| Cooldown | 20 seconds |
| Duration | 12 seconds |
| Effect | Traps a loose crystal stack in place — rivals cannot pick it up |
| Visual | Glowing net mesh over the crystal stack |
| Use case | Hold a dropped stack until your barge arrives |

### Decoy Flare
| Property | Value |
|---|---|
| Unlock | Runner tier 3 |
| Cooldown | 35 seconds |
| Duration | 20 seconds |
| Effect | Appears as a crystal stack on enemy minimaps |
| Visual | Glowing flare physically visible up close — not a perfect illusion |
| Use case | Draw Scrappers away from real hauler route |

### Smoke Pop
| Property | Value |
|---|---|
| Available | All roles (tier 2) |
| Cooldown | 20 seconds |
| Duration | 6 seconds |
| Effect | Faction-coloured smoke cloud, 8-stud radius, obscures vision |
| Note | Purely visual — no damage, no slow |
| Use case | Break line-of-sight during safe crack; escape cover during platform capture |

---

## Role Default Loadouts

| Role | Vehicle Gadget | On-Foot Gadget | Key Unlock |
|---|---|---|---|
| Runner | Rocket Booster | Lockpick | Tether Hook (T2), Decoy Flare (T3) |
| Hauler | Shield Bubble | Crystal Net (T2, starter: none) | Beacon Pulse (T2) |
| Drifter | Rocket Booster | Smoke Pop | Sensor Ping (T2), terrain grapple (T3) |
| Scrapper | EMP Burst | Smoke Pop | Magnet Grab (T3) |
| Wrenchhead | Shield Bubble | Repair Beam | Rally Beacon (T2) |

## Server Architecture
All gadgets follow the same pattern — client requests, server validates and executes:

```lua
-- Client fires: ReplicatedStorage.GadgetActivate:FireServer(gadgetId, targetInfo)
-- Server:
--   1. Validate cooldown (os.clock() timestamp check)
--   2. Validate player state (mounted/dismounted, alive, in correct zone)
--   3. Execute effect server-side
--   4. Broadcast result to relevant clients (VFX, UI alerts)
--   5. Update cooldown timestamp

playerGadgets[userId] = {
  vehicleGadget = "EMPBurst",
  footGadget    = "Lockpick",
  cooldowns = {
    EMPBurst  = 0,  -- os.clock() of last use
    Lockpick  = 0,
    WindBlaster = 0,
  },
}
-- Cooldown check: if os.clock() - lastUsed < cooldownDuration then reject
```

## On-Foot Scenarios

| Scenario | Role | Gadget Used | Duration |
|---|---|---|---|
| Safe crack raid | Runner | Lockpick → minigame | 15–20s |
| Crystal loading at Fields | Hauler | Crystal Net (hold stack) | 5–10s per stack |
| Crystal deposit at refinery | Hauler | Walk-up interaction | 3s |
| Platform capture | Drifter | Stand in zone (no gadget) | 30s |
| Repairing base shield | Wrenchhead | Repair Beam | 8s channel |
| Evading pursuit on enemy base | Any | Smoke Pop | Escape window |
| Defending against raider | Any | Wind Blaster | Continuous |
