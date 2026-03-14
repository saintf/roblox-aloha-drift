# Aloha Drift — Core Gameplay Loops

## Overview
Four interlocking loops provide variety and keep different player types engaged simultaneously. Every loop feeds the shared faction economy, creating interdependence between roles.

---

## Loop 1 — Lumicite Run (PvE + PvP)
**Primary roles:** Hauler (driver), Scrapper (interceptor), Runner (opportunist)

### Flow
1. Hauler flies to Lumicite Fields (low altitude, wide open)
2. Dismounts, loads crystal stacks onto barge (5–10s per stack, Crystal Net gadget helps)
3. Pilots slow barge back to home island — large and visible from a distance
4. At home base: dismounts, deposits crystals at Refinery (3s interaction)
5. Payout: personal coins + faction treasury

### Interception (PvP layer)
- Any rival player can use the Tether Hook gadget to latch onto the barge
- Tether lasts 8 seconds — attacker drags behind, then can "board" and steal one crystal stack
- Hauler can snap the tether by hitting Rocket Boost
- EMP Burst stuns the barge (vehicle stops, cargo vulnerable for 4s)
- If barge falls into ocean: crystal stacks become physics objects falling toward the sea — any player can fly through them to collect (first contact wins). Crystals that hit the ocean are lost permanently.

### Earnings
| Event | Personal | Faction |
|---|---|---|
| Small run (partial barge) | 80 coins | 80 coins |
| Full barge run | 300 coins | 300 coins |
| Intercepting a hauler | 100 coins | 50 coins |

---

## Loop 2 — Safe Raid (Stealth / Action)
**Primary roles:** Runner (attacker), any role (defender)

### Flow
1. Runner flies to enemy home island, dismounts at perimeter
2. Navigates to the safe on foot (avoid defenders, use Smoke Pop)
3. Equips Lockpick → triggers safe crack minigame
4. Minigame: 4-step Simon-says sequence, 15 seconds to complete
5. Getting spotted mid-crack: defender fires Wind Blaster → loot drops, hit counter increments
6. Successful crack: Runner runs back to vehicle, escapes to home island
7. Deposit at home base Refinery → payout

### Safe Crack Minigame (server-authoritative)
- 4-button sequence generated server-side, sent to client display-only
- Client sends back the sequence response; server validates timing and correctness
- Interruption rule: if a rival player gets within 10 studs, sequence resets (but lockpick is not consumed)
- Server never trusts client to report a successful crack — validation is entirely server-side

### Earnings
| Event | Personal | Faction |
|---|---|---|
| Successful safe raid | 200 coins | 200 coins |

---

## Loop 3 — Platform Capture (Passive Income)
**Primary roles:** Drifter, any role with a presence mid-map

### Flow
1. Fly to a contested sky platform (3 available: A, B, C)
2. Dismount and stand in the capture zone for 30 seconds
3. Platform flips to your faction — begins dripping income to faction treasury
4. Other factions can recapture (same 30s process)
5. While your faction holds the platform, you gain defender-mode Wind Blaster stats on it

### Earnings
| Event | Personal | Faction |
|---|---|---|
| Platform capture | 20 coins | 20 coins |
| Platform held (per minute) | 0 | 15 coins |

> **Design note:** Platform income is small individually but meaningful over a full session. Three platforms held for 20 minutes = 900 treasury coins — enough to unlock tier 2 faction perk.

---

## Loop 4 — World Event (All Factions)
**All roles, server-wide**

### Trigger
Server-side scheduler fires every 20 minutes. Runs regardless of player count.

### Flow
1. Server-wide announcement: fanfare sound + "DRIFT EVENT — MEGA DEPOSIT INCOMING" banner
2. Event Island becomes visible and accessible for 5 minutes
3. Large Lumicite deposit spawns — worth 3× a normal full barge run
4. All factions race to get a Hauler there, load crystals, and return to home base
5. First faction to deposit wins the payout + server-wide notification
6. Event Island disappears after 5 minutes regardless of outcome

### Earnings (winner only)
| | Personal | Faction |
|---|---|---|
| World Event win | 150 coins | 500 coins |

---

## Loop Interactions (emergent scenarios)
These are not programmed events — they emerge naturally from the loop design:

- **Decoy haul:** A Runner drops a Decoy Flare near the Lumicite Fields to look like a crystal stack on enemy minimaps, drawing Scrappers away from the real Hauler route
- **Coordinated raid:** Runner distracts defender (takes a wind hit deliberately), Drifter flanks the safe from the other side
- **Event island ambush:** Scrapper ignores the crystals entirely and EMP-blasts rival Haulers mid-route during the world event, letting their own Hauler return unopposed
- **Voluntary ocean escape:** A Runner being chased with 1 wind hit already taken jumps off the island edge intentionally — loses all loot but avoids the worse outcome of a 2-hit teleport with more loot stripped

---

## Earning Summary Table

| Action | Personal | Faction | Role |
|---|---|---|---|
| Full Lumicite run | 300 | 300 | Hauler |
| Small Lumicite run | 80 | 80 | Hauler |
| Safe raid success | 200 | 200 | Runner |
| Platform capture | 20 | 20 | Drifter |
| Platform held (per min) | 0 | 15 | Any |
| World Event win | 150 | 500 | Any |
| Hauler interception | 100 | 50 | Scrapper |
| Teammate repair (Wrenchhead) | 30 | 15 | Wrenchhead |
| Bounty collection | 50–200 | 25 | Any |
