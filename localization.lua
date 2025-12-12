local addonName, addon = ...

local L = setmetatable({}, { __index = function(t, k)
  local v = tostring(k)
  rawset(t, k, v)
  return v
end })

addon.L = L

local LOCALE = (GAME_LOCALE or GetLocale())

if LOCALE == "esES" or LOCALE == "esMX" then
  L["Blingtron 4000"] = "Joyatrón 4000"
  L["Trove of the Thunder King"] = "Tesoro del Rey del Trueno"
  return
elseif LOCALE == "frFR" then
  L["Blingtron 4000"] = "Bling-o-tron 4000"
  L["Trove of the Thunder King"] = "Trésor du roi-tonnerre"
  return
elseif LOCALE == "ruRU" then
  L["Blingtron 4000"] = "Блескотрон-4000"
  L["Trove of the Thunder King"] = "Сокровища Властелина Грома"
  return
elseif LOCALE == "koKR" then
  L["Blingtron 4000"] = "블링트론 4000"
  L["Trove of the Thunder King"] = "천둥왕의 보물"
  return
elseif LOCALE == "deDE" then
  L["Trove of the Thunder King"] = "Schatztruhe des Donnerkönigs"
  return
end
