-- TableUtil.lua
-- Shared table utility functions. No game logic here.
-- Import wherever table manipulation is needed rather than reimplementing inline.

local TableUtil = {}

-- Returns true if the array-style table contains the given value.
function TableUtil.contains(t, value)
  for _, v in ipairs(t) do
    if v == value then return true end
  end
  return false
end

-- Returns a shallow copy of the table.
function TableUtil.shallowCopy(t)
  local copy = {}
  for k, v in pairs(t) do copy[k] = v end
  return copy
end

-- Merges all keys from src into dst, overwriting on conflict. Returns dst.
function TableUtil.merge(dst, src)
  for k, v in pairs(src) do dst[k] = v end
  return dst
end

-- Removes the first occurrence of value from an array-style table.
-- Returns true if the value was found and removed, false otherwise.
function TableUtil.removeValue(t, value)
  for i, v in ipairs(t) do
    if v == value then
      table.remove(t, i)
      return true
    end
  end
  return false
end

-- Returns the number of keys in a dictionary-style table (# does not work for dicts).
function TableUtil.size(t)
  local count = 0
  for _ in pairs(t) do count += 1 end
  return count
end

return TableUtil
