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
  L["The Crumbled Chamberlain"] = "El chambelán hecho pedazos"
  L["Treasures of the Thunder King"] = "Tesoros del Rey del Trueno"
  return
elseif LOCALE == "frFR" then
  L["Blingtron 4000"] = "Bling-o-tron 4000"
  L["Trove of the Thunder King"] = "Trésor du roi-tonnerre"
  L["The Crumbled Chamberlain"] = "Morceaux de chambellan"
  L["Treasures of the Thunder King"] = "Les trésors du roi-tonnerre"
  return
elseif LOCALE == "ruRU" then
  L["Blingtron 4000"] = "Блескотрон-4000"
  L["Trove of the Thunder King"] = "Сокровища Властелина Грома"
  L["The Crumbled Chamberlain"] = "Древний хранитель ключей"
  L["Treasures of the Thunder King"] = "Сокровища Властелина Грома"
  return
elseif LOCALE == "koKR" then
  L["Blingtron 4000"] = "블링트론 4000"
  L["Trove of the Thunder King"] = "천둥왕의 보물"
  L["The Crumbled Chamberlain"] = "부스러진 시종장"
  L["Treasures of the Thunder King"] = "천둥왕의 보물"
  return
elseif LOCALE == "deDE" then
  L["Trove of the Thunder King"] = "Schatztruhe des Donnerkönigs"
  L["The Crumbled Chamberlain"] = "Der zerfallene Kämmerer"
  L["Treasures of the Thunder King"] = "Schätze des Donnerkönigs"
  return
end
