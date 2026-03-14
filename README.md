# Aloha Drift — Design Documents

This folder contains all game design documents for Aloha Drift. Commit these to your repo root so Claude Code and GitHub Copilot can reference them.

## Document Index

| File | Contents |
|---|---|
| `01-game-overview.md` | Vision, aesthetic, elevator pitch, differentiators |
| `02-world-and-map.md` | Island layout, dimensions, ocean sequence, world events |
| `03-factions.md` | Solaris & Tidalwave, party system, faction perks |
| `04-roles.md` | All 5 roles, XP tiers, vehicle assignments |
| `05-gameplay-loops.md` | 4 core loops, earning rates, emergent scenarios |
| `06-vehicles.md` | Physics pattern, stats table, Meshy pipeline |
| `07-gadgets.md` | All gadgets, loadouts, server architecture |
| `08-displacement-system.md` | No-death consequence system, Wind Blaster balance |
| `09-economy-and-monetisation.md` | DataStore schema, earning rates, gamepasses |
| `10-technical-architecture.md` | Service structure, RemoteEvents, security, build order |
| `11-development-roadmap.md` | 12 milestones, stories, Meshy asset priority |
| `CLAUDE-PROJECT-SYSTEM-PROMPT.md` | Paste into Claude Project as system instructions |

## How to use these documents

### With Claude Code
When starting a new session, include a reference to the relevant doc:
> "Refer to `docs/10-technical-architecture.md` for the service pattern. Now implement..."

Or add the whole `docs/` folder to Claude Code's context at session start.

### With GitHub Copilot
The config tables and function signatures in these docs are designed to be copy-paste starting points. Copilot will autocomplete from them accurately once they're in context.

### With the Claude Project (PM agent)
Paste the contents of `CLAUDE-PROJECT-SYSTEM-PROMPT.md` into your Claude Project's system instructions. Add all other docs as project files. The PM agent will help you generate detailed Claude Code prompts story by story.

## Suggested repo structure

```
aloha-drift/
  docs/                    ← this folder
  src/
    ServerScriptService/
      Services/
        DisplacementService.lua
        EconomyService.lua
        GadgetService.lua
        VehicleService.lua
        FactionService.lua
        EventScheduler.lua
        ZoneService.lua
        BountyService.lua
    ReplicatedStorage/
      RemoteEvents/
      ModuleScripts/
        Config/
    StarterPlayerScripts/
      LocalScripts/
    StarterCharacterScripts/
  assets/                  ← Meshy exports before Studio import
    meshes/
    textures/
  README.md
```

## First thing to build
See Milestone 1 in `11-development-roadmap.md`. Start with `DisplacementService` — it's the foundation everything else builds on.
