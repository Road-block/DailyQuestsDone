local addonName, addon = ...
local L = addon.L

function addon.OnSettingChanged(setting,value)
  addon.LDBIcon:Refresh(addonName,DailyQuestsDonePC.minimap)
end

function addon:CreateSettings()
  addon._category = Settings.RegisterVerticalLayoutCategory(addonName)
  local variableTable = DailyQuestsDonePC.minimap
  do
    local name = L["Hide Minimap Icon"]
    local variable = addonName.."_MINIMAP_HIDE"
    local variableKey = "hide"
    local defaultValue = true
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Hide the addon icon from Minimap.\nCan still display it on a DataBroker panel."]
    Settings.CreateCheckbox(addon._category, setting, tooltip)
  end
  do
    local name = L["Lock Minimap Icon"]
    local variable = addonName.."_MINIMAP_LOCK"
    local variableKey = "lock"
    local defaultValue = false
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Lock Minimap Icon position."]
    Settings.CreateCheckbox(addon._category, setting, tooltip)
  end
  do
    local name = L["Minimap Icon Position"]
    local variable = addonName.."_MINIMAP_POS"
    local variableKey = "minimapPos"
    local defaultValue = 275
    local minValue = 0
    local maxValue = 360
    local step = 5
    local function GetValue()
      return variableTable.minimapPos or defaultValue
    end
    local function SetValue(value)
      variableTable.minimapPos = value
    end
    local setting = Settings.RegisterProxySetting(addon._category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Minimap Icon Position in Degrees (0-360)."]
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(addon._category, setting, options, tooltip)
  end
  do
    variableTable = DailyQuestsDonePC
    local name = L["Boss Kill Check"]
    local variable = addonName.."_BOSSKILL_DELAY"
    local variableKey = "scanDelay"
    local defaultValue = 1.5
    local minValue = 0.5
    local maxValue = 5
    local step = 0.2
    local function GetValue()
      return variableTable.scanDelay or defaultValue
    end
    local function SetValue(value)
      variableTable.scanDelay = value
    end
    local setting = Settings.RegisterProxySetting(addon._category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["World Boss Kill Check Delay in Seconds (0.5-5.0).\nIncrease if server lag is typically High."]
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(addon._category, setting, options, tooltip)
  end

  Settings.RegisterAddOnCategory(addon._category)
end
