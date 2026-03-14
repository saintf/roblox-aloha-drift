-- DisplacementService.spec.lua
-- Tests for DisplacementService.
-- Run by pressing Play in Studio — results appear in the Output window.
-- `describe`, `it`, and `expect` are injected by TestEZ — no require needed.

return function()
  local DisplacementService = require(
    game.ServerScriptService.AlohaServer.services.DisplacementService
  )

  describe("onOceanContact", function()

    it("does not throw for a player with no state entry", function()
      -- playerState has no entry for this UserId — function should return early cleanly
      local mockPlayer = {
        UserId    = 888001,
        Parent    = game,
        Character = { FindFirstChild = function() return nil end },
      }
      expect(function()
        DisplacementService.onOceanContact(mockPlayer)
      end).never.to.throw()
    end)

    it("does not throw on a second call within the displacement window", function()
      local mockPlayer = {
        UserId    = 888002,
        Parent    = game,
        Character = { FindFirstChild = function() return nil end },
      }
      -- Both calls return early (no state entry) — neither should throw
      DisplacementService.onOceanContact(mockPlayer)
      expect(function()
        DisplacementService.onOceanContact(mockPlayer)
      end).never.to.throw()
    end)

  end)

  describe("isInvincible", function()

    it("returns false for a player with no state entry", function()
      local mockPlayer = { UserId = 999999 }
      expect(DisplacementService.isInvincible(mockPlayer)).to.equal(false)
    end)

    -- Requires a real player state entry — add once BaseService exposes a test hook:
    -- it("returns true within SPAWN_INVINCIBLE window after teleportHome", ...)
    -- it("returns false after SPAWN_INVINCIBLE window expires", ...)

  end)

  -- describe("onWindHit", function() ... end)   — implement in Milestone 8
  -- describe("teleportHome", function() ... end) — requires character rig; add in integration suite
end
