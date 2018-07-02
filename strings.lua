--[[----------------------------------------------------------------------------
	LOIHINterrups

	2015-
	Sanex @ EU-Arathor / ahak @ Curseforge
----------------------------------------------------------------------------]]--

local ADDON_NAME, ns = ...

local LOCALE = GetLocale()
local L = {}
ns.L = L

-- Config Anchor
L.ConfigAnchor = "%s Anchor" -- %s = ADDON_NAME

-- Assert
L.Assert = "Found unlisted interrupt spell '%s' (%d) casted by '%s' (%s - %s). Please report this to the author of the addon!" -- %s = spellName, %d = spellId, %s = sourceName, %s = class, %s = sourceGUID

-- CHAT_MSG_ADDON
L.ListReceived = "Interrupt list recieved from %s" -- %s = sender
L.PopUpLine = "%s Player '%s' is broadcasting following fixed interrupt list:\n\n%s\n\nDo you want to replace your current list with this list and change current more to %sFixed list -mode%s?" -- %s = ADDON_NAME, %s = sender, %s = list, %s = colorcode, %s = close colorcode
L.FixedNames = "Changed %s mode to %s and tried to fix realmnames for you on the list, but you should check them out to be sure they work (%s)!" -- %s = mode, %s = L.FixedList, %s = L.slash

-- Config
L.ConfigTitle = "%s Config" -- %s ADDON_NAME
L.ViewOptions = "View options"
L.FixedModeDesc = "%sFixed list%s -mode uses configurable list of players from Party, Raid or PvP-group to fill the bars and can be used to track interrupt rotations. Group leader can share his/hers list between Party and Raid members. Use %s to edit and share the list.\n" -- %s = colorcode, %s = close colorcode, %s = L.slash
L.AutofillModeDesc = "%sAutofill list%s -mode fills bars with Party members and can be used to easily track interrupt rotations in groups where fixed lists isn't that useful because of changing group roster.\n" -- %s = colorcode, %s = close colorcode
L.TrackModeDesc = "%sCooldown tracking%s -mode tracks only your Interrupt spell availability and adds new bars for other group members only when their Interrupt spells are on cooldown.\n" -- %s = color code, %s = close colorcode
L.SoloMode = "Solo mode"
L.SoloModeDesc = "Show when you are adventuring alone."
L.PartyMode = "Party mode"
L.PartyModeDesc = "Show when you are adventuring in Party group."
L.FixedList = "Fixed list"
L.AutofillList = "Autofill list"
L.CooldownTracking = "Cooldown tracking"
L.RaidMode = "Raid mode"
L.RaidModeDesc = "Show when you are adventuring in a Raid group."
L.PvPMode = "PvP mode"
L.PvPModeDesc = "Show when you are playing in a Arena or Battleground groups."
L.CombatOnly = "Show bars only when in Combat"
L.False = "False"
L.True = "True"
L.BarOptions = "Bar options"
L.Xpos = "X-position"
L.XposDesc = "X-position of anchor from CENTER of the screen."
L.Ypos = "Y-position"
L.YposDesc = "Y-position of anchor from CENTER of the screen."
L.Spacing = "Spacing"
L.SpacingDesc = "Spacing between bars."
L.Width = "Width"
L.WidthDesc = "Width of sigle cooldownbar."
L.Height = "Height"
L.HeightDesc = "Height of sigle cooldownbar."
L.FontSize = "Font Size"
L.FontSizeDesc = "Font size of text on bars."
L.barAlpha = "Bar Alpha"
L.barAlphaDesc = "Alpha-value of bars themselves. Increase for more opacity and decrease for more transparency."
L.textAlpha = "Text Alpha"
L.textAlphaDesc = "Alpha-value of texts in bars. Increase for more opacity and decrease for more transparency."
L.iconAlpha = "Icon Alpha"
L.iconAlphaDesc = "Alpha-value of icons in the bars. Increase for more opacity and decrease for more transparency."
L.GrowDirection = "Grow Direction"
L.GrowDirectionDesc = "Add new bars to BOTTOM or TOP of previous bars."
L.Down = "Down"
L.Up = "Up"
L.ClassColors = "Use class colors on bars"
L.ClassColorsDesc = "Use class colored bars instead of default green and red bars."
L.ShortNames = "Short Realm names on bars"
L.ShortNamesDesc = "Replace Realm names with (#) for connected realms and (*) for foreign realms on bars."
L.HealerIcons = "Healers specialization icons"
L.HealerIconsDesc = "Try to replace %s with specialization icons for healer classes without interrupt spell.\n\nThis depends on data provided by external Library and it can take time for the information to be available." -- %s = ?-icon
L.HideHealers = "Hide Healers with no interrupt"
L.HideHealersDesc = "Don't show bars for healers with no real interrupt spells."
L.MiscOptions = "Misc options"
L.Announce = "Announce Interrupts"
L.AnnounceDesc = "Announce in %s when you interrupt spellcast when you are in a group." -- %s = _G.SAY

-- Blizzard Options
L.textDesc = "%s is interrupt rotation/cooldown tracking tool created for guild %s<Lords of Ironhearts>%s at Arathor EU. All the bar settings are saved in profiles and Fixed lists are saved per character and can be shared between party and raid members with %sBroadcast%s-feature." -- %s = ADDON_NAME, rest %s' colorcodes and close colorcodes
L.infoDesc1 = "%s opens fixed list editor where you can edit and broadcast your fixed lists to your group.\n%s opens config frame where you can edit all the settings and profiles of this addon." -- %s = L.slash, %s = L.slash L.config
L.infoDesc2 = "%s enables interrupt bars (if group and combat settings are met).\n%s hides interrupt bars (even if group and combat settings are met)." -- %s = L.slash L.show, %s = L.slash L.hide
L.infoDesc3 = "%s prints current fixed list.\n%s adds your current target to the fixed list (on position # if given, first free slot if any free slots is left on the fixed list).\n%s removes entry number # from the fixed list." -- %s = L.slash L.list, %s = L.slash L.add, %s = L.slash L.remove
L.infoDesc4 = "%s resets current fixed list and adds you to position #1." -- %s = L.slash L.reset
L.infoDesc5 = "%s prints list of these slash commands or more information about commands if given as parameter." -- %s = L.slash L.help

-- List Config
L.CustomListTitle = "Custom list for 'Fixed list' -mode"
L.Interrupters = "Interrupters"
L["1st"] = "1st interrupter:"
L["2nd"] = "2nd interrupter:"
L["3rd"] = "3rd interrupter:"
L["4th"] = "4th interrupter:"
L["5th"] = "5th interrupter:"
L.BroadcastList = "Broadcast list"
L.SendList = "Send list"
L.SendListDesc = "Send list to party/raid members"
L.SendCombatExit = "You are in combat, not sending the list."
L.ListSent = "Interrupt list sent to %s" -- %s = _G.PARTY or _G.RAID
L.ResetList = "Reset list"
L.ResetListDesc = "Shift+Click to reset list"

-- SlashHandler
L.slash = "/lint" -- Translate only if needed
L.slash2 = "/loihint" -- Translate only if needed
-- -- slash params
L.hide = "hide"
L.show = "show"
L.list = "list"
L.add = "add"
L.remove = "remove"
L.reset = "reset"
L.config = "config"
L.help = "help"
-- --
L.AddedPostion = "Added %s to position %d on the fixed list." -- %s = target name, %d = position on list
L.AlreadyOnList = "Player %s is already in the fixed list on position %d." -- % target name, %d = position on list
L.ListFull = "Couldn't find free spot from the list, didn't add %s to the fixed list." -- %s = target name
L.NoTarget = "No target selected."
L.RemovedPosition = "Removed %s from the fixed list position %d." -- %s = name, %d = position on list
L.AlreadyEmpty = "Fixed list position %d is empty already." -- %d = position on list
L.RemoveInputError = "Only numbers 1-5 are accepted (you entered '%s')." -- %s = player input
L.Reseting = "Reseting fixed list."
L.HelpListParams = "Help:\n%s ( %s | %s | %s | %s | %s [#] | %s # | %s | %s [%s] )%s" -- %s = L.slash, %s' 2-8 = slash params, %s = L.command, %s = close colorcode
L.command = "command"
L.HelpNoParam = "%s opens fixed list editor where you can edit and broadcast your fixed lists to your group." -- %s = L.slash

L.HelpOn = "Help: %s" -- %s = input param
L.HelpConfig = "%s%s opens config frame where you can edit all the settings and profiles of this addon." -- %s = L.slash L.param, %s = close colorcode
L.HelpShow = "%s%s enables interrupt bars (if group and combat settings are met)." -- %s = L.slash L.param, %s = close colorcode
L.HelpHide = "%s%s hides interrupt bars (even if group and combat settings are met)." -- %s = L.slash L.param, %s = close colorcode
L.HelpList = "%s%s prints current fixed list." -- %s = L.slash L.param, %s = close colorcode
L.HelpAdd = "%s (#)%s adds your current target to the fixed list (on position # if given, first free slot if any free slots is left on the fixed list)." -- %s = L.slash L.param, %s = close colorcode
L.HelpRemove = "%s #%s removes entry number # from the fixed list." -- %s = L.slash L.param, %s = close colorcode
L.HelpReset = "%s%s resets current fixed list and adds you to position #1." -- %s = L.slash L.param, %s = close colorcode
L.HelpHelp = "%s%s prints list of these slash commands." -- %s = L.slash L.param, %s = close colorcode
L.HelpInputError = "Help:\nYou tried to get information about '%s' but couldn't find any." -- %s = input param
L.CombatLockdown = "You are in combat. Only %s and %s are accepted commands during combat." -- %s = L.slash L.show , %s = L.slash L.hide


	------------------------------------------------------------------------	

if LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@

elseif LOCALE == "esES" then
--@localization(locale="esES", format="lua_additive_table")@

elseif LOCALE == "esMX" then
--@localization(locale="esMX", format="lua_additive_table")@

elseif LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@

elseif LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@

elseif LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@

elseif LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@

elseif LOCALE == "koKR" then
--@localization(locale="koKR", format="lua_additive_table")@

elseif LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table")@

elseif LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@

end

-- #EOF