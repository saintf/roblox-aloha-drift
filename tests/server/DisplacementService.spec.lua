-- DisplacementService.spec.lua
-- Tests for DisplacementService.
-- Run by pressing Play in Studio — results appear in the Output window.
-- Add a describe block for each public function as it is implemented.
-- `describe`, `it`, and `expect` are injected by TestEZ — no require needed.

return function()
  local DisplacementService = require(
    game.ServerScriptService.AlohaServer.services.DisplacementService
  )

  describe("isInvincible", function()

    it("returns false for a player not in state", function()
      local mockPlayer = { UserId = 999999 }
      expect(DisplacementService.isInvincible(mockPlayer)).to.equal(false)
    end)

    -- Add more tests as onWindHit, onOceanContact, teleportHome are implemented:
    -- it("returns true within SPAWN_INVINCIBLE window after teleportHome", ...)
    -- it("returns false after SPAWN_INVINCIBLE window expires", ...)

  end)

  -- describe("onWindHit", function() ... end)
  -- describe("teleportHome", function() ... end)
end
