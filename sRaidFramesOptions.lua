local L = LibStub("AceLocale-3.0"):GetLocale("sRaidFrames")
local Media = LibStub("LibSharedMedia-3.0")
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local sRaidFrames = sRaidFrames

BINDING_HEADER_sRaidFrames = "sRaidFrames"
BINDING_NAME_ShowHideRaidWindows = L["Show/Hide Raid Windows"]
BINDING_NAME_ToggleBuffDebuffview = L["Toggle Buff/Debuff view"]
BINDING_NAME_Toggledisplayofonlydispellabledebuffs = L["Toggle display of only dispellable debuffs"]

local function SetVar(info, val)
	local var = info.arg
	sRaidFrames.db.profile[var] = val
end

local function GetVar(info)
	local var = info.arg
	return sRaidFrames.db.profile[var]
end


sRaidFrames.options = {
	type = 'group',
	handler = sRaidFrames,
	args = {
		lock = {
			name = L["Lock"],
			type = "toggle",
			desc = L["Lock/Unlock the raid frames"],
			get = function()
				return sRaidFrames.opt.Locked
			end,
			set = function(info, value)
				sRaidFrames.opt.Locked = value
				if not value then
					sRaidFrames.opt.ShowGroupTitles = true
					for _,f in pairs(sRaidFrames.groupframes) do
						sRaidFrames:UpdateTitleVisibility(f.header)
					end
				end
			end,
			disabled = function() return InCombatLockdown() end,
			order = 2,
			width = "half",
		},
		minimapIcon = {
			type = "toggle",
			order = 5,
			name = L["Minimap Icon"],
			desc = L["Show a Icon to open the config at the Minimap"],
			get = function() return not sRaidFrames.db.profile.minimapIcon.hide end,
			set = function(info, value) sRaidFrames.db.profile.minimapIcon.hide = not value; LDBIcon[value and "Show" or "Hide"](LDBIcon, "sRaidFrames") end,
			disabled = function() return not LDBIcon end,
		},
		frames = {
			type = "group",
			name = "Frames",
			order = 200,
			cmdInline = true,
			args = {
					titles = {
					name = L["Show group titles"],
					type = "toggle",
					desc = L["Toggle display of titles above each group frame"],
					get = function()
						return sRaidFrames.opt.ShowGroupTitles
					end,
					set = function(info, value)
						sRaidFrames.opt.ShowGroupTitles = value
						for _,f in pairs(sRaidFrames.groupframes) do
							sRaidFrames:UpdateTitleVisibility(f.header)
						end
					end,
					disabled = function() return not sRaidFrames.opt.Locked or InCombatLockdown() end,
					order = 1,
				},
				textures = {
					name = "Background/border",
					type = "group",
					desc = "Set the diffirent colors of the raid frames",
					dialogInline = true,
					args = {
						texture = {
							name = L["Bar textures"],
							type = "select",
							desc = L["Set the texture used on health and mana bars"],
							get = function()
								return sRaidFrames.opt.Texture
							end,
							set = function(info, value)
								sRaidFrames.opt.Texture = value
							
								local tex = Media:Fetch("statusbar", sRaidFrames.opt.Texture)
								for _, f in pairs(sRaidFrames.frames) do
									f.hpbar:SetStatusBarTexture(tex)
									f.mpbar:SetStatusBarTexture(tex)
								end
							end,
							values = AceGUIWidgetLSMlists.statusbar,
							order = 1,
							dialogControl = 'LSM30_Statusbar',
						},
						
						bordertexture = {
							name = L["Border texture"],
							type = "select",
							desc = L["Set the border texture"],
							get = function()
								return sRaidFrames.opt.BorderTexture
							end,
							set = function(info, value)
								sRaidFrames.opt.BorderTexture = value
							
								local tex = Media:Fetch("border", sRaidFrames.opt.BorderTexture)
								for _, frame in pairs(sRaidFrames.frames) do
									local backdrop = frame:GetBackdrop()
									backdrop.edgeFile = tex
									frame:SetBackdrop(backdrop)
								end
								sRaidFrames:UpdateAllUnits()
							end,
							values = AceGUIWidgetLSMlists.border,
							order = 2,
							dialogControl = 'LSM30_Border',
						},

						backgroundtexture = {
							name = "Background texture",
							type = "select",
							desc = "Set the background texture",
							get = function()
								return sRaidFrames.opt.BackgroundTexture
							end,
							set = function(info, value)
								sRaidFrames.opt.BackgroundTexture = value
							
								local tex = Media:Fetch("background", sRaidFrames.opt.BackgroundTexture)
								for _, frame in pairs(sRaidFrames.frames) do
									local backdrop = frame:GetBackdrop()
									backdrop.bgFile = tex
									frame:SetBackdrop(backdrop)
								end
								sRaidFrames:UpdateAllUnits()
							end,
							values = AceGUIWidgetLSMlists.background,
							order = 3,
							dialogControl = 'LSM30_Background',
						},
					},
				},
				colors = {
					name = L["Colors"],
					type = "group",
					desc = L["Set the diffirent colors of the raid frames"],
					dialogInline = true,
					args = {
						background = {
							type = "color",
							name = L["Background color"],
							desc = L["Change the background color"],
							get = function()
								local s = sRaidFrames.opt.BackgroundColor
								return s.r, s.g, s.b, s.a
							end,
							set = function(info, r, g, b, a)
								sRaidFrames.opt.BackgroundColor = {r = r, g = g, b = b, a = a}
								sRaidFrames:UpdateAllUnits()
							end,
							hasAlpha = true,
							order = 100,
						},
						border = {
							type = "color",
							name = L["Border color"],
							desc = L["Change the border color"],
							get = function()
								local s = sRaidFrames.opt.BorderColor
								return s.r, s.g, s.b, s.a
							end,
							set = function(info, r, g, b, a)
								sRaidFrames.opt.BorderColor = {r = r, g = g, b = b, a = a}

								for _, frame in pairs(sRaidFrames.frames) do
									frame:SetBackdropBorderColor(r, g, b, a)
								end
							end,
							hasAlpha = true,
							disabled = function() return not sRaidFrames.opt.Border end,
							order = 100,
						},

						healthtext = {
							type = "color",
							name = L["Health text color"],
							desc = L["Change the color of the health text"],
							get = function()
								local s = sRaidFrames.opt.HealthTextColor
								return s.r, s.g, s.b, s.a
							end,
							set = function(info, r, g, b, a)
								sRaidFrames.opt.HealthTextColor = {r = r, g = g, b = b, a = a}

								for _, frame in pairs(sRaidFrames.frames) do
									frame.hpbar.text:SetTextColor(r, g, b, a)
								end
							end,
							hasAlpha = false,
							order = 100,
						},
						healthbar = {
							type = "toggle",
							name = L["Color health bar by class"],
							desc = L["Color the health bar by class color"],
							get = function()
								return sRaidFrames.opt.HealthBarColorByClass
							end,
							set = function(info, value)
								sRaidFrames.opt.HealthBarColorByClass = value
								sRaidFrames:UpdateAllUnits()
							end,
							order = 110,
						},
					},
					order = 401,
				},
				scale = {
					name = L["Scale"],
					type = "range",
					desc = L["Set the scale of the raid frames"],
					min = 0.1,
					max = 3.0,
					step = 0.05,
					get = function()
						return sRaidFrames.opt.Scale
					end,
					set = function(info, value)
						sRaidFrames.opt.Scale = value
						sRaidFrames.master:SetScale(value)
					end,
					disabled = InCombatLockdown,
					order = 2,
				},
				invert = {
					name = L["Invert health bars"],
					type = "toggle",
					desc = L["Invert the growth of the health bars"],
					get = function()
						return sRaidFrames.opt.Invert
					end,
					set = function(info, value)
						sRaidFrames.opt.Invert = value
						sRaidFrames:UpdateAllUnits()
					end,
					order = 10,
				},
				positioning = {
					name = L["Positioning"],
					type = "group",
					desc = L["Set the positioning of the raid frames"],
					dialogInline = true,
					args = {
						reset = {
							name = L["Reset position"],
							type = "execute",
							desc = L["Reset the position of sRaidFrames"],
							func = "ResetPosition"
						},
						predefined = {
							name = L["Predefined position"],
							type = "select",
							desc = L["Set a predefined position for the raid frames"],
							get = function() return nil end,
							set = function(info, layout)
								sRaidFrames:PositionLayout(200, -200, layout)
							end,
							values = {
								["ctra"] = L["CT_RaidAssist"], 
								["horizontal"] = L["Horizontal"], 
								["vertical"] = L["Vertical"]},
						},
					},
					disabled = InCombatLockdown,
					order = 50,
				},
				growth = {
					name = L["Growth"],
					type = "select",
					desc = L["Set the default growth of the raid frames"],
					get = function()
						return sRaidFrames.opt.GrowthDefault
					end,
					set = function(info, value)
						sRaidFrames.opt.GrowthDefault = value
						sRaidFrames:SetGrowth()
					end,
					values = {
						["up"] = L["Up"], 
						["down"] = L["Down"], 
						["left"] = L["Left"], 
						["right"] = L["Right"]
					},
					disabled = InCombatLockdown,
					order = 20,
				},

				spacing = {
					name = L["Frame Spacing"],
					type = "range",
					desc = L["Set the spacing between each of the raid frames"],
					min = -20,
					max = 20,
					step = 1,
					get = function()
						return sRaidFrames.opt.Spacing
					end,
					set = function(info, s)
						sRaidFrames.opt.Spacing = s
						sRaidFrames:SetGrowth()
					end,
					disabled = InCombatLockdown,
					order = 10,
				},

				tooltiptype = {
					name = "Tooltip type",
					type = "select",
					desc = L["Determine the look of unit tooltips"],
					get = GetVar,
					set = SetVar,
					arg = "UnitTooltipType",
					values = {
						["blizz"] = "Game default", 
						["ctra"] = "sRaidFrames",
					},
				},
			},
		},
		
		sets = {
			name = L["Filter/Sort sets"],
			type = "group",
			desc = L["Toggle the display of certain Groups/Classes"],
			args = {},
			disabled = InCombatLockdown,
			order = 250,
		},
		informational = {
			type = "group",
			name = "Indicators",
			order = 300,
			cmdInline = true,
			args = {
				health = {
					name = L["Health text"],
					type = "select",
					desc = L["Set health display type"],
					get = function()
						return sRaidFrames.opt.HealthFormat
					end,
					set = function(info, value)
						sRaidFrames.opt.HealthFormat = value
						sRaidFrames:UpdateAllUnits()
					end,
					values = {["curmax"] = L["Current and max health"], ["deficit"] = L["Health deficit"], ["percent"] = L["Health percentage"], ["current"] = L["Current health"], ["curdeficit"] = L["Current health with deficit"], ["none"] = L["Hide health text"]},
					order = 20,
				},
				hidemaxhealth = {
					name = L["Hide Health at 100%"],
					type = "toggle",
					desc = L["Hide Health values if at 100%"],
					get = function()
						return sRaidFrames.opt.HideMaxHealth
					end,
					set = function(info, value)
						sRaidFrames.opt.HideMaxHealth = value
						sRaidFrames:UpdateAllUnits()
					end,
					order = 21,
				},
				powerfilter = {
					name = L["Power type visiblity"],
					type = "multiselect",
					desc = L["Toggle the display of certain power types (Mana, Rage, Energy)"],
					get = function(info, key)
						return sRaidFrames.opt.PowerFilter[key]
					end,
					set = function(info, key, value)
						sRaidFrames.opt.PowerFilter[key] = value
						sRaidFrames:UpdateAllUnits()
					end,
					values = {
						[Enum.PowerType.Mana] = L["Mana"],
						[Enum.PowerType.Rage] = L["Rage"],
						[Enum.PowerType.Energy] = L["Energy"],
					--	[Enum.PowerType.RunicPower] = L["Runic Power"],
					},
					order = 200,
				},
				vehiclepower = {
					name = L["Show Vehicle Power"],
					type = "toggle",
					desc = L["Always show the power of vehicles, independant of the power filter setting."],
					get = function(info)
						return sRaidFrames.opt.VehiclePower
					end,
					set = function(info, value)
						sRaidFrames.opt.VehiclePower = value
						sRaidFrames:UpdateAllUnits()
					end,
					order = 199,
					hidden = function() return sRaidFrames.isClassic end,
				},
				vehiclestatus = {
					name = L["Show Vehicle Name"],
					type = "toggle",
					desc = L["Show the name of the units vehicle in the statusbar."],
					get = function(info)
						return sRaidFrames.opt.VehicleStatus
					end,
					set = function(info, value)
						sRaidFrames.opt.VehicleStatus = value
						sRaidFrames:UpdateAllUnits()
					end,
					order = 190,
					hidden = function() return sRaidFrames.isClassic end,
				},
				tooltips = {
					name = L["Tooltip display"],
					type = "group",
					desc = L["Determine when a tooltip is displayed"],
					dialogInline = true,
					args = {
						units = {
							name = L["Unit tooltips"],
							type = "select",
							desc = L["Determine when a tooltip is displayed"],
							get = GetVar,
							set = SetVar,
							arg = "UnitTooltipMethod",
							values = {
								["never"] = L["Never"], 
								["notincombat"] = L["Only when not in combat"], 
								["always"] = L["Always"]
							},
						},
						buffs = {
							name = L["Buff tooltips"],
							type = "select",
							desc = L["Determine when a tooltip is displayed"],
							get = GetVar,
							set = SetVar,
							arg = "BuffTooltipMethod",
							values = {
								["never"] = L["Never"], 
								["notincombat"] = L["Only when not in combat"], 
								["always"] = L["Always"]
							},
						},
						debuffs = {
							name = L["Debuff tooltips"],
							type = "select",
							desc = L["Determine when a tooltip is displayed"],
							get = GetVar,
							set = SetVar,
							arg = "DebuffTooltipMethod",
							values = {
								["never"] = L["Never"],
								["notincombat"] = L["Only when not in combat"], 
								["always"] = L["Always"]
							},
						},
					},
					order = 401,
				},
				range = {
					name = L["Range"],
					type = "group",
					desc = L["Options for range checks"],
					dialogInline = true,
					args = {
						enable = {
							name = L["Enable range check"],
							type = "toggle",
							desc = L["Enable range checking"],
							get = function() return sRaidFrames.opt.RangeCheck end,
							set = function(info, value)
								sRaidFrames.opt.RangeCheck = value
								if not value then
									for unit in pairs(sRaidFrames.frames) do
										sRaidFrames.frames[unit]:SetAlpha(1)
									end
								end
							end,
							order = 1,
						},
						alpha = {
							name = L["Alpha"],
							type = "range",
							desc = L["The alpha level for units who are out of range"],
							get = GetVar,
							set = SetVar,
							arg = "RangeAlpha",
							min  = 0,
							max  = 1,
							step = 0.1,
							disabled = function() return not sRaidFrames.opt.RangeCheck end,
							order = 3,
						},
						frequency = {
							name = L["Frequency"],
							type = "range",
							desc = L["The interval between which range checks are performed"],
							get = function() return sRaidFrames.opt.RangeFrequency end,
							set = function(info, value)
								sRaidFrames.opt.RangeFrequency = value
								sRaidFrames:UpdateRangeFrequency()
							end,
							min  = 0.2,
							max  = 2.0,
							step = 0.1,
							disabled = function() return not sRaidFrames.opt.RangeCheck end,
							order = 4,
						},
						limit = {
							name = L["Range"],
							type = "select",
							desc = L["The range at which a unit is considered out of range"],
							get = function() return tostring(sRaidFrames.opt.RangeLimit) end,
							set = function(info, value)
								sRaidFrames.opt.RangeLimit = tonumber(value)
							end,
							values = {},
							disabled = function() return not sRaidFrames.opt.RangeCheck end,
							order = 2,
						}
					},
					order = 500,
				},
			},
		},
		buffsdebuffs = {
			type = "group",
			name = L["Buffs & Debuffs"],
			order = 500,
			cmdInline = true,
			args = {
				debuffs = {
					name = L["Debuffs"],
					type = "group",
					desc = L["Debuff settings"],
					args = {
						blacklist = {
							name = L["Debuff blacklist"],
							type = "group",
							desc = L["Set a list of debuffs to never be displayed"],
							dialogInline = true,
							args = {
								add = {
									name = L["Add debuff"],
									type = "input",
									desc = L["Add a debuff"],
									get = false,
									set = function(info, value)
										if tonumber(value) then
											value = GetSpellInfo(value)
										end
										if value and value ~= "" and not sRaidFrames.opt.DebuffFilter[value] and not sRaidFrames.opt.DebuffWhitelist[value] then
											sRaidFrames.opt.DebuffFilter[value] = true
											sRaidFrames:chatUpdateDebuffMenu()
											for unit in pairs(sRaidFrames:GetAllUnits()) do
												sRaidFrames:UpdateAuras(unit)
											end
										end
									end,
									-- dialogControl = "Spell_EditBox",
									usage = L["<name of debuff>"],
								},
								remove = {
									type = "select",
									name = L["Remove debuff"],
									desc = L["Remove debuffs from the filter"],
									order = 200,
									values = {},
									get = false,
									set = function(info, value)
										sRaidFrames.opt.DebuffFilter[value] = nil
										sRaidFrames:chatUpdateDebuffMenu()
										for unit in pairs(sRaidFrames:GetAllUnits()) do
											sRaidFrames:UpdateAuras(unit)
										end
									end,
								},
							},
							disabled = function() return (sRaidFrames.opt.BuffType == "buffs") end,
							order = 3,
						},
						whitelist = {
							name = L["Debuff whitelist"],
							type = "group",
							desc = L["Set a list of debuffs to always be displayed"],
							dialogInline = true,
							args = {
								add = {
									name = L["Add debuff"],
									type = "input",
									desc = L["Add a debuff"],
									get = false,
									set = function(info, value)
										if tonumber(value) then
											value = GetSpellInfo(value)
										end
										if value and value ~= "" and not sRaidFrames.opt.DebuffWhitelist[value] and not sRaidFrames.opt.DebuffFilter[value] then
											sRaidFrames.opt.DebuffWhitelist[value] = true
											sRaidFrames:chatUpdateDebuffMenu()
											for unit in pairs(sRaidFrames:GetAllUnits()) do
												sRaidFrames:UpdateAuras(unit)
											end
										end
									end,
								--	dialogControl = "Spell_EditBox",
									usage = L["<name of debuff>"],
								},
								remove = {
									type = "select",
									name = L["Remove debuff"],
									desc = L["Remove debuffs from the filter"],
									order = 200,
									values = {},
									get = false,
									set = function(info, value)
										sRaidFrames.opt.DebuffWhitelist[value] = nil
										sRaidFrames:chatUpdateDebuffMenu()
										for unit in pairs(sRaidFrames:GetAllUnits()) do
											sRaidFrames:UpdateAuras(unit)
										end
									end,
								},
							},
							disabled = function() return not (sRaidFrames.opt.BuffType ~= "buffs" and sRaidFrames.opt.ShowOnlyDispellable) end,
							order = 4,
						},
						debufftimer = {
							order = 5,
							type = "group",
							desc = L["Display a countdown on debuffs"],
							dialogInline = true,
							hidden = true,
							name = L["Debuff timer"],
							args={
								enable = {
									type = "toggle",
									name = L["Enable debuff countdowns"],
									desc = L["Select whether you want countdowns to be displayed on debuffs"],
									get = function() return sRaidFrames.opt.debufftimer.show end,
									set = function(info, value) sRaidFrames.opt.debufftimer.show = value end,
									order = 1,
								},
								limit = {
									type = "range",
									name = L["Maximum time"],
									desc = L["Debuffs lasting longer than this do not have a countdown"],
									get = function() return sRaidFrames.opt.debufftimer.max end,
									set = function(info, value) sRaidFrames.opt.debufftimer.max = value end,
									order = 2,
									disabled = function() return not sRaidFrames.opt.debufftimer.show end,
									min = 1,
									max = 99,
									step = 1,
									bigStep = 1,
								},
							},
						},
						curable = {
							order = 1,
							width = "full",
							name = L["Show only curable debuffs"],
							type = "toggle",
							desc = L["Show only debuffs that are curable by me"],
							get = function()
								return sRaidFrames.opt.ShowOnlyDispellable
							end,
							set = function(info, value)
								sRaidFrames.opt.ShowOnlyDispellable = value
								sRaidFrames:UpdateAllUnits()
							end,
							disabled = function() return (sRaidFrames.opt.BuffType == "buffs") end,
						},
					},
					order = 501,
				},

				buffs = {
					name = L["Buffs"],
					type = "group",
					desc = L["Buff settings"],
					disabled = function() return sRaidFrames.opt.BuffType == "debuffs" end,
					args = {
						displaysettings = {
							type = "group",
							name = L["Buff Display"],
							desc = L["Set which buffs are displayed by default"],
							order = 3,
							dialogInline = true,
							args = {
								display = {
									name = L["Default"],
									type = "select",
									desc = L["Set which buffs are displayed by default"],
									get = function()
										return sRaidFrames.opt.BuffDisplay.default
									end,
									set = function(info, value)
										sRaidFrames.opt.BuffDisplay.default = value
										for unit in pairs(sRaidFrames:GetAllUnits()) do
											sRaidFrames:UpdateAuras(unit)
										end
									end,
									values = {
										["own"] = L["Show buffs cast by me"],
										["known"] = "Show buffs I can cast",
										["all"] = L["Show all buffs"],
									},
									-- ["class"] = L["Show buffs cast by anyone from my class"], 
									order=1,
								},
								exceptions = {
									type = "group",
									name = L["Exceptions"],
									order = 2,
									desc = L["Add exceptions to the above default value"],
									dialogInline = true,
									args = {
										manage = {
											name = L["Buff"],
											desc = L["Select a buff to configure"],
											type = "input",
										--	dialogControl = "Aura_EditBox",
											get = function() return sRaidFrames.CurrentExceptionBuff or "" end,
											set = function(info, value) sRaidFrames.CurrentExceptionBuff = value end,
											order = 1,
										},
										suggest = {
											name = L["Already configured exceptions"],
											desc = L["A list of already configured exceptions"],
											type = "select",
											order = 2,
											get = function() return sRaidFrames.CurrentExceptionBuff or false end,
											set = function(info, value) sRaidFrames.CurrentExceptionBuff = value end,
											values = function() local t = {} for i, k in pairs(sRaidFrames.opt.BuffDisplay) do if i~="default" then t[i] = string.lower(i) end end if sRaidFrames.CurrentExceptionBuff then t[sRaidFrames.CurrentExceptionBuff] = sRaidFrames.CurrentExceptionBuff; end return t end,
										},
										set = {
											name = L["Set display type"],
											type = "group",
											desc = L["Set the display type for the above buff"],
											dialogInline = true,
											hidden = function() return not sRaidFrames.CurrentExceptionBuff end,
											order = 3,
											args = {
												own = {
													name = L["Own"],
													desc = L["Show this if it is cast by me"],
													type = "toggle",
													order = 1,
													get = function() return sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] and (sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] == "own") end,
													set = function() sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] = "own" for unit in pairs(sRaidFrames:GetAllUnits()) do sRaidFrames:UpdateAuras(unit) end end,
												},
												all = {
													name = L["All"],
													desc = L["Show this even if it is not cast by me"],
													type = "toggle",
													order = 2,
													get = function() return sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] and (sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] == "all") end,
													set = function() sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] = "all" for unit in pairs(sRaidFrames:GetAllUnits()) do sRaidFrames:UpdateAuras(unit) end end,
												},
												default = {
													name = L["Default"],
													desc = L["Show this according to the default setting"],
													type = "toggle",
													order = 3,
													get = function() return not sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] end,
													set = function() sRaidFrames.opt.BuffDisplay[string.lower(sRaidFrames.CurrentExceptionBuff)] = nil for unit in pairs(sRaidFrames:GetAllUnits()) do sRaidFrames:UpdateAuras(unit) end end,
												},
											},
										},
									},
								},
							},
						},
						filter = {
							name = L["Buff Filter"],
							type = "group",
							desc = L["Set a list of buffs to be exclusively displayed"],
							dialogInline = true,
							args = {
								add = {
									name = L["Add buff"],
									type = "input",
									desc = L["Add a buff"],
									get = false,
									set = function(info, value)
										if tonumber(value) then
											value = GetSpellInfo(value)
										end
										if value and value ~= "" and not sRaidFrames.opt.BuffFilter[string.lower(value)] then
											sRaidFrames.opt.BuffFilter[string.lower(value)] = true
											sRaidFrames:chatUpdateBuffMenu()
											for unit in pairs(sRaidFrames:GetAllUnits()) do
												sRaidFrames:UpdateAuras(unit)
											end
										end
									end,
								--	dialogControl = "Aura_EditBox",
									usage = L["<name of buff>"],
								},
								remove = {
									type = "select",
									name = L["Remove buff"],
									desc = L["Remove buffs from the filter"],
									order = 200,
									values = {},
									get = false,
									set = function(info, value)
										sRaidFrames.opt.BuffFilter[value] = nil
										sRaidFrames:chatUpdateBuffMenu()
										for unit in pairs(sRaidFrames:GetAllUnits()) do
											sRaidFrames:UpdateAuras(unit)
										end
									end,
								},
							},
							order=4,
						},
						oldblacklist = {
							name = L["Buff blacklist"],
							type = "group",
							desc = L["Prevent certain buffs from being displayed"],
							order = 1,
							dialogInline = true,
							args = {
								add = {
									type = "input",
								--	dialogControl = "Aura_EditBox",
									name = L["Add buff"],
									desc = L["Add a buff"],
									usage = L["<name of buff>"],
									get = false,
									set = function(info, value) sRaidFrames.opt.BuffDisplayOptions[string.lower(value)] = 0 for unit in pairs(sRaidFrames:GetAllUnits()) do sRaidFrames:UpdateAuras(unit) end end,
									order = 1,
								},
								remove = {
									type = "select",
									name = L["Remove buff"],
									desc = L["Remove a buff from the blacklist"],
									get = false,
									set = function(info, value) sRaidFrames.opt.BuffDisplayOptions[value]=3 for unit in pairs(sRaidFrames:GetAllUnits()) do sRaidFrames:UpdateAuras(unit) end end,
									values = function() local a = {}; for i, k in pairs(sRaidFrames.opt.BuffDisplayOptions) do if k==0 then a[i] = i; end end return a end,
									order = 2,
								},
							},
						},
						bufftimer = {
							name = L["Buff timer"],
							type = "group",
							desc = L["Display a countdown on buffs"],
							order = 5,
							hidden = true,
							dialogInline = true,
							args = {
								enable = {
									type = "toggle",
									name = L["Enable buff countdowns"],
									desc = L["Select whether you want countdowns to be displayed on buffs"],
									get = function() return sRaidFrames.opt.bufftimer.show end,
									set = function(info, value) sRaidFrames.opt.bufftimer.show = value end,
									order = 1,
								},
								limit = {
									type = "range",
									name = L["Maximum time"],
									desc = L["Buffs lasting longer than this do not have a countdown"],
									get = function() return sRaidFrames.opt.bufftimer.max end,
									set = function(info, value) sRaidFrames.opt.bufftimer.max = value end,
									order = 2,
									disabled = function() return not sRaidFrames.opt.bufftimer.show end,
									min = 1,
									max = 99,
									step = 1,
									bigStep = 1,
								},
							},
						},
					},
					order = 501,
				},
				bufftype = {
					name = L["Buff/Debuff visibility"],
					type = "select",
					desc = L["Show buffs or debuffs on the raid frames"],
					get = function()
						return sRaidFrames.opt.BuffType
					end,
					set = function(info, value)
						sRaidFrames.opt.BuffType = value
						sRaidFrames:UpdateAllUnits()
					end,
					values = {["none"] = "Hide all", ["buffs"] = L["Only buffs"], ["debuffs"] = L["Only debuffs"], ["buffsifnotdebuffed"] = L["Buffs if not debuffed"], ["both"] = L["Both buffs and debuffs"]},
					order = 501,
				},
			},
		},
		advanced = {
			name = L["Statuses"],
			type = "group",
			desc = L["Configure statuses"],
			args = {
				reset = {
					name = L["|cffff0000Delete all statuses|r"],
					desc = L["Resets all status maps, requires a RELOAD UI to initate the default maps"],
					type = "execute",
					func = function() 
						for key in pairs(sRaidFrames.opt.StatusMaps) do
							sRaidFrames.options.args.advanced.args[key] = nil
							sRaidFrames.opt.StatusMaps[key] = nil
						end
						-- reset custom statuses
						sRaidFramesDB.CustomStatuses = {};
					end,
					confirm = true,
					order = 500,
				},
				add = {
					name = L["|cff00ff00Add a status|r"],
					desc = "Adds a custom buff/debuff status",
					type = "input",
					usage = "<id>",
					set = function(info, value) sRaidFrames:AddExternalStatusMap(value) end,
					get = function() return "" end,
					order = 300,
				},
				delete = {
					name = L["|cff00ff00Remove a custom status|r"],
					desc = "Removes a custom status",
					type = "select",
					get = false,
					set = function(info, value) sRaidFrames:RemoveExternalStatusMap(value) end,
					arg = "RemoveCustomStatus",
					values = function() local a = {}; if not sRaidFramesDB.CustomStatuses then sRaidFramesDB.CustomStatuses = {}; end for id in pairs(sRaidFramesDB.CustomStatuses) do a[id] = GetSpellInfo(id); end return a; end,
					order = 400,
				},
				classfilter = {
					name = L["Class filtering"],
					type = "group",
					desc = L["Filter statuses by class"],
					dialogInline = true,
					args = {
						selectbuff = {
							name = L["Select Buff"],
							desc = L["Select a buff you want to change classes for"],
							type = "select",
							get = function () return sRaidFrames.currbuff or false end,
							set = function(info, value) sRaidFrames.currbuff = tonumber(value); end,
							values = function() local ret = {}; for i in pairs(sRaidFrames.opt.StatusMaps) do if string.match(i, "Buff_%d+") then local id = tonumber((string.match(i, "%d+"))); ret[id] = (select(1, GetSpellInfo(id))); end end return ret end,
							order = 1,
						},
						selectclass = {
							name = L["Select Classes"],
							desc = L["Select the classes that this status is available for"],
							type = "multiselect",
							get = function(info, key) if sRaidFrames.opt.classspelltable[sRaidFrames.currbuff][key] then return true else return false end end,
							set = function(info, key, value) sRaidFrames.opt.classspelltable[sRaidFrames.currbuff][key] = value; sRaidFrames:UpdateAllUnits() end,
							values = LOCALIZED_CLASS_NAMES_MALE,
							disabled = function() return not sRaidFrames.currbuff and true or sRaidFrames.opt.classspelltable[sRaidFrames.currbuff]["IsFiltered"] and false or true end,
							hidden = function() return sRaidFrames.currbuff and false or true end,
							order = 2,
						},
						selectclassall = {
							name = L["All"],
							desc = L["Enable this buff for all classes"],
							type = "toggle",
							get = function () if sRaidFrames.opt.classspelltable[sRaidFrames.currbuff]["IsFiltered"] then return false; else return true; end end,
							set = function(info, value) sRaidFrames.opt.classspelltable[sRaidFrames.currbuff]["IsFiltered"] = not value; sRaidFrames:UpdateAllUnits() end,
							hidden = function() if sRaidFrames.currbuff then return false; else return true; end end,
							order = 3,
						},
					},
					order = 600,
				},
			},
			order = 601,
		},
	},
}

function sRaidFrames:chatUpdateStatusElements()
	local i = 1
	for key, data in pairs(self.opt.StatusMaps) do
		local name = key
		if key:find("^Buff_") then
			local id = key:match("^Buff_(%d+)")
			name = GetSpellInfo(id)
		end
		if not self.options.args.advanced.args[key] and name then
			self.options.args.advanced.args[key] = {
				type = 'group',
				name = name,
				desc = ("Change settings for the status %s"):format(name),
				args = {
					priority = {
						name = L["Priority"],
						desc = L["Set the priority"],
						type = "range",
						min = 1,
						max = 200,
						step = 1,
						set = function(info, value) self.opt.StatusMaps[key].priority = value end,
						get = function() return self.opt.StatusMaps[key].priority end,
					},
					enabled = {
						name = L["Enabled"],
						desc = L["Enable the status indicator"],
						type = "toggle",
						set = function(info, value) self.opt.StatusMaps[key].enabled = value end,
						get = function() return self.opt.StatusMaps[key].enabled ~= false end,
					},
					elements = {
						name = "GUI Elements affected",
						desc = "Set which elements this status will affect",
						type = "multiselect",
						values = sRaidFrames.validateStatusElements,
						set = function(info, element, value) self.opt.StatusMaps[key].elements[element] = value end,
						get = function(info, element) return self.opt.StatusMaps[key].elements[element] end,
					},
					color = {
						name = L["Color"],
						desc = L["Set which color this status will use"],
						type = "color",
						set = function(info, r, g, b, a)
							self.opt.StatusMaps[key].color = {r = r, g = g, b = b, a = a}
						 end,
						get = function() 
							local color = self.opt.StatusMaps[key].color
							return color.r, color.g, color.b, color.a 
						end,
						hasAlpha = sRaidFrames.opt.advanced,
					},
					text = {
						name = L["Text"],
						desc = L["Set which text this status will show"],
						type = "input",
						usage = "<name>",
						set = function(info, value) self.opt.StatusMaps[key].text = value end,
						get = function() return self.opt.StatusMaps[key].text end,
					},
				},
				order = 200-self.opt.StatusMaps[key].priority,
			}
		end
	end
end

function sRaidFrames:chatUpdateBuffMenu()
	local filter = {}
	for k in pairs(self.opt.BuffFilter) do
		filter[k] = k
	end
	self.options.args.buffsdebuffs.args.buffs.args.filter.args.remove.values = filter
	
	-- local filter = {}
	-- for k in pairs(self.opt.BuffBlacklist) do
		-- filter[k] = k
	-- end
	-- self.options.args.buffsdebuffs.args.buffs.args.blacklist.args.remove.values = filter
	
	-- local filter = {}
	-- for k in pairs(self.opt.CombatBuffBlacklist) do
		-- filter[k] = k
	-- end
	-- self.options.args.buffsdebuffs.args.buffs.args.outofcombat.args.remove.values = filter
end

function sRaidFrames:chatUpdateDebuffMenu()
	local filter = {}
	for k in pairs(self.opt.DebuffWhitelist) do
		filter[k] = k
	end
	self.options.args.buffsdebuffs.args.debuffs.args.whitelist.args.remove.values = filter
	
	local filter = {}
	for k in pairs(self.opt.DebuffFilter) do
		filter[k] = k
	end
	self.options.args.buffsdebuffs.args.debuffs.args.blacklist.args.remove.values = filter
end

function sRaidFrames:UpdateRangeLimitOptions()
	self.options.args.informational.args.range.args.limit.values = {}
	for r, _ in pairs(self.RangeChecks) do
		self.options.args.informational.args.range.args.limit.values[tostring(r)] = L["%d yards"]:format(r)
	end
end
