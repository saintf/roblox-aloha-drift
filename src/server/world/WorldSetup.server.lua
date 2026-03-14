-- WorldSetup.server.lua
-- Runs on server start. Verifies that the expected world geometry exists in Workspace.
-- Does NOT create geometry — parts must already be present in the place file.
-- To create the geometry for the first time, enable and run GeometrySetup.server.lua once.

local function check(name, parent)
  parent = parent or workspace
  if not parent:FindFirstChild(name) then
    warn("[Aloha Drift] Missing expected geometry: " .. name)
    return false
  end
  return true
end

local ok = true
ok = check("SolarisBase")   and ok
ok = check("OceanSurface")  and ok
ok = check("KillPlane")     and ok

if ok then
  print("[Aloha Drift] World skeleton OK")
end
