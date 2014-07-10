-----------------------------------------------------------------------------------------------
-- Client Lua Script for VikingSettings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local NAME = "VikingSettings"
local VERSION = "0.0.1"

local tColors = {
  black       = "141122",
  white       = "ffffff",
  lightGrey   = "bcb7da",
  green       = "1fd865",
  yellow      = "ffd161",
  orange      = "e08457",
  lightPurple = "645f7e",
  purple      = "2b273d",
  red         = "e05757",
  blue        = "4ae8ee"
}

local defaults = {
  char = {
    ['*']                 = false,

    General = {
      colors = {
        background = "992b273d",
        gradient   = "ff141122"
      },
      dispositionColors = {
        [Unit.CodeEnumDisposition.Neutral]  = "ff" .. tColors.yellow,
        [Unit.CodeEnumDisposition.Hostile]  = "ff" .. tColors.red,
        [Unit.CodeEnumDisposition.Friendly] = "ff" .. tColors.green,
      }
    }
  }
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local VikingSettings = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
                                  NAME,
                                  true,
                                  {
                                    "Gemini:Logging-1.2",
                                    "GeminiColor",
                                    "Gemini:DB-1.0"
                                  })

function VikingSettings:OnInitialize()
  local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
  glog = GeminiLogging:GetLogger({
    level = GeminiLogging.INFO,
    pattern = "%d [%c:%n] %l - %m",
    appender = "GeminiConsole"
  })
  self.log = glog
  glog:info(string.format("Loaded "..NAME.." - "..VERSION))

  local GeminiColor= Apollo.GetPackage("GeminiColor").tPackage
  self.gcolor = GeminiColor

  self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, defaults)

  self.xmlDoc = XmlDoc.CreateFromFile("VikingSettings.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function VikingSettings:OnDocLoaded()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    Apollo.RegisterSlashCommand("vui", "OnVikingUISlashCommand", self)

    self.tAddons = {}
    self.wndContainers = {}
    self.wndButtons = {}

    VikingSettings.RegisterSettings(self, "VikingSettings")
  end
end

function VikingSettings.GetDatabase(strAddonName)
  local db = VikingSettings.db.char[strAddonName]
  if db then
    db.General = VikingSettings.db.char.General
  end
  return db
end

function VikingSettings.RegisterSettings(tAddon, strAddonName, tDefaults)
  if tAddon and strAddonName then
    if not VikingSettings.tAddons[strAddonName] then
      VikingSettings.tAddons[strAddonName] = tAddon

      if tDefaults then
        VikingSettings:RegisterDefaults(strAddonName, tDefaults)
      end

      if not VikingSettings.db.char[strAddonName] then
        VikingSettings.db.char[strAddonName] = {}
      end
    else
      glog:warn("Tried to register addon '" ..strAddonName.. "' but it was already registered.")
    end
  end
end

function VikingSettings:RegisterDefaults(strAddonName, tDefaults)
  if not VikingSettings.db.char[strAddonName] then
    VikingSettings.db.char[strAddonName] = {}
  end

  if not VikingSettings.db.defaults.char[strAddonName] then
    VikingSettings.db.defaults.char[strAddonName] = tDefaults
  end

  VikingSettings:MergeTables(VikingSettings.db.char[strAddonName], tDefaults)
end

function VikingSettings:ResetAddon(strAddonName)
  if not VikingSettings.db.char[strAddonName] then 
    return 
  end

  for k in pairs (VikingSettings.db.char[strAddonName]) do
    VikingSettings.db.char[strAddonName][k] = nil
  end

  local tDefaults = VikingSettings.db.defaults.char[strAddonName]

  if tDefaults then
    VikingSettings:RegisterDefaults(strAddonName, tDefaults)
  end

  VikingSettings:UpdateForm(strAddonName)
end

function VikingSettings:ShowSettings(bShow)
  if bShow then
    if not self.wndSettings then
      self:BuildSettingsWindow()
    end

    self:UpdateAllForms()
  end

  self.wndSettings:Show(bShow, false)
end

function VikingSettings:UpdateForm(strAddonName)
  local tAddon = VikingSettings.tAddons[strAddonName]
  local wndContainer = VikingSettings.wndContainers[strAddonName]

  if wndContainer and tAddon and tAddon.UpdateSettingsForm then
    tAddon:UpdateSettingsForm(wndContainer)
  end
end

function VikingSettings:UpdateAllForms()
  for strAddonName, tAddon in pairs(self.tAddons) do
    VikingSettings:UpdateForm(strAddonName)
  end
end

function VikingSettings:BuildSettingsWindow()
  self.wndSettings = Apollo.LoadForm(self.xmlDoc, "VikingSettingsForm", nil, self)

  local cnt = 0
  for strAddonName, tAddon in pairs(self.tAddons) do
    self.CreateAddonForm(strAddonName)
    self.wndButtons[strAddonName]:SetAnchorOffsets(0, cnt * 40, 0, (cnt + 1) * 40)

    if cnt == 0 then 
      self.wndButtons[strAddonName]:SetCheck(true) 
    end

    cnt = cnt + 1
  end

  self:OnSettingsMenuButtonCheck()
end

function VikingSettings.CreateAddonForm(strAddonName)
  local tAddon = VikingSettings.tAddons[strAddonName]
  local wndAddonContainer = Apollo.LoadForm(tAddon.xmlDoc, "VikingSettings", VikingSettings.wndSettings:FindChild("Content"), tAddon)
  local wndAddonButton    = Apollo.LoadForm(VikingSettings.xmlDoc, "AddonButton", VikingSettings.wndSettings:FindChild("Menu"), VikingSettings)
  
  -- attaching makes it show/hide the container according to the check state
  wndAddonButton:AttachWindow(wndAddonContainer)
  wndAddonButton:SetText(strAddonName)
  wndAddonButton:Show(true)
  wndAddonButton:SetCheck(false)

  wndAddonContainer:Show(false)

  VikingSettings.wndContainers[strAddonName] = wndAddonContainer
  VikingSettings.wndButtons[strAddonName] = wndAddonButton
end

-- merges t2 into t1 without overwriting values
function VikingSettings:MergeTables(t1, t2)
  for k, v in pairs(t2) do
      if type(v) == "table" then
          if not t1[k] or type(t1[k]) ~= "table" then
            t1[k] = {}
          end

          VikingSettings:MergeTables(t1[k], t2[k])
      elseif not t1[k] then
          t1[k] = v
      end
  end
  return t1
end

-----------------------------------------------------------------------------------------------
-- Color Functions
-----------------------------------------------------------------------------------------------

--
-- ShowColorPickerForSetting(tSection, strKeyName[, callback][, wndControl])
--
--   Shows a color picker for a specific color setting in the database
-- 
-- tSection is a reference to the table containing the color
-- strKeyName is the key name for the color in that section
-- callback is a function reference that's called when the color changes
-- wndControl is a window which bagground will show the color
--
-- callback(tSection, strKeyName, strColor, wndControl)
--
function VikingSettings.ShowColorPickerForSetting(tSection, strKeyName, callback, wndControl)
  local strInitialColor = tSection[strKeyName]

  VikingSettings.gcolor:ShowColorPicker(VikingSettings, "OnColorPicker", true, strInitialColor, tSection, strKeyName, callback, wndControl)
end

function VikingSettings:OnColorPicker(strColor, tSection, strKeyName, callback, wndControl)
  tSection[strKeyName] = strColor

  if wndControl then
    wndControl:SetBGColor(strColor)
  end

  if callback then
    callback(tSection, strKeyName, strColor, wndControl)
  end
end

-----------------------------------------------------------------------------------------------
-- VikingSettings Form Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnSettingsMenuButtonCheck( wndHandler, wndControl, eMouseButton )
  self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  self.wndSettings:FindChild("Content"):RecalculateContentExtents()
end

function VikingSettings:OnResetEverythingButton( wndHandler, wndControl, eMouseButton )
  for strAddonName, tAddon in pairs(self.tAddons) do
    self:ResetAddon(strAddonName)
  end
end

-----------------------------------------------------------------------------------------------
-- VikingSettings Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnVikingUISlashCommand(strCmd, strParam)
  self:ShowSettings(true)
end

function VikingSettings:OnConfigure()
  self:ShowSettings(true)
end

-----------------------------------------------------------------------------------------------
-- VikingSettingsForm Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnCloseButton()
  self:ShowSettings(false)
end