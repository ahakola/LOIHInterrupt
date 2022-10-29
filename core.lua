--[[----------------------------------------------------------------------------
	LOIHInterrupt
	------------------------------------------------------------------------	

	Interrupt manager for guild <Lords of Ironhearts> of Arathor EU.

	2015-
	Sanex @ EU-Arathor / ahak @ Curseforge

	------------------------------------------------------------------------	

	TODO:
	- Bug fixes
	- Fine tuning

----------------------------------------------------------------------------]]--

local ADDON_NAME, ns = ...
local L = ns.L

-- Libs and Upvalues -----------------------------------------------------------
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local ADB = LibStub("AceDB-3.0")
local ADO = LibStub("AceDBOptions-3.0")
local LGIST = LibStub:GetLibrary("LibGroupInSpecT-1.1")

local _G = _G
local Ambiguate = Ambiguate
local assert = assert
local C_ChatInfo = C_ChatInfo
local C_Timer = C_Timer
local ChatFrame1 = ChatFrame1
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local DEAD = DEAD
local DEBUG_CHAT_FRAME = DEBUG_CHAT_FRAME
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local FOREIGN_SERVER_LABEL = FOREIGN_SERVER_LABEL
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local GetSpecialization = GetSpecialization
local GetSpellTexture = GetSpellTexture
local GRAY_FONT_COLOR_CODE = GRAY_FONT_COLOR_CODE
local HIDE = HIDE
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local INTERACTIVE_SERVER_LABEL = INTERACTIVE_SERVER_LABEL
local INTERRUPTED = INTERRUPTED
local ipairs = ipairs
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown
local LE_REALM_RELATION_COALESCED = LE_REALM_RELATION_COALESCED
local LE_REALM_RELATION_VIRTUAL = LE_REALM_RELATION_VIRTUAL
local math = math
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE
local pairs = pairs
local PLAYER_OFFLINE = PLAYER_OFFLINE
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local READY = READY
local select = select
local SendChatMessage = SendChatMessage
local SHOW = SHOW
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
local string = string
local strjoin = strjoin
local strsplit = strsplit
local table = table
local tonumber = tonumber
local tostring = tostring
local tostringall = tostringall
local tremove = tremove
local type = type
local UIParent = UIParent
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitGUID = UnitGUID
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitName = UnitName
local UnitRealmRelationship = UnitRealmRelationship
local unpack = unpack

-- DB Defaults -----------------------------------------------------------------
-- DB Global name: LOIHInterruptDB
local defaults = {
	profile = {
		["debug"] = false,
		["solo"] = 1, -- 0 = "Hide", 1 = "Show"
		["party"] = 3, -- 0 = "Hide", 2 = "Fixed list", 3 = "Autofill list", 4 = "Cooldown tracking"
		["raid"] = 4, -- 0 = "Hide", 2 = "Fixed list", 4 = "Cooldown tracking"
		["pvp"] = 4, -- 0 = "Hide", 2 = "Fixed list", 4 = "Cooldown tracking"
		["combatOnly"] = 0, -- 0 = "False", 1 = "True"
		["xPos"] = 350,
		["yPos"] = 132,
		["width"] = 125,
		["height"] = 16,
		["spacing"] = 0,
		["fontSize"] = 12,
		["barAlpha"] = .75,
		["textAlpha"] = 1,
		["iconAlpha"] = 1,
		["growDirection"] = "down", -- down = "Down", up = "Up"
		["announce"] = false,
		["classColor"] = false,
		["shortRealmNames"] = true,
		["specIcons"] = false,
		["hideHealers"] = false,
	},
	char = {},
};

-- Spells, CDs, Textures and Specs saved for later use -------------------------
local spellTable = { -- SpellIds and CDs
	[47528] = 15, -- DEATHKNIGHT - Mind Freeze
	[183752] = 15, -- DEMONHUNTER - Consume Magic
	[106839] = 15, -- DRUID - Skull Bash (Feral, Guardian)
	[78675] = 60, -- DRUID - Solar Beam (Balance)
	[147362] = 24, -- HUNTER - Counter Shot (Beast Mastery, Marksmanship)
	[187707] = 15, -- HUNTER - Muzzle (Survival)
	[2139] = 24, -- MAGE - Counterspell
	--[212653] = 15, -- BEBUG - Blink
	[116705] = 15, -- MONK - Spear Hand Strike (Brewmaster, Windwalker)
	--[115098] = 15, -- DEBUG - Chi Wave
	[96231] = 15, -- PALADIN - Rebuke (Protection, Retribution)
	[15487] = 45, -- PRIEST - Silence (Shadow)
	[1766] = 15, -- ROGUE - Kick
	[57994] = 12, -- SHAMAN - Wind Shear (Elemental, Enhancement, Restoration)
	[132409] = 24, -- WARLOCK - Spell Lock (Sacrificing Felhunter)
	[119910] = 24, -- WARLOCK - Command Demon (Felhunter - Spell Lock)
	[171140] = 24, -- WARLOCK - Command Demon (Doomguard - Shadow Lock)
	[6552] = 15, -- WARRIOR - Pummel
}
local nopeSpells = { -- These interrupt, but aren't the actual interrupt spells or these fire when you use the actual interrupt.
	[31935] = true, -- PALADIN - Avenger's Shield
	[32747] = true, -- DEMONHUNTER - Interrupt?
	[93985] = true, -- DRUID - Skull Bash
	[97547] = true, -- DRUID - Solar Beam
	[220543] = true, -- PRIEST - Silence
	[240448] = true, -- Mythic+ Dungeon Affix 'Quaking' - Quake
	[328406] = true, -- SL dungeon 'Necrotic Wake' special one time use item 'Discharged Anima' - Discharged Anima
}
local nopeClasses = { -- Classes with specs without interrupt or different interrupt spells for different specs
	["DRUID"] = true,
	["HUNTER"] = true,
	["MONK"] = true,
	["PALADIN"] = true,
	["PRIEST"] = true,
}
local nopeSpecs = { -- Specs without interrupt spells
	[65] = true, -- Holy Paladin
	[105] = true, -- Restoration Druid
	[256] = true, -- Discipline Priest
	[257] = true, -- Holy Priest
	[270] = true, -- Mistweaver Monk
}
local nopeTextures = { -- These SpellTextures ain't interrupt spells' textures
	[135920] = true, -- Holy Paladin
	[135940] = true, -- Discipline Priest
	[136041] = true, -- Restoration Druid
	[237542] = true, -- Holy Priest
	[608952] = true, -- Mistweaver Monk
}
local classIcons ={ -- SpellTextures
	["DEATHKNIGHT"] = 237527,
	["DEMONHUNTER"] = 1305153,
	["DRUID"] = 236946,
	["DRUID102"] = 252188, -- Balance
	["DRUID103"] = 236946, -- Feral
	["DRUID104"] = 236946, -- Guardian
	["DRUID105"] = 136041, -- Restoration (No interrupt?)
	["HUNTER"] = 249170,
	["HUNTER253"] = 249170, -- Beast Mastery
	["HUNTER254"] = 249170, -- Marksmanship
	["HUNTER255"] = 1376045, -- Survival
	["MAGE"] = 135856,
	["MONK"] = 608940,
	["MONK268"] = 608940, -- Brewmaster
	["MONK269"] = 608940, -- Windwalker
	["MONK270"] = 608952, -- Mistweaver (No interrupt?)
	["PALADIN"] = 523893,
	["PALADIN65"] = 135920, -- Holy (No interrupt?)
	["PALADIN66"] = 523893, -- Protection
	["PALADIN70"] = 523893, -- Retribution
	["PRIEST"] = 458230,
	["PRIEST256"] = 135940, -- Discipline (No interrupt?)
	["PRIEST257"] = 237542, -- Holy (No interrupt?)
	["PRIEST258"] = 458230, -- Shadow
	["ROGUE"] = 132219,
	["SHAMAN"] = 136018,
	["WARLOCK"] = 136174,
	["WARRIOR"] = 132938,
}

local interruptMsg = INTERRUPTED.." |cff71d5ff|Hspell:%d:|h[%s]|h|r (%s)"
local defaultIcon = 134400 -- Interface\Icons\INV_Misc_QuestionMark
local greenBar = { 0, .75, 0, .75 }
local redBar = { .75, 0, 0, .75 }
local blackBar = { 0, 0, 0, .75 }
local grayBar = { .5, .5, .5, .75 }

-- Main Frame and RegisterEvents -----------------------------------------------
local f = CreateFrame("Frame")
do
	f:SetScript("OnEvent", function(self, event, ...)
		return self[event] and self[event](self, event, ...)
	end)

	f:RegisterEvent("ADDON_LOADED")
	f:RegisterEvent("CHAT_MSG_ADDON")
	f:RegisterEvent("GROUP_ROSTER_UPDATE")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PLAYER_LOGIN")
	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:RegisterEvent("UNIT_CONNECTION")
end -- OnEvent handler and RegisterEvents

-- Debug and Print -------------------------------------------------------------
local function Debug(text, ...)
	if not f.db.profile.debug then return end

	if text then
		if text:match("%%[dfqsx%d%.]") then
			(DEBUG_CHAT_FRAME or ChatFrame1):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. string.format(text, ...))
		else
			(DEBUG_CHAT_FRAME or ChatFrame1):AddMessage("|cffff9999"..ADDON_NAME..":|r " .. strjoin(" ", text, tostringall(...)))
		end
	end
end

local function Print(text, ...)
	if text then
		if text:match("%%[dfqs%d%.]") then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. string.format(text, ...))
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. strjoin(" ", text, tostringall(...)))
		end
	end
end

-- FrameFactory with recycling -------------------------------------------------
local AcquireFrame, ReleaseFrame, checkBarSettings
do
	local frame_cache = {}

	local function getFormattedName(name)
		if not name then return end
		if f.db.profile.shortRealmNames then -- Short Realm names
			local patern = "^([^%-]+)%-(.*)$"
			local relation = UnitRealmRelationship(name)
			local baseName = name:match(patern) and select(1, name:match(patern)) or name

			if relation == LE_REALM_RELATION_VIRTUAL then -- Connected realm
				return baseName..INTERACTIVE_SERVER_LABEL -- Shorten realm name into (#)
			elseif relation == LE_REALM_RELATION_COALESCED then -- Foreign realm
				return baseName..FOREIGN_SERVER_LABEL -- Shorten realm name into (*)
			else -- Same realm as Player
				return baseName
			end
		else -- Long Realm names
			return name
		end
	end

	function checkBarSettings(bar, name)
		--bar:ClearAllPoints()
		bar:SetSize(f.db.profile.width, f.db.profile.height)
		--bar:SetAllPoints()
		bar.fg:ClearAllPoints()
		bar.fg:SetPoint("TOPLEFT") -- If you use SetAllPoints(), you can't use SetWidth() anymore...
		bar.fg:SetPoint("BOTTOMLEFT")
		bar.fg:SetWidth(f.db.profile.width)
		bar.bg:ClearAllPoints()
		bar.bg:SetAllPoints()
		bar.iconFrame:SetSize(f.db.profile.height, f.db.profile.height)
		bar.icon:ClearAllPoints()
		bar.icon:SetAllPoints()

		local fontName, _, fontFlags = bar.text:GetFont()
		bar.text:SetFont(fontName, f.db.profile.fontSize, fontFlags)
		bar.timer:SetFont(fontName, f.db.profile.fontSize, fontFlags)

		bar.text:SetText(getFormattedName(name))

		bar.fg:SetAlpha(f.db.profile.barAlpha)
		bar.bg:SetAlpha(f.db.profile.barAlpha * 3/4)

		bar.timer:SetAlpha(f.db.profile.textAlpha)
		bar.text:SetAlpha(f.db.profile.textAlpha)

		bar.iconFrame:SetAlpha(f.db.profile.iconAlpha)
	end

	function AcquireFrame(parent, name, icon, guid)
		local frame

		if #frame_cache > 0 then
			frame = tremove(frame_cache)
			frame:SetParent(parent)

			checkBarSettings(frame, name)
		else
			frame = CreateFrame("Frame")
			frame:SetParent(parent)
			frame:SetSize(f.db.profile.width, f.db.profile.height)

			local fg = frame:CreateTexture(nil, "ARTWORK")
			fg:ClearAllPoints()
			fg:SetPoint("TOPLEFT")
			fg:SetPoint("BOTTOMLEFT")
			--fg:SetColorTexture(unpack(redBar))
			--fg:SetColorTexture(redBar[1], redBar[2], redBar[3], redBar[4]) -- unpack is slow?
			fg:SetColorTexture(redBar[1], redBar[2], redBar[3], 1) -- unpack is slow?
			fg:SetDrawLayer("ARTWORK", 2)
			fg:SetAlpha(f.db.profile.barAlpha)
			frame.fg = fg

			local bg = frame:CreateTexture(nil, "ARTWORK")
			bg:ClearAllPoints()
			bg:SetAllPoints()
			--bg:SetColorTexture(0, 0, 0, .5)
			bg:SetColorTexture(0, 0, 0, 2/3)
			bg:SetDrawLayer("ARTWORK", 1)
			bg:SetAlpha(f.db.profile.barAlpha * 3/4)
			frame.bg = bg

			local timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			timer:SetNonSpaceWrap(true)
			timer:SetPoint("RIGHT", -2, 0)
			timer:SetAlpha(f.db.profile.textAlpha)
			frame.timer = timer

			local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			text:SetNonSpaceWrap(true)
			text:SetPoint("LEFT", 2, 0)
			text:SetAlpha(f.db.profile.textAlpha)
			frame.text = text

			local fontName, _, fontFlags = frame.text:GetFont()
			frame.text:SetFont(fontName, f.db.profile.fontSize, fontFlags)
			frame.timer:SetFont(fontName, f.db.profile.fontSize, fontFlags)

			local iconFrame = CreateFrame("Frame", nil, frame)
			iconFrame:SetSize(frame:GetHeight(), frame:GetHeight())
			iconFrame:SetPoint("RIGHT", frame, "LEFT")
			iconFrame:SetAlpha(f.db.profile.iconAlpha)
			local icon = iconFrame:CreateTexture(nil, "OVERLAY")
			icon:ClearAllPoints()
			icon:SetAllPoints()
			icon:SetTexCoord(.08, .92, .08, .92) -- Strip the "borders"
			icon:SetTexture(defaultIcon)
			frame.iconFrame = iconFrame
			frame.icon = icon

			frame.data = {}
		end

		frame:Show()
		--frame.text:SetText(name)
		frame.text:SetText(getFormattedName(name))
		if nopeTextures[icon] and not f.db.profile.specIcons then
			frame.icon:SetTexture(defaultIcon)
		else
			frame.icon:SetTexture(icon)
		end
		frame.guid = guid

		return frame
	end

	function ReleaseFrame(frame)
		frame:Hide()
		frame:SetParent(nil)
		frame:ClearAllPoints()

		f.bars[frame.guid] = nil
		frame.guid = nil

		--table.insert(frame_cache, frame)
		frame_cache[#frame_cache + 1] = frame
	end
end -- FrameFactory/Recycling

-- Timer and Bar sorting -------------------------------------------------------
local Timer, sortAndArrange
do
	function sortAndArrange(inputTbl, inputIsFBarsTable)
		local function timerSort(a, b) -- Player always on top, shortest CDs next and tied timers in alphabetical order
			if (not a or not b) or (not a and b) or (not a.guid and not b.guid) or (not a.guid and b.guid) or
			(not f.rosterInfo[a.guid] and not f.rosterInfo[b.guid]) or (not f.rosterInfo[a.guid] and f.rosterInfo[b.guid]) then
				return false
			elseif (a and not b) or (a.guid and not b.guid) or (f.rosterInfo[a.guid] and not f.rosterInfo[b.guid]) then
				return true
			else
				if f.playerGUID == a.guid or f.playerGUID == b.guid then -- Player on top
					return f.playerGUID == a.guid
				elseif f.rosterInfo[a.guid] or f.rosterInfo[b.guid] then
					if f.rosterInfo[a.guid].delay == f.rosterInfo[b.guid].delay then -- Alphabetical sort
						return f.rosterInfo[a.guid].name < f.rosterInfo[b.guid].name
					else
						return f.rosterInfo[a.guid].delay < f.rosterInfo[b.guid].delay -- Timer sort
					end
				else
					return true
				end
			end
		end

		local function partySort(a, b)
			if (not a or not b) or (not a and b) or (not a.guid and not b.guid) or (not a.guid and b.guid) or
			(not f.rosterInfo[a.guid] and not f.rosterInfo[b.guid]) or (not f.rosterInfo[a.guid] and f.rosterInfo[b.guid]) then
				return false
			elseif (a and not b) or (a.guid and not b.guid) or (f.rosterInfo[a.guid] and not f.rosterInfo[b.guid]) then
				return true
			else
				return f.rosterInfo[a.guid].order < f.rosterInfo[b.guid].order -- Fixed order
			end
		end

		local function getOffset(iteration)
			if f.db.profile.growDirection == "down" then
				return f.db.profile.height - f.db.profile.height*(iteration-1) - f.db.profile.spacing*(iteration-1)
			else
				return f.db.profile.height + f.db.profile.height*(iteration-1) + f.db.profile.spacing*(iteration-1)
			end
		end

		local tbl
		if inputIsFBarsTable then
			tbl = {}
			for _, bar in pairs(inputTbl) do
				if bar:IsShown() and bar ~= nil then
					--table.insert(tbl, bar)
					tbl[#tbl + 1] = bar
				else
					if bar.guid ~= f.playerGUID and f.bars[bar.guid] then
						ReleaseFrame(f.bars[bar.guid])
					end
				end
			end
		elseif type(inputTbl) == "table" then
			tbl = inputTbl
		else
			tbl = {}
		end

		if (f.groupType == 3 and f.db.profile.pvp == 4) or
		(f.groupType == 2 and f.db.profile.raid == 4) or
		(f.groupType == 1 and f.db.profile.party == 4) then
			--Debug("sortAndArrange: timerSort")
			table.sort(tbl, timerSort)
		else
			--Debug("sortAndArrange: partySort")
			table.sort(tbl, partySort)
		end

		local repositioned = {}
		local i = 1
		for _, bar in ipairs(tbl) do
			if bar.guid ~= nil and not repositioned[bar.guid] then -- nil tables and other weird stuff blocked
				local yo = getOffset(i)
				bar:ClearAllPoints()

				--Debug("sortAndArrange: Sort SetPoint", i, bar.guid and f.rosterInfo[bar.guid].name or tostring(bar.guid), yo)
				bar:SetPoint("TOP", f.anchor, "BOTTOM", 0, yo)
				repositioned[bar.guid] = true -- Position bar only once if it is for some reason trying to get repositioned twice
				i = i + 1
			end
		end
	end

	local timers = {}

	Timer = CreateFrame("Frame")
	Timer:Hide()
	Timer:SetScript("OnUpdate", function(self, elapsed)
		local stop = true
		local changed = false
		local barAlpha = f.db.profile.barAlpha

		for i = #timers, 1, -1 do -- Don't leave holes, we might want to sort this table later...
			local bar = timers[i]

			if bar and bar.guid and f.rosterInfo[bar.guid] then
				f.rosterInfo[bar.guid].delay = f.rosterInfo[bar.guid].delay - elapsed

				if f.rosterInfo[bar.guid].delay > 0 then
					--bar.fg:SetWidth(bar:GetWidth() * f.rosterInfo[bar.guid].delay / math.max(f.rosterInfo[bar.guid].CD, 1))
					bar.fg:SetWidth(bar:GetWidth() * f.rosterInfo[bar.guid].delay / (f.rosterInfo[bar.guid].CD or 1)) -- math.max is slow?
					bar.timer:SetFormattedText("%.1f", f.rosterInfo[bar.guid].delay)

					if not f.rosterInfo[bar.guid].connected then -- Disconnected
						--bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], grayBar[4])
						bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], barAlpha)
					elseif f.rosterInfo[bar.guid].alive == true then -- Alive
						if f.db.profile.classColor == true then
							--bar.fg:SetColorTexture(unpack(f.rosterInfo[bar.guid].color))
							--bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], f.rosterInfo[bar.guid].color[4])
							bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], barAlpha)
						else
							--bar.fg:SetColorTexture(unpack(redBar))
							--bar.fg:SetColorTexture(redBar[1], redBar[2], redBar[3], redBar[4]) -- unpack is slow?
							bar.fg:SetColorTexture(redBar[1], redBar[2], redBar[3], barAlpha) -- unpack is slow?
						end
					else -- Dead
						--bar.fg:SetColorTexture(unpack(blackBar))
						--bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], blackBar[4]) -- unpack is slow?
						bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], barAlpha) -- unpack is slow?
					end

					timers[i] = bar
					stop = nil
				else
					if ((f.groupType == 3 and f.db.profile.pvp == 4) or
					(f.groupType == 2 and f.db.profile.raid == 4) or
					(f.groupType == 1 and f.db.profile.party == 4)) and bar.guid ~= f.playerGUID then -- Coolcdown tracking
						--Debug("Timer OnUpdate: Release bar from", f.rosterInfo[bar.guid].name, f.rosterInfo[bar.guid].order, "CDTracking")

						if f.bars[bar.guid] then
							ReleaseFrame(f.bars[bar.guid])
						end
						table.remove(timers, i)
						changed = true
					else
						bar.fg:SetWidth(bar:GetWidth())

						if not f.rosterInfo[bar.guid].connected then -- Disconnected
							--bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], grayBar[4])
							bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], barAlpha) -- unpack is slow?
							bar.timer:SetText(PLAYER_OFFLINE)
						elseif f.rosterInfo[bar.guid].alive == true then -- Alive
							if f.db.profile.classColor == true then
								--bar.fg:SetColorTexture(unpack(f.rosterInfo[bar.guid].color))
								--bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], f.rosterInfo[bar.guid].color[4])
								bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], barAlpha)
							else
								--bar.fg:SetColorTexture(unpack(greenBar))
								--bar.fg:SetColorTexture(greenBar[1], greenBar[2], greenBar[3], greenBar[4]) -- unpack is slow?
								bar.fg:SetColorTexture(greenBar[1], greenBar[2], greenBar[3], barAlpha) -- unpack is slow?
							end
							bar.timer:SetText(READY)
						else -- Dead
							--bar.fg:SetColorTexture(unpack(blackBar))
							--bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], blackBar[4]) -- unpack is slow?
							bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], barAlpha) -- unpack is slow?
							bar.timer:SetText(DEAD)
						end

						timers[i] = bar
					end
				end
			else
				--Debug("Timer OnUpdate: No bar info found for", tostring(bar.guid))

				if bar and f.bars[bar.guid] then
					ReleaseFrame(f.bars[bar.guid])
				end
				table.remove(timers, i)
				changed = true
			end
		end

		if changed then
			--sortAndArrange(timers)
			sortAndArrange(f.bars, true)
		end

		if stop then
			--Debug("Timer OnUpdate: Timer stopped")
			self:Hide()
		end
	end)

	function Timer:New(bar)
		--table.insert(timers, bar)
		timers[#timers + 1] = bar

		sortAndArrange(timers)

		if not self:IsShown() then
			self:Show()
		end
	end

	function Timer:ReColor()
		if self:IsShown() then return end -- Don't recolor if normal iterations are going on (they do the same).
		local barAlpha = f.db.profile.barAlpha

		for i = 1, #timers do
			if self:IsShown() then break end -- Break iterations if the timers start running.
			local bar = timers[i]

			if bar and bar.guid and f.rosterInfo[bar.guid] then
				if not f.rosterInfo[bar.guid].connected then -- Disconnected
					--bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], grayBar[4])
					bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], barAlpha)
				elseif f.rosterInfo[bar.guid].alive == true then -- Alive
					if f.db.profile.classColor == true then
						--bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], f.rosterInfo[bar.guid].color[4])
						bar.fg:SetColorTexture(f.rosterInfo[bar.guid].color[1], f.rosterInfo[bar.guid].color[2], f.rosterInfo[bar.guid].color[3], barAlpha)
					else
						if f.rosterInfo[bar.guid].delay > 0 then
							--bar.fg:SetColorTexture(redBar[1], redBar[2], redBar[3], redBar[4])
							bar.fg:SetColorTexture(redBar[1], redBar[2], redBar[3], barAlpha)
						else
							--bar.fg:SetColorTexture(greenBar[1], greenBar[2], greenBar[3], greenBar[4])
							bar.fg:SetColorTexture(greenBar[1], greenBar[2], greenBar[3], barAlpha)
						end
					end
				else -- Dead
					--bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], blackBar[4])
					bar.fg:SetColorTexture(blackBar[1], blackBar[2], blackBar[3], barAlpha)
				end

				timers[i] = bar
			end
		end
	end
end -- Timers

-- Anchors ---------------------------------------------------------------------
function f:CreateAnchor() -- All the bars attach to this
	local a = CreateFrame("Frame", ADDON_NAME.."Anchor", UIParent)
	a:SetSize(self.db.profile.width, self.db.profile.height)
	a:SetPoint("CENTER", self.db.profile.xPos, self.db.profile.yPos)
	a:SetScript("OnShow", function(this)
		-- Listen to CLEU when visible
		--Debug("CreateAnchor: CLEU")
		f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end)
	a:SetScript("OnHide", function(this)
		-- Stop listening to CLEU when hidden
		--Debug("CreateAnchor: !CLEU")
		f:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end)

	return a
end

function f:CreateConfigAnchor() -- This will be shown when the config is open
	local a = CreateFrame("Frame", ADDON_NAME.."ConfigAnchor", UIParent)
	--a:SetSize(self.db.profile.width, self.db.profile.height)
	a:SetAllPoints(self.anchor)

	local b = a:CreateTexture(nil, "ARTWORK")
	b:ClearAllPoints()
	b:SetAllPoints()
	b:SetColorTexture(0, 0, 0, .5)
	--b:SetColorTexture(1, 1, 0, 1)
	b:SetDrawLayer("ARTWORK", 1)
	a.b = b

	local s = a:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	s:SetText(string.format(L.ConfigAnchor, ADDON_NAME))
	s:SetPoint("CENTER")
	a.s = s

	return a
end

-- Init related Events ---------------------------------------------------------
function f:ADDON_LOADED(event, addon)
	if addon ~= ADDON_NAME then return end
	self:UnregisterEvent(event)

	LOIHInterruptDB = LOIHInterruptDB or {}
	self.db = ADB:New(LOIHInterruptDB, defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	self.ADDON_LOADED = nil
end

function f:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)

	self.anchor = self.anchor or self:CreateAnchor()
	self.configAnchor = self.configAnchor or self:CreateConfigAnchor()
	self.configAnchor:Hide()
	self.playerName = UnitName("player")
	self.playerGUID = UnitGUID("player")
	self.rosterInfo = {}
	self.bars = {}
	self.deadWatch = {}
	self.groupType = 0

	local _, playerClass = UnitClass("player")
	self.rosterInfo[self.playerGUID] = self.rosterInfo[self.playerGUID] or {
		["name"] = self.playerName,
		["class"] = playerClass,
		["alive"] = true,
		["spec"] = 0,
		["order"] = "player",
		["CD"] = 0,
		["delay"] = 0,
		["color"] = { RAID_CLASS_COLORS[playerClass].r, RAID_CLASS_COLORS[playerClass].g, RAID_CLASS_COLORS[playerClass].b, .75 },
		["connected"] = true,
	}

	local count = 0
	for _, v in pairs(self.db.char) do
		if v then
			count = count + 1
		end
	end
	Debug("PLAYER_LOGIN: Count:", count)
	if count == 0 then
		self.db.char[1] = self.playerName
	end

	self:GetOptions()
	C_ChatInfo.RegisterAddonMessagePrefix(ADDON_NAME)

	LGIST.RegisterCallback(self, "GroupInSpecT_Update", "HandleGIST")
	LGIST.RegisterCallback(self, "GroupInSpecT_Remove", "HandleGIST")

	local _ = LGIST:GetCachedInfo(self.playerGUID) -- Try to force Lib to cache player data on login

	self.PLAYER_LOGIN = nil
end

-- Help functions and Events to decide when to show the bars -------------------
function f:getViewCondition()
	if self.groupType == 3 then
		return self.db.profile.pvp > 0
	elseif self.groupType == 2 then
		return self.db.profile.raid > 0
	elseif self.groupType == 1 then
		return self.db.profile.party > 0
	else
		return self.db.profile.solo > 0
	end
end

local function updateGroupType()
	if f.configAnchor:IsShown() then
		f.groupType = 1
	elseif IsInGroup() then
		if IsInRaid() then
			local _, instanceType = IsInInstance()
			if instanceType == "arena" or instanceType == "pvp" then
				f.groupType = 3
			else
				f.groupType = 2
			end
		else
			f.groupType = 1
		end
	else
		f.groupType = 0
	end

	Debug("updateGroupType:", f.groupType, tostring(f.configAnchor:IsShown()))
end

function f:PLAYER_ENTERING_WORLD(event)
	Debug(event)
	--self:UnregisterEvent(event)

	updateGroupType()

	self.anchor:Hide()
	if self:getViewCondition() and (InCombatLockdown() or
	(not InCombatLockdown() and self.db.profile.combatOnly == 0)) then
		self.anchor:Show()
	end

	LGIST:Rescan()
	--self.GROUP_ROSTER_UPDATE()
	--self.PLAYER_ENTERING_WORLD = nil
end

function f:PLAYER_REGEN_DISABLED(event)
	if self:getViewCondition() and self.db.profile.combatOnly == 1 and not self.anchor:IsShown() then
		self.anchor:Show()
	end
end

function f:PLAYER_REGEN_ENABLED(event)
	if self:getViewCondition() and self.db.profile.combatOnly == 1 and self.anchor:IsShown() then
		self.anchor:Hide()
	end
end

--function f:UNIT_CONNECTION(event, unitID, hasConnected)
function f:UNIT_CONNECTION(event, unitID)
	local hasConnected = UnitIsConnected(unitID)
	--if not UnitIsConnected(unitID) then -- Disconnected
	--	bar.fg:SetColorTexture(grayBar[1], grayBar[2], grayBar[3], grayBar[4])
	--end
	Debug("UNIT_CONNECTION: %s, %s", tostring(unitID), tostring(hasConnected))

	local guid
	local found = false
	for guid_tmp, data in pairs(self.rosterInfo) do
		if data.order == unitID then
			Debug("UNIT_CONNECTION: By unitID '%s'", tostring(unitID))
			guid = guid_tmp
			found = true
			break
		end
	end
	if not found then -- Just to be safe, don't know if this will be ever needed?
		for guid_tmp, data in pairs(self.rosterInfo) do
			local name, realm = UnitName(unitID)
			if (name and data.name == name) or (name and realm and data.name == name.."-"..realm) then
				Debug("UNIT_CONNECTION: By name '%s - %s'", tostring(name), tostring(realm))
				guid = guid_tmp
				--found = true
				break
			end
		end
	end

	if guid and guid ~= nil and self.rosterInfo[guid] then
		if hasConnected == true then
			self.rosterInfo[guid].connected = true
		else
			self.rosterInfo[guid].connected = false
		end

		if IsInGroup(unitID) then
			Debug("UNIT_CONNECTION: -> ReColor!")
			Timer:ReColor()
		end
	end
end

-- Release (for recycling) and Create new Bars ---------------------------------
local DelayedUpdate
do -- GROUP_ROSTER_UPDATE throttling
	local throttling

	--local function DelayedUpdate()
	function DelayedUpdate(skipUpdate)
		throttling = nil
		local changed = true
		-- All the magic here is staggered to fire once every seconds at max rate, unless by passed by direct call
		--Debug("GROUP_ROSTER_UPDATE", #f.rosterInfo)

		if not skipUpdate then
			updateGroupType()
		end

		for guid, data in pairs(f.rosterInfo) do
			if f.bars[guid] then -- Release bars
				if f.db.profile.hideHealers and nopeSpecs[data.spec] then -- Hide healers
					Debug("GROUP_ROSTER_UPDATE: Release (hideHealers")

					ReleaseFrame(f.bars[guid])
				elseif (f.groupType == 1 and f.db.profile.party == 2) or -- Fixed list Party
				(f.groupType == 2 and f.db.profile.raid == 2) or -- Fixed list Raid
				(f.groupType == 3 and f.db.profile.pvp == 2) then -- Fixed list PvP
					if (f.db.char[data.order] and f.db.char[data.order] ~= data.name or
					f.db.char[data.order] == nil or f.db.char[data.order] == "") then -- Not in the Fixed list
						Debug("GROUP_ROSTER_UPDATE: Release (Fixed list)", data.name, data.order)

						ReleaseFrame(f.bars[guid])
					end
				elseif guid ~= f.playerGUID and data.delay <= 0 and
				((f.groupType == 1 and f.db.profile.party == 4) or
				(f.groupType == 2 and f.db.profile.raid == 4) or
				(f.groupType == 3 and f.db.profile.pvp == 4)) then -- Changed to Cooldown tracking, release 'Ready' non-Player bars
					Debug("GROUP_ROSTER_UPDATE: Release (Cooldown tracking)")

					ReleaseFrame(f.bars[guid])
				elseif ((f.groupType == 0 and f.db.profile.solo == 0) or -- Solo (Hide)
				(f.groupType == 1 and f.db.profile.party == 0) or -- Party (Hide)
				(f.groupType == 2 and f.db.profile.raid == 0) or -- Raid (Hide)
				(f.groupType == 3 and f.db.profile.pvp == 0)) then -- PvP (Hide)
					Debug("GROUP_ROSTER_UPDATE: Release (Hide)")

					ReleaseFrame(f.bars[guid])
				end
			elseif not (f.db.profile.hideHealers and nopeSpecs[data.spec]) then -- Create new bars
				--[[
					solo - 0 = "Hide", 1 = "Show"
					party - 0 = "Hide", 2 = "Fixed list", 3 = "Autofill list", 4 = "Cooldown tracking"
					raid - 0 = "Hide", 2 = "Fixed list", 4 = "Cooldown tracking"
					pvp - 0 = "Hide", 2 = "Fixed list", 4 = "Cooldown tracking"
				]]--

				if (guid == f.playerGUID and f.groupType == 0 and f.db.profile.solo == 1) or -- Player (Solo)
				(guid == f.playerGUID and ((f.groupType == 1 and f.db.profile.party == 4) or -- Party (Cooldown tracking)
				(f.groupType == 2 and f.db.profile.raid == 4 ) or -- Raid (Cooldown tracking)
				(f.groupType == 3 and f.db.profile.pvp == 4))) or -- PvP (Cooldown tracking)
				(f.groupType == 1 and f.db.profile.party == 3) then -- Party (Autofill)
					--Debug("GROUP_ROSTER_UPDATE: New bar:", data.name, data.order)
					local spellIcon
					if nopeClasses[data.class] and data.spec > 0 then
						spellIcon = classIcons[data.class..data.spec] or classIcons[data.class]
					else
						spellIcon = classIcons[data.class]
					end
					f.bars[guid] = AcquireFrame(f.anchor, data.name, spellIcon, guid)

					Timer:New(f.bars[guid])
					changed = false -- We re-sort on Timer:New() so we can cancel any previously queued re-sorting

				elseif (f.groupType == 1 and f.db.profile.party == 2) or -- Fixed list Party
				(f.groupType == 2 and f.db.profile.raid == 2) or -- Fixed list Raid
				(f.groupType == 3 and f.db.profile.pvp == 2) then -- Fixed list PvP
					--Debug("GROUP_ROSTER_UPDATE: Fixed list!")
					for k, listChar in pairs(f.db.char) do
						if listChar == data.name then
							--Debug("GROUP_ROSTER_UPDATE: -> New bar:", data.name)
							f.rosterInfo[guid].order = k
							local spellIcon
							if nopeClasses[data.class] and data.spec > 0 then
								spellIcon = classIcons[data.class..data.spec] or classIcons[data.class]
							else
								spellIcon = classIcons[data.class]
							end
							f.bars[guid] = AcquireFrame(f.anchor, data.name, spellIcon, guid)

							Timer:New(f.bars[guid])
							changed = false -- We re-sort on Timer:New() so we can cancel any previously queued re-sorting

							break
						end
					end
				end
			end
		end

		if changed then -- Reposition bars if we released any bars
			sortAndArrange(f.bars, true)
			if not Timer:IsShown() then
				Timer:Show()
			end
		end
	end

	local function ThrottleUpdate()
		if not throttling then
			throttling = true
			C_Timer.After(1, DelayedUpdate)
		end
	end

	f.GROUP_ROSTER_UPDATE = ThrottleUpdate -- Throttle GROUP_ROSTER_UPDATE
end

-- Update player data-table ----------------------------------------------------
function f:HandleGIST(event, guid, unit, info)
	if event == "GroupInSpecT_Remove" then
		if guid then
			if self.bars[guid] then
				Debug("HandleGIST: Release bar", self.rosterInfo[guid].name, self.rosterInfo[guid].order)

				ReleaseFrame(self.bars[guid])
			end
			self.rosterInfo[guid] = nil
			self.deadWatch[guid] = nil
		end
	elseif event == "GroupInSpecT_Update" then
		Debug("HandleGIST: GIST Update:", info.name, info.realm, info.global_spec_id, info.class, info.lku)

		local name = info.name
		local realm = info.realm
		if realm and realm ~= "" and realm ~= nil then
			name = name.."-"..realm
		end
		local r, g, b

		if self.rosterInfo[guid] then
			if name and name ~= "" and name ~= nil and name ~= self.rosterInfo[guid].name then
				self.rosterInfo[guid].name = name
				if self.bars[guid] then -- Update name also on the bar, it might be empty
					checkBarSettings(self.bars[guid], name)
				end
			end

			if info.class then
				r, g, b = RAID_CLASS_COLORS[info.class].r, RAID_CLASS_COLORS[info.class].g, RAID_CLASS_COLORS[info.class].b
			else
				r, g, b = greenBar[1], greenBar[2], greenBar[3]
			end

			if info.class and info.class ~= self.rosterInfo[guid].class then
				self.rosterInfo[guid].class = info.class
				--r, g, b = RAID_CLASS_COLORS[info.class].r, RAID_CLASS_COLORS[info.class].g, RAID_CLASS_COLORS[info.class].b
				self.rosterInfo[guid].color = { r, g, b, .75 }
			end
			--if info.class and self.rosterInfo[guid].color[1] == 0 and self.rosterInfo[guid].color[2] == 0 and self.rosterInfo[guid].color[3] == 0 then -- Update class colors
			if self.rosterInfo[guid].color[1] ~= r and self.rosterInfo[guid].color[2] ~= g and self.rosterInfo[guid].color[3] ~= b then -- Update class colors
				--if not (r and g and b) then
				--	r, g, b = RAID_CLASS_COLORS[info.class].r, RAID_CLASS_COLORS[info.class].g, RAID_CLASS_COLORS[info.class].b
				--end
				self.rosterInfo[guid].color[1] = r
				self.rosterInfo[guid].color[2] = g
				self.rosterInfo[guid].color[3] = b
			end

			if info.global_spec_id and info.global_spec_id ~= self.rosterInfo[guid].spec then
				self.rosterInfo[guid].spec = info.global_spec_id
			end

			local spellIcon
			if info.class and nopeClasses[info.class] then
				spellIcon = classIcons[info.class..self.rosterInfo[guid].spec] or classIcons[info.class]
				if nopeTextures[spellIcon] and not self.db.profile.specIcons then
					spellIcon = defaultIcon
				end
			else
				spellIcon = classIcons[info.class]
			end
			if self.bars[guid] and self.bars[guid].icon:GetTexture() ~= spellIcon then -- Update Icon if it was wrong
				Debug("HandleGIST: Update Icon")
				self.bars[guid].icon:SetTexture(spellIcon)
			end

			if (self.groupType == 1 and self.db.profile.party == 2) or -- Fixed list Party
			(self.groupType == 2 and self.db.profile.raid == 2) or -- Fixed list Raid
			(self.groupType == 3 and self.db.profile.pvp == 2) then -- Fixed list PvP
				--Debug("HandleGIST: Update Fixed list for", name)
				for k, listChar in pairs(self.db.char) do -- Update order
					if listChar == name then
						self.rosterInfo[guid].order = k

						break
					end
				end
			elseif info.lku and info.lku ~= self.rosterInfo[guid].order then -- Non Fixed list
				self.rosterInfo[guid].order = info.lku
			end
		else
			local isConnected = true
			if (name and name ~= "" and name ~= nil and not UnitIsConnected(name)) then
				if (info.lku and info.lku ~= "" and info.lku ~= nil and not UnitIsConnected(info.lku)) then
					isConnected = false
				end
			end

			if info.class then
				r, g, b = RAID_CLASS_COLORS[info.class].r, RAID_CLASS_COLORS[info.class].g, RAID_CLASS_COLORS[info.class].b
			else
				r, g, b = greenBar[1], greenBar[2], greenBar[3]
				--r, g, b = unpack(greenBar)
			end

			self.rosterInfo[guid] = {
				["name"] = name,
				["class"] = info.class,
				["alive"] = true,
				["spec"] = info.global_spec_id,
				["order"] = info.lku,
				["CD"] = 0,
				["delay"] = 0,
				["color"] = { r, g, b, .75 },
				["connected"] = isConnected,
			}
		end
	end

	DelayedUpdate()
end

-- Help functions and Events for firing and recoloring bars --------------------
function f:checkForDead()
	for guid, name in pairs(self.deadWatch) do -- Check if dead people have been Ressurected or some other way brought back to life
		if guid and name and not UnitIsDeadOrGhost(name) and UnitIsConnected(name) then
			--Debug("checkForDead: Back to life", name)
			self.rosterInfo[guid].alive = true
			self.deadWatch[guid] = nil
		elseif guid and not self.rosterInfo[guid] then
			Debug("checkForDead: Ghost", guid, tostring(name))
			self.deadWatch[guid] = nil
		end
	end

	--Timer:Show() -- Update bar colors
	Timer:ReColor()

	local count = 0
	for _ in pairs(self.deadWatch) do -- Count the dead
		count = count + 1
	end

	if count == 0 then
		Debug("checkForDead: Cancel ticker")
		if self.ticker then
			self.ticker:Cancel()
			self.ticker = nil
		end

		return
	end
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	--timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName
	local _, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellId, spellName, _, extraSpellId, extraSpellName = CombatLogGetCurrentEventInfo()

	-- Fire CD Bars
	if eventType == "SPELL_CAST_SUCCESS" and spellTable[spellId] and self.rosterInfo[sourceGUID] then
		if self.bars[sourceGUID] then -- Fire existing
			self.rosterInfo[sourceGUID].delay = spellTable[spellId]
			self.rosterInfo[sourceGUID].CD = spellTable[spellId]

			local spellIcon = GetSpellTexture(spellId)
			if self.bars[sourceGUID].icon:GetTexture() ~= spellIcon then -- Update Icon if it was wrong
				self.bars[sourceGUID].icon:SetTexture(spellIcon)
			end

			if not Timer:IsShown() then
				Timer:Show()
			end

		elseif ((self.groupType == 1 and self.db.profile.party == 4) or
		(self.groupType == 2 and self.db.profile.raid == 4) or
		(self.groupType == 3 and self.db.profile.pvp == 4)) then -- Create new bar on the fly for Cooldown tracking
			--Debug("CLEU: New bar for", sourceName, self.rosterInfo[sourceGUID].order)
			self.bars[sourceGUID] = AcquireFrame(self.anchor, sourceName, GetSpellTexture(spellId), sourceGUID)

			self.rosterInfo[sourceGUID].delay = spellTable[spellId]
			self.rosterInfo[sourceGUID].CD = spellTable[spellId]

			Timer:New(self.bars[sourceGUID])
		end
	end

	-- Announce
	if eventType == "SPELL_INTERRUPT" and self.db.profile.announce and
	self.groupType > 0 and self.playerGUID == sourceGUID and spellTable[spellId] then
		Debug("CLEU:", interruptMsg, extraSpellId, extraSpellName, destName)

		-- SendChatMessage() is partially hw event protected:
		-- 		"CHANNEL" is protected, "SAY", "YELL" are protected while outside of instances/raids.
		-- 		https://twitter.com/deadlybossmods/status/1176685822223011842
		if IsInInstance() then
			SendChatMessage(string.format(interruptMsg, extraSpellId, extraSpellName, destName), "SAY")
		else
			if self.groupType > 1 then -- Raid (or really random outdoor BG situation going on???)
				SendChatMessage(string.format(interruptMsg, extraSpellId, extraSpellName, destName), "RAID")
			else -- Party
				SendChatMessage(string.format(interruptMsg, extraSpellId, extraSpellName, destName), "PARTY")
			end
		end
	elseif eventType == "SPELL_INTERRUPT" and self.rosterInfo[sourceGUID] and spellId and not spellTable[spellId] then
		assert(nopeSpells[spellId], string.format(L.Assert, tostring(spellName), tonumber(spellId), tostring(sourceName), tostring(self.rosterInfo[sourceGUID].class), tostring(sourceGUID)))
	end

	if eventType == "UNIT_DIED" and self.rosterInfo[destGUID] then
		--Debug("UNIT_DIED", destName)

		self.rosterInfo[destGUID].alive = false
		self.deadWatch[destGUID] = destName

		self.ticker = self.ticker or C_Timer.NewTicker(1, function() f:checkForDead() end)

		--Timer:Show() -- Update bar colors
		Timer:ReColor()
	end
end

-- AddonCom Event and help functions -------------------------------------------
function f:CHAT_MSG_ADDON(event, prefix, message, channel, sender)
	--if prefix == ADDON_NAME then Debug("CHAT_MSG_ADDON: Message:", prefix, message, channel, sender) end

	if not ((channel == "RAID" or channel == "PARTY") and prefix == ADDON_NAME) then return end
	--if not ((channel == "RAID" or channel == "PARTY" or channel == "GUILD") and prefix == ADDON_NAME) then return end -- Debug

	local shortSender = Ambiguate(sender, "none")
	local command, data = strsplit("=", message)
	if command == "L" and shortSender ~= self.playerName then
	--if command == "L" then -- Debug
		Debug("CHAT_MSG_ADDON: Received list:", data, "from", sender)
		Print(L.ListReceived, sender)

		local tbl = { strsplit(":", data) }
		local nameTbl = {}
		for i, name in pairs(tbl) do -- Try to fix realmnames for players from different realms
			Debug("CHAT_MSG_ADDON: Iterate:", i, tostring(name))
			if name and name ~= "" then
				--local shortName = Ambiguate(name, "short")
				local patern = "^([^%-]+)%-(.*)$"
				local shortName = name:match(patern) and select(1, name:match(patern)) or name
				local newName, realm = UnitName(shortName)
				if realm and realm ~= "" then -- From different realm
					tbl[i] = newName.."-"..realm
					nameTbl[i] = newName.."-"..realm
				else -- From same realm
					tbl[i] = newName and newName or name
					nameTbl[i] = newName and newName or name
				end
			else -- Empty
				nameTbl[i] = ""
			end
		end

		Debug("CHAT_MSG_ADDON: nameTbl", #nameTbl)
		for k, name in pairs(nameTbl) do
			if name and name ~= "" then
				local _, class = UnitClass(name)
				if class then
					nameTbl[k] = "|c"..RAID_CLASS_COLORS[class].colorStr..name..FONT_COLOR_CODE_CLOSE
				else
					nameTbl[k] = GRAY_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE
				end
			end
		end

		local newList = strjoin(" / ", tostringall(unpack(nameTbl)))
		Debug("CHAT_MSG_ADDON: newList:", newList)
		newList = string.gsub(newList, " /  / ", " / ")

		local line = string.format(L.PopUpLine, NORMAL_FONT_COLOR_CODE..ADDON_NAME..":"..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..shortSender..FONT_COLOR_CODE_CLOSE, newList, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE)
		

		local dialogFrame = StaticPopup_Show(ADDON_NAME.."_RECIEVE_LIST_CONFIRM", line)
		if dialogFrame then
			dialogFrame.data = tbl
		end
	end
end

StaticPopupDialogs[ADDON_NAME.."_RECIEVE_LIST_CONFIRM"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Debug("StaticPopupDialogs: Accepting new list")

		local frame = ACD.OpenFrames[ADDON_NAME.."List"]
		if frame then -- Close frame if it was open to update the info
			ACD:Close(ADDON_NAME.."List")
		end

		for i = 1, 5 do -- Fill the list
			local value = data[i] or nil
			f.db.char[i] = value
		end

		if f.groupType == 3 then -- Change to Fixed list -mode
			f.db.profile.pvp = 2
		elseif f.groupType == 2 then
			f.db.profile.raid = 2
		else
			f.db.profile.party = 2
		end

		DelayedUpdate()

		Print(L.FixedNames, (f.groupType == 3 and _G.PVP or (f.groupType == 2 and _G.RAID or _G.PARTY)), NORMAL_FONT_COLOR_CODE..L.FixedList..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash..FONT_COLOR_CODE_CLOSE)

		Debug("StaticPopupDialogs: List status:", tostring(frame))
		if frame then -- Reopen frame with refreshed info
			C_Timer.After(0.5, function() ACD:Open(ADDON_NAME.."List") end)
		end
	end,
	timeout = 0, --60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

-- Config help and build functions ---------------------------------------------
function f:RefreshConfig()
	Debug("RefreshConfig")

	self.anchor:ClearAllPoints()
	self.anchor:SetSize(self.db.profile.width, self.db.profile.height)
	self.anchor:SetPoint("CENTER", self.db.profile.xPos, self.db.profile.yPos)

	DelayedUpdate()

	for guid, bar in pairs(self.bars) do
		checkBarSettings(bar, f.rosterInfo[guid].name)
	end
	if not Timer:IsShown() then
		Timer:Show()
	end

	self.anchor:Hide()
	if self:getViewCondition() and (InCombatLockdown() or
	(not InCombatLockdown() and self.db.profile.combatOnly == 0)) then
		Debug("RefreshConfig: Show")
		self.anchor:Show()
	else
		Debug("RefreshConfig: Remove")
		local changed = false
		for guid in pairs(self.bars) do
			if guid ~= self.playerGUID then
				ReleaseFrame(self.bars[guid])
				changed = true
			end
		end

		if changed then
			sortAndArrange(self.bars, true)
		end
	end
end

function f:GetOptions()
	if self.optionsFrame then return end

	-- Actual options in the config frame
	local options = {
		type = "group",
		name = string.format(L.ConfigTitle, ADDON_NAME),
		order = 103,
		get = function(info) return self.db.profile[info[#info]] end,
		set = function(info, value) self.db.profile[info[#info]] = value; self:RefreshConfig(); end,
		args = {
			modesContainer = {
				type = "group",
				name = L.ViewOptions,
				inline = true,
				order = 1,
				args = {
					fixedMode = {
						type = "description",
						name = string.format(L.FixedModeDesc, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash..FONT_COLOR_CODE_CLOSE),
						order = 1,
						fontSize = "medium",
					},
					autofillMode = {
						type = "description",
						name = string.format(L.AutofillModeDesc, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE),
						order = 2,
						fontSize = "medium",
					},
					trackMode = {
						type = "description",
						name = string.format(L.TrackModeDesc, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE),
						order = 3,
						fontSize = "medium",
					},
					solo = {
						type = "select",
						name = L.SoloMode,
						desc = L.SoloModeDesc,
						order = 4,
						values = {
							[0] = HIDE,
							[1] = SHOW,
						},
					},
					party = {
						type = "select",
						name = L.PartyMode,
						desc = L.PartyModeDesc,
						order = 5,
						values = {
							[0] = HIDE,
							[2] = L.FixedList,
							[3] = L.AutofillList,
							[4] = L.CooldownTracking,
						},
					},
					raid = {
						type = "select",
						name = L.RaidMode,
						desc = L.RaidModeDesc,
						order = 6,
						values = {
							[0] = HIDE,
							[2] = L.FixedList,
							[4] = L.CooldownTracking,
						},
					},
					pvp = {
						type = "select",
						name = L.PvPMode,
						desc = L.PvPModeDesc,
						order = 7,
						values = {
							[0] = HIDE,
							[2] = L.FixedList,
							[4] = L.CooldownTracking,
						},
					},
					combatOnly = {
						type = "select",
						name = L.CombatOnly,
						order = 8,
						values = {
							[0] = L.False,
							[1] = L.True,
						},
					},
				},
			},
			spacer = {
				type = "description",
				name = "\n",
				order = 2,
				width = "full",
			},
			barOptions = {
				type = "group",
				name = L.BarOptions,
				inline = true,
				order = 3,
				args = {
					xPos = {
						type = "range",
						name = L.Xpos,
						desc = L.XposDesc,
						order = 1,
						min = -math.floor(GetScreenWidth()/2 + 0.5),
						max = math.floor(GetScreenWidth()/2 + 0.5),
						step = 1,
					},
					yPos = {
						type = "range",
						name = L.Ypos,
						desc = L.YposDesc,
						order = 2,
						min = -math.floor(GetScreenHeight()/2 + 0.5),
						max = math.floor(GetScreenHeight()/2 + 0.5),
						step = 1,
					},
					spacing = {
						type = "range",
						name = L.Spacing,
						desc = L.SpacingDesc,
						order = 3,
						min = 0,
						max = 10,
						step = 1,
					},
					spacer = {
						type = "description",
						name = "\n",
						order = 4,
						width = "full",
					},
					width = {
						type = "range",
						name = L.Width,
						desc = L.WidthDesc,
						order = 5,
						min = 50,
						max = 250,
						step = 1,
					},
					height = {
						type = "range",
						name = L.Height,
						desc = L.HeightDesc,
						order = 6,
						min = 8,
						max = 32,
						step = 1,
					},
					fontSize = {
						type = "range",
						name = L.FontSize,
						desc = L.FontSizeDesc,
						order = 7,
						min = 8,
						max = 32,
						step = 1,
					},
					spacer2 = {
						type = "description",
						name = "\n",
						order = 8,
						width = "full",
					},
					barAlpha = {
						type = "range",
						name = L.barAlpha,
						desc = L.barAlphaDesc,
						order = 9,
						min = 0,
						max = 1,
						step = .05,
					},
					textAlpha = {
						type = "range",
						name = L.textAlpha,
						desc = L.textAlphaDesc,
						order = 10,
						min = 0,
						max = 1,
						step = .05,
					},
					iconAlpha = {
						type = "range",
						name = L.iconAlpha,
						desc = L.iconAlphaDesc,
						order = 11,
						min = 0,
						max = 1,
						step = .05,
					},
					spacer3 = {
						type = "description",
						name = "\n",
						order = 12,
						width = "full",
					},
					growDirection = {
						type = 'select',
						name = L.GrowDirection,
						desc = L.GrowDirectionDesc,
						order = 14,
						values = {
							["down"] = L.Down,
							["up"] = L.Up,
						},
					},
					spacer6 = {
						type = "description",
						name = "\n",
						order = 15,
						width = "full",
					},
					classColor = {
						type = "toggle",
						name = L.ClassColors,
						desc = L.ClassColorsDesc,
						order = 16,
					},
					shortRealmNames = {
						type = "toggle",
						name = L.ShortNames,
						desc = L.ShortNamesDesc,
						order = 17,
					},
					spacer7 = {
						type = "description",
						name = "\n",
						order = 18,
						width = "full",
					},
					specIcons = {
						type = "toggle",
						name = L.HealerIcons,
						desc = string.format(L.HealerIconsDesc, "|T"..defaultIcon..":0:0:0:0:32:32:2:30:2:30|t"),
						order = 19,
					},
					hideHealers = {
						type = "toggle",
						name = L.HideHealers,
						desc = L.HideHealersDesc,
						order = 20,
						width = "double",
					},
				},
			},
			spacer2 = {
				type = "description",
				name = "\n",
				order = 4,
				width = "full",
			},
			misc = {
				type = "group",
				name = L.MiscOptions,
				inline = true,
				order = 5,
				args = {
					announce = {
						type = "toggle",
						name = L.Announce,
						desc = string.format(L.AnnounceDesc, string.upper(_G.SAY)),
						order = 1,
					},
				},
			},
			spacer3 = {
				type = "description",
				name = "\n",
				order = 6,
				width = "full",
			},
		},
	}

	ACR:RegisterOptionsTable(ADDON_NAME.."Config", options)

	options.args.profiles = ADO:GetOptionsTable(self.db)
	options.args.profiles.guiInline = true
	ACR:RegisterOptionsTable(ADDON_NAME.."Profiles", options.args.profiles)

	-- Help showing in the Blizzard Options
	local blizzOptions = {
		type = "group",
		name = ADDON_NAME,
		order = 103,
		args = {
			textDesc = {
				type = "description",
				name = string.format(L.textDesc, ADDON_NAME, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE),
				order = 0,
				fontSize = "large",
			},
			infoDesc1 = {
				type = "description",
				name = string.format(L.infoDesc1, NORMAL_FONT_COLOR_CODE..L.slash..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.config..FONT_COLOR_CODE_CLOSE),
				order = 1,
				fontSize = "large",
			},
			infoDesc2 = {
				type = "description",
				name = string.format(L.infoDesc2, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.show..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.hide..FONT_COLOR_CODE_CLOSE),
				order = 2,
				fontSize = "large",
			},
			infoDesc3 = {
				type = "description",
				name = string.format(L.infoDesc3, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.list..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.add.." (#)"..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.remove.." #"..FONT_COLOR_CODE_CLOSE),
				order = 3,
				fontSize = "large",
			},
			infoDesc4 = {
				type = "description",
				name = string.format(L.infoDesc4, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.reset..FONT_COLOR_CODE_CLOSE),
				order = 4,
				fontSize = "large",
			},
			infoDesc5 = {
				type = "description",
				name = string.format(L.infoDesc5, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.help..FONT_COLOR_CODE_CLOSE),
				order = 5,
				fontSize = "large",
			},
		},
	}

	ACR:RegisterOptionsTable(ADDON_NAME.."BlizzInfo", blizzOptions, true)
	self.optionsFrame = ACD:AddToBlizOptions(ADDON_NAME.."BlizzInfo", ADDON_NAME)

	-- Fixed list editor frame
	local list = {
		type = "group",
		name = ADDON_NAME,
		order = 103,
		get = function(info) return self.db.char[info[#info]] end,
		set = function(info, value) if value == "" then value = nil end; self.db.char[info[#info]] = value; self:RefreshConfig(); end,
		args = {
			listContainer = {
				type = "group",
				name = L.CustomListTitle,
				inline = true,
				order = 1,
				args = {
					header = {
						type = "header",
						name = L.Interrupters,
						order = 0,
					},
					[1] = {
						type = "input",
						name = L["1st"],
						order = 1,
						width = "full",
					},
					[2] = {
						type = "input",
						name = L["2nd"],
						order = 2,
						width = "full",
					},
					[3] = {
						type = "input",
						name = L["3rd"],
						order = 3,
						width = "full",
					},
					[4] = {
						type = "input",
						name = L["4th"],
						order = 4,
						width = "full",
					},
					[5] = {
						type = "input",
						name = L["5th"],
						order = 5,
						width = "full",
					},
					header2 = {
						type = "header",
						name = L.BroadcastList,
						order = 6,
					},
					button = {
						type = "execute",
						name = L.SendList,
						desc = L.SendListDesc,
						order = 7,
						func = function()
							Debug("GetOptions: BButton pressed")
							if self.groupType == 0 then return end

							if UnitAffectingCombat("player") then
								Print(L.SendCombatExit)
								return
							end

							local tbl = {}
							for n = 1, 5 do -- Replace nils with empty strings
								if not self.db.char[n] or self.db.char[n] == nil or self.db.char[n] == "" then
									tbl[n] = ""
								else
									tbl[n] = self.db.char[n]
								end
							end
							local sync = strjoin(":", tostringall(unpack(tbl)))
							local commType = self.groupType >= 2 and "RAID" or "PARTY"
							--local commType = "GUILD" -- Debug
							C_ChatInfo.SendAddonMessage(ADDON_NAME, "L="..(sync or ""), commType)
							Print(L.ListSent, _G[commType])
							Debug("GetOptions: -> Sending list:", sync, commType)

							SendChatMessage(L.Interrupters..":", commType)
							Debug("GetOptions:", L.Interrupters..":", commType)
							for i = 1, 5 do
								if tbl[i] and tbl[i] ~= "" then
									SendChatMessage(i.." "..tbl[i], commType)
									Debug("GetOptions:", i.." "..tbl[i], commType)
								end
							end
						end,
						disabled = function()
								if self.groupType == 0 then
									return true;
								else
									return UnitIsGroupLeader("player") and false or true;
								end;
							end,
						width = "full",
					},
					header3 = {
						type = "header",
						name = L.ResetList,
						order = 8,
					},
					button2 = {
						type = "execute",
						name = L.ResetList,
						desc = L.ResetListDesc,
						order = 9,
						func = function()
							Debug("GetOptions: RButton pressed")
							if IsShiftKeyDown() then
								Debug("GetOptions: Reseting")

								for i = 1, 5 do
									self.db.char[i] = nil
								end

								self.db.char[1] = self.playerName
								DelayedUpdate()
							end
						end,
						width = "full",
					},
				},
			},
		},
	}

	ACR:RegisterOptionsTable(ADDON_NAME.."List", list, true)
end

-- Slash -----------------------------------------------------------------------
SLASH_LOIHINTERRUPT1 = L.slash
SLASH_LOIHINTERRUPT2 = L.slash2

local SlashHandlers = {
	["roster"] = function() -- Debug stuff
		local count = 0
		Print("rosterInfo:")
		for k, v in pairs(f.bars) do
			Print(">", tostring(k), tostring(v.text:GetText()))
			count = count + 1
		end
		Print("Total:", count)
	end,
	["refresh"] = function() -- Debug stuff
		LGIST:Rescan()
		if not Timer:IsShown() then
			Timer:Show()
		end
		Debug("SlashHandlers: Initiating data-refresh")
	end,
	["debug"] = function() -- Debug stuff
		f.db.profile.debug = not f.db.profile.debug
		Print("Debugging:", tostring(f.db.profile.debug))
	end,
	[L.hide] = function()
		Print(HIDE)
		if f:IsShown() then
			f:Hide()
		end
		if f.anchor:IsShown() then
			f.anchor:Hide()
		end
		if f.configAnchor:IsShown() then
			f.configAnchor:Hide()
		end
		if Timer:IsShown() then
			Timer:Hide()
		end
	end,
	[L.show] = function()
		Print(SHOW)
		if not f:IsShown() then
			f:Show()
		end
		if not f.anchor:IsShown() then
			f.anchor:Show()
		end
		if not Timer:IsShown() then
			Timer:Show()
		end
	end,
	[L.list] = function()
		Print(L.CustomListTitle)
		for k, v in pairs(f.db.char) do
			Print(">", tostring(k)..".", tostring(v))
		end
	end,
	[L.add] = function(...)
		local number = tonumber(...)
		local target, realm = UnitName("target")

		if realm and realm ~= "" then
			target = target.."-"..realm
		end

		if target and number and number >= 1 and number <= 5 then
			f.db.char[number] = target
			Print(L.AddedPosition, target, number)
		elseif target then
			local inserted = false
			for i = 1, 5 do -- Check if the target is already in the list
				if f.db.char[i] == target then
					inserted = string.format(L.AlreadyOnList, target, i)

					break
				end
				i = i + 1
			end

			if not inserted then
				for i = 1, 5 do -- Not in the list, check if there is room on the list
					if not f.db.char[i] or f.db.char[i] == "" or f.db.char[i] == nil then
						f.db.char[i] = target
						inserted = string.format(L.AddedPosition, target, i)
						DelayedUpdate()

						break
					end

					i = i + 1
				end
			end

			if inserted then
				Print(inserted)
			else
				Print(L.ListFull, target)
			end
		else
			Print(L.NoTarget)
		end
	end,
	[L.remove] = function(...)
		local number = tonumber(...)
		if number and number >= 1 and number <= 5 and f.db.char[number] then
			Print(L.RemovedPosition, f.db.char[number], number)

			f.db.char[number] = nil
			DelayedUpdate()
		elseif number and number >= 1 and number <= 5 then
			Print(L.AlreadyEmpty, number)
		else
			Print(L.RemoveInputError, tostring(number))
		end
	end,
	[L.reset] = function()
		Print(L.Reseting)
		for i = 1, 5 do
			f.db.char[i] = nil
		end

		f.db.char[1] = f.playerName
		DelayedUpdate()
	end,
	[L.config] = function()
		ACD:Open(ADDON_NAME.."Config")

		local frame = ACD.OpenFrames[ADDON_NAME.."Config"]
		if frame then
			Debug("SlashHandlers: OW YISSS!", tostring(frame.status))
			f.configAnchor:Show()

			f.rosterInfo["Test1"] = { -- Shadow Priest
				name = "Test Priest", class = "PRIEST", alive = true, spec = 258, order = "party1", CD = 0, delay = 0, color = { 1, 1, 1, .75 }, connected = true,
			}
			f.rosterInfo["Test2"] = { -- Fire Mage
				name = "Test Mage", class = "MAGE", alive = true, spec = 63, order = "party2", CD = 0, delay = 0, color = { .41, .8, .94, .75 }, connected = true,
			}
			f.rosterInfo["Test3"] = { -- Restoration Shaman
				name = "Test Shaman", class = "SHAMAN", alive = true, spec = 264, order = "party3", CD = 0, delay = 0, color = { 0, .44, .87, .75 }, connected = true,
			}
			f.rosterInfo["Test4"] = { -- Restoration Druid
				name = "Test Druid", class = "DRUID", alive = true, spec = 105, order = "party4", CD = 0, delay = 0, color = { 1, .49, .04, .75 }, connected = true,
			}
			DelayedUpdate()
			local counter = 0
			for _ in pairs(f.rosterInfo) do
				counter = counter + 1
			end
			Debug("Start Count:", counter)

			hooksecurefunc(frame, "Hide", function(this)
				f.configAnchor:Hide()

				f.rosterInfo["Test1"] = nil
				f.rosterInfo["Test2"] = nil
				f.rosterInfo["Test3"] = nil
				f.rosterInfo["Test4"] = nil
				DelayedUpdate()
				local counter = 0
				for _ in pairs(f.rosterInfo) do
					counter = counter + 1
				end
				Debug("End Count:", counter)

			end)
		else
			Debug("SlashHandlers: OH NOES!")
		end
	end,
	[L.help] = function(...)
		local helpTbl = {
			[L.config] = L.HelpConfig,
			[L.show] = L.HelpShow,
			[L.hide] = L.HelpHide,
			[L.list] = L.HelpList,
			[L.add] = L.HelpAdd,
			[L.remove] = L.HelpRemove,
			[L.reset] = L.HelpReset,
			[L.help] = L.HelpHelp,
		}
		local param = ...
		if not param or param == "" then
			Print(L.HelpListParams, NORMAL_FONT_COLOR_CODE..L.slash, L.config, L.show, L.hide, L.list, L.add, L.remove, L.reset, L.help, L.command, FONT_COLOR_CODE_CLOSE)
			Print(L.HelpNoParam, NORMAL_FONT_COLOR_CODE..L.slash..FONT_COLOR_CODE_CLOSE)
		elseif helpTbl[param] then
			Print(L.HelpOn, tostring(param))
			Print(helpTbl[param].."\n", NORMAL_FONT_COLOR_CODE..L.slash.." "..L[param], FONT_COLOR_CODE_CLOSE)
		else
			Print(L.HelpInputError, tostring(param))
		end
	end,
}

SlashCmdList["LOIHINTERRUPT"] = function(text)
	local command, params = strsplit(" ", text, 2)

	if InCombatLockdown() and (command ~= L.show and command ~= L.hide) then
		Print(L.CombatLockdown, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.show..FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE..L.slash.." "..L.hide..FONT_COLOR_CODE_CLOSE)

		return
	end

	if SlashHandlers[command] then
		SlashHandlers[command](params)
	else
		ACD:SetDefaultSize(ADDON_NAME.."List", 275, 400)
		ACD:Open(ADDON_NAME.."List")
	end
end

-- #EOF