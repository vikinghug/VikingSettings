-----------------------------------------------------------------------------------------------
-- Client Lua Script for VikingSettings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

-----------------------------------------------------------------------------------------------
-- VikingSettings Module Definition
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local NAME = "VikingSettings"
local VERSION = "0.0.1"

local tColors = {
  black       = "201e2d",
  white       = "ffffff",
  lightGrey   = "bcb7da",
  green       = "1fd865",
  yellow      = "ffd161",
  orange      = "e08457",
  lightPurple = "645f7e",
  purple      = "28253a",
  red         = "e05757",
  blue        = "4ae8ee"
}

local defaults = {
  char = {
    ['*']                 = false,
    testbool              = true,

    VikingTargetFrame = {
      Player = {
        style             = 0,
        HighHealthColor   = "ff" .. tColors.green,
        HealthColor       = "ff" .. tColors.yellow,
        LowHealthColor    = "ff" .. tColors.red,
        ShieldColor       = "ff" .. tColors.blue,
        AbsorbColor       = "ff" .. tColors.yellow,
        EnableCastbar     = true
      },
      Target = {
        style             = 0,
        HighHealthColor   = "ff" .. tColors.green,
        HealthColor       = "ff" .. tColors.yellow,
        LowHealthColor    = "ff" .. tColors.red,
        ShieldColor       = "ff" .. tColors.blue,
        AbsorbColor       = "ff" .. tColors.yellow,
        EnableCastbar     = true
      },
      Focus = {
        style             = 0,
        HighHealthColor   = "ff2fdc02",
        HealthColor       = "ffffd161",
        LowHealthColor    = "ffe05757",
        ShieldColor       = "ff00ffff",
        AbsorbColor       = "ffffff00",
        EnableCastbar     = true
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

    self.bSettingsOpen = false


    -- Do additional Addon initialization here
  end
end

function VikingSettings:ShowHideSettings()
  self.bSettingsOpen = not self.bSettingsOpen
  if not self.wndSettings then
    -- Create Window
    self.wndSettings = Apollo.LoadForm(self.xmlDoc, "VikingSettingsForm", nil, self)
    self.Addons = {}
    self.AddonContainers = {}
    self.AddonButtons = {}
    self.currentID = 0

    if Apollo.GetAddon("VikingTargetFrame") then
      self:CreateAddonForm("VikingTargetFrame")
    end
    if Apollo.GetAddon("VikingClassResources") then
      self:CreateAddonForm("VikingClassResources")
    end

    for id, currentAddonButton in ipairs(self.AddonButtons) do
      currentAddonButton:SetAnchorOffsets(0, ((id-1)*40), 192, (id*40))
    end
  end
  if self.bSettingsOpen then
    -- Open Window
    self.AddonButtons[1]:SetCheck(true)
    self:OnSettingsMenuButtonCheck()
  end
  self.wndSettings:Show(self.bSettingsOpen, false)
end

function VikingSettings:CreateAddonForm(addonName)
  glog:info("Create Addon Form: '"..addonName.."'")

  local newAddonContainer = Apollo.LoadForm(self.xmlDoc, addonName, self.wndSettings:FindChild("Content"), self)

  local newAddonButton = Apollo.LoadForm(self.xmlDoc, "AddonButton", self.wndSettings:FindChild("Menu"), self)
  newAddonButton:SetText(addonName)

  if addonName == "VikingTargetFrame" then
    newAddonContainer:FindChild("Menu:PlayerButton"):SetCheck(true)
    newAddonContainer:FindChild("Content"):RecalculateContentExtents()

    newAddonContainer:FindChild("Content:Player:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Player:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Player:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Player:Colors:LifeBar:HighHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Player.HighHealthColor)
    newAddonContainer:FindChild("Content:Player:Colors:LifeBar:HealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Player.HealthColor)
    newAddonContainer:FindChild("Content:Player:Colors:LifeBar:LowHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Player.LowHealthColor)
    newAddonContainer:FindChild("Content:Player:Colors:LifeBar:ShieldButton"):SetTextColor(self.db.char.VikingTargetFrame.Player.ShieldColor)
    newAddonContainer:FindChild("Content:Player:Colors:LifeBar:AbsorbButton"):SetTextColor(self.db.char.VikingTargetFrame.Player.AbsorbColor)
    newAddonContainer:FindChild("Content:Player:OtherSettings:Content:CastBarButton"):SetCheck(self.db.char.VikingTargetFrame.Player.EnableCastbar)

    newAddonContainer:FindChild("Content:Target:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Target:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Target:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Target:Colors:LifeBar:HighHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Target.HighHealthColor)
    newAddonContainer:FindChild("Content:Target:Colors:LifeBar:HealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Target.HealthColor)
    newAddonContainer:FindChild("Content:Target:Colors:LifeBar:LowHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Target.LowHealthColor)
    newAddonContainer:FindChild("Content:Target:Colors:LifeBar:ShieldButton"):SetTextColor(self.db.char.VikingTargetFrame.Target.ShieldColor)
    newAddonContainer:FindChild("Content:Target:Colors:LifeBar:AbsorbButton"):SetTextColor(self.db.char.VikingTargetFrame.Target.AbsorbColor)
    newAddonContainer:FindChild("Content:Target:OtherSettings:Content:CastBarButton"):SetCheck(self.db.char.VikingTargetFrame.Target.EnableCastbar)

    newAddonContainer:FindChild("Content:Focus:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Focus:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Focus:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Focus:Colors:LifeBar:HighHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Focus.HighHealthColor)
    newAddonContainer:FindChild("Content:Focus:Colors:LifeBar:HealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Focus.HealthColor)
    newAddonContainer:FindChild("Content:Focus:Colors:LifeBar:LowHealthButton"):SetTextColor(self.db.char.VikingTargetFrame.Focus.LowHealthColor)
    newAddonContainer:FindChild("Content:Focus:Colors:LifeBar:ShieldButton"):SetTextColor(self.db.char.VikingTargetFrame.Focus.ShieldColor)
    newAddonContainer:FindChild("Content:Focus:Colors:LifeBar:AbsorbButton"):SetTextColor(self.db.char.VikingTargetFrame.Focus.AbsorbColor)
    newAddonContainer:FindChild("Content:Focus:OtherSettings:Content:CastBarButton"):SetCheck(self.db.char.VikingTargetFrame.Focus.EnableCastbar)
  end
  if addonName == "VikingClassResources" then
    newAddonContainer:FindChild("Menu:WarriorButton"):SetCheck(true)
    newAddonContainer:FindChild("Content"):RecalculateContentExtents()

    newAddonContainer:FindChild("Content:Warrior:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Warrior:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Warrior:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Warrior:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Warrior.ResourceColor)

    newAddonContainer:FindChild("Content:Spellslinger:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Spellslinger:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Spellslinger:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Spellslinger:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Spellslinger.ResourceColor)

    newAddonContainer:FindChild("Content:Esper:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Esper:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Esper:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Esper:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Esper.ResourceColor)
    newAddonContainer:FindChild("Content:Esper:Effects:Content:GlowButton"):SetCheck(self.db.char.VikingClassResources.Esper.EnableGlow)

    newAddonContainer:FindChild("Content:Engineer:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Engineer:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Engineer:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Engineer:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Engineer.ResourceColor)

    newAddonContainer:FindChild("Content:Stalker:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Stalker:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Stalker:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Stalker:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Stalker.ResourceColor)

    newAddonContainer:FindChild("Content:Medic:Style:Content:Button0"):Enable(false)
    newAddonContainer:FindChild("Content:Medic:Style:Content:Button1"):Enable(false)
    newAddonContainer:FindChild("Content:Medic:Style:Content:Button2"):Enable(false)
    newAddonContainer:FindChild("Content:Medic:Colors:Content:ResourceBarButton"):SetTextColor(self.db.char.VikingClassResources.Medic.ResourceColor)
  end

  table.insert(self.Addons, addonName)
  table.insert(self.AddonContainers, newAddonContainer)
  table.insert(self.AddonButtons, newAddonButton)
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
    self.AddonContainers[id]:Show(self.AddonButtons[id]:IsChecked())
    if self.AddonButtons[id]:IsChecked() then
      self.currentID = id
    end
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

function VikingSettings:OnTargetFrameHealthColorButton( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingTargetFrame[target].HealthColor, wndHandler, "VikingTargetFrame", target, "HealthColor")
end

function VikingSettings:OnTargetFrameLowHealthColorButton( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingTargetFrame[target].LowHealthColor, wndHandler, "VikingTargetFrame", target, "LowHealthColor")
end

function VikingSettings:OnTargetFrameShieldColorButton( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingTargetFrame[target].ShieldColor, wndHandler, "VikingTargetFrame", target, "ShieldColor")
end

function VikingSettings:OnTargetFrameAbsorbColorButton( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.gcolor:ShowColorPicker(self, "UpdateTextColor", true, self.db.char.VikingTargetFrame[target].AbsorbColor, wndHandler)
end

function VikingSettings:OnTargetFrameCastBarButtonUp( wndHandler, wndControl, eMouseButton )
  local target = wndHandler:GetParent():GetParent():GetParent():GetName()
  self.db.char.VikingTargetFrame[target].EnableCastbar = wndHandler:IsChecked()
end

-----------------------------------------------------------------------------------------------
-- ClassResource Functions
-----------------------------------------------------------------------------------------------
function VikingSettings:OnClassResourceMenuButtonCheck( wndHandler, wndControl, eMouseButton )
  self.AddonContainers[self.currentID]:FindChild("Content:Warrior"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:WarriorButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Spellslinger"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:SpellslingerButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Esper"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:EsperButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Engineer"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:EngineerButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Stalker"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:StalkerButton"):IsChecked())
  self.AddonContainers[self.currentID]:FindChild("Content:Medic"):Show(self.AddonContainers[self.currentID]:FindChild("Menu:MedicButton"):IsChecked())

  self.wndSettings:FindChild("Content"):SetVScrollPos(0)
  self.AddonContainers[self.currentID]:FindChild("Content"):RecalculateContentExtents()
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
