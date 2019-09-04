local HealComm = LibStub("LibClassicHealComm-1.0", true)
if not HealComm then return end

local GUIDmap = HealComm:GetGUIDUnitMapTable()

local sRaidFrames = sRaidFrames

function sRaidFrames:GetUnitByGUID(guid)
	if GUIDmap[guid] then return GUIDmap[guid] end
	for i=1, GetNumRaidMembers() do
		if UnitGUID("raid"..i) == guid then return "raid"..i end
	end
end

function sRaidFrames:GetHealFlag()
	local flag = 0
	if self.opt.heals.direct then
		flag = flag+HealComm.DIRECT_HEALS
	end
	if self.opt.heals.channel then
		flag = flag+HealComm.CHANNEL_HEALS
	end
	if self.opt.heals.hot then
		flag = flag+HealComm.HOT_HEALS
	end
	if self.opt.heals.bomb and not sRaidFrames.isClassic then
		flag = flag+HealComm.BOMB_HEALS
	end
	return flag
end

function sRaidFrames:UpdateHealsOnUnit(unit)
	local incomingHeals = HealComm:GetHealAmount(UnitGUID(unit), self:GetHealFlag()) or 0

	if incomingHeals > 0 then
		incomingHeals = incomingHeals * HealComm:GetHealModifier(UnitGUID(unit))
		self:SetStatus(unit, "Heal", ("+%d"):format(incomingHeals), nil, true)
	else
		self:UnsetStatus(unit, "Heal")
	end
end

function sRaidFrames:HealComm_HealStarted(event, casterGUID, spellID, healType, endTime, ...)
	if not self.opt.HighlightHeals then return end
	for i=1, select('#', ...) do
		local targetUnit=self:GetUnitByGUID(select(i, ...))
		if targetUnit then
			self:UpdateHealsOnUnit(targetUnit)
		end
	end
end

function sRaidFrames:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
	if not self.opt.HighlightHeals then return end
	for i=1, select('#', ...) do
		local targetUnit=self:GetUnitByGUID(select(i, ...))
		if targetUnit then
			self:UpdateHealsOnUnit(targetUnit)
		end
	end
end

function sRaidFrames:HealComm_ModifierChanged(event, guid)
	if not self.opt.HighlightHeals then return end
	local targetUnit = self:GetUnitByGUID(guid)
	if targetUnit then
		self:UpdateHealsOnUnit(targetUnit)
	end
end
