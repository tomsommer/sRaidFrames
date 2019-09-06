local L = LibStub("AceLocale-3.0"):GetLocale("sRaidFrames")
local Media = LibStub("LibSharedMedia-3.0")
local sRaidFrames = sRaidFrames

sRaidFrames.Layouts = {}

function sRaidFrames:RegisterLayout(name, data)
	self.Layouts[name] = data
	
	self.options.args.behaviour.args.layout.values = {}
	for _name, _data in pairs(self.Layouts) do
		self.options.args.behaviour.args.layout.values[_name] = _data.Name
	end
end

function sRaidFrames:SetLayout(name)
	if not self.Layouts[name] then
		name = "CTRA_WithBorders"
	end
	self.opt.Layout = name
	self.CurrentLayout = self.Layouts[name]
end

function sRaidFrames:ApplyLayout()
	for _, f in ipairs(self.frames) do
		self:GetLayout().StyleUnitFrame(f)
	end
	for unit in pairs(self:GetAllUnits()) do
		self:UpdateStatuses(unit)
	end
	self:SetSpacing()
end

function sRaidFrames:GetLayout()
	if not self.CurrentLayout then
		self:SetLayout(self.opt.Layout)
	end
	return self.CurrentLayout
end

sRaidFrames:RegisterLayout("CTRA_WithBorders", {
	Name = L["CT_RaidAssist"],
	HasBorders = true,
	StyleUnitFrame = function(f)
		local width = 90
		local height = 38
		local border = 2
		local padding = border + 1

		sRaidFrames:SetWHP(f, width, height)
		sRaidFrames:SetWHP(f.title, f:GetWidth() - padding, 16, "TOPLEFT", f, "TOPLEFT",  padding, -1 * padding)
		sRaidFrames:SetWHP(f.aura1, 16, 16, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
		sRaidFrames:SetWHP(f.aura2, 16, 16, "RIGHT", f.aura1, "LEFT", 0, 0)
		if sRaidFrames.opt.BuffType == "both" then
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f.aura2,"TOPLEFT", 0, 0);
		else
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
		end
		sRaidFrames:SetWHP(f.buff2, 12, 12, "RIGHT", f.buff1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff3, 12, 12, "RIGHT", f.buff2, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff4, 12, 12, "RIGHT", f.buff3, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.hpbar, f.title:GetWidth() - (border * 2), 12, "TOPLEFT", f.title, "BOTTOMLEFT", 0, 0)
		sRaidFrames:SetWHP(f.mpbar, f.title:GetWidth() - (border * 2), 4, "TOPLEFT", f.hpbar, "BOTTOMLEFT", 0, 0)
	
		sRaidFrames:SetWHP(f.hpbar.text, f.hpbar:GetWidth(), f.hpbar:GetHeight(), "CENTER", f.hpbar, "CENTER", 0, 0)
		sRaidFrames:SetWHP(f.statustext, f.mpbar:GetWidth(), f.mpbar:GetHeight(), "CENTER", f.mpbar, "CENTER", 0, 0)
		
		
		f:SetBackdrop({ bgFile = Media:Fetch("background", sRaidFrames.opt.BackgroundTexture),
						tile = true,
						tileSize = border * 4,
						edgeFile = Media:Fetch("border", sRaidFrames.opt.BorderTexture),
						edgeSize = border,
						insets = { left = border, right = border, top = border, bottom = border }
					})
								
		f:SetBackdropColor(sRaidFrames.opt.BackgroundColor.r, sRaidFrames.opt.BackgroundColor.g, sRaidFrames.opt.BackgroundColor.b, sRaidFrames.opt.BackgroundColor.a)
		f:SetBackdropBorderColor(sRaidFrames.opt.BorderColor.r, sRaidFrames.opt.BorderColor.g, sRaidFrames.opt.BorderColor.b, sRaidFrames.opt.BorderColor.a)
		f.hpbar.text:SetTextColor(sRaidFrames.opt.HealthTextColor.r, sRaidFrames.opt.HealthTextColor.g, sRaidFrames.opt.HealthTextColor.b, sRaidFrames.opt.HealthTextColor.a)
	end,
	unitframeWidth = 90,
	unitframeHeight = 40,
	headerWidth = 90,
	headerHeight = 15,
	debuffCount = 2,
	buffCount = 4,
})

sRaidFrames:RegisterLayout("CTRA_NoBorders", {
	Name = L["CT_RaidAssist (Without Borders)"],
	HasBorders = false,
	StyleUnitFrame = function(f)
		sRaidFrames:SetWHP(f, 80, 32)
		sRaidFrames:SetWHP(f.title, 80, 16, "TOPLEFT", f, "TOPLEFT",  0, 0)
		sRaidFrames:SetWHP(f.aura1, 16, 16, "TOPRIGHT", f, "TOPRIGHT", 0, 0)
		sRaidFrames:SetWHP(f.aura2, 16, 16, "RIGHT", f.aura1, "LEFT", 0, 0)
		if sRaidFrames.opt.BuffType == "both" then
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f.aura2, "TOPLEFT", 0, 0);
		else
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f, "TOPRIGHT", 0, 0)
		end
		sRaidFrames:SetWHP(f.buff2, 12, 12, "RIGHT", f.buff1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff3, 12, 12, "RIGHT", f.buff2, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff4, 12, 12, "RIGHT", f.buff3, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.hpbar, 80, 12, "TOPLEFT", f.title, "BOTTOMLEFT", 0, 0)
		sRaidFrames:SetWHP(f.mpbar, 80, 4, "TOPLEFT", f.hpbar, "BOTTOMLEFT", 0, 0)
	
		sRaidFrames:SetWHP(f.hpbar.text, f.hpbar:GetWidth(), f.hpbar:GetHeight(), "CENTER", f.hpbar, "CENTER", 0, 0)
		sRaidFrames:SetWHP(f.statustext, f.mpbar:GetWidth(), f.mpbar:GetHeight(), "CENTER", f.mpbar, "CENTER", 0, 0)
		
		f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
										tile = true, tileSize = 16,
										insets = { left = 0, right = 0, top = 0, bottom = 0 }
									})
		
		f:SetBackdropColor(sRaidFrames.opt.BackgroundColor.r, sRaidFrames.opt.BackgroundColor.g, sRaidFrames.opt.BackgroundColor.b, sRaidFrames.opt.BackgroundColor.a)
		f.hpbar.text:SetTextColor(sRaidFrames.opt.HealthTextColor.r, sRaidFrames.opt.HealthTextColor.g, sRaidFrames.opt.HealthTextColor.b, sRaidFrames.opt.HealthTextColor.a)
	end,
	unitframeWidth = 80,
	unitframeHeight = 32,
	headerWidth = 80,
	headerHeight = 15,
	debuffCount = 2,
	buffCount = 4,
})

sRaidFrames:RegisterLayout("CTRA_NoBordersWide", {
	Name = L["CT_RaidAssist (Without borders, Wide)"],
	HasBorders = false,
	StyleUnitFrame = function(f)
		sRaidFrames:SetWHP(f, 90, 40)
		sRaidFrames:SetWHP(f.title, 80, 16, "TOPLEFT", f, "TOPLEFT",  5, -4)
		sRaidFrames:SetWHP(f.aura1, 16, 16, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
		sRaidFrames:SetWHP(f.aura2, 16, 16, "RIGHT", f.aura1, "LEFT", 0, 0)
		if sRaidFrames.opt.BuffType == "both" then
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f.aura2, "TOPLEFT", 0, 0);
		else
			sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
		end
		sRaidFrames:SetWHP(f.buff2, 12, 12, "RIGHT", f.buff1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff3, 12, 12, "RIGHT", f.buff2, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff4, 12, 12, "RIGHT", f.buff3, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.hpbar, 80, 12, "TOPLEFT", f.title, "BOTTOMLEFT", 0, 0)
		sRaidFrames:SetWHP(f.mpbar, 80, 4, "TOPLEFT", f.hpbar, "BOTTOMLEFT", 0, 0)
	
		sRaidFrames:SetWHP(f.hpbar.text, f.hpbar:GetWidth(), f.hpbar:GetHeight(), "CENTER", f.hpbar, "CENTER", 0, 0)
		sRaidFrames:SetWHP(f.statustext, f.mpbar:GetWidth(), f.mpbar:GetHeight(), "CENTER", f.mpbar, "CENTER", 0, 0)
		
		
		f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
										tile = true, tileSize = 16,
										insets = { left = 0, right = 0, top = 0, bottom = 0 }
									})
								
		f:SetBackdropColor(sRaidFrames.opt.BackgroundColor.r, sRaidFrames.opt.BackgroundColor.g, sRaidFrames.opt.BackgroundColor.b, sRaidFrames.opt.BackgroundColor.a)
		f.hpbar.text:SetTextColor(sRaidFrames.opt.HealthTextColor.r, sRaidFrames.opt.HealthTextColor.g, sRaidFrames.opt.HealthTextColor.b, sRaidFrames.opt.HealthTextColor.a)
	end,
	unitframeWidth = 90,
	unitframeHeight = 40,
	headerWidth = 90,
	headerHeight = 15,
	debuffCount = 2,
	buffCount = 4,
})

--[[
sRaidFrames:RegisterLayout("sRaidFrames", {
	Name = "sRaidFrames",
	HasBorders = true,
	StyleUnitFrame = function(f)
		sRaidFrames:SetWHP(f, 80, 30)
		sRaidFrames:SetWHP(f.title, 78, 13, "TOPLEFT", f, "TOPLEFT",  1, 0)
		sRaidFrames:SetWHP(f.aura1, 13, 13, "TOPRIGHT", f, "TOPRIGHT", -1, -1)
		sRaidFrames:SetWHP(f.aura2, 13, 13, "RIGHT", f.aura1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff1, 13, 13, "TOPRIGHT", f, "TOPRIGHT", -1, -1)
		sRaidFrames:SetWHP(f.buff2, 13, 13, "RIGHT", f.buff1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff3, 13, 13, "RIGHT", f.buff2, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.hpbar, 78, 12, "TOPLEFT", f.title, "BOTTOMLEFT", 0, 0)
		sRaidFrames:SetWHP(f.mpbar, 78, 4, "TOPLEFT", f.hpbar, "BOTTOMLEFT", 0, 0)
	
		sRaidFrames:SetWHP(f.hpbar.text, f.hpbar:GetWidth(), f.hpbar:GetHeight(), "CENTER", f.hpbar, "CENTER", 0, 0)
		sRaidFrames:SetWHP(f.statustext, f.mpbar:GetWidth(), f.mpbar:GetHeight(), "CENTER", f.mpbar, "CENTER", 0, 0)
		
		
		f:SetBackdrop({ bgFile = "Interface\\Addons\\sRaidFrames\\textures\\solidborder",
									tile = true,
									tileSize = 16,
									edgeFile = "Interface\\Addons\\sRaidFrames\\textures\\solidborder",
									edgeSize = 1,
									insets = { left = 1, right = 1, top = 1, bottom = 1 }
								})
								
		f:SetBackdropColor(sRaidFrames.opt.BackgroundColor.r, sRaidFrames.opt.BackgroundColor.g, sRaidFrames.opt.BackgroundColor.b, sRaidFrames.opt.BackgroundColor.a)
		f:SetBackdropBorderColor(sRaidFrames.opt.BorderColor.r, sRaidFrames.opt.BorderColor.g, sRaidFrames.opt.BorderColor.b, sRaidFrames.opt.BorderColor.a)
		f.hpbar.text:SetTextColor(sRaidFrames.opt.HealthTextColor.r, sRaidFrames.opt.HealthTextColor.g, sRaidFrames.opt.HealthTextColor.b, sRaidFrames.opt.HealthTextColor.a)
	end,
	unitframeWidth = 80,
	unitframeHeight = 30,
	headerWidth = 85,
	headerHeight = 15,
	debuffCount = 2,
	buffCount = 3,
})



sRaidFrames:RegisterLayout("Grid", {
	Name = "Dispell Grid",
	HasBorders = false,
	StyleUnitFrame = function(f)
		sRaidFrames:SetWHP(f, 26, 26)
		sRaidFrames:SetWHP(f.title, 80, 16, "TOPLEFT", f, "TOPLEFT",  5, -4)
		
		sRaidFrames:SetWHP(f.aura1, 16, 16, "CENTER", f, "CENTER", 0, 0)
		
		sRaidFrames:SetWHP(f.buff1, 12, 12, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
		sRaidFrames:SetWHP(f.buff2, 12, 12, "RIGHT", f.buff1, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff3, 12, 12, "RIGHT", f.buff2, "LEFT", 0, 0)
		sRaidFrames:SetWHP(f.buff4, 12, 12, "RIGHT", f.buff3, "LEFT", 0, 0)
		
		sRaidFrames:SetWHP(f.hpbar, 80, 12, "TOPLEFT", f, "TOPLEFT", 0, 0)
		sRaidFrames:SetWHP(f.mpbar, 80, 4, "TOPRIGHT", f, "TOPRIGHT", 0, 0)
		
		f.hpbar:Hide()
		f.mpbar:Hide()
	
		sRaidFrames:SetWHP(f.title, f:GetWidth()-4, f.hpbar:GetHeight(), "CENTER", f, "CENTER", 0, 0)
		
		f.title:SetJustifyH("CENTER")
		f.title:SetNonSpaceWrap(true)
		
		f:SetBackdropColor(sRaidFrames.opt.BackgroundColor.r, sRaidFrames.opt.BackgroundColor.g, sRaidFrames.opt.BackgroundColor.b, sRaidFrames.opt.BackgroundColor.a)
		f:SetBackdropBorderColor(sRaidFrames.opt.BorderColor.r, sRaidFrames.opt.BorderColor.g, sRaidFrames.opt.BorderColor.b, sRaidFrames.opt.BorderColor.a)
		f.hpbar.text:SetTextColor(sRaidFrames.opt.HealthTextColor.r, sRaidFrames.opt.HealthTextColor.g, sRaidFrames.opt.HealthTextColor.b, sRaidFrames.opt.HealthTextColor.a)
		
		f:SetBackdrop( {
				      bgFile = "Interface\\Addons\\sRaidFrames\\textures\\solidborder", tile = true, tileSize = 16,
				      edgeFile = "Interface\\Addons\\sRaidFrames\\textures\\solidborder", edgeSize = 1,
				      insets = {left = 1, right = 1, top = 1, bottom = 1},
			      })
	end,
	unitframeWidth = 26,
	unitframeHeight = 26,
	headerWidth = 26,
	headerHeight = 15,
	debuffCount = 1,
	buffCount = 4,
})
]]--