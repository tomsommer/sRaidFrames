local HealComm = LibStub("LibClassicHealComm-1.0", true)

local GUIDmap = HealComm:GetGUIDUnitMapTable()

local sRaidFrames = sRaidFrames

function sRaidFrames:GetUnitByGUID(guid)
	if GUIDmap[guid] then 
		return GUIDmap[guid] 
	end
	for unit in pairs(self:GetAllUnits()) do
		if UnitGUID(unit) == guid then
			return unit
		end 
	end
	for i=1, GetNumGroupMembers() do
		if UnitGUID("raid"..i) == guid then 
			return "raid"..i 
		end
	end
end

function sRaidFrames:UpdateHealsOnUnit(unit)
	local incomingHeals = HealComm:GetHealAmount(UnitGUID(unit), HealComm.CASTED_HEALS) or 0
	if incomingHeals and incomingHeals > 0 then
		incomingHeals = incomingHeals * HealComm:GetHealModifier(UnitGUID(unit))
		self:SetStatus(unit, "Heal", ("+%d"):format(incomingHeals), nil, true)
	else
		self:UnsetStatus(unit, "Heal")
	end
end

function sRaidFrames:HealComm_HealStarted(event, casterGUID, spellID, healType, endTime, ...)
	for i=1, select('#', ...) do
		local targetUnit = self:GetUnitByGUID(select(i, ...))
		if targetUnit then
			self:UpdateHealsOnUnit(targetUnit)
		end
	end
end

function sRaidFrames:HealComm_HealStopped(event, casterGUID, spellID, healType, interrupted, ...)
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
