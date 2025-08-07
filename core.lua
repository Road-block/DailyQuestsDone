-- boilerplate
local addonName, addon = ...
local L = addon.L
addon.events = CreateFrame("Frame")
addon.OnEvent = function(self,event,...)
  return addon[event] and addon[event](addon,event,...)
end
addon.events:SetScript("OnEvent", addon.OnEvent)
function addon:RegisterEvent(event)
  if C_EventUtils.IsEventValid(event) then
    addon.events:RegisterEvent(event)
  end
end
function addon:UnregisterEvent(event)
  if C_EventUtils.IsEventValid(event) then
    if addon.events:IsEventRegistered(event) then
      addon.events:UnregisterEvent(event)
    end
  end
end
function addon:IsEventRegistered(event)
  if C_EventUtils.IsEventValid(event) then
    return addon.events:IsEventRegistered(event)
  end
end
function addon:RegisterUnitEvent(event,unit)
  if C_EventUtils.IsEventValid(event) then
    addon.events:RegisterUnitEvent(event,unit)
  end
end
-- upvalues
local GetQuestLogTitle = _G.GetQuestLogTitle
local GetNumQuestLogEntries = _G.GetNumQuestLogEntries
local GetQuestLogIndexByID = _G.GetQuestLogIndexByID
local GetServerTime = _G.GetServerTime
local GetInstanceInfo = _G.GetInstanceInfo
local ExpandQuestHeader = _G.ExpandQuestHeader
local CollapseQuestHeader = _G.CollapseQuestHeader
local InCombatLockdown = _G.InCombatLockdown
local GetQuestLink = _G.GetQuestLink
local GetQuestTagInfo = _G.GetQuestTagInfo
local GetCursorPosition = _G.GetCursorPosition
local CountTable = _G.CountTable
local MergeTable = _G.MergeTable
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetMapInfo = C_Map.GetMapInfo
local GetSecondsUntilDailyReset = C_DateAndTime.GetSecondsUntilDailyReset
local GetSecondsUntilWeeklyReset = C_DateAndTime.GetSecondsUntilWeeklyReset
local GetMapParentInfo = MapUtil.GetMapParentInfo
local After = C_Timer.After
local NewTicker = C_Timer.NewTicker
local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local format = string.format
local wipe = wipe
local date = date
local SECONDS_PER_DAY = SECONDS_PER_DAY or (60*60*24)
local SECONDS_PER_WEEK = SECONDS_PER_WEEK or (SECONDS_PER_DAY*7)
--local DAILY_TAG_ID, WEEKLY_TAG_ID = Enum.QuestFrequency.Daily, Enum.QuestFrequency.Weekly

local LABEL = "|T136814:14:14|t|cff00BFFFDaily|r Quests |cff00ff00Done|r"
local LABEL_COLON = format("%s%s",LABEL,HEADER_COLON)
local LABEL_SHORT = "|cff007FFFDaily|rQ|cff00ff00Done|r|T136814:14:14|t"
local LABEL_DAILY = format("|T894601:14:14:0:0:64:128:18:27:0:36|t%s:",_G.DAILY)
local LABEL_WEEKLY = format("|T894601:14:14:0:0:64:128:18:27:72:108|t%s:",_G.WEEKLY)
local LABEL_RESET = format("|T654232:16:16|t%s",_G.RESET)
local LABEL_ACCOUNT = "|T344169:14:14:0:0:128:128:0:76:51:128|t"

local timeToResetFormatter = CreateFromMixins(SecondsFormatterMixin)
timeToResetFormatter:Init(60,SecondsFormatter.Abbreviation.OneLetter,false,true)
timeToResetFormatter:SetMinInterval(SecondsFormatter.Interval.Minutes)
timeToResetFormatter:SetStripIntervalWhitespace(true)

addon.ToDailyResetFormat = "|T894601:14:14:0:0:64:128:18:27:0:36|tD:%s"
addon.ToWeeklyResetFormat = "|T894601:14:14:0:0:64:128:18:27:72:108|tW:%s"
addon.ToDailyReset = format(addon.ToDailyResetFormat,_G.NOT_APPLICABLE)
addon.ToWeeklyReset = format(addon.ToWeeklyResetFormat,_G.NOT_APPLICABLE)
addon.ToDailyResetPlain = _G.NOT_APPLICABLE
addon.ToWeeklyResetPlain = _G.NOT_APPLICABLE
local function UpdateExpirationTimersText()
  if addon.Ticker then return end
  addon.ToDailyResetPlain = timeToResetFormatter:Format(GetSecondsUntilDailyReset())
  addon.ToWeeklyResetPlain = timeToResetFormatter:Format(GetSecondsUntilWeeklyReset())
  addon.ToDailyReset = format(addon.ToDailyResetFormat,addon.ToDailyResetPlain)
  addon.ToWeeklyReset = format(addon.ToWeeklyResetFormat,addon.ToWeeklyResetPlain)
  addon.PruneExpiredDailies(addon.db_pc.dailyDone)
  addon.PruneExpiredDailies(addon.db.dailyDone)
  addon.UpdateLDBText()
  addon.Ticker = NewTicker(60,function(self)
    addon.ToDailyResetPlain = timeToResetFormatter:Format(GetSecondsUntilDailyReset())
    addon.ToWeeklyResetPlain = timeToResetFormatter:Format(GetSecondsUntilWeeklyReset())
    addon.ToDailyReset = format(addon.ToDailyResetFormat,addon.ToDailyResetPlain)
    addon.ToWeeklyReset = format(addon.ToWeeklyResetFormat,addon.ToWeeklyResetPlain)
    addon.PruneExpiredDailies(addon.db_pc.dailyDone)
    addon.PruneExpiredDailies(addon.db.dailyDone)
    addon.UpdateLDBText()
  end)
end

local nextExpirationDaily, nextExpirationWeekly
local prevExpirationDaily, prevExpirationWeekly
local function GetExpirationBracketAsRealmTime(tag, epoch)
  local serverEpoch = GetServerTime()
  if tag == LE_QUEST_FREQUENCY_DAILY then
    if not nextExpirationDaily or (nextExpirationDaily <= serverEpoch) then
      nextExpirationDaily = serverEpoch + GetSecondsUntilDailyReset()
      prevExpirationDaily = nextExpirationDaily - SECONDS_PER_DAY
    end
    local inBracket = epoch > prevExpirationDaily and epoch < nextExpirationDaily
    return inBracket, prevExpirationDaily, nextExpirationDaily
  elseif tag == LE_QUEST_FREQUENCY_WEEKLY then
    if not nextExpirationWeekly or (nextExpirationWeekly <= serverEpoch) then
      nextExpirationWeekly = serverEpoch + GetSecondsUntilWeeklyReset()
      prevExpirationWeekly = nextExpirationWeekly - SECONDS_PER_WEEK
    end
    local inBracket = epoch > prevExpirationWeekly and epoch < nextExpirationWeekly
    return inBracket, prevExpirationWeekly, nextExpirationWeekly
  end
end

local function ShouldQueue()
  if QuestLogFrame and QuestLogFrame:IsVisible() then
    return true
  end
  if WorldMapFrame and WorldMapFrame:IsVisible() then
    return true
  end
  if InCombatLockdown() then
    if not addon:IsEventRegistered("PLAYER_REGEN_ENABLED") then
      addon:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    return true
  end
end

local restoreCollapse = {}
local taskQueue = {}
local frequency_whitelist = {
  [LE_QUEST_FREQUENCY_DAILY]=true,
  [LE_QUEST_FREQUENCY_WEEKLY]=true
}
local tag_to_text = {
  [LE_QUEST_FREQUENCY_DAILY]=_G.DAILY,
  [LE_QUEST_FREQUENCY_WEEKLY]=_G.WEEKLY
}
local ScanAndStoreDailies
ScanAndStoreDailies = function()
  if ShouldQueue() then
    if not tContains(taskQueue,ScanAndStoreDailies) then
      tinsert(taskQueue,ScanAndStoreDailies)
    end
    return
  else
    restoreCollapse = wipe(restoreCollapse)
    local questLogEntries = GetNumQuestLogEntries()
    if questLogEntries > 0 then
      for i=questLogEntries,1,-1 do -- back to front
        local qTitle, qLevel, qTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
        if isHeader then
          if isCollapsed then
            QuestMapFrame.ignoreQuestLogUpdate = true
            restoreCollapse[qTitle] = true
            ExpandQuestHeader(i)
          end
        else
          if frequency and frequency_whitelist[frequency] then
            if questID and not addon.db.knownDailies[questID] then
              --local link = GetQuestLink(questID)
              addon.db.knownDailies[questID] = {tag=frequency,name=qTitle}
            end
          end
        end
      end
    end
    questLogEntries = GetNumQuestLogEntries()
    for i=questLogEntries,1,-1 do -- re-iterate expanded log getting more info and restoring collapse status
      local qTitle, qLevel, qTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
      if frequency and frequency_whitelist[frequency] then
        if questID and not addon.db.knownDailies[questID] then
          --local link = GetQuestLink(questID)
          addon.db.knownDailies[questID] = {tag=frequency,name=qTitle}
        end
      end
      if isHeader and restoreCollapse[qTitle] then
        CollapseQuestHeader(i)
        restoreCollapse[qTitle] = nil
      end
    end
    QuestMapFrame.ignoreQuestLogUpdate = nil
  end
end

local function CheckQuestForCaching(questID)
  if not addon.db.knownDailies[questID] then
    local qLogIndex = GetQuestLogIndexByID(questID)
    if qLogIndex then
      local qTitle, qLevel, qTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(qLogIndex)
      if frequency and frequency_whitelist[frequency] then
        --local link = GetQuestLink(questID)
        addon.db.knownDailies[questID] = {tag=frequency,name=qTitle}
      end
    end
  end
end

function addon.RunQueue()
  if not ShouldQueue() then
    local queue_length = CountTable(taskQueue)
    while queue_length > 0 do
      (tremove(taskQueue))()
      queue_length = CountTable(taskQueue)
    end
  end
end

local linkifyTextCache = {}
function addon.LinkifyText(name)
  if not linkifyTextCache[name] then
    linkifyTextCache[name] = format("[%s]",name)
  end
  return linkifyTextCache[name]
end
local linkifyCache = {}
function addon.Linkify(questID)
  if not linkifyCache[questID] then
    linkifyCache[questID] = format("quest:%d",questID)
  end
  return linkifyCache[questID]
end

local mapNameCache = {}
function addon.GetMapInfoFromCache(mapID)
  if not mapNameCache[mapID] then
    local mapInfo = GetMapInfo(mapID)
    if mapInfo then
      mapNameCache[mapID] = mapInfo.name
    end
  end
  return mapNameCache[mapID] or _G.UNKNOWN
end

local knownAccountQuests = {
  [31752] = true -- Blingtron
}
function addon.IsAccountQuest(questID) -- hardcoded for now since GetQuestTagInfo is semi-functioning in Mists Classic
  return knownAccountQuests[questID] or false
end

function addon.GetTurninInfo(questID)
  local info = {}
  local zoneID, continentID = -1, -1
  local mapID = GetBestMapForUnit("player")
  if mapID then
    local mapInfoZone = GetMapParentInfo(mapID, Enum.UIMapType.Zone, true)
    if mapInfoZone then
      zoneID = mapInfoZone.mapID
    end
    local mapInfoContinent = GetMapParentInfo(mapID, Enum.UIMapType.Continent, true)
    if mapInfoContinent then
      continentID = mapInfoContinent.mapID
    end
  end
  if continentID and zoneID then
    info.turnedin = GetServerTime()
    info.continent = continentID
    info.zone = zoneID
    info.tag = addon.db.knownDailies[questID].tag
    info.quest = questID
    info.name = addon.db.knownDailies[questID].name
  end
  return info
end

function addon.PruneExpiredDailies(dailyContainer)
  local numDailies = #dailyContainer
  if numDailies > 0 then
    for index=numDailies,1,-1 do -- walk backwards to limit re-indexing
      local dailyInfo = dailyContainer[index]
      local inBracket = GetExpirationBracketAsRealmTime(dailyInfo.tag, dailyInfo.turnedin)
      if not inBracket then
        tremove(dailyContainer,index)
      end
    end
  end
end

local function sorter_tag_continent_zone_time(a,b)
  -- weekly > continent > zone > oldest
  if a.tag ~= b.tag then
    return a.tag > b.tag
  elseif a.continent ~= b.continent then
    return a.continent > b.continent
  elseif a.zone ~= b.zone then
    return a.zone > b.zone
  elseif a.turnedin ~= b.turnedin then
    return a.turnedin < b.turnedin
  else
    return a.quest < b.quest
  end
end

local mergedDoneRecords = {}
function addon.SortDailiesDone()
  addon.PruneExpiredDailies(addon.dailiesContainer)
  addon.PruneExpiredDailies(addon.db.dailyDone)
  mergedDoneRecords = wipe(mergedDoneRecords)
  for k,v in pairs(addon.dailiesContainer) do
    tinsert(mergedDoneRecords,v)
  end
  for k,v in pairs(addon.db.dailyDone) do
    tinsert(mergedDoneRecords,v)
  end
  tsort(mergedDoneRecords,sorter_tag_continent_zone_time)
  return mergedDoneRecords
end

function addon.FilterDailiesDone(filterby)

end

function addon:Print(msg)
  if msg and msg:trim() ~= "" then
    local chatFrame = (DEFAULT_CHAT_FRAME or SELECTED_CHAT_FRAME)
    local out = format("%s:%s",LABEL_SHORT,msg)
    chatFrame:AddMessage(out)
  end
end

local defaults_perchar = {
  dailyDone = {}, -- {turnedin=epoch,continent=continent,zone=zone,tag=tag,quest=questid,name=questtitle}
  minimap = {
    hide = true,
    lock = false,
    minimapPos = 275,
  }
}
local defaults = {
  knownDailies = {-- questid = {tag=tag, name=link_or_title}
    [31752] = {tag=LE_QUEST_FREQUENCY_DAILY,name=L["Blingtron 4000"]}
  },
  dailyDone = {}, -- account wide mirror
  allChars = {}
}

addon:RegisterEvent("ADDON_LOADED")
function addon:ADDON_LOADED(event,...)
  if ... == addonName then
    DailyQuestsDoneDB = DailyQuestsDoneDB or {}
    DailyQuestsDonePC = DailyQuestsDonePC or {}
    -- upgrade sv if something was added to defaults
    for k,v in pairs(defaults) do
      if DailyQuestsDoneDB[k] == nil then
        if type(v) == "table" then
          DailyQuestsDoneDB[k] = CopyTable(v)
        else
          DailyQuestsDoneDB[k] = v
        end
      end
    end
    for k,v in pairs(defaults_perchar) do
      if DailyQuestsDonePC[k] == nil then
        if type(v) == "table" then
          DailyQuestsDonePC[k] = CopyTable(v)
        else
          DailyQuestsDonePC[k] = v
        end
      end
    end
    if IsLoggedIn() then
      self:PLAYER_LOGIN("PLAYER_LOGIN")
    else
      self:RegisterEvent("PLAYER_LOGIN")
    end
  end
end

function addon.ShowQuestTooltip(self,data)
  GameTooltip:SetOwner(data.parent, "ANCHOR_NONE")
  GameTooltip:SetHyperlink(data.link)
  GameTooltip:ClearAllPoints()
  local x,y = GetCursorPosition()
  if x < GetScreenHeight()/2 then
    GameTooltip:SetPoint("BOTTOMLEFT",data.parent,"TOPLEFT")
  else
    GameTooltip:SetPoint("TOPLEFT",data.parent,"BOTTOMLEFT")
  end
  GameTooltip:Show()
end
function addon.HideQuestTooltip(self,data)
  if GameTooltip:IsOwned(data.parent) then
    GameTooltip_Hide()
  end
end

function addon.OnLDBIconTooltipShow(obj)
  local mergedRecords = addon.SortDailiesDone()
  addon.dailesAdded = false
  if addon.LQTip then
    if not addon.LQTip:IsAcquired(addonName.."QTip1.0") then
      addon.QTip = addon.LQTip:Acquire(addonName.."QTip1.0",4,"LEFT","LEFT","LEFT","LEFT")
    else
      addon.QTip:Clear()
    end
    addon.QTip:SetAutoHideDelay(1.5,obj,addon.OnLDBIconTooltipHide)
    local line, col = addon.QTip:AddHeader()
    addon.QTip:SetCell(line,1,LABEL_RESET,nil,"LEFT")
    addon.QTip:SetCell(line,2,LABEL_DAILY..addon.ToDailyResetPlain,nil,"LEFT")
    addon.QTip:SetCell(line,3,LABEL_WEEKLY..addon.ToWeeklyResetPlain,nil,"LEFT")
    addon.QTip:SetCellTextColor(line,1,1,1,0)
    line = addon.QTip:AddSeparator()
    line = addon.QTip:AddLine()
    local header
    if addon.selectedCharacterKey == addon.characterKey then
      header = LABEL
    else
      header = format("%s (%s)",LABEL,addon.selectedCharacterKey)
    end
    addon.QTip:SetCell(line,1,header,nil,"CENTER",3)
    local lastTag, lastContinent, lastZone
    if #mergedRecords > 0 then
      for _,data in ipairs(mergedRecords) do
        -- dataspec: .turnedin, .continent, .zone, .tag, .quest, .name
        local tag, continent, zone, name, turnedin, quest = data.tag, data.continent, data.zone, data.name, data.turnedin, data.quest
        local tagText = tag_to_text[tag] or _G.UNKNOWN
        local continentText = addon.GetMapInfoFromCache(continent)
        local zoneText = addon.GetMapInfoFromCache(zone)
        local timeText = date("%H:%M",turnedin)
        if not lastTag or (lastTag ~= tag) then
          lastTag = tag
          line, col = addon.QTip:AddLine()
          addon.QTip:SetCell(line,1,tagText,nil,"LEFT",3)
          addon.QTip:SetCellTextColor(line,1,0,191/255,1)
        end
        if not lastContinent or (lastContinent ~= continent) then
          lastContinent = continent
          line, col = addon.QTip:AddLine()
          addon.QTip:SetCell(line,1,continentText,nil,"CENTER")
          addon.QTip:SetCellTextColor(line,1,1,204/255,153/255)
        end
        if not lastZone or (lastZone ~= zone) then
          lastZone = zone
          line, col = addon.QTip:AddLine()
          addon.QTip:SetCell(line,1,"")
          addon.QTip:SetCell(line,2,zoneText,nil,"LEFT")
          addon.QTip:SetCellTextColor(line,2,1,1,153/255)
        end
        local displayName = addon.LinkifyText(name)
        if addon.IsAccountQuest(quest) then
          displayName = LABEL_ACCOUNT..displayName
        end
        local link = addon.Linkify(quest)
        line = addon.QTip:AddLine()
        addon.QTip:SetCell(line,1,"")
        addon.QTip:SetCell(line,2,displayName,nil,"RIGHT")
        addon.QTip:SetCellTextColor(line,2,1,1,0) -- system yellow
        addon.QTip:SetCell(line,3,timeText,nil,"RIGHT")
        addon.QTip:SetLineScript(line, "OnEnter", addon.ShowQuestTooltip, {parent=addon.QTip,link=link})
        addon.QTip:SetLineScript(line, "OnLeave", addon.HideQuestTooltip, {parent=addon.QTip})
      end
      addon.dailesAdded = true
    end
    if not addon.dailesAdded then
      line = addon.QTip:AddLine("",L["No Dailies recorded yet!"])
      addon.QTip:SetLineTextColor(line,0.8,0.8,0.8)
    end
    line = addon.QTip:AddSeparator()
    line = addon.QTip:AddLine(L["Left-Click: Options"])
    addon.QTip:SetLineTextColor(line,0.7,0.7,0.7)
    line = addon.QTip:AddLine(L["Shift-Left-Click: Check for expired Dailies"])
    addon.QTip:SetLineTextColor(line,0.7,0.7,0.7)
    line = addon.QTip:AddLine(L["Right-Click: Alt Viewer"])
    addon.QTip:SetLineTextColor(line,0.7,0.7,0.7)
    addon.QTip:SmartAnchorTo(obj)
    --if TipTac then TipTac:AddModifiedTip(addon.QTip) end
    addon.QTip:Show()
    addon.QTip:UpdateScrolling(600)
  end
end

function addon.OnLDBIconTooltipHide()
  if addon.LQTip:IsAcquired(addonName.."QTip1.0") then
    if GameTooltip:IsOwned(addon.QTip) then
      GameTooltip_Hide()
    end
    addon.LQTip:Release(addon.QTip)
  end
end

function addon.OnLDBIconClick(frame, mbutton, down)
  if mbutton == "LeftButton" then
    if IsShiftKeyDown() then
      if #addon.db_pc.dailyDone > 0 then
        addon.SortDailiesDone()
        addon:Print(L["Expired Dailies check done."])
      else
        addon:Print(L["No Dailies found to prune."])
      end
    else
      Settings.OpenToCategory(addon._category:GetID())
    end
  elseif mbutton == "RightButton" then
    addon.OnLDBIconTooltipHide()
    local menu = MenuUtil.CreateRadioContextMenu(frame,
      addon.IsCharacterSelected,
      addon.SelectCharacter,
      {_G.YOU,addon.characterKey},
      addon.GetCharactersTuple()
    )
  end
end

function addon.UpdateLDBText()
  if addon.LDBObj then
    addon.LDBObj.text = format("%s||%s",addon.ToDailyReset,addon.ToWeeklyReset)
  end
end

local characters = {}
function addon.GetCharactersTuple()
  characters = wipe(characters)
  for characterKey in pairs(addon.db.allChars) do
    if characterKey ~= addon.characterKey then
      tinsert(characters,{characterKey,characterKey})
    end
  end
  tsort(characters)
  return unpack(characters)
end

function addon.IsCharacterSelected(charKey)
  return charKey == addon.selectedCharacterKey
end

function addon.SelectCharacter(charKey)
  addon.selectedCharacterKey = charKey
  addon.SetDailiesContainer()
end

function addon.SetDailiesContainer()
  if addon.selectedCharacterKey == addon.characterKey then
    addon.dailiesContainer = addon.db_pc.dailyDone
  else
    if addon.db.allChars[addon.selectedCharacterKey] then
      addon.dailiesContainer = addon.db.allChars[addon.selectedCharacterKey]
    end
  end
  if addon.dailiesContainer then
    addon.SortDailiesDone(addon.dailiesContainer)
  end
end

function addon:PLAYER_LOGIN(event)
  addon:UnregisterEvent("PLAYER_LOGIN")
  self.db = DailyQuestsDoneDB
  self.db_pc = DailyQuestsDonePC
  self:RegisterEvent("QUEST_ACCEPTED")
  self:RegisterEvent("QUEST_TURNED_IN")
  self:RegisterUnitEvent("UNIT_QUEST_LOG_CHANGED","player")
  After(5,function()
    local num_entries, num_quests = GetNumQuestLogEntries()
    if num_quests > 0 then
      addon:UNIT_QUEST_LOG_CHANGED("UNIT_QUEST_LOG_CHANGED","player")
    end
  end)
  if QuestLogFrame then
    QuestMapFrame:HookScript("OnHide",addon.RunQueue)
  end
  if WorldMapFrame then
    WorldMapFrame:HookScript("OnHide",addon.RunQueue)
  end
  UpdateExpirationTimersText()
  addon.LDB = addon.LDB or LibStub("LibDataBroker-1.1",true)
  addon.LDBIcon = addon.LDBIcon or LibStub("LibDBIcon-1.0",true)
  addon.LDBObj = addon.LDBObj or addon.LDB:NewDataObject(addonName,
    {
      type = "data source",
      text = addonName,
      icon = 369214,
      label = "DailyQs Done",
      OnEnter = addon.OnLDBIconTooltipShow,
--      OnLeave = addon.OnLDBIconTooltipHide,
      OnClick = addon.OnLDBIconClick,
    })
  addon.LDBIcon:Register(addonName, addon.LDBObj, addon.db_pc.minimap)
  addon.LQTip = addon.LQTip or LibStub("LibQTip-1.0",true)
  --addon.LQTip.TooltipManager.TooltipPrototype.HookScript = nil -- fuck off
  addon.UpdateLDBText()
  addon:CreateSettings()
  addon:RegisterEvent("PLAYER_LOGOUT")
  addon.characterKey = format("%s-%s",(UnitNameUnmodified("player")),(GetNormalizedRealmName()))
  addon.dailiesContainer = addon.db_pc.dailyDone
  addon.selectedCharacterKey = addon.characterKey
end

function addon:PLAYER_LOGOUT(event)
  addon.PruneExpiredDailies(addon.db_pc.dailyDone)
  addon.PruneExpiredDailies(addon.db.dailyDone)
  if #addon.db_pc.dailyDone > 0 then
    addon.db.allChars[addon.characterKey] = CopyTable(addon.db_pc.dailyDone)
  end
end

function addon:PLAYER_REGEN_ENABLED(event)
  self.RunQueue()
end

function addon:UNIT_QUEST_LOG_CHANGED(event,unit)
  ScanAndStoreDailies()
end

function addon:QUEST_ACCEPTED(event,...)
  local arg1, arg2 = ...
  local questID = arg2 and arg2 or arg1
  After(0.2,function() CheckQuestForCaching(questID) end)
end

function addon:QUEST_TURNED_IN(event,...)
  local questID = ...
  if not questID then return end
  if not self.db.knownDailies[questID] then
    CheckQuestForCaching(questID)
  end
  if self.db.knownDailies[questID] then
    local info = addon.GetTurninInfo(questID)
    if info.turnedin then
      if addon.IsAccountQuest(questID) then
        tinsert(addon.db.dailyDone,info)
      else
        tinsert(addon.db_pc.dailyDone,info)
      end
    end
  end
end

--_G[addonName] = addon