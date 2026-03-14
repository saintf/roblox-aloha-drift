# Aloha Drift — Economy & Monetisation

## Currency: Drift Coins
Single in-game currency. Earned through gameplay, spent on vehicles and upgrades.

- **Personal wallet** — persisted via DataStore across sessions
- **Faction treasury** — session-only, resets each server (teams always rebuild)
- **Split rule** — every earning event: 50% personal, 50% faction treasury

---

## Earning Rates

| Action | Personal | Faction | Role |
|---|---|---|---|
| Full Lumicite run (full barge) | 300 | 300 | Hauler |
| Small Lumicite run (partial) | 80 | 80 | Hauler |
| Safe raid success | 200 | 200 | Runner |
| Platform capture | 20 | 20 | Drifter |
| Platform held (per minute) | 0 | 15 | Any |
| World Event win | 150 | 500 | Any |
| Hauler interception | 100 | 50 | Scrapper |
| Teammate repair (Wrenchhead) | 30 | 15 | Wrenchhead |
| Bounty collection (scales) | 50–200 | 25 | Any |

---

## Personal Spending

| Item | Cost | Notes |
|---|---|---|
| Tier 1 vehicle (starter) | Free | Default for new players |
| Tier 2 vehicle upgrade | 800 coins | OR unlock via role XP (500 XP) |
| Tier 3 vehicle upgrade | 2,400 coins | OR 1,500 XP |
| Tier 4 vehicle upgrade | 6,000 coins | OR 3,500 XP |
| Cosmetic livery (vehicle skin) | 500–1,500 coins | |
| Gadget (non-default) | 1,000 coins | OR unlock via role XP |
| Single-use Rocket Boost (consumable) | 100 coins | Backup if gadget on cooldown — optional |

---

## Faction Treasury Spending

| Perk | Cost | Effect |
|---|---|---|
| Signal Buoy (T1) | 1,000 coins | Radar shows enemy haulers 60s |
| Drift Boost Pad (T2) | 2,500 coins | Deployable speed ramp on home island |
| Party Cannon (T3) | 5,000 coins | Confetti cannon slows intruders briefly |
| Holo-Decoy (T4) | 10,000 coins | Spawn a fake hauler barge for 30s |
| Base Shield Upgrade | 800/level | Increases hits required to destroy shield generator |

---

## Anti-Stomp Measures (server-enforced)

### New player protection
- 30 seconds spawn shield on first joining a server
- 30 seconds spawn shield after every displacement/teleport home
- Shield shown as golden shimmer — visible to all players

### Bounty system
- Players on a winning streak (3+ consecutive successful raids or interceptions) gain a visible bounty
- Bounty amount: 50–200 coins (scales with streak)
- Any player who defeats or displaces a bounty player earns the bounty
- Naturally draws attention to dominant players without admin intervention

### Faction snowball prevention
- If one faction's treasury is more than 2× another's, treasury income for the leading faction is reduced by 20%
- Does not affect personal earnings — only the faction drip rate
- Prevents permanent dominant factions on long-running servers

---

## Monetisation

### Design Philosophy
Gamepasses accelerate, never gate. Free players can reach tier 5 in every role through gameplay. The fastest free vehicle is within 15% of the best paid vehicle in raw stats. Regular free seasonal content drops keep the game fresh and the community engaged.

### Gamepasses (one-time purchase)

| Pass | Price (R$) | What it gives |
|---|---|---|
| Island Hopper | 299 | Exclusive hover-glider vehicle (comparable to tier 3 free stats, cosmetically distinct) |
| Role Flex | 199 | Switch role freely mid-session (free players lock role on first pick per server) |
| Drift Legacy | 149 | Skip to tier 2 on first unlock of each role (one-time, not all future unlocks) |
| Neon Crew | 99 | Bioluminescent vehicle skin set + character accessories cosmetic pack |

### Developer Products (repeatable purchase)

| Product | Price (R$) | What it gives |
|---|---|---|
| Drift Coin Pack (small) | 75 | +2,000 Drift Coins |
| Drift Coin Pack (large) | 249 | +8,000 Drift Coins |
| Faction Boost | 99 | +50% personal earn rate for 1 hour (session only) |

### Under-13 Compliance
- All purchases gated behind Roblox's standard payment flow (handles age restrictions automatically)
- No purchase provides a meaningful combat advantage
- No loot boxes or random reward mechanics
- No time-limited "buy now or miss it" pressure on under-13 players

---

## DataStore Schema

```lua
-- Per-player persistent data (saved to DataStore)
playerData[userId] = {
  personalCoins  = 0,
  roleXP = {
    runner     = 0,
    hauler     = 0,
    drifter    = 0,
    scrapper   = 0,
    wrenchhead = 0,
  },
  unlockedVehicles = {},   -- array of vehicle IDs
  unlockedGadgets  = {},   -- array of gadget IDs
  gamepasses       = {},   -- array of gamepass IDs (synced from MarketplaceService)
  cosmetics        = {},   -- owned skins/decals
  stats = {
    totalRaids       = 0,
    totalDeliveries  = 0,
    totalRepairs     = 0,
  }
}

-- Faction treasury (session-only, NOT persisted)
factionData[factionId] = {
  treasury    = 0,
  researchTier = 0,
  unlockedPerks = {},
  heldPlatforms = {},  -- array of platform IDs
}
```

> **Important:** Faction treasury is never written to DataStore. It lives only in server memory. This is intentional — fresh start each server, prevents permanent dominant factions across sessions.
