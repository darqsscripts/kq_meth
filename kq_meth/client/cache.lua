local cache = {}

function SaveCache(key, data, ttl)
  cache[key] = {
    data = data,
    maxAge = GetGameTimer() + (ttl or 3000)
  }
end

function WipeCache(key)
  cache[key] = nil
end

function UseCache(key, callback, ttl)
  local cached = cache[key]
  if not cached or cached.maxAge < GetGameTimer() then
    local result = {callback()}
    SaveCache(key, result, ttl)
    return table.unpack(result)
  end
  return table.unpack(cached.data)
end