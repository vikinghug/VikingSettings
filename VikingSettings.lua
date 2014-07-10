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
-- Upvalues
-----------------------------------------------------------------------------------------------
local MergeTables, RegisterDefaults, UpdateForm, UpdateAllForms, CreateAddonForm, BuildSettingsWindow

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

local tAddons = {}
local wndContainers = {}
local wndButtons = {}

local wndSettings

local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
local glog

local GColor = Apollo.GetPackage("GeminiColor").tPackage

local db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(VikingSettings, defaults)

function VikingSettings:OnInitialize()
  glog = GeminiLogging:GetLogger({
              level = GeminiLogging.INFO,
              pattern = "%d [%c:%n] %l - %m",
              appender = "GeminiConsole"
             })

  glog:info(string.format("Loaded "..NAME.." - "..VERSION))

  self.xmlDoc = XmlDoc.CreateFromFile("VikingSettings.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function VikingSettings:OnDocLoaded()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    Apollo.RegisterSlashCommand("vui", "OnVikingUISlashCommand", self)

    VikingSettings.RegisterSettings(self, "VikingSettings")
  end
end

function VikingSettings.GetDatabase(strAddonName)
  local tDb = db.char[strAddonName]
  if tDb then
    tDb.General = db.char.General
  end
  return tDb
end

function VikingSettings.RegisterSettings(tAddon, strAddonName, tDefaults)
  if tAddon and strAddonName then
    if not tAddons[strAddonName] then
      tAddons[strAddonName] = tAddon

      if tDefaults then
        RegisterDefaults(strAddonName, tDefaults)
      end

      if not db.char[strAddonName] then
        db.char[strAddonName] = {}
      end
    else
      glog:warn("Tried to register addon '" ..strAddonName.. "' but it was already registered.")
    end
  end
end

function RegisterDefaults(strAddonName, tDefaults)
  if not db.char[strAddonName] then
    db.char[strAddonName] = {}
  end

  if not db.defaults.char[strAddonName] then
    db.defaults.char[strAddonName] = tDefaults
  end

  MergeTables(db.char[strAddonName], tDefaults)
end

function VikingSettings:ResetAddon(strAddonName)
  if not db.char[strAddonName] then 
    return 
  end

  for k in pairs (db.char[strAddonName]) do
    db.char[strAddonName][k] = nil
  end

  local tDefaults = db.defaults.char[strAddonName]

  if tDefaults then
    RegisterDefaults(strAddonName, tDefaults)
  end

  UpdateForm(strAddonName)
end

function VikingSettings:ShowSettings(bShow)
  if bShow then
    if not wndSettings then
      BuildSettingsWindow()
    end

    UpdateAllForms()
  end

  wndSettings:Show(bShow, false)
end

function UpdateForm(strAddonName)
  local tAddon = tAddons[strAddonName]
  local wndContainer = wndContainers[strAddonName]

  if wndContainer and tAddon and tAddon.UpdateSettingsForm then
    tAddon:UpdateSettingsForm(wndContainer)
  end
end

function UpdateAllForms()
  for strAddonName, tAddon in pairs(tAddons) do
    UpdateForm(strAddonName)
  end
end

function BuildSettingsWindow()
  wndSettings = Apollo.LoadForm(VikingSettings.xmlDoc, "VikingSettingsForm", nil, VikingSettings)

  local cnt = 0
  for strAddonName, tAddon in pairs(tAddons) do
    CreateAddonForm(strAddonName)
    wndButtons[strAddonName]:SetAnchorOffsets(0, cnt * 40, 0, (cnt + 1) * 40)

    if cnt == 0 then 
      wndButtons[strAddonName]:SetCheck(true) 
    end

    cnt = cnt + 1
  end

  VikingSettings:OnSettingsMenuButtonCheck()
end

function CreateAddonForm(strAddonName)
  local tAddon = tAddons[strAddonName]
  local wndAddonContainer = Apollo.LoadForm(tAddon.xmlDoc, "VikingSettings", wndSettings:FindChild("Content"), tAddon)
  local wndAddonButton    = Apollo.LoadForm(VikingSettings.xmlDoc, "AddonButton", wndSettings:FindChild("Menu"), VikingSettings)
  
  -- attaching makes it show/hide the container according to the check state
  wndAddonButton:AttachWindow(wndAddonContainer)
  wndAddonButton:SetText(strAddonName)
  wndAddonButton:Show(true)
  wndAddonButton:SetCheck(false)

  wndAddonContainer:Show(false)

  wndContainers[strAddonName] = wndAddonContainer
  wndButtons[strAddonName] = wndAddonButton
end

-- merges t2 into t1 without overwriting values
function MergeTables(t1, t2)
  for k, v in pairs(t2) do
      if type(v) == "table" then
          if not t1[k] or type(t1[k]) ~= "table" then
            t1[k] = {}
          end

          MergeTables(t1[k], t2[k])
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

  GColor:ShowColorPicker(VikingSettings, "OnColorPicker", true, strInitialColor, tSection, strKeyName, callback, wndControl)
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
  wndSettings:FindChild("Content"):SetVScrollPos(0)
  wndSettings:FindChild("Content"):RecalculateContentExtents()
end

function VikingSettings:OnResetEverythingButton( wndHandler, wndControl, eMouseButton )
  for strAddonName, tAddon in pairs(tAddons) do
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