# Aloha Drift — Displacement & Consequence System

## Core Philosophy
There is no death in Aloha Drift. Every dangerous situation resolves through a **displacement chain** — a sequence of escalating consequences that always ends in a cheerful teleport home. The player loses current progress but never feels harshly punished — back in the action within 3 seconds.

The teleport is the game's consequence system. It works identically regardless of cause: wind blast, ocean fall, or voluntary jump. Consistency is more important than leniency.

---

## Displacement Flow

```
Safe territory → Wind hit / fall → Loot drops (partial) → Threshold reached? → Teleport home ✦
```

---

## Trigger Conditions

| Trigger | Context | Loot Fate |
|---|---|---|
| Fall into ocean | Any — on foot or vehicle | All carried loot returned to rightful owner |
| Fall below world boundary | Any | Same as ocean |
| Wind Blaster threshold (defender: 2 hits / 20s) | On foot, enemy base | Loot returned, partial dropped on floor |
| Wind Blaster threshold (attacker: 3 hits / 30s) | On foot, any location | Same |
| Single wind hit (own/neutral territory) | On foot | Push only — no teleport, no loot loss |
| Knocked off vehicle by EMP + fall into ocean | Vehicle destroyed mid-air | Crystal cargo spills, player teleports |
| Voluntary ocean jump | Player choice | Same as forced ocean fall — no exceptions |

> **Key rule:** A single wind blast in enemy territory knocks back and drops loot — but teleport only triggers after the threshold. Skilled players have a fighting chance to recover and escape.

---

## Wind Blaster Stats (recap from 07-gadgets.md)

| Stat | Defender mode | Attacker mode |
|---|---|---|
| Push force | 28 studs | 12 studs |
| Cooldown | 2.5 seconds | 5.0 seconds |
| Cone | 70°, 12 studs | 60°, 10 studs |
| Loot drop per hit | 20% | 15% |
| Teleport threshold | 2 hits in 20s | 3 hits in 30s |

Context is determined by the **firing player's** location:
- Own home island → defender mode
- Contested platform your faction holds → defender mode
- Enemy island, neutral zones, unowned platforms → attacker mode

---

## Loot Rules

### What counts as "loot"
- **Safe coins** (stolen from enemy safe) → returned to enemy faction treasury on displacement
- **Crystal stacks** (harvested Lumicite) → returned to the *original harvesting faction's* storage, regardless of who stole them mid-transit
- **Captured platform income** → already deposited per-tick; nothing to lose
- **Personal wallet coins** → **never lost** on displacement — only *undeposited run earnings* are at risk

> **Fairness rule:** Coins already deposited at your base are always safe. The risk is only on what you're actively carrying. This makes the deposit-run loop meaningful without being brutal.

### Dropped loot piles (on-island)
| State | Duration | Who can collect |
|---|---|---|
| Freshly dropped (wind hit) | 20 seconds | Any player — first contact wins |
| Uncollected after 20s | Instant auto-return | Returned to rightful faction treasury |
| Crystals falling from barge | Until ocean contact | Any player mid-air |
| Crystals hit ocean | Instant | Lost permanently — nobody gets them |

---

## Scenario Breakdown

### Raider hit twice by defender (defender wins)
1. Hit 1: pushed 28 studs, 20% loot drops at hit location as glowing pile
2. Hit 2 (within 20s): pushed again, another 20% drops — threshold reached
3. Teleport triggers: cheerful swirl VFX, cartoon whoosh, player arrives at home spawn
4. All remaining loot returned to enemy faction treasury instantly
5. Dropped piles remain on the island 20s for defenders to collect
- **Total loot stripped:** ~36% dropped + 64% auto-returned
- **Time to resolution:** ~5 seconds

### Raider dodges first shot, eats second (raider might escape)
1. Raider dodges hit 1 — defender on 2.5s cooldown
2. Brief window to sprint to safe, start crack, or recall vehicle
3. If hit again before escaping: threshold reached → teleport
4. If escaped: raider keeps most loot

### Falls into ocean (any cause)
1. Ocean surface `Touched` → splash particles, screen tints teal, bubble sounds
2. All carried loot flagged server-side — 5s grace window (loot not yet returned)
3. 0–4s: underwater wonder sequence (fish, possible mermaid)
4. 4–5s: upward current UI indicator
5. 5s: player teleports to nearest friendly island spawn with pop + bubble burst
6. Loot returned to rightful owners

### Hauler barge destroyed mid-air
1. Barge stunned by EMP, begins falling
2. Crystal cargo spills — each stack becomes a physics object falling toward ocean
3. Any player (any faction) can fly through falling crystals to collect
4. Crystals reaching ocean: permanently lost — creates urgency to catch them
5. Hauler player teleports to nearest friendly island

### Voluntary ocean jump (escape tactic)
Same rules as forced fall. Lose all carried loot, 5s wonder window, teleport home.
This is an intentional emergent behaviour — a panic button for skilled players.
> **Tip (shown in onboarding):** "The ocean is always a way out — but you'll lose what you're carrying."

---

## Arrival Experience (teleport home)
The teleport must feel like a comic pratfall, not a punishment screen.

| Moment | Audio | Visual |
|---|---|---|
| Wind blast hit | Cartoon whoosh + boing | Faction-coloured burst, player spins slightly |
| Loot dropping | Coins scatter sound | Glowing pile, small bounce animation |
| Hit 2 warning | Gentle warning chime | Small "2/3" icon pulses at screen edge |
| Teleport trigger | Cheerful ascending tone | Teal swirl engulfs player (1s) |
| Arriving home | Soft landing whomp | Sparkle burst at spawn, 3s golden shimmer |

### Invincibility window
3 seconds of invincibility on arrival at home spawn — **non-negotiable.**
Without it a defender could chain-blast a newly returned player immediately.
The golden shimmer communicates the window clearly to all players.

---

## DisplacementService Architecture

Centralise ALL teleport/loot logic in one `ModuleScript`. Every displacement trigger routes through this single module.

```lua
-- DisplacementService (ModuleScript, server-side)

DisplacementService.onWindHit(player, attackerTeam)
  -- 1. Determine context (server zone check on player position)
  -- 2. Apply VectorForce impulse to HumanoidRootPart
  -- 3. If enemy territory: dropLoot(player, cfg.lootDrop)
  -- 4. incrementHitCounter(player, cfg.threshold, cfg.window)
  -- 5. If hits >= threshold: teleportHome(player)

DisplacementService.onOceanContact(player)
  -- 1. Flag loot for return (5s grace)
  -- 2. FireClient: start underwater FX
  -- 3. task.delay(5, function() teleportHome(player) end)

DisplacementService.teleportHome(player)
  -- 1. returnAllLoot(player)
  -- 2. CFrame player to faction spawn point
  -- 3. Grant 3s invincibility flag (checked by all damage/push handlers)
  -- 4. FireClient: play arrival VFX + sound

DisplacementService.returnAllLoot(player)
  -- Iterate player loot table
  -- Safe coins → enemy faction treasury
  -- Crystals → original harvesting faction storage
  -- Clear player loot table

-- Hit counter with decay window
playerState[userId] = {
  windHits      = 0,
  firstHitTime  = 0,
  invincible    = false,
  invincibleUntil = 0,
}

-- On each wind hit in enemy/neutral territory:
if os.clock() - firstHitTime > cfg.window then
  windHits = 1        -- window expired, reset
  firstHitTime = os.clock()
else
  windHits += 1
end
if windHits >= cfg.threshold then teleportHome(player) end
```

### Config table (single source of truth)
```lua
local WIND = {
  defender = { force=28, cooldown=2.5, cone=70, lootDrop=0.20, threshold=2, window=20 },
  attacker = { force=12, cooldown=5.0, cone=60, lootDrop=0.15, threshold=3, window=30 },
}
```
All tuning numbers live here. During playtesting, only this table changes.

---

## Tuning Guide

| If this feels wrong | Adjust | Direction |
|---|---|---|
| Raiding is basically impossible | Defender teleport threshold | Raise 2 → 3 hits |
| Raiding is too easy | Defender push force | Raise 28 → 34 studs |
| Two defenders too oppressive | Defender cooldown | Raise 2.5s → 3.0s |
| Platform fights feel chaotic | Neutral push force | Lower 12 → 9 studs |
| Smoke Pop makes raiding trivial | Smoke duration | Lower 6s → 4s |
| Solo defending feels hopeless | Loot drop per hit | Raise 20% → 25% |
| Pushes feel cheap | Wind blast visual tell | Extend charge-up 0.3s → 0.6s |
| Bases never get raided | Base layout | Add cover objects for dodging angles |

> **Do not equalise** defender and attacker stats. The asymmetry is the design. Tune the skill ceiling, not the advantage.
