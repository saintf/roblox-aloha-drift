# Aloha Drift — Developer Guide

## Prerequisites

- Roblox Studio (latest)
- Rojo VS Code extension OR `rojo` CLI
- Wally — https://github.com/UpliftGames/wally/releases (used for TestEZ only)
- Git

---

## Local Development Loop

```
1. Clone repo
2. Open terminal in project root
3. Run: wally install          (downloads TestEZ into Packages/ — only needed once, or after wally.toml changes)
4. Run: rojo serve
5. Open Roblox Studio → Rojo plugin → Connect (localhost:34872)
6. Studio now reflects local src/ and Packages/ in real time
7. Edit code locally in VS Code — changes hot-sync into Studio
8. Press Play in Studio to test
```

---

## Running Tests

```
- Tests live in tests/ and follow the TestEZ spec format (https://github.com/Roblox/testez)
- TestEZ is installed as a Wally dependency into Packages/TestEZ — do not require it directly
  by path; use the bootstrap script in tests/init.server.lua (see below)
- To run: open Studio → press Play → check the Output window for PASS / FAIL lines
- The test bootstrap auto-discovers all .spec.lua files under tests/
- Each service has a corresponding spec file
- New services MUST have a spec file or the implementation is incomplete
```

---

## Config Tuning in Studio

```
- All tunable numbers live in src/shared/config/*.lua
- These sync live via Rojo — edit locally, they update in Studio immediately
- For rapid in-Studio tuning (e.g. playtesting Wind Blaster force values):
    1. Pause Rojo sync temporarily
    2. Tweak values directly in Studio's explorer on the config ModuleScript
    3. Note the values that feel right
    4. Re-apply them to the local .lua file and resume sync
- Never commit Studio-only config changes — always bring them back to the .lua files
```

---

## Adding a New Service

```
1. Create src/server/services/YourService.lua
2. Require BaseService and call BaseService.new("YourService")
3. Implement :init() and :start() methods
4. Register it in src/server/init.server.lua (in dependency order)
5. Create tests/server/YourService.spec.lua
```

---

## Adding a New Config Value

```
1. Add it to the appropriate src/shared/config/*.lua file
2. Give it a descriptive ALL_CAPS name
3. Add a comment explaining units and expected range
4. Never hardcode a tunable number in a service file
```

---

## Adding a New RemoteEvent

```
1. Add its name as a string constant to src/shared/RemoteEvents.lua
2. Document the payload shape in a comment next to the constant
3. The instance is created automatically — reference it via RemoteEvents.YourName
4. Never use a raw string literal for a remote name anywhere else in the codebase
```

---

## Adding a New In-Game Model

```
- Every in-game model (vehicle, safe, crystal cluster, island building) lives inside
  one Model instance with a clear .Name
- No loose Parts floating directly in Workspace
- The Model's PrimaryPart must be set
- All configuration attributes (e.g. ZoneOwner, ZoneType) go on the Model root,
  not on child Parts
- Meshy exports go into assets/meshes/ before being imported into Studio
```

---

## Code Conventions

```
- PascalCase:           Services, classes, Model names
- camelCase:            Local variables, functions
- SCREAMING_SNAKE_CASE: Config constants
- Every public function gets a one-line comment (what it does, what it returns)
- No magic numbers anywhere in service or controller files — use CFG / Config tables
- Max function length ~40 lines — if longer, split it into named helpers
- No backward compatibility debt — if a schema or API changes, update all call sites
  immediately. Do not add "if legacy then" branches.
- Services do not reach into each other's internal state — only call public API functions
- Faction treasury is NEVER written to DataStore — session memory only
```
