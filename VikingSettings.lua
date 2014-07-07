-----------------------------------------------------------------------------------------------
-- Client Lua Script for VikingSettings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"

-----------------------------------------------------------------------------------------------
-- VikingSettings Module Definition
-----------------------------------------------------------------------------------------------

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
    testbool              = true,

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
    },

    VikingUnitFrames = {
      style               = 0,
      position = {
        playerFrame = {
          fPoints  = {0.5, 1, 0.5, 1},
          nOffsets = {-350, -200, -100, -120}
        },
        targetFrame = {
          fPoints  = {0.5, 1, 0.5, 1},
          nOffsets = {100, -200, 350, -120}
        },
        focusFrame = {
          fPoints  = {0, 1, 0, 1},
          nOffsets = {40, -500, 250, -440}
        }
      },
      text = {
        percent = true,
        value   = false,
        none    = false
      },
      colors = {
        Health = { high = "ff" .. tColors.green,  average = "ff" .. tColors.yellow, low = "ff" .. tColors.red },
        Shield = { high = "ff" .. tColors.blue,   average = "ff" .. tColors.blue, low = "ff" ..   tColors.blue },
        Absorb = { high = "ff" .. tColors.yellow, average = "ff" .. tColors.yellow, low = "ff" .. tColors.yellow },
      },
    },

    VikingClassResources = {
      Warrior = {
        style             = 0,
        ResourceColor     = "ffffffff",
      },
      Spellslinger = {
        style             = 0,
        ResourceColor     = "ffffffff",
      },
      Esper = {
        style             = 0,
        ResourceColor     = "ffffffff",
        EnableGlow        = true,
      },
      Engineer = {
        style             = 0,
        ResourceColor     = "ffffffff",
      },
      Stalker = {
        style             = 0,
        ResourceColor     = "ffffffff",
      },
      Medic = {
        style             = 0,
        ResourceColor     = "ffffffff",
      },
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

    VikingSettings.RegisterSettings(self, "VikingSettings")
  end
end

function VikingSettings.RegisterSettings(tAddon, strAddonName)
  if tAddon then
    local tAddonData = 
    {
      tAddon = tAddon,
      strAddonName = strAddonName
    }

    if not VikingSettings:IsAddonRegistered(strAddonName) then
      table.insert(VikingSettings.tAddons, tAddonData)
    else
      glog:warn("Tried to register addon '" ..strAddonName.. "' but it was already registered.")
    end
  end
end

function VikingSettings:IsAddonRegistered(strAddonName)
  for id, tAddonData in pairs(self.tAddons) do
    if tAddonData.strAddonName == strAddonName then
      return true
    end
  end

  return false
end

function VikingSettings:ShowSettings(bShow)
  if not self.wndSettings then
    self:BuildSettingsWindow()
  end

  self.wndSettings:Show(bShow, false)
end

function VikingSettings:BuildSettingsWindow()
  self.wndSettings = Apollo.LoadForm(self.xmlDoc, "VikingSettingsForm", nil, self)

  for id, tAddonData in ipairs(self.tAddons) do
    self.CreateAddonForm(tAddonData)
    tAddonData.tButton:SetAnchorOffsets(0, (id - 1) * 40, 0, id * 40)
  end

  self.tAddons[1].tButton:SetCheck(true)
  self:OnSettingsMenuButtonCheck()
end

function VikingSettings.CreateAddonForm(tAddonData)
  local wndAddonContainer = Apollo.LoadForm(tAddonData.tAddon.xmlDoc, "VikingSettings", VikingSettings.wndSettings:FindChild("Content"), tAddonData.tAddon)
  local wndAddonButton    = Apollo.LoadForm(VikingSettings.xmlDoc, "AddonButton", VikingSettings.wndSettings:FindChild("Menu"), VikingSettings)
  
  -- attaching makes it show/hide the container according to the check state
  wndAddonButton:AttachWindow(wndAddonContainer)
  wndAddonButton:SetText(tAddonData.strAddonName)
  wndAddonButton:Show(true)
  wndAddonButton:SetCheck(false)

  wndAddonContainer:Show(false)

  tAddonData.tContainer = wndAddonContainer
  tAddonData.tButton = wndAddonButton
end

-----------------------------------------------------------------------------------------------
-- Color Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:UpdateTextColor(strColor, wndHandler, addon, subSection, varName)
  self.db.char[addon][subSection][varName] = strColor
  wndHandler:SetTextColor(strColor)
end

-----------------------------------------------------------------------------------------------
-- VikingSettings Form Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnSettingsMenuButtonCheck( wndHandler, wndControl, eMouseButton )
  self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  self.wndSettings:FindChild("Content"):RecalculateContentExtents()
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