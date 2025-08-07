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
    local variable = "hide"
    local variableKey = "hide"
    local defaultValue = true
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Hide the addon icon from Minimap.\nCan still display it on a DataBroker panel."]
    Settings.CreateCheckbox(addon._category, setting, tooltip)
  end
  do
    local name = L["Lock Minimap Icon"]
    local variable = "lock"
    local variableKey = "lock"
    local defaultValue = false
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Lock Minimap Icon position."]
    Settings.CreateCheckbox(addon._category, setting, tooltip)
  end
  do
    local name = L["Minimap Icon Position"]
    local variable = "minimapPos"
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

  Settings.RegisterAddOnCategory(addon._category)
end