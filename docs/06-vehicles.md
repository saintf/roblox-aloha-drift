# Aloha Drift — Vehicles

## Physics Approach
All vehicles use `VectorForce` + `AlignOrientation` constraints — NOT legacy `BodyVelocity`. This gives:
- Natural tilt on acceleration
- Idle bob (sine wave on Y axis)
- Altitude hold above terrain
- Proper collision response
- Faction-specific max speed constants

### Hover Vehicle Base Pattern
```lua
-- VectorForce on RootPart.Attachment0, RelativeTo World
-- AlignOrientation on same attachment, RigidityEnabled false, Responsiveness 12
-- Heartbeat loop:
--   1. Raycast downward to find ground distance
--   2. PD controller: force = HOVER_FORCE * (HOVER_HEIGHT - dist) * 8
--   3. Tilt toward velocity: AlignOrientation.CFrame = CFrame.Angles(-vel.Z * TILT, 0, vel.X * TILT)
--   4. Idle bob: Y offset += math.sin(tick() * 2) * 0.08
```

## Vehicle Stats

### Hover-Bike (Runner)
| Stat | Value |
|---|---|
| Top speed | 90 studs/s |
| Acceleration | Fast |
| Armour | Low (2 EMP hits to disable) |
| Capacity | 1 player |
| Hover height | 3 studs |
| Tilt factor | 0.20 (aggressive lean) |

**Aesthetic:** Narrow, forward-leaning. Thruster pods under each side. Pastel coral + gold. Leans hard into turns.

**Meshy prompt:**
> "Futuristic hover bike, tropical Pacific aesthetic, chunky cartoon proportions, pastel coral and gold colour scheme, bioluminescent accent lights under chassis, no wheels, two thruster pods underneath, rider seat with roll bar, thick outlines, bold clean silhouette, 3/4 front view, white background"

---

### Hover-Barge (Hauler)
| Stat | Value |
|---|---|
| Top speed | 25 studs/s |
| Acceleration | Slow |
| Armour | High (5 EMP hits to disable) |
| Capacity | 1 player + crystal cargo holds |
| Hover height | 4 studs |
| Tilt factor | 0.05 (very stable) |

**Aesthetic:** Large flat platform with 4 glowing crystal holds. Lumbering but imposing. Visible from across the map — intentionally. Teal/white.

---

### Hover-Skiff (Drifter)
| Stat | Value |
|---|---|
| Top speed | 70 studs/s |
| Acceleration | Very fast |
| Armour | Medium (3 EMP hits) |
| Capacity | 1 player |
| Hover height | 3.5 studs |
| Tilt factor | 0.18 (responsive) |

**Aesthetic:** Open cockpit, swept-back fins, nimble silhouette. Best agility stat in the game. Purple + white.

---

### Hover-Quad (Scrapper)
| Stat | Value |
|---|---|
| Top speed | 55 studs/s |
| Acceleration | Medium |
| Armour | High (5 EMP hits) |
| Capacity | 1 player |
| Hover height | 4 studs |
| Tilt factor | 0.10 (sturdy) |

**Aesthetic:** Four corner thruster pods, chunky and square. Built for intercepting, not racing. Dark coral + gunmetal.

---

### Hover-Surfboard (Wrenchhead)
| Stat | Value |
|---|---|
| Top speed | 38 studs/s |
| Acceleration | Slow |
| Armour | Medium (3 EMP hits) |
| Capacity | 1 player |
| Hover height | 2.5 studs (low to ground) |
| Tilt factor | 0.08 (steady) |

**Aesthetic:** Wide, stable, low-profile. Repair toolkit strapped to deck. Bioluminescent teal trim. Immediately readable as "support."

**Meshy prompt:**
> "Futuristic hover surfboard vehicle, wide stable platform shape, teal and white colour scheme, four small thruster fins on underside, repair toolkit and wrench strapped to deck surface, bioluminescent teal trim lines, chunky cartoon proportions, low profile, no rider included, 3/4 top-front view, white background"

---

## Tier Progression (per vehicle, per role)

| Tier | XP Required | Changes |
|---|---|---|
| 1 — Starter | 0 | Base vehicle, default faction colour |
| 2 — Seasoned | 500 | +10% top speed, new decal option |
| 3 — Veteran | 1,500 | Passive perk unlocks (role-specific) |
| 4 — Elite | 3,500 | Visual glow upgrade, +15% stat |
| 5 — Legend | 8,000 | Unique legendary skin, title badge |

### Example Passive Perks (tier 3)
- **Runner:** Slipstream — reduced air resistance, +8% top speed at max velocity
- **Hauler:** Stabiliser — cargo spill chance reduced 30% if EMP'd
- **Drifter:** Drift Grip — tighter turn radius, no speed loss in corners
- **Scrapper:** Surge Coil — EMP Burst range +4 studs
- **Wrenchhead:** Quick Hands — Repair Beam channel time 3s → 2s

## Vehicle Recall
All players can recall their parked vehicle at any time.

- **Activation:** Hold a button (configurable); fires `RemoteEvent` to server
- **Cooldown:** 45 seconds (server-tracked)
- **Behaviour:** Vehicle Tweens autonomously to player's `HumanoidRootPart` position over 4 seconds
- **During recall:** Vehicle is vulnerable — can be EMP'd or intercepted mid-flight
- **Visual:** Vehicle emits a teal beam upward while flying back
- **Design intent:** Using recall in enemy territory is a tactical choice — it announces your position

## Gamepass Vehicles
One exclusive vehicle available per faction via gamepass:
- Comparable stats to tier 3 free vehicle (within 15%)
- Visually distinct — can be identified by rivals
- Cosmetically exciting (unique particle trails, animated details)
- Cannot be unlocked through XP — purely a cosmetic/convenience purchase

## Asset Pipeline (Meshy → Roblox)
1. Generate 4 variants in Meshy, select best silhouette
2. Import as `.obj` or `.fbx` into Roblox Studio
3. Keep poly count under 2,000 tris per vehicle (mobile performance)
4. **Discard Meshy's PBR texture** — apply flat, bold hand-painted `SurfaceAppearance.ColorMap` instead
5. Set `Roughness: 0.8+`, `Metalness: 0.1` — preserves cartoon-real look at all LODs
6. Test 32×32 pixel silhouette readability before finalising
