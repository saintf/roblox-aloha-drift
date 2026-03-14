-- tests/init.server.lua
-- Test runner bootstrap. Runs automatically when Studio enters Play mode.
-- Discovers all .spec.lua files under the AlohaTests folder and runs them via TestEZ.
-- Output appears in the Studio Output window: look for PASS / FAIL lines.
--
-- To add tests: create a new .spec.lua file in tests/server/ or tests/shared/.
-- It will be picked up automatically — no registration needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

-- Collect all spec modules under this Script's parent (the AlohaTests folder)
local function collectSpecs(parent, specs)
  specs = specs or {}
  for _, child in ipairs(parent:GetChildren()) do
    if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
      table.insert(specs, child)
    end
    collectSpecs(child, specs)
  end
  return specs
end

local specs = collectSpecs(script.Parent)

if #specs == 0 then
  warn("[Tests] No .spec.lua files found — nothing to run.")
  return
end

print(string.format("[Tests] Running %d spec file(s)...", #specs))

local results = TestEZ.TestBootstrap:run(specs)

-- Surface a clear summary line so it's easy to spot in a long output window
local passed  = results.successCount  or 0
local failed  = results.failureCount  or 0
local skipped = results.skippedCount  or 0

print(string.format(
  "[Tests] Done — %d passed, %d failed, %d skipped",
  passed, failed, skipped
))

if failed > 0 then
  warn("[Tests] ⚠ Some tests failed — check output above for details.")
end
