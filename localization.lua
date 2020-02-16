
local addon, ns = ...

local L = {};
ns.L = setmetatable(L,{__index=function(t,k)
	local v = tostring(k)
	rawset(t,k,v)
	return v
end});

-- Do you want to help localize this addon?
-- https://www.curseforge.com/wow/addons/guildapplicanttracker/localization

--@do-not-package@
L["AddOnLoaded"] = "AddOn loaded..."
L["AddOnLoadedDesc"] = "Display 'AddOn loaded...' message on login"
L["CLCmds"] = "Commands:";
L["CLHeader"] = "Commandline options"
L["CLMinimapDesc"] = "Show/Hide minimap button"
L["CLMinimap"] = "minimap"
L["CLOptionsDesc"] = "Show/Hide option panel"
L["CLResetFrameDesc"] = "Reset frame position"
L["CLResetSettingsDesc"] = "Reset addon settings"
L["CLToggleDesc"] = "Show/Hide tracker frame"
L["CLUsage"] = "Usage: /gat <command>"
L["MinimapButtonDesc"] = "Append a button to the minimap. Show/Hide addon window (left click) or options (right click)."
L["MinimapButton"] = "Show minimap button"
L["No comment..."] = "No comment..."
L["OptionsButtonTooltip"] = "Click to open options"
L["PopupOnNewDesc"] = "Automatically popup the tracker frame on new applicants"
L["PopupOnNew"] = "Popup on new applicants"
L["ResetFrameDesc"] = "Reset position of the tracker frame on your UI"
L["ResetFrame"] = "Reset frame"
L["ResetOptions"] = "Reset options"
L["ResetSettingsDesc"] = "Reset the settings of this addon"
L["ResetSettings"] = "Reset settings"
L["TooltipHintLeftClick"] = "Left click # Open/Close addon window"
L["TooltipHintRightClick"] = "Right click # Open/Close addon options"
--@end-do-not-package@

--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@

if LOCALE_deDE then
--@localization(locale="deDE", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_esES then
--@localization(locale="esES", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_esMX then
--@localization(locale="esMX", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_frFR then
--@localization(locale="frFR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_itIT then
--@localization(locale="itIT", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_koKR then
--@localization(locale="koKR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_ptBR or LOCALE_ptPT then
--@localization(locale="ptBR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_ruRU then
--@localization(locale="ruRU", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_zhCN then
--@localization(locale="zhCN", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_zhTW then
--@localization(locale="zhTW", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end
