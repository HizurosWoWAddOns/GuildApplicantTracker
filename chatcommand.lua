
local addon, ns = ...;
local L = ns.L;

SlashCmdList["GUILDAPPLICANTTRACKER"] = function(cmd)
	local cmd, arg = strsplit(" ", cmd, 2)
	cmd = cmd:lower()

	if cmd=="toggle" then
		GuildApplicantTracker:Toggle()
	elseif cmd=="offline" then
		GuildApplicantTracker:ToggleOffline()
	elseif cmd=="minimap" then
		GuildApplicantTracker:ToggleMinimap();
	elseif cmd=="reset" then
		GuildApplicantTracker:Reset();
		ReloadUI();
	elseif cmd=="resetframe" then
		GuildApplicantTracker:ResetFrame();
	else
		print(L["Commandline options for %s"]:format(addon));
		print("   "..L["Usage: /gat <command>"]);
		print(L["Commands:"]);
		print("   toggle - " .. L["Show/Hide tracker frame"]);
		print("   offline - " .. L["Show/Hide offline applicants"]);
		print("   minimap - " .. L["Show/Hide minimap icon"]);
		print("   reset - " .. L["Reset addon settings"]);
		print("   resetframe - " .. L["Reset frame position"]);
	end
end

SLASH_GUILDAPPLICANTTRACKER1 = "/gat"

