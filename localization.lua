local addonName, addon = ...

local L = setmetatable({}, { __index = function(t, k)
  local v = tostring(k)
  rawset(t, k, v)
  return v
end })

addon.L = L

local LOCALE = GetLocale()

if LOCALE == "esES" or LOCALE == "esMX" then
  L["Blingtron 4000"] = "Joyatrón 4000"
  return
elseif LOCALE == "frFR" then
  L["Blingtron 4000"] = "Bling-o-tron 4000"
  return
elseif LOCALE == "ruRU" then
  L["Blingtron 4000"] = "Блескотрон-4000"
  return
elseif LOCALE == "koKR" then
  L["Blingtron 4000"] = "블링트론 4000"
  return
end