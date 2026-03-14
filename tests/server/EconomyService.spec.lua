-- EconomyService.spec.lua
-- Tests for EconomyService.
-- Run by pressing Play in Studio — results appear in the Output window.
-- `describe`, `it`, and `expect` are injected by TestEZ — no require needed.

return function()
  local EconomyService = require(
    game.ServerScriptService.AlohaServer.services.EconomyService
  )

  describe("getCoins", function()

    it("returns 0 for a player with no data", function()
      local mockPlayer = { UserId = 999998 }
      expect(EconomyService.getCoins(mockPlayer)).to.equal(0)
    end)

    -- Add more tests as awardCoins, awardXP, transferToFaction are implemented:
    -- it("awards coins and splits correctly between personal and faction", ...)
    -- it("respects the snowball cap for the leading faction", ...)

  end)

  -- describe("awardXP", function() ... end)
  -- describe("transferToFaction", function() ... end)
end
