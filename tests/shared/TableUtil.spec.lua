-- TableUtil.spec.lua
-- Tests for TableUtil shared library.
-- `describe`, `it`, and `expect` are injected by TestEZ — no require needed.

return function()
  local TableUtil = require(game.ReplicatedStorage.AlohaShared.lib.TableUtil)

  describe("contains", function()
    it("returns true when value is present", function()
      expect(TableUtil.contains({1, 2, 3}, 2)).to.equal(true)
    end)
    it("returns false when value is absent", function()
      expect(TableUtil.contains({1, 2, 3}, 9)).to.equal(false)
    end)
  end)

  describe("shallowCopy", function()
    it("returns a new table with the same keys", function()
      local original = { a = 1, b = 2 }
      local copy = TableUtil.shallowCopy(original)
      expect(copy.a).to.equal(1)
      expect(copy).never.to.equal(original)
    end)
  end)

  describe("removeValue", function()
    it("removes the first matching value and returns true", function()
      local t = { "x", "y", "z" }
      local result = TableUtil.removeValue(t, "y")
      expect(result).to.equal(true)
      expect(#t).to.equal(2)
    end)
    it("returns false when value is not present", function()
      expect(TableUtil.removeValue({"a"}, "b")).to.equal(false)
    end)
  end)

  describe("size", function()
    it("counts dictionary keys correctly", function()
      expect(TableUtil.size({ a=1, b=2, c=3 })).to.equal(3)
    end)
  end)
end
