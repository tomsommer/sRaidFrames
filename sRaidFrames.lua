﻿local select, next, pairs, tinsert, tconcat, tonumber, ceil, fmod = select, next, pairs, tinsert, table.concat, tonumber, ceil, math.fmod
local InCombatLockdown, IsInInstance, CheckInteractDistance, IsSpellInRange, IsRaidLeader, IsRaidOfficer =
      InCombatLockdown, IsInInstance, CheckInteractDistance, IsSpellInRange, IsRaidLeader, IsRaidOfficer
local GetNumTalentTabs, GetTalentTabInfo, GetSpellInfo, GetNumGroupMembers, GetRaidRosterInfo =
      GetNumTalentTabs, GetTalentTabInfo, GetSpellInfo, GetNumGroupMembers, GetRaidRosterInfo
local UnitClass, UnitInRange, UnitIsVisible, UnitIsUnit, UnitName, UnitIsDead, UnitIsGhost, UnitIsConnected, UnitIsAFK =
      UnitClass, UnitInRange, UnitIsVisible, UnitIsUnit, UnitName, UnitIsDead, UnitIsGhost, UnitIsConnected, UnitIsAFK
local UnitHealth, UnitHealthMax, UnitPowerType, UnitMana, UnitManaMax, UnitDebuff, UnitBuff, UnitAffectingCombat, UnitRace =
      UnitHealth, UnitHealthMax, UnitPowerType, UnitMana, UnitManaMax, UnitDebuff, UnitBuff, UnitAffectingCombat, UnitRace
local UnitExists, IsAltKeyDown = UnitExists, IsAltKeyDown
local GetRaidTargetIndex = GetRaidTargetIndex

local PowerBarColor, RAID_CLASS_COLORS = PowerBarColor, RAID_CLASS_COLORS

local L = LibStub("AceLocale-3.0"):GetLocale("sRaidFrames")
local LibGroupTalents = LibStub:GetLibrary("LibGroupTalents-1.0", true)
local HealComm = LibStub("LibClassicHealComm-1.0", true)
local ResComm = LibStub("LibResComm-1.0", true)
local Media = LibStub("LibSharedMedia-3.0")
local Banzai = LibStub("LibBanzai-2.0", true)
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local createLDBLauncher

local AE2 = AceLibrary and AceLibrary:HasInstance("AceEvent-2.0") and AceLibrary("AceEvent-2.0")

Media:Register("statusbar", "Otravi", "Interface\\AddOns\\sRaidFrames\\textures\\otravi")
Media:Register("statusbar", "Smooth", "Interface\\AddOns\\sRaidFrames\\textures\\smooth")
Media:Register("statusbar", "Striped", "Interface\\AddOns\\sRaidFrames\\textures\\striped")
Media:Register("statusbar", "BantoBar", "Interface\\AddOns\\sRaidFrames\\textures\\bantobar")

sRaidFrames = LibStub("AceAddon-3.0"):NewAddon("sRaidFrames",
	"AceEvent-3.0",
	"AceTimer-3.0",
	"AceBucket-3.0",
	"AceConsole-3.0"
)

local sRaidFrames = sRaidFrames

local SpellCache = setmetatable({}, {
	__index = function(table, id)
		local name = GetSpellInfo(id)
		if not name then
			print("sRaidFrames: spell was removed", id)
		else
			table[id] = name
		end
		return name
	end
})

local defaults = { profile = {
	Locked				= false,
	HealthFormat		= 'percent',
	HideMaxHealth		= false,
	Invert 				= false,
	Scale				= 1,
	Border				= true,
	Texture				= "Otravi",
	BuffType			= "debuffs",
	ShowOnlyDispellable	= 1,
	BackgroundColor		= {r = 0.32, g = 0.50, b = 0.70, a = 0.90},
	classspelltable 	= {['*'] = {IsFiltered = false}},
	BorderColor			= {r = 1, g = 1, b = 1, a = 1},
	HealthTextColor		= {r = 1, g = 1, b = 1, a = 1},
	HealthBarColorByClass = false,
	HealthFrequentUpdates = true,
	Growth				= {["default"] = "down"},
	Spacing				= 0,
	ShowGroupTitles		= true,
	UnitTooltipMethod	= "notincombat",
	BuffTooltipMethod 	= "always",
	DebuffTooltipMethod = "always",
	UnitTooltipType		= "ctra",
	BorderTexture		= "Blizzard Tooltip",
	BuffFilter			= {},
	BuffDisplayOptions	= {},
	DebuffFilter		= {},
	DebuffWhitelist		= {},
	PowerFilter			= {[Enum.PowerType.Mana] = true, [Enum.PowerType.Rage] = false, [Enum.PowerType.Energy] = false, [Enum.PowerType.RunicPower] = false},
	RangeCheck 			= true,
	RangeLimit			= 38,
	RangeFrequency		= 0.2,
	RangeAlpha 			= 0.5,
	ReadyCheck			= true,
	AggroCheck			= false,
	HighlightTarget		= false,
	HighlightHeals		= true,
	heals =				{channel=true, direct=true, hot=false, bomb=true},
	HighlightDebuffs 	= "onlyself",
	Layout				= "CTRA_WithBorders",
	GroupSetup			= L["By class"],
	GroupSetups			= {},
	Positions				= { ['*'] = {} },
	StatusMaps			= {},
	HideInArena			= true,
	Show				= true,
	BuffDisplay			= {default="own"},
	minimapIcon 		= {},
	VehicleSwitch		= true,
	VehiclePower		= true,
	VehicleStatus		= false,
	debufftimer			= {max=9, show=false},
	bufftimer			= {max=30, show=true},
}}

sRaidFrames.CONFIG_VERSION = 1

function sRaidFrames:OnInitialize()
	-- convert Ace2 -> Ace3 config
	if sRaidFramesDB and sRaidFramesDB.currentProfile then
		if not sRaidFramesDB.profileKeys then
			sRaidFramesDB.profileKeys = {}
		end
		-- copy stored/configured profiles
		-- Note: class/* and realm/* values are not changed, 
		-- since there is no way to determine what they should 
		-- be for the individual chars.
		for k, v in pairs(sRaidFramesDB.currentProfile) do
			local new_value = v
			if v == "char" then
				new_value = k
			end
			sRaidFramesDB.profileKeys[k] = new_value
		end
		sRaidFramesDB.currentProfile = nil
		
		-- move actual data
		-- Only char/ is moved due to the same restrictions as above.
		for key, data in pairs(sRaidFramesDB.profiles) do
			if key:find("^char/") then
				local new_key = key:match("^char/(.+)")
				sRaidFramesDB.profiles[new_key] = data
				sRaidFramesDB.profiles[key] = nil
			end
		end
	end
	
	local optFunc = function()
		LibStub("AceConfigDialog-3.0"):Open("sRaidFrames")
	end
	self:RegisterChatCommand("srf", optFunc)
	
	self.db = LibStub("AceDB-3.0"):New("sRaidFramesDB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileEnable")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileEnable")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileEnable")
	
	sRaidFrames.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	sRaidFrames.options.args.profiles.order = 1000
	LibStub("AceConfig-3.0"):RegisterOptionsTable("sRaidFrames", sRaidFrames.options, {"/sraidframes", "/srf", "srf", "sraidframes"})
	
	-- Upgrade Config
	local cv = self.db.profile.configVersion or 0
	
	-- Version 1: Numeric Buff Status Maps, remove the old ones.
	if cv < 1 then
		for k,v in pairs(self.db.profile.StatusMaps) do
			if k:find("^Buff_") then
				self.db.profile.StatusMaps[k] = nil
			end
		end
	end
	
	self.db.profile.configVersion = sRaidFrames.CONFIG_VERSION
	
	self.opt = self.db.profile

	-- Init variables
	self.enabled = false
	self.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
	self.frames, self.groupframes = {}, {}, {}
	self.res, self.RangeChecks = {}, {}
	self.FramesByUnit = {}
	self.statusstate = {}
	self.statusElements = {}
	self.validateStatusElements = {}
	self.vehicleUpdate = {}
	--Conversion to new checkbox buff filtering
	if self.opt.BuffBlacklist then
		for i, k in pairs(self.opt.BuffBlacklist) do
			if k then
				self.opt.BuffDisplayOptions[string.lower(i)] = 0;
				self.opt.BuffBlacklist[i] = nil;
			end
		end
		self.opt.BuffBlacklist = nil;
	end
	if type(self.opt.BuffDisplay) ~= "table" then
		local buffdisplay = self.opt.BuffDisplay
		self.opt.BuffDisplay = {default=self.opt.BuffDisplay}
	end
	if self.opt.CombatBuffBlacklist then
		for i, k in pairs(self.opt.CombatBuffBlacklist) do
			if k then
				self.opt.BuffDisplayOptions[string.lower(i)] = 2;
				self.opt.CombatBuffBlacklist[i] = nil;
			end
		end
		self.opt.CombatBuffBlacklist = nil;
	end
	for i, k in pairs(self.opt.BuffFilter) do
		if i ~= string.lower(i) then
			self.opt.BuffFilter[string.lower(i)] = k;
			self.opt.BuffFilter[i] = nil;
		end
	end
	-- Conversion to per-group growth settings
	if self.opt.Growth and not self.opt.Growth["default"] then
		local growth = self.opt.Growth
		self.opt.Growth = {};
		self.opt.Growth["default"] = growth;
	end

	self.cooldownSpells = {}
	-- self.cooldownSpells["WARLOCK"] = SpellCache[27239] -- Soulstone Resurrection
	-- self.cooldownSpells["DRUID"] = SpellCache[26994] -- Rebirth
	self.cooldownSpells["SHAMAN"] = SpellCache[20608] -- Reincarnation
	self.cooldownSpells["PALADIN"] = SpellCache[19753] -- Divine Intervention

	self.cleanseTypes= {
		["PRIEST"] = {
			["Magic"] = true,
			["Disease"] = true,
		},
		["SHAMAN"] = {
			["Poison"] = true,
			["Disease"] = true,
			["Curse"] = true,
		},
		["PALADIN"] = {
			["Magic"] = true,
			["Poison"] = true,
			["Disease"] = true,
		},
		["MAGE"] = {
			["Curse"] = true,
		},
		["DRUID"] = {
			["Curse"] = true,
			["Poison"] = true,
		},
	}
	
	local statusSpellTable = {}
	if sRaidFrames.isClassic then
		local statusSpellTable = {
			[19753] = true, -- Divine Intervention
			--[35079] = true, -- Misdirection
			[5384] = true, -- Feign Death
		--	[3411] = true, -- Intervene
		--	[29166] = true, -- Innervate
			[20711] = true, -- Spirit of Redemption
			[871] = true, -- Shield Wall
			[12975] = true, -- Last Stand
			-- [45438] = true, -- Ice Block
			--[40733] = true, -- Divine Shield
		-- 	[26889] = true, -- Vanish
			-- [39666] = true, -- Cloak of Shadows
			[66] = true, -- Invisibility
			[1787] = true, -- Stealth
		--	[38541] = true, -- Evasion
		--	[10060] = true, -- Power Infusion
		--	[32182] = true, -- Heroism
		--	[2825] = true, -- Bloodlust
			[6346] = true, -- Fear Ward
			[15473] = true, -- Shadowform
			[498] = true, -- Divine Protection
			[10278] = true, -- Hand of Protection
			[22812] = true, -- Barkskin
		--	[33206] = true, -- Pain Suppression
		--	[61336] = true, -- Survival Instincts
		--	[55233] = true, -- Vampiric Blood
		--	[48792] = true, -- Icebound Fortitude
		--	[48707] = true, -- Anti-Magic Shell
		--	[51271] = true, -- Unbreakable Armor
			--[47788] = true, -- Guardian Spirit
		}
	end

	self.statusSpellTable = {}
	for k in pairs(statusSpellTable) do
		self.statusSpellTable[SpellCache[k]] = k
	end
	if sRaidFramesDB.classspelltable then
		self.opt.classpelltable = sRaidFramesDB.classspelltable
		sRaidFramesDB.classspelltable = nil;
	end
	if not sRaidFramesDB.CustomStatuses then
		sRaidFramesDB.CustomStatuses = {};
	end
	for c in pairs(sRaidFramesDB.CustomStatuses) do
		self.statusSpellTable[SpellCache[c]] = c
	end

	self:AddStatusMap("ReadyCheck_Pending", 80, {"background"}, L["Ready?"], {r = 0.1, g = 0.1, b = 0.1})

	self:AddStatusMap("Death", 70, {"background"}, L["Dead"], {r = 0.1, g = 0.1, b = 0.1, a = 1})

	-- Spirit of Redemption
	self:AddStatusMap("Buff_20711", 65, {"statusbar"}, L["Dead"], {r=1,g=0,b=0,a=1})
	-- Divine Intervention
	self:AddStatusMap("Buff_19753", 65, {"statusbar"}, L["Intervened"], {r=1,g=0,b=0,a=1})

	self:AddStatusMap("Aggro", 50, {"border"}, "Aggro", {r = 1, g = 0, b = 0})
	self:AddStatusMap("Target", 55, {"border"}, "Target", {r = 1, g = 0.75, b = 0})
	self:AddStatusMap("Raid Icon: Star", 60, {"statusbar"}, "Star", {r = 1, g=1, b=0}, true)
	self:AddStatusMap("Raid Icon: Circle", 60, {"statusbar"}, "Circle", {r = 1, g=0.5, b=0,a=1}, true)
	self:AddStatusMap("Raid Icon: Diamond", 60, {"statusbar"}, "Diamond", {r = 1, g=0, b=1,a=1}, true)
	self:AddStatusMap("Raid Icon: Triangle", 60, {"statusbar"}, "Triangle", {r=0, g=1, b=0,a=1}, true)
	self:AddStatusMap("Raid Icon: Moon", 60, {"statusbar"}, "Moon", {r=1, g=1, b=1,a =1}, true)
	self:AddStatusMap("Raid Icon: Square", 60, {"statusbar"}, "Square", {r=0.4156862745098, g=0.8078431372549, b=0.96470588235294, a=1}, true);
	self:AddStatusMap("Raid Icon: Cross", 60, {"statusbar"}, "Cross", {r=1, g=0, b=0, a=1}, true);
	self:AddStatusMap("Raid Icon: Skull", 60, {"statusbar"}, "Skull", {r=1, g=1, b=1, a=1}, true);

	self:AddStatusMap("Debuff_Curse", 55, {"background"}, "Cursed", {r=1, g=0, b=0.75, a=0.5})
	self:AddStatusMap("Debuff_Magic", 54, {"background"}, "Magic", {r=1, g=0, b=0, a=0.5})
	self:AddStatusMap("Debuff_Disease", 53, {"background"}, "Diseased", {r=1, g=1, b=0, a=0.5})
	self:AddStatusMap("Debuff_Poison", 52, {"background"}, "Poisoned", {r=0, g=0.5, b=0, a=0.5})

	if sRaidFrames.isClassic then
		-- Shield Wall
		self:AddStatusMap("Buff_871", 53, {"statusbar"}, SpellCache[871], {r=1,g=1,b=1,a=1})
		-- Last Stand
		self:AddStatusMap("Buff_12975", 52, {"statusbar"}, SpellCache[12975], {r=1,g=1,b=1,a=1})
		-- Vanish
		self:AddStatusMap("Buff_26889", 51, {"statusbar"}, L["Vanished"], {r=0,g=1,b=0,a=1})
		-- Invisibility
		self:AddStatusMap("Buff_66", 51, {"statusbar"}, SpellCache[66], {r=0,g=1,b=0,a=1})
		-- Evasion
		self:AddStatusMap("Buff_38541", 50, {"statusbar"}, SpellCache[38541], {r=1,g=1,b=0,a=1})
		-- Stealth
		self:AddStatusMap("Buff_1787", 50, {"statusbar"}, L["Stealthed"], {r=1,g=1,b=1,a=1})
		-- Innervate
		self:AddStatusMap("Buff_29166", 51, {"statusbar"}, L["Innervating"], {r=0,g=1,b=0,a=1})
		-- Ice Block
		self:AddStatusMap("Buff_45438", 50, {"statusbar"}, SpellCache[45438], {r=1,g=1,b=1,a=1})
		-- Divine Protection
		self:AddStatusMap("Buff_498", 53, {"statusbar"}, SpellCache[498], {r=1,g=1,b=1,a=1})
		-- Hand of Protection
		self:AddStatusMap("Buff_10278", 53, {"statusbar"}, L["Protection"], {r=1,g=1,b=1,a=1})
		-- Barkskin
		self:AddStatusMap("Buff_22812", 52, {"statusbar"}, SpellCache[22812], {r=1,g=1,b=1,a=1})
		-- Pain Suppression
		self:AddStatusMap("Buff_33206", 53, {"statusbar"}, SpellCache[33206], {r=1,g=1,b=1,a=1})
		-- Anti-Magic Shell
		self:AddStatusMap("Buff_48707", 52, {"statusbar"}, SpellCache[48707], {r=1,g=1,b=1,a=1})
		-- Icebound Fortitude
		self:AddStatusMap("Buff_48792", 53, {"statusbar"}, L["IBF"], {r=1,g=1,b=1,a=1})
		-- Vampiric Blood
		--self:AddStatusMap("Buff_55233", 52, {"statusbar"}, SpellCache[55233], {r=1,g=1,b=1,a=1})
		-- Survival Instincts
		self:AddStatusMap("Buff_61336", 52, {"statusbar"}, SpellCache[61336], {r=1,g=1,b=1,a=1})
		-- Unbreakable Armor
		self:AddStatusMap("Buff_51271", 53, {"statusbar"}, L["Unbreakable"], {r=1,g=1,b=1,a=1})
		-- Guardian Spirit
		self:AddStatusMap("Buff_47788", 53, {"statusbar"}, L["Guardian"], {r=1,g=1,b=1,a=1})
		
		-- Feign Death
		self:AddStatusMap("Buff_5384", 50, {"statusbar"}, SpellCache[5384], {r=0,g=1,b=0,a=1})
		-- Cloak of Shadows
		self:AddStatusMap("Buff_39666", 50, {"statusbar"}, SpellCache[39666], {r=1,g=1,b=1,a=1})
		-- Divine Shield
		--self:AddStatusMap("Buff_40733", 50, {"statusbar"}, SpellCache[40733], {r=1,g=1,b=1,a=1})
		-- Power Infusion
		self:AddStatusMap("Buff_10060", 50, {"statusbar"}, L["Infused"], {r=1,g=1,b=1,a=1})

		-- Misdirection
		-- self:AddStatusMap("Buff_35079", 45, {"statusbar"}, SpellCache[35079], {r=0,g=1,b=0,a=1})
		-- Intervene
		--self:AddStatusMap("Buff_3411", 45, {"statusbar"}, SpellCache[3411], {r=0,g=1,b=0,a=1})
		-- Fear Ward
		self:AddStatusMap("Buff_6346", 40, {"statusbar"}, SpellCache[6346], {r=1,g=1,b=0,a=1})
		-- Heroism
		--self:AddStatusMap("Buff_32182", 39, {"statusbar"}, SpellCache[32182], {r=1,g=1,b=1,a=1})
		-- Bloodlust
		--self:AddStatusMap("Buff_2825", 39, {"statusbar"}, SpellCache[2825], {r=1,g=1,b=1,a=1})

		self:AddStatusMap("Heal", 36, {"statusbar"}, "Inc. heal", {r = 0, g = 1, b = 0})
		-- Shadowform
		self:AddStatusMap("Buff_15473", 35, {"statusbar"}, SpellCache[15473], {r=1,g=0,b=0.75,a=1})
	end

	self:AddStatusMap("Vehicle", 56, {"statusbar"}, "On Vehicle", {r=1,g=1,b=1,a=1})

	self:RegisterStatusElement("border", "Border", 
		function(self, frame, status)
			if status == nil then
				frame:SetBackdropBorderColor(self.opt.BorderColor.r, self.opt.BorderColor.g, self.opt.BorderColor.b, self.opt.BorderColor.a or 1)
			else
				frame:SetBackdropBorderColor(status.color.r, status.color.g, status.color.b, status.color.a or 1)
			end
		end
	)
	
	self:RegisterStatusElement("background", "Background",
		function(self, frame, status)
			if status == nil then
				frame:SetBackdropColor(self.opt.BackgroundColor.r, self.opt.BackgroundColor.g, self.opt.BackgroundColor.b, self.opt.BackgroundColor.a or 1)
			else
				frame:SetBackdropColor(status.color.r, status.color.g, status.color.b, status.color.a or 1)
			end
		end
	)
	
	self:RegisterStatusElement("statusbar", "StatusBar",
		function(self, frame, status)
			if status == nil then
				frame.statustext:SetText(nil)
			else
				frame.statustext:SetText(status.text)
				frame.statustext:SetTextColor(status.color.r, status.color.g, status.color.b, status.color.a or 1)
			end
		end
	)

	self:DefaultGroupSetups()

	self:chatUpdateFilterMenu()
	self:chatUpdateBuffMenu()
	self:chatUpdateDebuffMenu()
	self:chatUpdateStatusElements()

	self.master = CreateFrame("Frame", "sRaidFrame", UIParent)
	self.master:SetMovable(true)
	self.master:SetScale(self.opt.Scale)

	self.master:SetHeight(200);
	self.master:SetWidth(200);
	createLDBLauncher()
end

function sRaidFrames:AddExternalStatusMap(name)
	if string.match(name, "Buff_%d+") ~= name and string.match(name, "%d+") ~= name then print("Invalid name specified"); return end
	local id = string.match(name, "%d+");
	local buff;
	if id==name then
		buff = "Buff_"..name;
	else
		buff = name;
	end
	id = tonumber(id);
	self.statusSpellTable[SpellCache[id]] = id
	self:AddStatusMap(buff, 0, {"background"}, SpellCache[id], {r=0, g=0, b=0, a=0});
	if not sRaidFramesDB.CustomStatuses	then
		sRaidFramesDB.CustomStatuses = {}
	end
	sRaidFramesDB.CustomStatuses[id] = true;
	for unit in pairs(self:GetAllUnits()) do
		self:UpdateAuras(unit)
	end
end

function sRaidFrames:RemoveExternalStatusMap(id)
	name = "Buff_"..tonumber(id);
	for unit in pairs(self:GetAllUnits()) do
		self:UnsetStatus(unit, name);
	end
	
	self.options.args.advanced.args[name] = nil
	self.opt.StatusMaps[name] = nil
	if not sRaidFramesDB.CustomStatuses then
		sRaidFramesDB.CustomStatuses = {};
	end
	sRaidFramesDB.CustomStatuses[id] = nil
end

function sRaidFrames:ScheduleLeaveCombatAction(callback, arg1)
	if not InCombatLockdown() then
		self[callback](self, arg1)
		return
	else
		if not self.leaveCombatActions then self.leaveCombatActions = {} end
		tinsert(self.leaveCombatActions, {callback = callback, arg = arg1})
	end
end

function sRaidFrames:PLAYER_REGEN_ENABLED()
	self.InCombat = false;					--since InCombatLockdown doesn't immedeately return correct values, we're setting this variable.
	for unit in pairs(self:GetAllUnits()) do
		self:UpdateAuras(unit)
	end
	if not self.leaveCombatActions then return end
	for key,info in pairs(self.leaveCombatActions) do 
		self[info.callback](self, info.arg)
		self.leaveCombatActions[key] = nil
	end
end

function sRaidFrames:PLAYER_REGEN_DISABLED()
	self.InCombat = true;					--since InCombatLockdown doesn't immedeately return correct values, we're setting this variable.
	for unit in pairs(self:GetAllUnits()) do
		self:UpdateAuras(unit)
	end
end

StaticPopupDialogs["SRAIDFRAMES_PROFILE"] = {
  text = L["After changing the Profile it is required that you reload the UI to apply the new settings.\n Do you want reload the UI now?"],
  button1 = YES,
  button2 = NO,
  OnAccept = function()
     ReloadUI()
  end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 0,
}

function sRaidFrames:OnProfileEnable()
	self.opt = self.db.profile
	StaticPopup_Show ("SRAIDFRAMES_PROFILE")
end

function sRaidFrames:OnEnable()
	if CUSTOM_CLASS_COLORS then
		RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS
	end
	
	self.PlayerClass = select(2, UnitClass("player"))
	
	self:InitRangeChecks()
--	self:RegisterEvent("PLAYER_TALENT_UPDATE", "InitRangeChecks")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "InitRangeChecks")

	self:RegisterBucketEvent("RAID_ROSTER_UPDATE", 0.2, "UpdateRoster")
	Media.RegisterCallback(self, "LibSharedMedia_SetGlobal")

	self:UpdateRoster()
	self:ToggleFrequentUpdates()
end

function sRaidFrames:InitRangeChecks()
	self.RangeChecks = {}
	
	self:AddRangeFunction(10, function (unit) return CheckInteractDistance(unit, 3) == 1 end)
	self:AddRangeFunction(28, function (unit) return CheckInteractDistance(unit, 4) == 1 end)
	self:AddRangeFunction(38, function (unit) return UnitInRange(unit) end)
	self:AddRangeFunction(100, function (unit) return UnitIsVisible(unit) == 1 end)
	
	self:ScanSpellbookForRange()
end

local EventsHealth = {"UNIT_HEALTH", "UNIT_MAXHEALTH"}
local EventsPower = {"UNIT_MANA", "UNIT_RAGE", "UNIT_ENERGY", "UNIT_FOCUS", "UNIT_RUNIC_POWER", "UNIT_MAXMANA", "UNIT_MAXRAGE", "UNIT_MAXFOCUS", "UNIT_MAXENERGY", "UNIT_MAXRUNIC_POWER", "UNIT_DISPLAYPOWER"}

function sRaidFrames:UpdateRaidTargets()
	for unit in pairs(sRaidFrames:GetAllUnits()) do
		sRaidFrames:UpdateAuras(unit)
	end
end

function sRaidFrames:EnableFrames()
	self.enabled = true
	self.statusstate = {}

	self:CreateFrames()

	self.healthBucket = self:RegisterBucketEvent(EventsHealth, 0.05, "UNIT_HEALTH")
	self.powerBucket = self:RegisterBucketEvent(EventsPower, 1, "UNIT_POWER")
	self.auraBucket = self:RegisterBucketEvent("UNIT_AURA", 0.2)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateTarget")
	
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "UpdateVehicle")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "UpdateVehicle")
	self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidTargets")

	if HealComm then
		HealComm.RegisterCallback(self, "HealComm_HealUpdated")
		HealComm.RegisterCallback(self, "HealComm_HealStarted", "HealComm_HealUpdated")
		HealComm.RegisterCallback(self, "HealComm_HealStopped", "HealComm_HealUpdated")
		HealComm.RegisterCallback(self, "HealComm_HealDelayed", "HealComm_HealUpdated")
		HealComm.RegisterCallback(self, "HealComm_ModifierChanged")
	end
	
	if ResComm then
		ResComm.RegisterCallback(self, "ResComm_ResStart")
		ResComm.RegisterCallback(self, "ResComm_ResEnd")
		ResComm.RegisterCallback(self, "ResComm_Ressed")
		ResComm.RegisterCallback(self, "ResComm_CanRes")
		ResComm.RegisterCallback(self, "ResComm_ResExpired")
	end

	if Banzai then
		Banzai:RegisterCallback(sRaidFrames.Banzai_Callback)
	end
	
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	self.rangeTimer = self:ScheduleRepeatingTimer("RangeCheck", self.opt.RangeFrequency)

	self:UpdateRoster()

	self.master:Show()
end

function sRaidFrames:DisableFrames()
	if not self.enabled then return end
	self.statusstate = {}
	self.FramesByUnit = {}

	self:UnregisterBucket(self.healthBucket)
	self:UnregisterBucket(self.powerBucket)
	self:UnregisterBucket(self.auraBucket)

	self:UnregisterEvent("PLAYER_TARGET_CHANGED")

	if Banzai and self.isClassic then
		Banzai:UnregisterCallback(sRaidFrames.Banzai_Callback)
	end

	if self.rangeTimer then
		self:CancelTimer(self.rangeTimer)
		self.rangeTimer = nil
	end

	if HealComm and self.isClassic then
		HealComm.UnregisterCallback(self, "HealComm_DirectHealStart")
		HealComm.UnregisterCallback(self, "HealComm_DirectHealStop")
		HealComm.UnregisterCallback(self, "HealComm_DirectHealDelayed")
		HealComm.UnregisterCallback(self, "HealComm_HealModifierUpdate")
	end
	
	if ResComm and self.isClassic then
		ResComm.UnregisterCallback(self, "ResComm_ResStart")
		ResComm.UnregisterCallback(self, "ResComm_ResEnd")
		ResComm.UnregisterCallback(self, "ResComm_Ressed")
		ResComm.UnregisterCallback(self, "ResComm_CanRes")
		ResComm.UnregisterCallback(self, "ResComm_ResExpired")
	end
	
	self.enabled = false
	self.master:Hide()
end

function sRaidFrames:ToggleFrequentUpdates()
	if self.opt.HealthFrequentUpdates and self.isClassic then
		self.master:SetScript("OnUpdate", function() sRaidFrames:FrequentHealthUpdate() end)
	else
		self.master:SetScript("OnUpdate", nil)
	end
end

function sRaidFrames:LibSharedMedia_SetGlobal(type, handle)
	if type == "statusbar" then
		local texture = Media:Fetch("statusbar", handle)
		for _, frame in pairs(self.frames) do
			frame.hpbar:SetStatusBarTexture(texture)
			frame.mpbar:SetStatusBarTexture(texture)
		end
	end
end

function sRaidFrames:ScanSpellbookForRange()
	local i = 1
	while true do
		local SpellId = i
		local name, _, _, _, _, _, _, _, maxRange = GetSpellInfo(SpellId)
		if not name then break end
		
		if maxRange and IsSpellInRange(SpellId, "spell", "player") ~= nil then
			self:AddRangeFunction(tonumber(maxRange), function (unit) return IsSpellInRange(SpellId, "spell", unit) == 1 end)
		end
		i = i + 1
	end
end

-- RosterLib replacement
do
	local roster, oldroster = { n = 0 }, {}
	function sRaidFrames:ScanRoster()
		local numRaid = GetNumGroupMembers()
		for id, name in pairs(roster) do
			oldroster[id] = name
		end
		
		for i = 1, numRaid do
			local unit = ("raid%d"):format(i)
			roster[unit] = UnitName(unit)
			if roster[unit] ~= oldroster[unit] then
				self:Roster_UnitChanged(unit)
			end
			oldroster[unit] = nil
		end
		roster.n = numRaid
		
		oldroster.n = nil
		-- anything thats left in the oldroster now can go
		for id, name in pairs(oldroster) do
			oldroster[id] = nil
			roster[id] = nil
			self:Roster_UnitLeft(id)
		end
	end
	
	function sRaidFrames:GetUnitByName(unitname)
		for id, name in pairs(roster) do
			if name == unitname then
				return id
			end
		end
	end
end

function sRaidFrames:Roster_UnitChanged(unitid)
	ShouldUpdateFrameCache = true
	
	self.statusstate[unitid] = {}
	self:UpdateAll(unitid)
end

function sRaidFrames:Roster_UnitLeft(unitid)
	ShouldUpdateFrameCache = true
	
	self.statusstate[unitid] = nil
end

function sRaidFrames:UpdateRoster()
	local inRaid = GetNumGroupMembers() > 0
	local inBG = select(2, IsInInstance()) == "pvp"
	local inArena = select(2, IsInInstance()) == "arena"

	if not sRaidFrames.enabled then
		if inRaid and not (sRaidFrames.opt.HideInArena and inArena) and sRaidFrames.opt.Show then
			sRaidFrames:EnableFrames()
		end
	end
	if sRaidFrames.enabled then
		if not inRaid then
			sRaidFrames:DisableFrames()
		end
		if sRaidFrames.opt.HideInArena and inArena then
			sRaidFrames:DisableFrames()
		end
		if not sRaidFrames.opt.Show then
			sRaidFrames:DisableFrames()
		end
	end
	sRaidFrames:ScanRoster()
end

function sRaidFrames:UpdateAllUnits()
	for unit in pairs(self:GetAllUnits()) do
		self:UpdateAll(unit)
	end
end

function sRaidFrames:UpdateAll(unit)
	if self.vehicleUpdate[unit] then
		self:CancelTimer(self.vehicleUpdate[unit], true)
		self.vehicleUpdate[unit] = nil
	end
	self:UpdateUnitDetails(unit)
	self:UpdateUnitHealth(unit)
	self:UpdateUnitPower(unit)
	self:UpdateStatuses(unit)
	self:UpdateAuras(unit)
end

function sRaidFrames:UpdateVehicle(event, unit)
	if not self:IsTracking(unit) then return end
	self:UpdateAll(unit)
	--self:ScheduleTimer("UpdateAll", 0.5, unit)
end

function sRaidFrames:UNIT_POWER(units)
	for unit in pairs(units) do
		local u = self:GetNonVehicleUnit(unit)
		self:UpdateUnitPower(u)
	end
end

function sRaidFrames:UNIT_HEALTH(units)
	for unit in pairs(units) do
		local u = self:GetNonVehicleUnit(unit)
		self:UpdateUnitHealth(u)
	end
end

function sRaidFrames:UNIT_AURA(units)
	for unit in pairs(units) do
		local u = self:GetNonVehicleUnit(unit)
		self:UpdateAuras(u)
	end
end

function sRaidFrames:READY_CHECK(event, author)
	if not self.opt.ReadyCheck or not (IsRaidLeader() or IsRaidOfficer()) then return end

	local authorid = self:GetUnitByName(author)

	for unitid in pairs(self:GetAllUnits()) do
		if unitid ~= authorid then
			self:SetStatus(unitid, "ReadyCheck_Pending")
		end
	end
end

function sRaidFrames:READY_CHECK_CONFIRM(event, unitid, confirm)
	if not self.opt.ReadyCheck then return end

	if not string.match(unitid, "raid%d+") then return end

	self:UnsetStatus(unitid, "ReadyCheck_Pending")
	if confirm then
		self:SetStatus(unitid, "ReadyCheck_Ready")
	else
		self:SetStatus(unitid, "ReadyCheck_NotReady")
	end
end

function sRaidFrames:READY_CHECK_FINISHED()
	if not self.opt.ReadyCheck then return end

	for unitid in pairs(self:GetAllUnits()) do
		self:UnsetStatus(unitid, "ReadyCheck_Pending")
		self:UnsetStatus(unitid, "ReadyCheck_Ready")
		self:UnsetStatus(unitid, "ReadyCheck_NotReady")
	end
end

local LastTarget
function sRaidFrames:UpdateTarget()
	if not self.opt.HighlightTarget then return end

	if LastTarget then
		self:UnsetStatus(LastTarget, "Target")
	end

	for unit in pairs(self:GetAllUnits()) do
		if UnitIsUnit(unit, "target") then
			self:SetStatus(unit, "Target")
			LastTarget = unit
			break
		end
	end
end

function sRaidFrames.Banzai_Callback(aggro, name, ...)
	local self = sRaidFrames
	if not self.opt.AggroCheck then return end

	local unit = self:GetUnitByName(name)
	if not unit or not self:IsTracking(unit) then return end

	local aggro = Banzai:GetUnitAggroByUnitName(name)
	if aggro then
		self:SetStatus(unit, "Aggro")
	else
		self:UnsetStatus(unit, "Aggro")
	end
end

function sRaidFrames:ResComm_ResStart(event, _, _, target)
	local unit = self:GetUnitByName(target)
	if unit then
		self.res[unit] = 3
		self:UpdateUnitHealth(unit)
	end
end

function sRaidFrames:ResComm_ResEnd(event, _, target)
	if ResComm:IsUnitBeingRessed(target) then return end
	
	local unit = self:GetUnitByName(target)
	if unit then
		self.res[unit] = nil
		self:UpdateUnitHealth(unit)
	end
end

function sRaidFrames:ResComm_CanRes(event, target)
	local unit = self:GetUnitByName(target)
	if unit then
		self.res[unit] = 1
		self:UpdateUnitHealth(unit)
	end
end

function sRaidFrames:ResComm_Ressed(event, target)
	local unit = self:GetUnitByName(target)
	if unit then
		self.res[unit] = 2
		self:UpdateUnitHealth(unit)
	end
end

function sRaidFrames:ResComm_ResExpired(event, target)
	local unit = self:GetUnitByName(target)
	if unit then
		self.res[unit] = nil
		self:UpdateUnitHealth(unit)
	end
end

function sRaidFrames:IsUnitInRange(unit, range)
	if not self.RangeChecks[range] then
		-- fallback to UnitInRange if an invalid range is specified
		return UnitInRange(unit)
	end
	return self.RangeChecks[range](unit)
end

function sRaidFrames:CanDispell(type)
	return (self.cleanseTypes[self.PlayerClass] and self.cleanseTypes[self.PlayerClass][type])
end

function sRaidFrames:RangeCheck()
	if not self.opt.RangeCheck then return end
	local RangeLimit = self.opt.RangeLimit
	local RangeAlpha = self.opt.RangeAlpha

	for unit in pairs(self:GetAllUnits()) do
		local vunit = self:GetVehicleUnit(unit)
		if self:IsUnitInRange(vunit, RangeLimit) then
			for _, f in pairs(self:FindUnitFrames(unit)) do
				f:SetAlpha(1)
			end
		else
			for _, f in pairs(self:FindUnitFrames(unit)) do
				f:SetAlpha(RangeAlpha)
			end
		end
	end
end

function sRaidFrames:AddRangeFunction(range, check)
	if self.RangeChecks[range] then return end
	self.RangeChecks[range] = check
	self:UpdateRangeLimitOptions()
end

function sRaidFrames:UpdateRangeFrequency()
	if self.rangeTimer then
		self:CancelTimer(self.rangeTimer)
	end
	self.rangeTimer = self:ScheduleRepeatingTimer("RangeCheck", self.opt.RangeFrequency)
end

function sRaidFrames:UpdateStatuses(unit)
	for element in pairs(self.statusElements) do
		self:UpdateUnitStatusElement(unit, element)
	end
end

function sRaidFrames:UpdateUnitDetails(unit)
	if not self:IsTracking(unit) then return end
	for _, f in pairs(self:FindUnitFrames(unit)) do
		local class = select(2, UnitClass(unit))
		f.title:SetText(UnitName(unit) or L["Unknown"])
		if class then
			local color = RAID_CLASS_COLORS[class]
			f.title:SetTextColor(color.r, color.g, color.b, 1)
			if self.opt.HealthBarColorByClass then
				f.hpbar:SetStatusBarColor(color.r, color.g, color.b)
			end
		end
		
		if self.opt.VehicleStatus and UnitHasVehicleUI(unit) then
			self:SetStatus(unit, "Vehicle", UnitName(self:GetVehicleUnit(unit)))
		else
			self:UnsetStatus(unit, "Vehicle")
		end
	end
end

local hpcache = {}
function sRaidFrames:FrequentHealthUpdate()
	for munit in pairs(self:GetAllUnits()) do
		if not self:GetStatus(munit, "Death") then
			local unit = self:GetVehicleUnit(munit)
			local hp = UnitHealth(unit) or 0
			local hpmax = UnitHealthMax(unit)
			local hpp = (hpmax ~= 0) and ceil((hp / hpmax) * 100) or 0
			
			if hpcache[munit] ~= hp then
				hpcache[munit] = hp
				for _, f in pairs(self:FindUnitFrames(munit)) do
					self:UpdateSingleUnitHealth(f, hp, hpmax, hpp)
				end
			end
		end
	end
end

function sRaidFrames:UpdateSingleUnitHealth(f, hp, hpmax, hpp)
	local hptext, hpvalue
	if self.opt.HideMaxHealth and (hp == hpmax) then
		hptext = nil
	else
		local format = self.opt.HealthFormat
		if format == "percent" then
			hptext = hpp .."%"
		elseif format == "deficit" then
			hptext = (hp-hpmax)
		elseif format == "current" then
			hptext = hp
		elseif format == "curmax" then
			hptext = hp .."/".. hpmax
		elseif format == "curdeficit" then
			hptext = (hp ~= hpmax) and hp .." |cffff0000".. (hp-hpmax) or hpmax
		end
	end

	if self.opt.Invert then
		hpvalue = 100 - hpp
	else
		hpvalue = hpp
	end

	f.hpbar.text:SetText(hptext)
	f.hpbar:SetValue(hpvalue)
	if not self.opt.HealthBarColorByClass then
		f.hpbar:SetStatusBarColor(self:GetHPSeverity(hpp/100))
	end
end

function sRaidFrames:UpdateUnitHealth(munit)
	if not self:IsTracking(munit) then return end
	local unit = self:GetVehicleUnit(munit)
	for _, f in pairs(self:FindUnitFrames(munit)) do
		local status, dead, ghost = nil, UnitIsDead(unit), UnitIsGhost(unit)
		
		if not UnitIsConnected(munit) then status = "|cffff0000"..L["Offline"].."|r"
		elseif dead and self.res[munit] == 1 then status = "|cff00ff00"..L["Can Recover"].."|r"
		elseif (dead or ghost) and self.res[munit] == 2 then status = "|cff00ff00"..L["Resurrected"].."|r"
		elseif (dead or ghost) and self.res[munit] == 3 then status = "|cffff8c00"..L["Resurrecting"].."|r"
		elseif ghost then status = "|cffff0000"..L["Released"].."|r"
		elseif dead then status = "|cffff0000"..L["Dead"].."|r"
		end

		if status then
			f.hpbar.text:SetText(status)
			f.hpbar:SetValue(0)
			f.mpbar:SetValue(0)
			self:SetStatus(munit, "Death")
		else
			self:UnsetStatus(munit, "Death")
			self.res[munit] = nil
			local hp = UnitHealth(unit) or 0
			local hpmax = UnitHealthMax(unit)
			local hpp = (hpmax ~= 0) and ceil((hp / hpmax) * 100) or 0

			-- Fix for vehicles that are not loaded fully yet (not connected)
			if unit ~= munit and (not UnitIsConnected(unit) or hpmax == 0) then
				hp, hpmax, hpp = 1, 1, 100
				if not self.vehicleUpdate[munit] then
					self.vehicleUpdate[munit] = self:ScheduleTimer("UpdateAll", 0.2, munit)
				end
			end

			self:UpdateSingleUnitHealth(f, hp, hpmax, hpp)
		end
	end
end

function sRaidFrames:UpdateUnitPower(munit)
	if not self:IsTracking(munit) then return end
	for _, f in pairs(self:FindUnitFrames(munit)) do
		local unit = self:GetVehicleUnit(munit)
		local powerType = UnitPowerType(unit)
		if not self.opt.PowerFilter[powerType] and not (self.opt.VehicleSwitch and self.opt.VehiclePower and munit ~= unit) then
			f.mpbar:SetValue(0)
		else
			local color = PowerBarColor[powerType]
			local mp = UnitMana(unit) or 0
			local mpmax = UnitManaMax(unit)
			local mpp = (mpmax ~= 0) and ceil((mp / mpmax) * 100) or 0
			f.mpbar:SetStatusBarColor(color.r, color.g, color.b)
			f.mpbar:SetValue(mpp)
		end
	end
end

function sRaidFrames:UpdateAuras(munit)
	if not self:IsTracking(munit) then return end
	local layout = self:GetLayout()
	for _, f in pairs(self:FindUnitFrames(munit)) do
		local unit = self:GetVehicleUnit(munit)
		for i = 1, layout.debuffCount do
			f["aura".. i]:Hide()
			f["aura".. i].timer:SetText(nil)
		end

		for i = 1, layout.buffCount do
			f["buff".. i]:Hide()
			f["buff".. i].timer:SetText(nil)
		end

		local BuffType = self.opt.BuffType
		local DebuffSlots = 0
		local HighLightRule = self.opt.HighlightDebuffs
		local DebuffFilter = self.opt.DebuffFilter
		local DebuffWhitelist = self.opt.DebuffWhitelist
		local ShowOnlyDispellable = self.opt.ShowOnlyDispellable
		local debuffsFull, typeFound = false, (HighLightRule == "never")
		self:UnsetStatus(munit, "Debuff_Curse")
		self:UnsetStatus(munit, "Debuff_Magic")
		self:UnsetStatus(munit, "Debuff_Poison")
		self:UnsetStatus(munit, "Debuff_Disease")
		
		local i = 1
		local debuffName, _, debuffTexture, debuffApplications, debuffType, duration, expirationTime = UnitDebuff(unit, i)
		while debuffName and not (debuffsFull and typeFound) do
			if debuffType and not typeFound and (HighLightRule ~= "onlyself" or self:CanDispell(debuffType)) then
				typeFound = true
				self:SetStatus(munit, "Debuff_".. debuffType, debuffName)
			end
			
			if not debuffsFull and BuffType == "debuffs" or BuffType == "buffsifnotdebuffed" or BuffType == "both" then
				if not DebuffFilter[debuffName] and ((ShowOnlyDispellable and (self:CanDispell(debuffType) or DebuffWhitelist[debuffName])) or not ShowOnlyDispellable) then
					DebuffSlots = DebuffSlots + 1
					local debuffFrame = f["aura".. DebuffSlots]
					if not debuffFrame then break end
					debuffFrame.unitid = unit
					debuffFrame.debuffid = i
					debuffFrame.count:SetText(debuffApplications > 1 and debuffApplications or nil);
					debuffFrame.texture:SetTexture(debuffTexture)
					debuffFrame:Show()
					debuffFrame.timer.DebuffName = debuffName
					if self.opt.debufftimer.show and ((math.floor(expirationTime-GetTime())) <= self.opt.debufftimer.max) then
						local seconds = tostring(math.floor(expirationTime-GetTime()))
						debuffFrame.timer:SetText(seconds)
						debuffFrame.timer.cache = seconds
						local supposedsize = math.floor(expirationTime-GetTime()) >= 10 and 9 or 12
						if debuffFrame.timer.fontsize ~= supposedsize then
							debuffFrame.timer:SetFont("Fonts\\FRIZQT__.TTF", supposedsize, "OUTLINE")
							debuffFrame.timer.fontsize = supposedsize
						end
					else
						debuffFrame.timer:SetText(nil)
						debuffFrame.timer.cache = nil
					end
				end
				if DebuffSlots == layout.debuffCount then debuffsFull = true end
			end
			i = i + 1
			debuffName, _, debuffTexture, debuffApplications, debuffType = UnitDebuff(unit, i)
		end

		local BuffSlots = 0
		local BuffFilter = self.opt.BuffFilter
		local HasBuffFilter = next(BuffFilter) and true or false
		--local BuffBacklist = self.opt.BuffBlacklist
		--local CombatBuffBlacklist = self.opt.CombatBuffBlacklist
		local BuffDisplayOptions = self.opt.BuffDisplayOptions
		local BuffDisplay = self.opt.BuffDisplay.default
		local showOnlyCastable = (BuffDisplay == "class") and "RAID" or nil
		local buffsFull = false
		
		for name, id in pairs(self.statusSpellTable) do
			self:UnsetStatus(munit, "Buff_" .. id)
		end
		
		
		local i = 1
		local name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff(unit, i, showOnlyCastable)
		local isMine, buffId
		while name do
			isMine = (caster == "player")
			if not buffsFull and BuffType == "buffs" or (BuffType == "buffsifnotdebuffed" and DebuffSlots == 0) or BuffType == "both" then
				local displaytype = BuffDisplayOptions[string.lower(name)]
				if not buffsFull and ((displaytype == 3 or not displaytype) or (displaytype ==1 and self.InCombat) or (displaytype == 2 and not self.InCombat)) and ((isMine and (self.opt.BuffDisplay[string.lower(name)] or BuffDisplay) == "own" and duration > 0) or (showOnlyCastable and duration > 0) or (self.opt.BuffDisplay[string.lower(name)] or BuffDisplay)  == "all") and (not HasBuffFilter or (HasBuffFilter and BuffFilter[string.lower(name)])) then
						BuffSlots = BuffSlots + 1
						local buffFrame = f["buff".. BuffSlots]
						if not buffFrame then break end
						buffFrame.buffid = i
						buffFrame.unitid = unit
						buffFrame.showCastable = showOnlyCastable
						buffFrame.count:SetText(count > 1 and count or nil)
						buffFrame.texture:SetTexture(icon)
						buffFrame.timer.BuffName = name
						if self.opt.bufftimer.show and ((expirationTime-GetTime()) <= self.opt.bufftimer.max) then
							local seconds = tostring(math.floor(expirationTime-GetTime()))
							buffFrame.timer:SetText(seconds)
							buffFrame.timer.cache = seconds
							local supposedsize = math.floor(expirationTime-GetTime()) >= 10 and 6 or 9
							if buffFrame.timer.fontsize ~= supposedsize then
								buffFrame.timer:SetFont("Fonts\\FRIZQT__.TTF", supposedsize, "OUTLINE")
								buffFrame.timer.fontsize = supposedsize
							end
						else
							buffFrame.timer:SetText(nil)
							buffFrame.timer.cache = nil
						end
						if BuffSlots == 1 and self.opt.BuffType == "both" then
							local parent
							local offset
							if f.aura2:IsShown() then
								parent = f.aura2;
							elseif f.aura1:IsShown() then
								parent = f.aura1;
							end
							if self:GetLayout()["Name"] == L["CT_RaidAssist (Without Borders)"] then
								offset = 0;
							else
								offset = -4;
							end
							if not parent then
								self:SetWHP(buffFrame, buffFrame:GetWidth(), buffFrame:GetHeight(), "TOPRIGHT", f, "TOPRIGHT", offset, offset)
							else
								self:SetWHP(buffFrame, buffFrame:GetWidth(), buffFrame:GetHeight(), "TOPRIGHT", parent, "TOPLEFT", 0, 0)
							end
						end
						buffFrame:Show()
						if BuffSlots == layout.buffCount then buffsFull = true end
				end
			end
			if not showOnlyCastable then
				buffId = self.statusSpellTable[name]
				if buffId then
					if not self.opt.classspelltable[buffId]["IsFiltered"] or self.opt.classspelltable[buffId][self.PlayerClass] then
						self:SetStatus(munit, "Buff_" .. buffId)
					end
				end
			end
			
			i = i + 1
			name, rank, icon, count, debuffType, duration, expirationTime, caster, isStealable = UnitBuff(unit, i, showOnlyCastable)
		end
		local i = 1
		local name = UnitDebuff(unit, i)
		while name do
			buffId = self.statusSpellTable[name]
			if buffId then
				if not self.opt.classspelltable[buffId]["IsFiltered"] or self.opt.classspelltable[buffId][self.PlayerClass] then
					self:SetStatus(munit, "Buff_"..buffId)
				end
			end
			i = i+1;
			name = UnitDebuff(unit, i)
		end
		-- This is kind of a hack, should somehow be improved
		if showOnlyCastable then
			local i = 1
			local name = UnitBuff(unit, i)
			while name do
				buffId = self.statusSpellTable[name]
				if buffId then
					if not self.opt.classspelltable[buffId]["IsFiltered"] or self.opt.classspelltable[buffId][self.PlayerClass] then
						self:SetStatus(munit, "Buff_" .. buffId)
					end
				end
				
				i = i + 1
				name = UnitBuff(unit, i)
			end
		end
		local raidtarget = GetRaidTargetIndex(unit);
		local raidtargets = {"Raid Icon: Star", "Raid Icon: Circle", "Raid Icon: Diamond", "Raid Icon: Triangle", "Raid Icon: Moon", "Raid Icon: Square", "Raid Icon: Cross", "Raid Icon: Skull"};
		if raidtarget then
			for i=1, #raidtargets do
				if i ~= raidtarget then
					self:UnsetStatus(munit, raidtargets[i]);
				else
					self:SetStatus(munit, raidtargets[i]);
				end
			end
		else
			for i=1, #raidtargets do
				self:UnsetStatus(munit, raidtargets[i]);
			end
		end
	end
end

function sRaidFrames:AddStatusMap(statuskey, priority, elements, text, color, disabled)
	if self.opt.StatusMaps[statuskey] then return end
	self.opt.StatusMaps[statuskey] = {["priority"] = priority, ["elements"] = {}, ["text"] = text, ["color"] = color, ["enabled"] = disabled ~= true}
	for _, element in pairs(elements) do
		self.opt.StatusMaps[statuskey].elements[element] = true
	end
	self:chatUpdateStatusElements()
end

function sRaidFrames:GetStatus(unit, statuskey)
	return self.statusstate[unit] and self.statusstate[unit][statuskey] or nil
end

function sRaidFrames:SetStatus(unit, statuskey, text, color, update)
	if not self:IsTracking(unit) then return end

	local map = self.opt.StatusMaps[statuskey]

	if not map then return end
	if map.enabled == false then return end

	if not self.statusstate[unit] then
		self.statusstate[unit] = {}
	end

	local hasStatus = self:GetStatus(unit, statuskey)
	if hasStatus and not update then return end

	if text then
		map.text = text
	end

	if color then
		map.color = color
	end

	self.statusstate[unit][statuskey] = map

	self:UpdateStatusElements(unit, statuskey)
end

function sRaidFrames:UnsetStatus(unit, statuskey)
	if not self:IsTracking(unit) then return end
	if self.opt.StatusMaps[statuskey] and self:GetStatus(unit, statuskey) then
		self.statusstate[unit][statuskey] = nil
		self:UpdateStatusElements(unit, statuskey)
	end
end

function sRaidFrames:UpdateStatusElements(unit, statuskey)
	for element in pairs(self.opt.StatusMaps[statuskey].elements) do
		self:UpdateUnitStatusElement(unit, element)
	end
end

function sRaidFrames:RegisterStatusElement(element, name, func)
	self.statusElements[element] = { ["func"] = func, ["name"] = name }
	self.validateStatusElements[element] = name
end

function sRaidFrames:UpdateUnitStatusElement(unit, element)
	local status = self:GetTopStatus(element, unit)

	for _, frame in pairs(self:FindUnitFrames(unit)) do
		if self.statusElements[element] then
			self.statusElements[element].func(self, frame, status)
		end
	end
end

function sRaidFrames:GetTopStatus(element, unit)
	if not self.statusstate[unit] then
		return nil
	end

	local TopStatus, TopPriority = nil, 0
	for name, data in pairs(self.statusstate[unit]) do
		if self.opt.StatusMaps[name].elements[element] and self.opt.StatusMaps[name].priority > TopPriority then
			TopPriority = self.opt.StatusMaps[name].priority
			TopStatus = name
		end
	end

	return self.statusstate[unit][TopStatus] or nil
end

function sRaidFrames:GetHPSeverity(percent)
	if (percent >= 0.5) then
		return (1.0-percent)*2, 1.0, 0.0
	else
		return 1.0, percent*2, 0.0
	end
end

function sRaidFrames:QueryTooltipDisplay(value)
	if value == "never" then
		return false
	elseif value == "notincombat" and UnitAffectingCombat("player") then
		return false
	else
		return true
	end
end

function sRaidFrames:UnitTooltip(frame)
	local name, rank, subgroup, level, class, eclass, zone, _, _, role  = GetRaidRosterInfo(frame.id)
	local unit = frame:GetAttribute("unit")
	if not unit or not name then return end
	
	GameTooltip:SetOwner(frame)
	
	if self.opt.UnitTooltipType == "blizz" then
			GameTooltip:SetUnit(unit)
			GameTooltip:Show()
			return
	end

	GameTooltip:AddDoubleLine(name, level > 0 and level or nil, RAID_CLASS_COLORS[eclass].r, RAID_CLASS_COLORS[eclass].g, RAID_CLASS_COLORS[eclass].b, 1, 1, 1)
	
	if UnitHasVehicleUI(unit) then
		GameTooltip:AddLine(UnitName(self:GetVehicleUnit(unit)))
	end
	
	if UnitIsAFK(unit) then
		GameTooltip:AddLine(L["AFK: Away From Keyboard"], 1, 1, 0)
	end

	local spec, role
	if LibGroupTalents then
		spec = LibGroupTalents:GetUnitTalentSpec(unit)
		role = LibGroupTalents:GetUnitRole(unit)
	end

	if spec and role then
		GameTooltip:AddDoubleLine(UnitRace(unit) .. " " .. class, spec .. " (" .. role ..")", 1, 1, 1, RAID_CLASS_COLORS[eclass].r, RAID_CLASS_COLORS[eclass].g, RAID_CLASS_COLORS[eclass].b);
	else
		GameTooltip:AddLine(UnitRace(unit) .. " " .. class, 1, 1, 1);
	end
	
	GameTooltip:AddDoubleLine(zone or UNKNOWN, L["Group %d"]:format(subgroup), 1, 1, 1, 1, 1, 1);

	local cooldownSpell = self.cooldownSpells[eclass]
	if oRA and oRA:HasModule("OptionalCooldown") and cooldownSpell then
		if oRA:GetModule("OptionalCooldown").db.realm.cooldowns and oRA:GetModule("OptionalCooldown").db.realm.cooldowns[name] then
			local expire = oRA:GetModule("OptionalCooldown").db.realm.cooldowns[name]-time()
			if expire > 0 then
				GameTooltip:AddDoubleLine(cooldownSpell, SecondsToTime(expire), nil, nil, nil, 1, 0, 0)
			else
				GameTooltip:AddDoubleLine(cooldownSpell, L["Ready!"], nil, nil, nil, 0, 1, 0)
			end
		else
			GameTooltip:AddDoubleLine(cooldownSpell, UNKNOWN, nil, nil, nil, 1, 1, 0)
		end
	end

	GameTooltip:Show()
end

local ShouldUpdateFrameCache = false
local function sRaidFrames_OnAttributeChanged(frame, name, value)
	if name == "unit" then
		ShouldUpdateFrameCache = true

		if value then
			frame.id = select(3, value:find("(%d+)"))
		end
	end
end

local function sRaidFrames_InitUnitFrame(frame)
	frame:SetScript("OnAttributeChanged", sRaidFrames_OnAttributeChanged)
	sRaidFrames:CreateUnitFrame(frame)
end

function sRaidFrames:UpdateFrameCache()
	self.FramesByUnit = {}
	for k, frame in pairs(self.frames) do
		local unit = frame:GetAttribute("unit")
		if unit then
			if not self.FramesByUnit[unit] then
				self.FramesByUnit[unit] = {}
			end
			tinsert(self.FramesByUnit[unit], frame)
		end
	end
	ShouldUpdateFrameCache = false
	self:UpdateAllUnits()
end

local function BuffFrame_OnEnter(this)
	if sRaidFrames:QueryTooltipDisplay(sRaidFrames.opt.BuffTooltipMethod) then
		GameTooltip:SetOwner(this)
		GameTooltip:SetUnitBuff(this.unitid, this.buffid, this.showCastable)
	end
end

local function BuffFrame_OnLeave(this)
	GameTooltip:Hide()
end

local function DebuffFrame_OnEnter(this)
	if sRaidFrames:QueryTooltipDisplay(sRaidFrames.opt.DebuffTooltipMethod) then
		GameTooltip:SetOwner(this)
		GameTooltip:SetUnitDebuff(this.unitid, this.debuffid)
	end
end

local function DebuffFrame_OnLeave(this)
	GameTooltip:Hide()
end

local DebuffFrame_OnLeave = BuffFrame_OnLeave

local function UnitFrame_OnEnter(this)
	if sRaidFrames:QueryTooltipDisplay(sRaidFrames.opt.UnitTooltipMethod) then
		sRaidFrames:UnitTooltip(this)
	end
end

local UnitFrame_OnLeave = BuffFrame_OnLeave


-- Adapts frames created by Secure Headers
function sRaidFrames:CreateUnitFrame(f)
	local layout = self:GetLayout()
	--f:EnableMouse(true)
	f:RegisterForClicks("AnyUp")
	
	f:SetAttribute("type1", "target")
	f:SetAttribute("*type1", "target")
	
	f:SetAttribute("toggleForVehicle", true)
	--f:SetAttribute("allowVehicleTarget", true)

	f:SetScript("OnEnter", UnitFrame_OnEnter)
	f:SetScript("OnLeave", UnitFrame_OnLeave)

	f.title = f:CreateFontString(nil, "ARTWORK")
	f.title:SetFontObject(GameFontNormalSmall)
	f.title:SetJustifyH("LEFT")


	for i = 1, layout.debuffCount do
		local debuffFrame = CreateFrame("Button", nil, f)
		debuffFrame:SetScript("OnEnter", DebuffFrame_OnEnter);
		debuffFrame:SetScript("OnLeave", DebuffFrame_OnLeave)
		debuffFrame.texture = debuffFrame:CreateTexture(nil, "ARTWORK")
		debuffFrame.texture:SetAllPoints(debuffFrame);
		debuffFrame.count = debuffFrame:CreateFontString(nil, "OVERLAY")
		debuffFrame.count:SetFontObject(GameFontHighlightSmallOutline)
		debuffFrame.count:SetJustifyH("CENTER")
		debuffFrame.count:SetPoint("CENTER", debuffFrame, "CENTER", 0, 0);
		debuffFrame:Hide()
		local debuffTimer = debuffFrame:CreateFontString(nil, "ARTWORK")
		debuffTimer:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		debuffTimer.fontsize = 12
		debuffTimer:SetTextColor(0.7, 0.7, 0)
		debuffTimer:ClearAllPoints()
		debuffTimer:SetAllPoints(debuffFrame)
		debuffFrame:SetScript("OnUpdate", function()
			local self = debuffTimer
			if not self:IsVisible() then return end
			if not self.DebuffName then return end
			local expires = select(7, UnitDebuff(f:GetAttribute("unit"), self.DebuffName)) or GetTime()
			local seconds = math.floor(expires-GetTime())
			if sRaidFrames.opt.debufftimer.show and (seconds <= sRaidFrames.opt.debufftimer.max) then
				seconds = tostring(seconds)
				if self.cache ~= seconds then
					self:SetText(seconds)
					self.cache = seconds
				end
				local supposedsize = math.floor(expires-GetTime()) >= 10 and 9 or 12
				if supposedsize ~= self.fontsize then
					self:SetFont("Fonts\\FRIZQT__.TTF", supposedsize, "OUTLINE")
					self.fontsize = supposedsize
				end
			elseif self.cache then
				self:SetText(nil)
				self.cache = nil
			end
		end)
		f["aura"..i] = debuffFrame
		f["aura"..i].timer = debuffTimer
	end

	for i = 1, layout.buffCount do
		local buffFrame = CreateFrame("Button", nil, f)
		buffFrame:SetScript("OnEnter", BuffFrame_OnEnter)
		buffFrame:SetScript("OnLeave", BuffFrame_OnLeave)
		buffFrame.texture = buffFrame:CreateTexture(nil, "ARTWORK")
		buffFrame.texture:SetAllPoints(buffFrame)
		buffFrame.count = buffFrame:CreateFontString(nil, "OVERLAY")
		buffFrame.count:SetFontObject(GameFontHighlightSmallOutline)
		buffFrame.count:SetJustifyH("CENTER")
		buffFrame.count:SetPoint("CENTER", buffFrame, "CENTER", 0, 0);
		buffFrame:Hide()
		local buffTimer = buffFrame:CreateFontString(nil, "ARTWORK")
		buffTimer:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
		buffTimer.fontsize = 9
		buffTimer:SetTextColor(0.7, 0.7, 0)
		buffTimer:ClearAllPoints()
		buffTimer:SetAllPoints(buffFrame)
		buffFrame:SetScript("OnUpdate", function()
			local self = buffTimer
			if not self:IsVisible() then return end
			if not self.BuffName then return end
			local expires = select(7, UnitBuff(f:GetAttribute("unit"), self.BuffName)) or GetTime()
			local seconds = math.floor(expires-GetTime())
			if sRaidFrames.opt.bufftimer.show and (seconds <= sRaidFrames.opt.bufftimer.max) then
				seconds = tostring(seconds)
				if self.cache ~= seconds then
					self:SetText(seconds)
					self.cache = seconds
				end
				local supposedsize = math.floor(expires-GetTime()) >= 10 and 6 or 9
				if supposedsize ~= self.fontsize then
					self:SetFont("Fonts\\FRIZQT__.TTF", supposedsize, "OUTLINE")
					self.fontsize = supposedsize
				end
			elseif self.cache then
				self:SetText(nil)
				self.cache = nil
			end
		end)
		f["buff"..i] = buffFrame
		f["buff"..i].timer = buffTimer
	end

	local texture = Media:Fetch("statusbar", self.opt.Texture)

	f.hpbar = CreateFrame("StatusBar", nil, f)
	f.hpbar:SetStatusBarTexture(texture)
	f.hpbar:SetMinMaxValues(0,100)
	f.hpbar:SetValue(0)

	f.hpbar.text = f.hpbar:CreateFontString(nil, "ARTWORK")
	f.hpbar.text:SetFontObject(GameFontHighlightSmall)
	f.hpbar.text:SetJustifyH("CENTER")

	local color = self.opt.HealthTextColor
	f.hpbar.text:SetTextColor(color.r, color.g, color.b, color.a)

	f.mpbar = CreateFrame("StatusBar", nil, f)
	f.mpbar:SetStatusBarTexture(texture)
	f.mpbar:SetMinMaxValues(0,100)
	f.mpbar:SetValue(0)

	f.statustext = f.mpbar:CreateFontString(nil, "ARTWORK")
	f.statustext:SetFontObject(GameFontHighlightSmall)
	f.statustext:SetJustifyH("CENTER")

	layout.StyleUnitFrame(f)

	--f:Hide();

	tinsert(self.frames, f)
	ShouldUpdateFrameCache = true

	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[f] = true
end

function sRaidFrames:CreateFrames()
	if not self.enabled then return end

	local neededGroups = #self:GetCurrentGroupSetup()
	local createdGroups = #self.groupframes
	for i = createdGroups+1, neededGroups do
		self:CreateGroupFrame(i)
	end
	self:SetPosition()
	self:SetGroupFilters()
	self:SetGrowth()
end

function sRaidFrames:SetGroupFilters()
	if InCombatLockdown() then return end

	for _, f in pairs(self.groupframes) do
		local id = f:GetID()
		local frame = self:GetCurrentGroupSetup()[id]
		if frame and not frame.hidden then
			for attribute, value in pairs(frame.attributes) do
				f.header:SetAttribute(attribute, value or nil)
			end
			f.title:SetText(frame.caption)
			f.header:Show()
		else
			f.header:Hide()
			f.header:SetAttribute("groupFilter", false)
			f.header:SetAttribute("nameList", false)
		end
		self:UpdateTitleVisibility(f.header)
	end
end

function sRaidFrames:GroupFrameGetNumChildren(frame)
	local i = 1
	local child = frame:GetAttribute("child"..i)
	while child do
		if not child:IsVisible() or not UnitExists(child:GetAttribute("unit")) then
			break
		end
		i = i + 1
		child = frame:GetAttribute("child"..i)
	end
	return (i-1)
end

function sRaidFrames:UpdateTitleVisibility(frame)
	if self.opt.ShowGroupTitles and self:GroupFrameGetNumChildren(frame) > 0 then
		frame:GetParent().anchor:Show()
	else
		frame:GetParent().anchor:Hide()
	end
end

function sRaidFrames:SetGrowth()
	for i, f in pairs(self.groupframes) do
		f.header:ClearAllPoints();
		local growth = self.opt.Growth["default"];
		if not self.opt.Growth[self.opt.GroupSetup] then self.opt.Growth[self.opt.GroupSetup] = {}; end
		if self.opt.Growth[self.opt.GroupSetup][i] and self.opt.Growth[self.opt.GroupSetup][i] ~= "default" then
			growth = self.opt.Growth[self.opt.GroupSetup][i];
		end
		if growth == "up" then
			f.header:SetAttribute("point", "TOP")
			f.header:SetPoint("BOTTOM", f.anchor, "TOP")
		elseif growth == "right" then
			f.header:SetAttribute("point", "LEFT")
			f.header:SetPoint("LEFT", f.anchor, "RIGHT")
		elseif growth == "left" then
			f.header:SetAttribute("point", "RIGHT")
			f.header:SetPoint("RIGHT", f.anchor, "LEFT")
		elseif growth == "down" then
			f.header:SetAttribute("point", "BOTTOM")
			f.header:SetPoint("TOP", f.anchor, "BOTTOM")
		end
	end
	self:SetSpacing()
end

function sRaidFrames:SetSpacing()
	local s = self.opt.Spacing
	for i, f in pairs(self.groupframes) do
		local growth = self.opt.Growth["default"];
		if self.opt.Growth[self.opt.GroupSetup][i] and self.opt.Growth[self.opt.GroupSetup][i] ~= "default" then
			growth = self.opt.Growth[self.opt.GroupSetup][i];
		end
		if growth == "down" then
			f.header:SetAttribute("xOffset", 0)
			f.header:SetAttribute("yOffset", s)
		elseif growth == "up" then
			f.header:SetAttribute("xOffset", 0)
			f.header:SetAttribute("yOffset", -s)
		elseif growth == "left" then
			f.header:SetAttribute("xOffset", s)
			f.header:SetAttribute("yOffset", 0)
		elseif growth == "right" then
			f.header:SetAttribute("xOffset", -s)
			f.header:SetAttribute("yOffset", 0)
		end
	end
end

function sRaidFrames:StartMovingAll(f, this)
	this.multidrag = 1
	local id = f:GetID()
	local fg = self.groupframes[id]
	local x, y = fg:GetLeft(), fg:GetTop()
	if ( not x or not y ) then
		return
	end
	for k, f in pairs(self.groupframes) do
		if k ~= id then
			local oX, oY = f:GetLeft(), f:GetTop()
			if ( oX and oY ) then
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", fg, "TOPLEFT", oX-x, oY-y)
			end
		end
	end
end

function sRaidFrames:StopMovingOrSizingAll(this)
	this.multidrag = nil
	local id = this:GetID()
	local fg = self.groupframes[id]
	for k, f in pairs(self.groupframes) do
		if k ~= id then
			local oX, oY = f:GetLeft(), f:GetTop()
			if ( oX and oY ) then
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", oX, oY)
			end
		end
	end
end

local function sRaidFrames_OnGroupFrameEvent(frame, event)
	if event == "PARTY_MEMBERS_CHANGED" and frame:IsVisible() then
  	sRaidFrames:ScheduleLeaveCombatAction("UpdateTitleVisibility", frame)
	end
end

function sRaidFrames:CreateGroupFrame(id)
	local layout = self:GetLayout()
	local f = CreateFrame("Frame", "sRaidFramesGroupBase".. id, self.master)
	f:SetHeight(layout.headerHeight)
	f:SetWidth(layout.headerWidth)
	f:SetMovable(true)
	f:SetID(id)

	f.header = CreateFrame("Frame", "sRaidFramesGroupHeader" .. id, f, "SecureRaidGroupHeaderTemplate")
	f.header:SetAttribute("template", "SecureUnitButtonTemplate")
	f.header.initialConfigFunction = sRaidFrames_InitUnitFrame
	f.header:HookScript("OnEvent", sRaidFrames_OnGroupFrameEvent)

	-- hack to reduce login lockup times
	-- f.header:UnregisterEvent("UNIT_NAME_UPDATE")

	f.anchor = CreateFrame("Button", "sRaidFramesAnchor"..id, self.master)
	f.anchor:SetHeight(layout.headerHeight)
	f.anchor:SetWidth(layout.headerWidth)
	f.anchor:SetScript("OnDragStart", function(this) if self.opt.Locked then return end if IsAltKeyDown() then self:StartMovingAll(f, this) end f:StartMoving() end)
	f.anchor:SetScript("OnDragStop", function(this) if this.multidrag == 1 then self:StopMovingOrSizingAll(this) end f:StopMovingOrSizing(f) self:SavePosition() end)
	f.anchor:EnableMouse(true)
	f.anchor:RegisterForDrag("LeftButton")
	f.anchor:RegisterForClicks("AnyUp")
	f.anchor:SetPoint("CENTER", f)

	f.title = f.anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.title:SetJustifyH("CENTER")
	f.title:ClearAllPoints()
	f.title:SetPoint("CENTER", f.anchor)

	self.groupframes[id] = f
end

function sRaidFrames:SetWHP(frame, width, height, p1, relative, p2, x, y)
	if not frame:IsProtected() or not InCombatLockdown() then
		frame:SetWidth(width)
		frame:SetHeight(height)

		if (p1) then
			frame:ClearAllPoints()
			frame:SetPoint(p1, relative, p2, x, y)
		end
	end
	if frame:IsProtected() then
		frame:SetAttribute("initial-width", width)
		frame:SetAttribute("initial-height", height)
	end
end

function sRaidFrames:GetAllUnits()
	if ShouldUpdateFrameCache then self:UpdateFrameCache() end
	return self.FramesByUnit
end

function sRaidFrames:FindUnitFrames(unit)
	if ShouldUpdateFrameCache then self:UpdateFrameCache() end
	return self.FramesByUnit[unit] or {}
end

function sRaidFrames:GetNonVehicleUnit(unit)
	local noPet = unit:gsub("[pP][eE][tT](%d)", "%1")
	if self.opt.VehicleSwitch and UnitHasVehicleUI(noPet) then
		unit = noPet
	end
	return unit
end

function sRaidFrames:GetVehicleUnit(unit)
	if self.opt.VehicleSwitch and UnitHasVehicleUI(unit) then
		unit = unit .. "pet"
		-- map raid1pet to raidpet1
		unit = gsub(unit, "^([^%d]+)([%d]+)[pP][eE][tT]", "%1pet%2");
	end
	return unit
end

function sRaidFrames:IsTracking(unit)
	if ShouldUpdateFrameCache then self:UpdateFrameCache() end
	return (self.FramesByUnit[unit] ~= nil)
end

function sRaidFrames:SetPosition()
	if #self.opt.Positions[self.opt.GroupSetup] <= 0 then
		self:ResetPosition()
	else
		self:RestorePosition()
	end
end

function sRaidFrames:SavePosition()
	if not self.opt.Positions[self.opt.GroupSetup] then
		self.opt.Positions[self.opt.GroupSetup] = {}
	end

	for k,frame in pairs(self.groupframes) do
		local dbentry = {}
		local x, y, s = frame:GetLeft(), frame:GetTop(), frame:GetEffectiveScale()
		x, y = x * s, y  * s
		
		dbentry.x = x
		dbentry.y = y
		dbentry.s = s

		self.opt.Positions[self.opt.GroupSetup][k] = dbentry
	end
end

function sRaidFrames:RestorePosition()
	local aryPos = self.opt.Positions[self.opt.GroupSetup]
	local scale = self.master:GetEffectiveScale()

	for k, data in pairs(aryPos) do
		local groupframe = self.groupframes[k]
		if groupframe then
			local x, y, s = data.x, data.y, groupframe:GetEffectiveScale()
			x, y = x and x / s, y and y / s
			groupframe:ClearAllPoints()
			groupframe:SetPoint(x and "topleft" or "center", UIParent, y and "bottomleft" or "center", x or 0, y or 0)
		end
	end
end

function sRaidFrames:ResetPosition()
	self:PositionLayout("ctra", 200, -200)
end

function sRaidFrames:PositionLayout(layout, xBuffer, yBuffer)
	local xMod, yMod, i = 0, 0, -1
	local frameHeight = self:GetLayout().unitframeHeight+3+self.opt.Spacing
	local framePadding = MEMBERS_PER_RAID_GROUP

	for k,frame in pairs(self.groupframes) do
		i = i + 1
		if layout == "horizontal" then
			yMod = i * frame:GetWidth()
			xMod = 0
		elseif layout == "vertical" then
			if i ~= 0 and fmod(i, 2) == 0 then
				xMod = xMod + (-1*framePadding*frameHeight)
				yMod = 0
				i = 0
			else
				yMod = i * frame:GetWidth()
			end
		elseif layout == "ctra" then
			if i ~= 0 and fmod(i, 2) == 0 then
				yMod = yMod + frame:GetWidth()
				xMod = 0
				i = 0
			else
				xMod = i * (-1*framePadding*frameHeight)
			end
		end

		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xBuffer+yMod, yBuffer+xMod)
	end

	self:SavePosition()
end

function createLDBLauncher()
	local version = GetAddOnMetadata("sRaidFrames", "version") or ""
	if LDB then
		local launcher = LibStub("LibDataBroker-1.1"):NewDataObject("sRaidFrames", {
			type = "launcher",
			label = "sRaidFrames",
			icon = "Interface\\Icons\\INV_Helmet_06",
			OnClick = function(self, button)
				if button == "LeftButton" then
					if InCombatLockdown() then return end
					if sRaidFrames.master:IsVisible() then
						sRaidFrames.master:Hide()
					else
						sRaidFrames.master:Show()
					end
				else
					if LibStub("AceConfigDialog-3.0").OpenFrames["sRaidFrames"] then
						LibStub("AceConfigDialog-3.0"):Close("sRaidFrames")
					else
						LibStub("AceConfigDialog-3.0"):Open("sRaidFrames")
					end
				end
			end,
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine("sRaidFrames ".. version)
				tooltip:AddLine("|cffffff00" .. L["Left-click to toggle visiblity."] .. "|r")
				tooltip:AddLine("|cffffff00" .. L["Right-click for options."] .. "|r")
			end
		})
		
		if LDBIcon then
			LDBIcon:Register("sRaidFrames", launcher, sRaidFrames.db.profile.minimapIcon)
		end
	end
end
