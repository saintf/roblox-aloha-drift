# Aloha Drift — Development Roadmap

## Philosophy: Additive & Playable Early
Each milestone produces something playable and testable. No milestone should produce code that can only be tested once 3 other systems exist. Features are layered in — you can always play the current state of the game.

---

## Milestone 1 — "The Foundation" *(play-testable: falling & teleporting)*

**Goal:** A player can join, fall off an island, see the ocean sequence, and teleport home. Nothing else exists yet.

### Stories
1. **World skeleton** — Create a single floating island (200×200 studs, placeholder grey baseplate) above an ocean plane. Add a sky atmosphere.
2. **Ocean surface** — Add ocean `Part` with `WaterTransparency`, configure to detect player contact via `Touched` event.
3. **DisplacementService (core)** — Implement `onOceanContact()` and `teleportHome()`. Player falls → 5s delay → teleports to spawn. No loot yet.
4. **Underwater FX (client)** — `LocalScript`: screen tint teal, bubble sound, camera tilt on ocean contact. Pure cosmetic.
5. **Spawn shield** — `teleportHome()` grants 3s invincibility flag; golden shimmer VFX on arrival.
6. **World boundary** — Kill plane below ocean; routes to `DisplacementService.onBelowWorldBoundary()`.

**Playable test:** Jump off the island. See teal screen tint. Wait 5 seconds. Teleport back to spawn with golden shimmer.

---

## Milestone 2 — "The Economy" *(play-testable: coins exist and save)*

**Goal:** Players have a coin wallet, can earn coins from a placeholder source, and coins persist between sessions.

### Stories
1. **DataStore setup** — `EconomyService`: load/save player data on join/leave, autosave every 60s. Schema: `{ personalCoins, roleXP{} }`.
2. **Basic HUD** — Coin counter in top-right corner. Updates in real-time via `RemoteEvent`.
3. **Placeholder earn source** — A glowing orb on the island: walk up to collect 50 coins. Resets every 30s. Uses `EconomyService.awardCoins()`.
4. **Faction system scaffold** — Two factions (Solaris, Tidalwave). Auto-assign on join (balance check). Faction colour on spawn.
5. **Faction treasury HUD** — Small display showing faction treasury total. Updates on every `awardCoins` call.
6. **Persistence test** — Leave and rejoin; coin total persists.

**Playable test:** Join as Solaris, collect coins from orb, see wallet update. Rejoin — coins still there.

---

## Milestone 3 — "First Vehicle" *(play-testable: hover around the island)*

**Goal:** One vehicle (hover-bike) with full physics. Player can mount, fly, and dismount.

### Stories
1. **VehicleService scaffold** — `spawnVehicle()`, `mountPlayer()`, `dismountPlayer()`. Vehicle is tied to one player at a time.
2. **Hover physics** — `VectorForce` + `AlignOrientation` PD controller. Altitude hold, idle bob, velocity tilt. Config table at top.
3. **Input handling (LocalScript)** — WASD/thumbstick drive. Space = ascend, Shift = descend. No speed hacks: max velocity clamped server-side.
4. **Vehicle recall** — Hold `R` (or mobile button) to recall vehicle. 45s cooldown. Vehicle tweens to player over 4s. Teal beam VFX.
5. **Fall from vehicle** — If vehicle falls off island edge, player dismounts automatically and DisplacementService handles the rest.
6. **Placeholder hover-bike mesh** — Simple Roblox primitive (wedge + two cylinder pods) until Meshy asset is ready. Use faction colour.

**Playable test:** Spawn hover-bike, fly around island, fly off edge, fall into ocean, teleport home, recall vehicle.

---

## Milestone 4 — "The Map" *(play-testable: two islands, open sky between them)*

**Goal:** Basic map layout exists. Two faction home islands, open sky, ocean below. No gameplay yet, just geography.

### Stories
1. **ZoneService** — Tag each island Part with `ZoneOwner` and `ZoneType` attributes. `getZone(position)` returns zone data.
2. **Second island** — Mirror of first island, opposite corner. Tidalwave faction colours.
3. **Altitude layers** — Solaris at Y=180, Tidalwave at Y=180 (opposite X/Z), ocean at Y=0.
4. **Spawn assignment** — Players spawn on their faction's island. `teleportHome()` routes to correct spawn.
5. **Minimap (basic)** — Top-down 2D minimap showing player dot and island outlines. No enemy positions yet.
6. **Drift Market placeholder** — Flat platform at mid-altitude centre. No-combat zone (Wind Blaster disabled by zone check — even though Wind Blaster doesn't exist yet, wire up the `isNoCombatZone()` check in ZoneService now).

**Playable test:** Two players, different factions, can fly between islands. Spawn on correct island after teleport.

---

## Milestone 5 — "The Wind Blaster" *(play-testable: first real conflict)*

**Goal:** Players can push each other. Displacement system fully live. First real gameplay loop exists.

### Stories
1. **Wind Blaster gadget** — On-foot gadget, all roles. Client fires `GadgetActivate`, server validates and applies `VectorForce` impulse.
2. **Context detection** — `ZoneService.getWindConfig(firingPlayer)` returns defender or attacker stats. Full WIND config table.
3. **Loot drop on hit** — In enemy territory: drop 15–20% of carried coins as a glowing pickup. Any player collects. Auto-return after 20s.
4. **Hit counter + teleport threshold** — Per-player hit counter with decay window. Triggers `DisplacementService.teleportHome()` at threshold.
5. **Friendly fire prevention** — Server checks faction match before applying force.
6. **Wind Blaster VFX** — Faction-coloured wind burst on activation. Cartoon sound.
7. **Placeholder coins to carry** — Give players 200 coins on spawn (non-persisted) so loot drops can be tested.

**Playable test:** Two players on enemy base. One pushes the other. Loot drops. Three hits → teleport home. Pushed player loses coins. Pusher can collect dropped pile.

---

## Milestone 6 — "Safe Crack" *(play-testable: first heist)*

**Goal:** Runner can raid an enemy safe. Full heist loop works end-to-end.

### Stories
1. **Safe object** — Glowing safe model on each home island. Has a proximity prompt (appears only if player has Lockpick equipped).
2. **Lockpick gadget** — On-foot gadget (Runner default). Enables safe proximity prompt. Sparkle VFX on equip.
3. **Safe crack minigame** — Server generates 4-button sequence. Client displays UI. Player inputs sequence. Server validates. 15s timeout.
4. **Interruption rule** — Any rival within 10 studs resets the sequence. Server Heartbeat check during active crack.
5. **Crack success reward** — `EconomyService.awardCoins()` to Runner (personal) and faction treasury. Safe resets after 3 minutes.
6. **Crack VFX** — Safe swings open, coin burst particle effect, success sound.
7. **Defender alert** — When a crack begins, all players on the island (same faction as safe owner) get a subtle UI alert: "⚠ Safe under attack!"

**Playable test:** Runner flies to enemy base, equips lockpick, completes minigame without being caught. Coins awarded. Then test being interrupted mid-crack. Then test being wind-blasted during crack.

---

## Milestone 7 — "Crystal Haul" *(play-testable: the economy loop)*

**Goal:** Full Lumicite harvest and delivery loop. The game's primary income source works.

### Stories
1. **Lumicite Fields island** — Low-altitude island with 8 crystal spawn points. Crystals are glowing `Part` objects that reset every 3 minutes.
2. **Crystal pickup (on foot)** — Walk up to crystal: 2s hold interaction. Crystal added to player's carried inventory. Max 3 stacks on foot.
3. **Hover-barge vehicle** — Second vehicle type. Slow, large, 4 cargo holds. `VehicleService.addCargo()` and `spillCargo()`.
4. **Crystal loading** — While mounted on barge at Fields: hold interact to transfer foot-inventory to barge cargo holds.
5. **Refinery interaction** — On home island: drive barge to Refinery marker, hold interact 3s, deposit all cargo for coins.
6. **Cargo spill on EMP** — When barge is EMP'd: `VehicleService.spillCargo()` drops crystal `Part` objects as physics objects. Ocean contact = lost.
7. **Hauler XP** — `EconomyService.awardXP(player, "hauler", amount)` on each delivery.
8. **Crystal minimap markers** — Barge shown as large dot on minimap (visible to enemies).

**Playable test:** Fly to fields on bike, switch to barge, load crystals, haul home, deposit. Then: have second player try to EMP and intercept mid-route.

---

## Milestone 8 — "Gadget Suite" *(play-testable: full role gameplay)*

**Goal:** All gadgets implemented. Each role plays distinctly.

### Stories
1. **GadgetService** — Full validation framework. Cooldown tracking. All gadget activations routed here.
2. **EMP Burst** (Scrapper) — Vehicle gadget. Stun nearby enemy vehicles 4s. Orange charge-up tell.
3. **Tether Hook** (Runner T2) — Vehicle gadget. Physical joint to barge. 8s drag, then steal one stack.
4. **Shield Bubble** (Hauler, Wrenchhead) — Vehicle gadget. 5s dome deflects EMP.
5. **Sensor Ping** (Drifter T2) — Vehicle gadget. Enemy positions on team minimap 10s.
6. **Rocket Booster** — Vehicle gadget. 3s speed burst, all roles.
7. **Repair Beam** (Wrenchhead) — On-foot gadget. 3s channel on teammate vehicle. Removes stun, restores boost.
8. **Crystal Net** (Hauler T2) — On-foot gadget. Traps loose crystal 12s.
9. **Decoy Flare** (Runner T3) — On-foot gadget. Fake crystal on enemy minimap 20s.
10. **Smoke Pop** — On-foot gadget. Faction-coloured 6s vision cloud.
11. **Gadget HUD** — Two-slot display with cooldown indicators.
12. **Role selection UI** — On spawn: choose role, see gadget loadout preview.

**Playable test:** Each role has its gadgets. Scrapper EMP's a barge. Runner tethers and steals cargo. Wrenchhead repairs a stunned teammate.

---

## Milestone 9 — "Contested Platforms & World Events"

**Goal:** Mid-map territorial gameplay and periodic server-wide event.

### Stories
1. **Platform islands** — Three contested platforms (A, B, C). 80×80, low barrier lip.
2. **Capture mechanic** — Stand in zone 30s → platform flips to faction. Defender wind buff activates.
3. **Platform income drip** — `EventScheduler` ticks every 60s, pays held platforms to faction treasury.
4. **Platform HUD** — Show which faction holds each platform on minimap.
5. **World Event scheduler** — 20-minute loop. Fires `WorldEventAnnounce` to all clients.
6. **Event Island** — Spawns with large crystal deposit. 5-minute window. `EventScheduler` tracks which faction deposits first.
7. **Event win announcement** — Server-wide banner + sound when a faction wins the event.

---

## Milestone 10 — "Faction Perks & Progression Polish"

**Goal:** Team research tree works. Tier progression feels rewarding.

### Stories
1. **Faction perk UI** — Treasury display + research tree. Shows cost and current tier.
2. **Signal Buoy perk** — Tier 1 perk: enemy haulers show on minimap for 60s after activation.
3. **Drift Boost Pad perk** — Tier 2: deployable speed ramp on home island.
4. **Party Cannon perk** — Tier 3: confetti cannon that briefly slows intruders.
5. **Holo-Decoy perk** — Tier 4: fake barge spawns and moves for 30s.
6. **Tier unlock notifications** — VFX + sound when a role tier is reached.
7. **Bounty system** — Win-streak tracking, visible bounty badge, payout on defeat.
8. **Snowball prevention** — 2× treasury cap rule implemented in `EconomyService`.

---

## Milestone 11 — "Ocean Charm & World Polish"

**Goal:** The world feels alive. Small details that make players talk about the game.

### Stories
1. **Mermaid NPCs** — 3–4 mermaid models (Meshy asset) placed at varying depths. 1-in-4 ocean falls triggers nearest mermaid visibility.
2. **Mermaid animations** — 6 idle animations (Moon Animator). Random selection on trigger.
3. **Underwater details** — Coral, distant whale silhouette, Lumicite fragments (visual only), sunken vehicle wreck.
4. **Mermaid city fog effect** — Distant unreachable skyline in ocean fog. Creates mythology.
5. **Faction base visual themes** — Solaris island: warm coral/gold architecture. Tidalwave island: cool teal/white architecture.
6. **Drift Market polish** — Beach chairs, tiki bars, neon signs, no-combat visual indicators.
7. **Sound design pass** — Ambient ocean, wind sounds at altitude, faction-specific UI sounds.
8. **Seasonal/event placeholder** — Empty hook for future seasonal content drops.

---

## Milestone 12 — "Monetisation & Launch Prep"

**Goal:** Gamepasses work. The game is ready for public testing.

### Stories
1. **MarketplaceService integration** — Gamepass ownership check on join; sync to `playerData.gamepasses`.
2. **Island Hopper vehicle** — Exclusive gamepass hover-glider. Stats comparable to tier 3 free.
3. **Role Flex pass** — Enable free role-switching for pass holders.
4. **Drift Legacy pass** — Apply tier 2 skip on first unlock.
5. **Neon Crew cosmetics** — Bioluminescent skin set applied to vehicles.
6. **Coin packs (Developer Products)** — Small + large Drift Coin packs.
7. **Faction Boost product** — 1-hour personal earn rate boost.
8. **Onboarding tutorial** — 60-second guided intro: "Here's your vehicle. Here are the islands. The ocean is always a way out."
9. **Performance audit** — Profile on mobile. Verify all vehicles under 2,000 tris. Check Heartbeat loop times.
10. **Anti-cheat audit** — Review all RemoteEvent handlers for rate limiting and input validation.

---

## Meshy Asset Priority Order

| Priority | Asset | Reason |
|---|---|---|
| 1 | Hover-bike | Most-seen vehicle, sets visual bar |
| 2 | Hover-surfboard | Most distinctive silhouette, validates style |
| 3 | Lumicite crystal cluster | Most-seen static asset |
| 4 | Mermaid NPC | Requires rigging, needs time |
| 5 | Home island base building | After style locked by vehicles |
| 6 | Hover-barge | Simpler shape, can come after bike |
| 7 | Safe object | Small, low priority |
