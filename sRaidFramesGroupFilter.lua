local L = LibStub("AceLocale-3.0"):GetLocale("sRaidFrames")
local sRaidFrames = sRaidFrames

if sRaidFrames.isClassic then
	local function GetNumClasses()
		return 9
	end
end

function sRaidFrames:RegisterGroupSetup(name)
	self.opt.GroupSetups[name] = {}
	self:chatUpdateFilterMenu()
end

function sRaidFrames:GetGroupSetup(name)
	return self.opt.GroupSetups[name]
end

function sRaidFrames:RenameGroupSetup(old, new)
	self.opt.GroupSetups[new] = self.opt.GroupSetups[old]
	self.opt.GroupSetups[old] = nil
	if self.opt.GroupSetup == old then
		self.opt.GroupSetup = new
	end
	
	self.opt.Positions[new] = self.opt.Positions[old]
	self.opt.Positions[old] = nil

	self:chatUpdateFilterMenu()
	return self.opt.GroupSetups[new]
end

function sRaidFrames:DefaultGroupSetups()
	if not self:GetGroupSetup(L["By class"]) then
		self:RegisterGroupSetup(L["By class"])
		self:CreateGroupFilter(L["By class"], 1, L["Warriors"], {["groupFilter"] = "WARRIOR"})
		self:CreateGroupFilter(L["By class"], 2, L["Mages"], {["groupFilter"] = "MAGE"})
		self:CreateGroupFilter(L["By class"], 3, L["Paladins"], {["groupFilter"] = "PALADIN"})
		self:CreateGroupFilter(L["By class"], 4, L["Druids"], {["groupFilter"] = "DRUID"})
		self:CreateGroupFilter(L["By class"], 5, L["Hunters"], {["groupFilter"] = "HUNTER"})
		self:CreateGroupFilter(L["By class"], 6, L["Rogues"], {["groupFilter"] = "ROGUE"})
		self:CreateGroupFilter(L["By class"], 7, L["Warlocks"], {["groupFilter"] = "WARLOCK"})
		self:CreateGroupFilter(L["By class"], 8, L["Priests"], {["groupFilter"] = "PRIEST"})
		self:CreateGroupFilter(L["By class"], 9, L["Shamans"], {["groupFilter"] = "SHAMAN"})
		self:CreateGroupFilter(L["By class"], 10, "Death Knights", {["groupFilter"] = "DEATHKNIGHT"})
	end

	if not self:GetGroupSetup(L["By group"]) then
		self:RegisterGroupSetup(L["By group"])
		self:CreateGroupFilter(L["By group"], 1, L["Group 1"], {["groupFilter"] = "1"})
		self:CreateGroupFilter(L["By group"], 2, L["Group 2"], {["groupFilter"] = "2"})
		self:CreateGroupFilter(L["By group"], 3, L["Group 3"], {["groupFilter"] = "3"})
		self:CreateGroupFilter(L["By group"], 4, L["Group 4"], {["groupFilter"] = "4"})
		self:CreateGroupFilter(L["By group"], 5, L["Group 5"], {["groupFilter"] = "5"})
		self:CreateGroupFilter(L["By group"], 6, L["Group 6"], {["groupFilter"] = "6"})
		self:CreateGroupFilter(L["By group"], 7, L["Group 7"], {["groupFilter"] = "7"})
		self:CreateGroupFilter(L["By group"], 8, L["Group 8"], {["groupFilter"] = "8"})
	end

	if not self:GetGroupSetup(L["By role"]) then
		self:RegisterGroupSetup(L["By role"])
		self:CreateGroupFilter(L["By role"], 1, L["Tanks"], {["groupFilter"] = "WARRIOR"})
		self:CreateGroupFilter(L["By role"], 2, L["Melee DPS"], {["groupFilter"] = "ROGUE,WARRIOR"})
		self:CreateGroupFilter(L["By role"], 3, L["Range DPS"], {["groupFilter"] = "MAGE,WARLOCK,HUNTER"})
		self:CreateGroupFilter(L["By role"], 4, L["Healers"], {["groupFilter"] = "PALADIN,SHAMAN,PRIEST,DRUID"})
	end
end

function sRaidFrames:DeleteGroupSetup(name)
	self.opt.GroupSetups[name] = nil
	self:chatUpdateFilterMenu()
end

function sRaidFrames:GetGroupSetupFilter(name, group)
	return self.opt.GroupSetups[name][group]
end

function sRaidFrames:GetCurrentGroupSetup()
	return self:GetGroupSetup(self.opt.GroupSetup)
end

function sRaidFrames:CreateGroupFilter(name, id, caption, attributes)
	self:UpdateGroupFilter(name, id, {["caption"] = caption, ["attributes"] = attributes})
end

function sRaidFrames:UpdateGroupFilter(name, id, data)
	if not data.attributes["sortMethod"] then
		data.attributes["sortMethod"] = "NAME"
	end
	if not data.attributes["sortDir"] then
		data.attributes["sortDir"] = "DESC"
	end

	self.opt.GroupSetups[name][id] = data
	self:chatUpdateFilterMenu()
	self:CreateFrames()
end

function sRaidFrames:DeleteGroupFilter(name, id)
	tremove(self.opt.GroupSetups[name], id)
	self:chatUpdateFilterMenu()
	self:CreateFrames()
end

function sRaidFrames:SetCurrentGroupSetup(name)
	self.opt.GroupSetup = name
	self:CreateFrames()
	self:Print(L["Current filter set is now '%s'"]:format(name))
	self:chatUpdateFilterMenu()
end

function sRaidFrames:GetAllGroupFilters()
	return self.opt.GroupSetups
end

function sRaidFrames:chatUpdateFilterMenu()
	self.options.args.sets.args = {
		reset = {
			name = L["Reset to default"],
			type = "execute",
			desc = L["Reset to default sets"],
			func = function()
				self.opt.GroupSetups = {}
				self:DefaultGroupSetups()
				end,
			order = 300,
		},
		add = {
			name = L["Add new set"],
			type = "input",
			desc = L["Add a new set of frames"],
			usage = L["<Name>"],
			get = false,
			set = function(info, value)
				self:RegisterGroupSetup(value)
				end,
			order = 200,
		},
	}

	local i = 0
	for name, _ in pairs(self:GetAllGroupFilters()) do
		i = i + 1
		self.options.args.sets.args["set".. i] = {
			type = 'group',
			name = L["Set: "] .. name .. ((name == self.opt.GroupSetup) and L[" |cff00ff00[Active]|r "] or ""),
			desc = name,
			args = {},
			order = 100,
			childGroups = "select",
		}

		if name ~= self.opt.GroupSetup then
			self.options.args.sets.args["set".. i].args.use = {
				type = 'execute',
				name = L["|cff00ff00Activate this set!"],
				desc = name,
				func = function()
									self:SetCurrentGroupSetup(name)
									self:chatUpdateFilterMenu()
							 end,
				order = 1,
			}

			self.options.args.sets.args["set".. i].args.delete = {
				type = 'execute',
				name = L["|cffff0000Delete this set"],
				desc = name,
				func = function()
									self:DeleteGroupSetup(name)
							 end,
				order = 300,
			}
		end

		self.options.args.sets.args["set".. i].args.rename = {
			type = 'input',
			name = L["Rename this set"],
			desc = name,
			get = function()
							return name
						end,
			set = function(info, value)
							self:RenameGroupSetup(name, value)
						end,
			usage = L["<Name>"],
			order = 2,
		}

		self.options.args.sets.args["set".. i].args.add = {
			type = 'input',
			name = L["Add new frame"],
			desc = L["Add a new frame with the title entered here"],
			usage = L["<Name>"],
			get = false,
			set = function(info, value)
							self:CreateGroupFilter(name, (#self:GetGroupSetup(name)+1), value, {})
						end,
			order = 200,
		}

		for id, data in pairs(self:GetGroupSetup(name)) do
			self.options.args.sets.args["set".. i].args["frame".. id] = {
				type = 'group',
				name = L["Frame #"].. id .. " (".. data.caption ..")",
				desc = L["Frame "].. id,
				args = {},
			}

			self.options.args.sets.args["set".. i].args["frame".. id].args.caption = {
				type = 'input',
				name = L["Caption"],
				desc = L["Caption"],
				usage = L["<Caption>"],
				get = function()
								return data.caption
							end,
				set = function(info, value)
					data.caption = value
					self:UpdateGroupFilter(name, id, data)
				end
			}
			self.options.args.sets.args["set".. i].args["frame".. id].args.namelist = {
				type = 'input',
				name = L["Players"],
				desc = L["A comma separated list of player names, i.e: PLAYER1,PLAYER2,PLAYER3"],
				usage = L["<PLAYER1,PLAYER2,PLAYER3>"],
				get = function()
								return data.attributes.nameList
							end,
				set = function(info, value)
					data.attributes.nameList = value:len() > 0 and value or nil
					self:UpdateGroupFilter(name, id, data)
				end,
				disabled = function() return (data.attributes.groupFilter and #data.attributes.groupFilter > 0) end,
			}
			self.options.args.sets.args["set".. i].args["frame".. id].args.hide = {
				type = 'toggle',
				name = "Hide frame",
				desc = "Hide this frame from this filter",
				order = 250,
				get = function() return data.hidden end,
				set = function(info, value)
								data.hidden = value
								self:SetGroupFilters()
							end
			}

			self.options.args.sets.args["set".. i].args["frame".. id].args.remove = {
				type = 'execute',
				name = L["|cffff0000Remove frame|r"],
				desc = L["Remove this frame from this filter"],
				order = 300,
				func = function()
								self:DeleteGroupFilter(name, id)
								self:chatUpdateFilterMenu()
								self:SetGroupFilters()
							end,
				confirm = true,
			}
			
			self.options.args.sets.args["set"..i].args["frame"..id].args.coords = {
				name = L["Coordinates"],
				desc = L["Manually modify this frame's coordinates"],
				order = 350,
				dialogInline = true,
				type = "group",
				hidden = function() return not self.opt.advanced end,
				args = {
					x = {
						name = "X",
						type = "input",
						desc = function() return self.opt.Positions[name] and self.opt.Positions[name][id] and "" or L["Placement data is only available after the set was loaded for the first time"] end,
						order = 1,
						get = function() return self.opt.Positions[name] and self.opt.Positions[name][id] and tostring(self.opt.Positions[name][id].x) or "" end,
						set = function(info, value) if self.opt.Positions[name] and self.opt.Positions[name][id] then self.opt.Positions[name][id].x = tonumber(value); self:RestorePosition(); end end,
					},
					y = {
						name = "Y",
						type = "input",
						desc = function() return self.opt.Positions[name] and self.opt.Positions[name][id] and "" or L["Placement data is only available after the set was loaded for the first time"] end,
						order = 2,
						get = function() return self.opt.Positions[name] and self.opt.Positions[name][id] and tostring(self.opt.Positions[name][id].y) or "" end,
						set = function(info, value) if self.opt.Positions[name] and self.opt.Positions[name][id] then self.opt.Positions[name][id].y = tonumber(value); self:RestorePosition(); end end,
					},
				},
			}




			self.options.args.sets.args["set".. i].args["frame".. id].args.sortmethod = {
				type = 'select',
				name = L["Sort method"],
				desc = L["Select which method to use for sorting"],
				values = {
					["NAME"] = L["By player name"],
					["INDEX"] = L["By position in group"],
				},
				get = function()
								return data.attributes.sortMethod
							end,
				set = function(info, value)
								data.attributes.sortMethod = value
								self:UpdateGroupFilter(name, id, data)
							end,

			}


			self.options.args.sets.args["set".. i].args["frame".. id].args.sortdirection = {
				type = 'select',
				name = L["Sort direction"],
				desc = L["Select in which direction to sort players"],
				values = {
					["DESC"] = L["Descending"],
					["ASC"] = L["Ascending"],
				},
				get = function()
								return data.attributes.sortDir
							end,
				set = function(info, value)
								data.attributes.sortDir = value
								self:UpdateGroupFilter(name, id, data)
							end,
			}

			self.options.args.sets.args["set".. i].args["frame".. id].args.strictfilter = {
				type = 'toggle',
				name = L["Strict filtering"],
				desc = L["If set, characters must match both a group and a class from the list"],
				get = function()
								return data.attributes.strictFiltering or false
							end,
				set = function(info, value)
								data.attributes.strictFiltering = value
								self:UpdateGroupFilter(name, id, data)
							end,
				order = 200,
			}

			self.options.args.sets.args["set".. i].args["frame".. id].args.classes = {
				type = 'multiselect',
				name = L["Classes"],
				desc = L["Classes contained in this frame"],
				values = function() 
					local classMap = {}
					for classID = 1, 20 do -- 20 is for GetNumClasses() but that function doesn't exists on Classic
						local classInfo = C_CreatureInfo.GetClassInfo(classID);
						if classInfo then
							classMap[classInfo.classFile] = classInfo.className
						end
					end
					return classMap
				end,
				get = function(info, key)
								local groupFilter = { strsplit(",", data.attributes.groupFilter or "") }
								for _, _class in pairs(groupFilter) do
									if tostring(key) == _class then
											return true
									end
								end
								return false
							end,
				set = function(info, key, value)
								local groupFilter = data.attributes.groupFilter or ""
								groupFilter = groupFilter:len() >0 and {strsplit(",", groupFilter)} or {}

								if value then
									table.insert(groupFilter, tostring(key))
								else
									groupFilter = table_removeByValue(groupFilter, tostring(key))
								end

								data.attributes.groupFilter = #groupFilter > 0 and table.concat(groupFilter, ",") or false
								self:UpdateGroupFilter(name, id, data)
							end,
			}

			self.options.args.sets.args["set".. i].args["frame".. id].args.groups = {
				type = 'multiselect',
				name = L["Groups"],
				desc = L["Groups contained in this frame"],
				values = {
					["1"] = L["Group %d"]:format(1),
					["2"] = L["Group %d"]:format(2),
					["3"] = L["Group %d"]:format(3),
					["4"] = L["Group %d"]:format(4),
					["5"] = L["Group %d"]:format(5),
					["6"] = L["Group %d"]:format(6),
					["7"] = L["Group %d"]:format(7),
					["8"] = L["Group %d"]:format(8),
				},
				get = function(info, key)
								local groupFilter = { strsplit(",", data.attributes.groupFilter or "") }
								for _, _group in pairs(groupFilter) do
									if tostring(key) == _group then
											return true
									end
								end
								return false
							end,
				set = function(info, key, value)
								local groupFilter = data.attributes.groupFilter or ""
								groupFilter = groupFilter:len() >0 and {strsplit(",", groupFilter)} or {}

								if value then
									table.insert(groupFilter, tostring(key))
								else
									groupFilter = table_removeByValue(groupFilter, tostring(key))
								end

								data.attributes.groupFilter = #groupFilter > 0 and table.concat(groupFilter, ",") or false
								self:UpdateGroupFilter(name, id, data)
							 end,
			}
			self.options.args.sets.args["set".. i].args["frame".. id].args.roles = {
				type = 'multiselect',
				name = "Roles",
				desc = "Roles contained in this frame",
				values = {
					["MAINTANK"] = "Main tanks",
					["MAINASSIST"] = "Main assists",
				},
				get = function(info, key)
								local groupFilter = { strsplit(",", data.attributes.groupFilter or "") }
								for _, _class in pairs(groupFilter) do
									if tostring(key) == _class then
											return true
									end
								end
								return false
							end,
				set = function(info, key, value)
								local groupFilter = data.attributes.groupFilter or ""
								groupFilter = groupFilter:len() >0 and {strsplit(",", groupFilter)} or {}

								if value then
									table.insert(groupFilter, tostring(key))
								else
									groupFilter = table_removeByValue(groupFilter, tostring(key))
								end

								data.attributes.groupFilter = #groupFilter > 0 and table.concat(groupFilter, ",") or false
								self:UpdateGroupFilter(name, id, data)
							end,
			}
		end -- End For loop of frames
	end -- End For loop of groups
end -- End Function

function table_removeByValue(tbl, value)
	for k,v in pairs(tbl) do
		if v == value then
			table.remove(tbl, k)
		end
	end
	return tbl
end
