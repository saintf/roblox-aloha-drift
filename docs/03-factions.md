# Aloha Drift — Factions

## Overview
Factions are the core social unit of Aloha Drift. Players join a faction on entry and compete for resources, territory, and dominance. The faction system scales from 2 teams at launch to 4 teams on larger servers.

## Launch Factions (2)

### Solaris
- **Colours:** Coral / gold
- **Theme:** Sun-worshippers with volcanic tech
- **Vehicle style:** Fast but fragile, warm colour schemes
- **Speciality:** Raiding and speed

### Tidalwave
- **Colours:** Teal / ocean white
- **Theme:** Ocean engineers
- **Vehicle style:** Heavier, tankier, cool colour schemes
- **Speciality:** Hauling and defence

## Future Factions (server size permitting)
- **Stormveil** — lightning / purple — speed and disruption
- **Bloomcraft** — nature / green — support and area control

## Joining & Balance
- New players are auto-assigned to the faction with the fewest members **and** lowest collective XP
- If a player has a Roblox friend already in the server, they are offered "join their faction?" — auto-assigned if faction balance allows (within ±1 player count)
- Players cannot switch factions mid-session

### Party / Friend System (server-side)
```lua
-- On player join:
-- 1. Call Players:GetFriendsAsync(newPlayer.UserId)
-- 2. Cross-reference with current server population
-- 3. If friend found in a faction AND abs(factionA.size - factionB.size) <= 1:
--    offer join prompt to new player
-- 4. Otherwise: auto-assign to smaller/weaker faction
```

## Faction Economy

### Split Rule
Every earning event splits 50/50:
- **50% → player's personal wallet** (persisted via DataStore)
- **50% → faction treasury** (session-only, resets each server)

### Treasury Usage
The faction treasury funds team-level upgrades and perks. It resets each server session so teams always rebuild — this keeps the game fresh and prevents permanent dominant factions.

## Faction Perks (Team Research)
Perks are fun and flavourful — not game-breaking. They enhance the experience without making it overwhelming for opponents.

| Tier | Perk | Effect |
|---|---|---|
| 1 | Signal Buoy | Radar ping shows enemy haulers on minimap for 60s |
| 2 | Drift Boost Pad | Deployable launch ramp on home island (speed boost) |
| 3 | Party Cannon | Confetti cannon that briefly slows intruders (fun, mild) |
| 4 | Holo-Decoy | Spawn a decoy hauler barge that looks real for 30s |

> **Design note:** Perks are unlocked in order. Tier 1 costs ~1,000 treasury coins. Each tier roughly doubles in cost. No perk changes core balance enough to make the game unwinnable for opponents.

## Faction Identity in the World
- Home island visual theme matches faction colours and aesthetic
- Vehicles default to faction colour scheme (customisable with cosmetics)
- Wind Blaster fires faction-coloured wind burst
- Teleport arrival sparkle is faction-coloured
- Faction name and treasury total shown on leaderboard display boards at Drift Market
