
local addon, ns = ...;
local L = ns.L;

SlashCmdList["GUILDAPPLICANTTRACKER"] = function(cmd)
	local cmd, arg = strsplit(" ", cmd, 2)
	cmd = cmd:lower()

	if cmd=="toggle" then
		GuildApplicantTracker:Toggle()
	elseif cmd=="options" then
		GuildApplicantTracker:ToggleOptions()
	elseif cmd=="minimap" then
		GuildApplicantTracker:ToggleMinimap();
	elseif cmd=="resetsettings" then
		GuildApplicantTracker:ResetSettings();
	elseif cmd=="resetframe" then
		GuildApplicantTracker:ResetFrame();
	else
		ns.print(L["CLHeader"]); -- Commandline options
		ns.print(true,"   "..L["CLUsage"]); -- Usage: /gat <command>
		ns.print(true,L["CLCmds"]);
		ns.print(true,"   toggle","-",       L["CLToggleDesc"]); -- Show/Hide tracker frame
		ns.print(true,"   options","-",      L["CLOptionsDesc"]); -- Show/Hide option panel
		ns.print(true,"   minimap","-",      L["CLMinimapDesc"]); -- Show/Hide minimap button
		ns.print(true,"   resetsettings","-",L["CLResetSettingsDesc"]); -- Reset addon settings
		ns.print(true,"   resetframe","-",   L["CLResetFrameDesc"]); -- Reset frame position
	end
end

SLASH_GUILDAPPLICANTTRACKER1 = "/gat"

