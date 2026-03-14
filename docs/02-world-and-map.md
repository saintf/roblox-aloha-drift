# Aloha Drift — World & Map Design

## World Concept
A chain of floating tropical islands at varying altitudes above a warm, glittering ocean. The sky is always golden-hour or midday. Bioluminescent palms glow at night. The ocean below is not a death zone — it's a soft landing with a 5-second wonder window before teleporting home.

## Map Dimensions
- **Bounding box:** ~2,200 × 2,000 studs (comparable to Emergency Hamburg)
- **Open sky fills gaps** — no wasted solid terrain between islands
- **Travel time** home island → Lumicite Fields at mid-speed: ~25–35 seconds (tense but not tedious)

## Island Roster

| Island / Zone | Size (studs) | Altitude | Purpose |
|---|---|---|---|
| Solaris Base | 200 × 200 | High (~180u) | Faction spawn, safe, upgrade shop, refinery |
| Tidalwave Base | 200 × 200 | High (~180u) | Same, opposite corner of map |
| Drift Market | 150 × 150 | Mid (~90u) | Neutral commerce hub, no combat zone |
| Lumicite Fields | 400 × 300 | Low (~30u) | Crystal harvest source, most contested area |
| Platform A | 80 × 80 | Mid-low | Contested — capture for passive income |
| Platform B | 80 × 80 | Mid-low | Contested — capture for passive income |
| Platform C | 80 × 80 | High | Contested — highest altitude, greatest visibility |
| Event Island | 250 × 200 | Low / sea-adjacent | Appears on 20-min timer, mega crystal deposit |

## Altitude Layers
Altitude is design, not decoration:
- **Home bases are highest** — natural sight advantage, defensible position, raiders must fly upward to escape (slower)
- **Market is mid** — accessible from both sides equally
- **Lumicite Fields are lowest** — harvesters are exposed during collection (intentional risk/reward)
- **Event Island spawns near sea level** — everyone descends to compete, equalising travel time from all bases

## Spatial Layout (approximate)
```
         [Platform C]          <- highest point
   
[Solaris Base]    [Tidalwave Base]   <- high altitude, opposite corners

        [Drift Market]              <- centre, mid altitude

[Platform A]              [Platform B]   <- mid-low, flanking

           [Lumicite Fields]        <- low altitude, wide open

          - - [Event Island] - -    <- periodic, sea-adjacent
          
~~~~~~~~~~~ OCEAN ~~~~~~~~~~~~~~~~~~~
```

## The Ocean
Not a death zone. A soft landing with charm:

1. Player hits ocean surface → splash particles, screen tints teal, camera tilts slightly
2. 0–4s: bioluminescent fish scatter, caustic light shimmer. **25% chance:** a mermaid NPC appears (goofy idle — reading, waving, sleeping, playing ukulele)
3. 4–5s: upward current UI indicator appears
4. 5s: player teleports to nearest friendly island spawn

### Underwater Decorative Elements (always visible)
- Bioluminescent coral formations
- Scattered Lumicite fragments (visual only, cannot be picked up)
- Distant slow-moving whale silhouette in background fog
- Sunken hover-vehicle wreck (lore flavour)
- Small "secret" sign with goofy text

### Rare / Discoverable
- Mermaid city visible in far distance fog (unreachable — creates mythology)
- Mermaid NPC with randomised idle animation (1-in-4 ocean falls)

### Mermaid Idle Animations (random)
Reading a glowing book | Waving enthusiastically | Sleeping on coral rock | Playing tiny ukulele | Feeding fish | Doing a thumbs-up

## Base Layout Guidelines
Each 200×200 home island must contain:
- **Spawn area** with vehicle garage
- **Safe** (raid target) — not in the centre, requires navigating the base
- **Refinery** (crystal deposit point)
- **Upgrade shop** terminal
- **Shield generator** (repairable by Wrenchhead)
- **Cover objects** — hover-tech crates, palm clusters, generator units

> **Critical design note:** Cover placement is a gameplay decision. A flat base lets defenders land 28-stud pushes that immediately send raiders off the edge. Cover gives raiders dodging angles so the skill gap on both sides can play out. Aim for 4–6 significant cover objects scattered around the safe area.

## Contested Platforms
- Each platform is 80×80 studs with a low barrier/lip around the edge
- The lip means a single 12-stud push does not guarantee a fall — requires 2+ pushes to go off the edge
- Once captured (stand in zone 30s), the capturing faction gains defender-mode wind blasts on that platform
- Platforms generate 15 Drift Coins per minute to faction treasury while held

## Drift Market (Neutral Zone)
- No combat allowed — wind blaster deactivated server-side when player is inside Market boundary
- Contains: vehicle dealer, gadget shop, cosmetics vendor, faction treasury display boards
- Mid-altitude makes it equidistant from both home bases
- Should feel like a vacation resort: beach chairs, tiki bars, neon signs

## World Events
A server-side scheduler fires every 20 minutes:
1. Server-wide announcement (fanfare sound, map marker appears)
2. Event Island becomes visible and accessible for 5 minutes
3. Large Lumicite deposit spawns on the island
4. First faction to get a hauler there, load crystals, and return home wins a large treasury payout
5. All factions notified of the winner
