local HealComm = LibStub("LibClassicHealComm-1.0", true)
if not HealComm then return end

local GUIDmap = HealComm:GetGUIDUnitMapTable()

local sRaidFrames = sRaidFrames

function sRaidFrames:GetUnitByGUID(guid)
	if GUIDmap[guid] then return GUIDmap[guid] end
	for i=1, GetNumGroupMembers() do
		if UnitGUID("raid"..i) == guid then return "raid"..i end
	end
end

function sRaidFrames:GetHealFlag()
	local flag = 0
	if self.opt.heals.direct and HealComm.DIRECT_HEALS then
		flag = flag+HealComm.DIRECT_HEALS
	end
	if self.opt.heals.channel and HealComm.CHANNEL_HEALS then
		flag = flag+HealComm.CHANNEL_HEALS
	end
	if self.opt.heals.hot and HealComm.HOT_HEALS then
		flag = flag+HealComm.HOT_HEALS
	end
	if self.opt.heals.bomb and HealComm.BOMB_HEALS then
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
	for i=1, select('#', ...) do
		local targetUnit=self:GetUnitByGUID(select(i, ...))
		if targetUnit then
			self:UpdateHealsOnUnit(targetUnit)
		end
	end
end

function sRaidFrames:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
	for i=1, select('#', ...) do
		local targetUnit=self:GetUnitByGUID(select(i, ...))
		if targetUnit then
			self:UpdateHealsOnUnit(targetUnit)
		end
	end
end

function sRaidFrames:HealComm_ModifierChanged(event, guid)
	local targetUnit = self:GetUnitByGUID(guid)
	if targetUnit then
		self:UpdateHealsOnUnit(targetUnit)
	end
end
