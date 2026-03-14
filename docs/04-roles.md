# Aloha Drift — Roles

## Overview
Players choose a role within their faction. Each role has its own XP track, vehicle progression, and gadget unlocks. Roles are chosen at spawn and can be changed at the home base or Drift Market (Role Flex gamepass allows free mid-session switching).

## Role Roster

### Runner
- **Primary income:** Raiding safes, collecting bounties
- **Vehicle:** Hover-bike (fast, agile, fragile)
- **Default gadgets:** Rocket Booster (vehicle), Lockpick (on-foot)
- **Unique ability:** Sprint dash — brief speed burst on demand
- **Unlock path:** Tether Hook (tier 2), Decoy Flare (tier 3)
- **Playstyle:** High risk, high reward. The primary raiding role.

### Hauler
- **Primary income:** Lumicite crystal deliveries
- **Vehicle:** Hover-barge (slow, high capacity, tanky)
- **Default gadgets:** Shield Bubble (vehicle), Crystal Net (on-foot)
- **Unique ability:** Magnet tether — pulls nearby loose crystals toward barge
- **Unlock path:** Beacon Pulse (tier 2 — marks safe route on team map)
- **Playstyle:** Steady income, team-critical. The economic backbone.

### Drifter
- **Primary income:** Platform captures, territorial control
- **Vehicle:** Hover-skiff (agile open-cockpit, best manoeuvrability)
- **Default gadgets:** Rocket Booster (vehicle), Smoke Pop (on-foot)
- **Unique ability:** Grapple hook — latch to terrain for rapid repositioning
- **Unlock path:** Sensor Ping (tier 2), terrain grapple upgrade (tier 3)
- **Playstyle:** Roamer and skirmisher. Controls the mid-map.

### Scrapper
- **Primary income:** Intercepting haulers, bounties
- **Vehicle:** Hover-quad (armoured, medium speed, wide EMP range)
- **Default gadgets:** EMP Burst (vehicle), Smoke Pop (on-foot)
- **Unique ability:** EMP pulse — stuns target vehicle for 4 seconds
- **Unlock path:** Magnet Grab (tier 3 — pull a crystal stack 10 studs toward you)
- **Playstyle:** Disruptor and interceptor. The anti-hauler specialist.

### Wrenchhead
- **Primary income:** Repairing teammates, supporting operations
- **Vehicle:** Hover-surfboard (wide, stable, slow, distinctive silhouette)
- **Default gadgets:** Shield Bubble (vehicle), Repair Beam (on-foot)
- **Unique ability:** Repair beam — restores boost capacity and removes stun from teammates
- **Unlock path:** Rally Beacon (tier 2 — pings teammates to location with map marker)
- **Playstyle:** Support. Great entry role for newer or younger players. Earns steadily without direct combat.

> **Design note:** Wrenchhead on a hover-surfboard is visually immediately readable. Wide, slow, teal-trimmed board with a repair toolkit strapped to the deck. Nobody confuses it for a combat vehicle.

## XP & Tier Progression

Each role has 5 tiers. Progression is per-role and persists across sessions via DataStore.

| Tier | XP Required | Unlocks |
|---|---|---|
| 1 — Starter | 0 (free) | Base vehicle, default colour, 1 gadget slot |
| 2 — Seasoned | 500 XP | +10% speed or capacity, new decal option, gadget upgrade |
| 3 — Veteran | 1,500 XP | Passive perk unlocks, second gadget variant option |
| 4 — Elite | 3,500 XP | Visual glow upgrade, +15% stat boost |
| 5 — Legend | 8,000 XP | Unique legendary vehicle skin, title badge, second on-foot gadget slot |

### XP Sources (per role)
- **Runner:** +50 XP per successful safe crack, +20 XP per bounty collected
- **Hauler:** +40 XP per crystal stack delivered, +80 XP per full barge run
- **Drifter:** +60 XP per platform capture, +10 XP per minute holding a platform
- **Scrapper:** +35 XP per hauler interception, +25 XP per crystal stack stolen
- **Wrenchhead:** +30 XP per repair, +50 XP per shield generator repair

### Gamepass Acceleration
The "Drift Legacy" gamepass skips the player to tier 2 on their **first unlock only** — a head-start, not a skip to the end.

## Silhouette Rule
All five vehicles must be instantly distinguishable as 32×32 pixel thumbnails. Before finalising any Meshy asset, screenshot it, scale to 32×32, and ask: "Can I tell what this is?"

| Vehicle | Silhouette key |
|---|---|
| Hover-bike | Narrow, aggressive, leans forward |
| Hover-surfboard | Wide, flat, low profile |
| Hover-barge | Large, rectangular, cargo holds visible |
| Hover-skiff | Open cockpit, swept-back fins |
| Hover-quad | Four corner pods, chunky and square |
