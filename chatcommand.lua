
local addon, ns = ...;
local L = ns.L;


SlashCmdList["GUILDAPPLICANTTRACKER"] = function(cmd)
	local cmd, arg = strsplit(" ", cmd, 2)
	cmd = cmd:lower()

	if cmd=="toggle" then
		GuildApplicantTracker_Toggle()
	elseif cmd=="offline" then
		GuildApplicantTracker_ToggleOffline()
	elseif cmd=="minimap" then
		GuildApplicantTracker_ToggleMinimap();
	elseif cmd=="reset" then
		GuildApplicantTracker_Reset();
		ReloadUI();
	else
		print(L["Commandline options for %s"]:format(addon));
		print("   "..L["Usage: /gat <command>"]);
		print(L["Commands:"]);
		print("   toggle - " .. L["Show/Hide tracker frame."]);
		print("   offline - " .. L["Show/Hide offline applicants."]);
		print("   minimap - " .. L["Show/Hide minimap icon."]);
		print("   reset - " .. L["Reset addon settings."]);
	end
end

SLASH_GUILDAPPLICANTTRACKER1 = "/gat"

