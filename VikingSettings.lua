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
                                  false,
                                  {
                                    "Gemini:Logging-1.2",
                                    "GeminiColor",
                                    "Gemini:DB-1.0"
                                  })

function VikingSettings:OnInitialize()
  -- setup logger
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

  -- setup database
  self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, defaults)

  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("VikingSettings.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- VikingSettings OnDocLoaded
-----------------------------------------------------------------------------------------------
function VikingSettings:OnDocLoaded()

  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
      self.wndMain = Apollo.LoadForm(self.xmlDoc, "VikingSettingsForm", nil, self)
    if self.wndMain == nil then
      Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
      return
    end

      self.wndMain:Show(false, true)

    -- if the xmlDoc is no longer needed, you should set it to nil
    -- self.xmlDoc = nil

    -- Register handlers for events, slash commands and timer, etc.

    Apollo.RegisterSlashCommand("vui", "OnVikingUISlashCommand", self)
    self.Addons = {}
    self.AddonContainers = {}
    self.AddonButtons = {}

    self.bSettingsOpen = false


    -- Do additional Addon initialization here
  end
end

function VikingSettings:ShowHideSettings()
  self.bSettingsOpen = not self.bSettingsOpen
  if not self.wndSettings then
    -- Create Window
    self.wndSettings = Apollo.LoadForm(self.xmlDoc, "VikingSettingsForm", nil, self)
    self.currentID = 0

    for id, addon in ipairs(self.Addons) do
      self.CreateAddonForm(addon.parent, addon.addonName)
    end
  --   if Apollo.GetAddon("VikingTargetFrame") then
  --     self.CreateAddonForm("VikingTargetFrame")
  --   end
  --   if Apollo.GetAddon("VikingClassResources") then
  --     self.CreateAddonForm("VikingClassResources")
  --   end

    for id, currentAddonButton in ipairs(self.AddonButtons) do
      currentAddonButton:SetAnchorOffsets(0, ((id-1)*40), 192, (id*40))
    end
  end
  if self.bSettingsOpen then
    -- Open Window
    SendVarToRover("self.AddonButtons[1]", self.AddonButtons[1])
    self.AddonButtons[1]:Show(true)
    self.AddonButtons[1]:SetCheck(true)
    self:OnSettingsMenuButtonCheck()
  end
  self.wndSettings:Show(self.bSettingsOpen, false)

end

function VikingSettings.CreateAddonForm(parent, addonName)
  glog:info("Create Addon Form: '"..addonName.."'")

  SendVarToRover("VikingSettings", parent.xmlDoc)

  local newAddonContainer = Apollo.LoadForm(parent.xmlDoc         , "VikingSettings" , VikingSettings.wndMain:FindChild("Content") , VikingSettings)
  local newAddonButton    = Apollo.LoadForm(VikingSettings.xmlDoc , "AddonButton"    , VikingSettings.wndMain:FindChild("Menu")    , VikingSettings)
  newAddonButton:SetText(addonName)

  table.insert(VikingSettings.AddonContainers, newAddonContainer)
  table.insert(VikingSettings.AddonButtons, newAddonButton)
end

function VikingSettings.RegisterSettings(parent, addonName)
  local addon = {
    parent    = parent,
    addonName = addonName
  }
  table.insert(VikingSettings.Addons, addon)
  return
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
  for id, currentAddon in ipairs(self.Addons) do
    -- self.AddonContainers[id]:Show(self.AddonButtons[id]:IsChecked())
    -- if self.AddonButtons[id]:IsChecked() then
    --   self.currentID = id
    -- end
  end
  glog:info("Current ID: "..self.currentID)

  self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  self.wndSettings:FindChild("Content"):RecalculateContentExtents()
end

-----------------------------------------------------------------------------------------------
-- TargetFrame Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnTargetFrameMenuButtonCheck( wndHandler, wndControl, eMouseButton )
  self.AddonContainers[self.currentID]:FindChild("Content:Player"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:PlayerButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Target"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:TargetButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Focus"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:FocusButton"):IsChecked())

  self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  self.AddonContainers[self.currentID]:FindChild("Content"):RecalculateContentExtents()
end

function VikingSettings:OnTargetFrameHighHealthColorButton( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingTargetFrame[target].HighHealthColor, wndHandler, "VikingTargetFrame", target, "HighHealthColor")
end


-----------------------------------------------------------------------------------------------
-- ClassResource Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnClassResourceMenuButtonCheck( wndHandler, wndControl, eMouseButton )
  -- self.AddonContainers[self.currentID]:FindChild("Content:Warrior"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:WarriorButton"):IsChecked())
  -- self.AddonContainers[self.currentID]:FindChild("Content:Spellslinger"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:SpellslingerButton"):IsChecked())
  -- self.AddonContainers[self.currentID]:FindChild("Content:Esper"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:EsperButton"):IsChecked())
  -- self.AddonContainers[self.currentID]:FindChild("Content:Engineer"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:EngineerButton"):IsChecked())
  -- self.AddonContainers[self.currentID]:FindChild("Content:Stalker"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:StalkerButton"):IsChecked())
  -- self.AddonContainers[self.currentID]:FindChild("Content:Medic"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:MedicButton"):IsChecked())

  -- self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  -- self.AddonContainers[self.currentID]:FindChild("Content"):RecalculateContentExtents()
end

function VikingSettings:OnClassResourceResourceBarColorButton( wndHandler, wndControl, eMouseButton )
  local class = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingClassResources[class].ResourceColor, wndHandler, "VikingClassResources", class, "ResourceColor")
end

function VikingSettings:OnClassResourceGlowEffectButtonUp( wndHandler, wndControl, eMouseButton )
  local class = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.db.char.VikingClassResources[class].EnableGlow = wndHandler:IsChecked()
end

-----------------------------------------------------------------------------------------------
-- VikingSettings Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/vui"
function VikingSettings:OnVikingUISlashCommand(strCmd, strParam)
  if string.find(strParam, "tb") == 1 then
    if string.find(strParam, "1") == 4 then
      self.db.char.testbool = true
      glog:info("testbool = true")
    elseif string.find(strParam, "0") == 4 then
      self.db.char.testbool = false
      glog:info("testbool = false")
    else
      if self.db.char.testbool then
        glog:info("testbool == true")
      else
        glog:info("testbool == false")
      end
    end
  else
    self:ShowHideSettings()-- show the window
  end
end


-----------------------------------------------------------------------------------------------
-- VikingSettingsForm Functions
-----------------------------------------------------------------------------------------------
-- when the Close button is clicked
function VikingSettings:OnCloseButton()
  self:ShowHideSettings() -- hide the window
end
