
-- SavedVariables
GuildApplicantTrackerDB = {}

-- Libs
local libDataBroker = LibStub("LibDataBroker-1.1");
local libDBIcon = LibStub("LibDBIcon-1.0");

-- Local variables
GuildApplicantTrackerMixin = {};
local addon, ns = ...;
local L = ns.L;
local guildClubId,applicantList,numApplicants,hasChanged,hasNewPlayer,aceOptionsInit = false,false,0,false,false;
local EntryOffset,EntryHeight = 2;
local db_defaults = {
	showAddonLoaded   = true,
	Minimap           = {hide=false},
	frameShow         = true,
	popupOnNew        = true,
	hideOnEmpty       = true,
	knownGUIDs        = {},
}


--[[ print functions ]]
do
	local addon_short = "GAT";
	local colors = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"};
	local function colorize(...)
		local t,c,a1 = {tostringall(...)},1,...;
		if type(a1)=="boolean" then tremove(t,1); end
		if a1~=false then
			tinsert(t,1,"|cff0099ff"..((a1==true and addon_short) or (a1=="||" and "||") or addon).."|r"..(a1~="||" and ":" or ""));
			c=2;
		end
		for i=c, #t do
			if not t[i]:find("\124c") then
				t[i],c = "|cff"..colors[c]..t[i].."|r", c<#colors and c+1 or 1;
			end
		end
		return unpack(t);
	end
	function ns.print(...)
		print(colorize(...));
	end
	function ns.debug(...)
		ConsolePrint(date("|cff999999%X|r"),colorize(...));
	end
end

--[[ string coloring function ]]
local colors = {ltblue="ff69ccf0",ltgreen="ff80ff80",ltyellow="fffff569",dkyellow="ffffcc00",copper="fff0a55f",gray="ff808080",green="ff00ff00",blue="ff0099ff"};
for n, c in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
	colors[n:upper()] = c.colorStr;
end
local function C(color,str)
	return "|c"..( colors[color] or "ffffffff" )..str.."|r";
end

--[[ main funcitons ]]
local function canGuildInvite()
	if not IsInGuild() then
		guildClubId = false;
		return false;
	end
	return CanGuildInvite();
end

local function specs2roles(specIds)
	local roles = {};
	for i=1, #specIds do
		local role = GetSpecializationRoleByID(specIds[i]);
		if role then
			roles[role] = true;
		end
	end
	return roles;
end

local function updateApplicants()
	local brokerText = "n/a";

	if canGuildInvite() then
		guildClubId = C_Club.GetGuildClubId()
--@do-not-package@
		if not guildClubId then
			ns.debug("something goes wrong with the club API. IsInGuild is true but could not find a club with clubType 'guild'.");
			brokerText = "Err1"
		end
--@end-do-not-package@
	end

	if guildClubId then
		hasNewPlayer = false;
		applicantList = C_ClubFinder.ReturnClubApplicantList(guildClubId);
--@do-not-package@
		if not applicantList then
			ns.debug("something goes wrong with the club API. applicantList is not a table. got "..type(applicantList));
			brokerText = "Err2"
		end
--@end-do-not-package@
	end

	if applicantList then
		local currentGUIDs = {};
		for _,applicant in ipairs(applicantList) do
			if applicant.clubFinderGUID then
				currentGUIDs[applicant.clubFinderGUID]=true;
				if not GuildApplicantTrackerDB.knownGUIDs[applicant.clubFinderGUID]==nil then
					GuildApplicantTrackerDB.knownGUIDs[applicant.clubFinderGUID]=true;
					hasNewPlayer = true;
				end
				applicant.roles = specs2roles(applicant.specIds);
			end
		end

		-- prune knownGUIDs from old entries
		for clubFinderGUID in pairs(GuildApplicantTrackerDB.knownGUIDs) do
			if not currentGUIDs[clubFinderGUID] then
				GuildApplicantTrackerDB.knownGUIDs[clubFinderGUID] = nil;
			end
		end

		local num = #applicantList;
		local visible = GuildApplicantTracker:IsVisible();
		if hasNewPlayer then
			if GuildApplicantTracker:IsVisible() and num~=numApplicants then
				-- update scroll list
				GuildApplicantTracker.Scroll:update();
			elseif GuildApplicantTrackerDB.popupOnNew and not visible then
				-- popup on new players
				GuildApplicantTracker:Toggle(true);
			end
		elseif GuildApplicantTrackerDB.hideOnEmpty and num==0 and visible then
			-- hide on empty list
			GuildApplicantTracker:Toggle(false);
		end

		numApplicants = num;
		brokerText = num;
	end

	(libDataBroker:GetDataObjectByName(addon) or {}).text = C("dkyellow",brokerText);
end


--[[ libDataBroker & libDBIcon ]]
local function dataBrokerInit()
	if (libDataBroker) then
		local obj = libDataBroker:NewDataObject(addon, {
			type          = "data source",
			label         = L[addon],
			icon          = "Interface\\Icons\\Achievement_boss_cthun",
			--OnEnter       = nil,
			--OnLeave       = nil,
			OnClick       = function(self,button)
				if (button=="LeftButton") then
					GuildApplicantTracker:Toggle()
				elseif (button=="RightButton") then
					GuildApplicantTracker:ToggleOptions()
				end
			end,
			--OnDoubleClick = nil,
			OnTooltipShow = function(tt)
				tt:AddDoubleLine(addon,#applicantList);
				tt:AddLine(" ");
				for i=1, #applicantList do
					local localizedClass, englishClass, localizedRace, englishRace, sex, playerName, realm = GetPlayerInfoByGUID(applicantList[i].playerGUID);
					tt:AddDoubleLine(C(englishClass:upper(),applicantList[i].name),C("dkyellow",realm or GetRealmName()));
				end
				tt:AddLine(" ");
				tt:AddLine("|c"..colors.copper..L["TooltipHintLeftClick"]:gsub("#","\124r|||c"..colors.green).."|r");
				tt:AddLine("|c"..colors.copper..L["TooltipHintRightClick"]:gsub("#","\124r|||c"..colors.green).."|r");
			end
		})

		if (libDBIcon) then
			libDBIcon:Register(addon,obj,GuildApplicantTrackerDB.Minimap);
		end
	end
end


--[[ tooltip functions mixin ]]
GuildApplicantTrackerTooltipMixin = {};
function GuildApplicantTrackerTooltipMixin:OnEnter()
	if type(self.tooltip)=="table" then
		if (self.tooltip.point) then
			GameTooltip:SetOwner(self.tooltip.owner or self, "ANCHOR_NONE");
			GameTooltip:SetPoint(unpack(self.tooltip.point));
		else
			GameTooltip:SetOwner(self.tooltip.owner or self, self.tooltip.ownerAnchor or "ANCHOR_TOP");
		end
		if (self.tooltip.title) then
			GameTooltip:SetText(self.tooltip.title);
		end
		if (self.tooltip.lines) then
			for i,v in ipairs(self.tooltip.lines) do
				GameTooltip:AddLine(v,1,1,1,true);
			end
		end
		GameTooltip:Show();
	end
end

function GuildApplicantTrackerTooltipMixin:OnLeave()
	GameTooltip:Hide();
end


--[[ applicant list entry functions mixin ]]
GuildApplicantTrackerEntryMixin = {};
function GuildApplicantTrackerEntryMixin:RespondToApplicant(shouldInvite)
	local info = self.Info;
	if self.Info and self.Info.clubFinderGUID then
		C_ClubFinder.RespondToApplicant(self.Info.clubFinderGUID, self.Info.playerGUID, shouldInvite, Enum.ClubFinderRequestType.Guild, self.Info.name, false);
		C_Timer.After(1,updateApplicants);
	end
end

function GuildApplicantTrackerEntryMixin:OnClick(button)
	local localizedClass, englishClass, localizedRace, englishRace, sex, playerName, realm = GetPlayerInfoByGUID(self.Info.playerGUID);
	local playerName_realm = playerName.."-"..realm;
	if button=="LeftButton" then -- Whisper
		SetItemRef("player:"..playerName_realm,("|Hplayer:%1$s|h[%1$s]|h"):format(playerName_realm), button);
	end
end


--[[ applicant list functions mixin ]]
GuildApplicantTrackerListMixin = {}

local function buttonIconUpdate(button,icon,bool)
	if not button[icon] then return end
	if bool then
		button[icon]:SetAlpha(1);
		button[icon]:SetDesaturated(false);
	else
		button[icon]:SetAlpha(0.40);
		button[icon]:SetDesaturated(true);
	end
end

function GuildApplicantTrackerListMixin:update()
	local scroll = GuildApplicantTrackerContainer;
	local button, index, offset, nButtons, applicant;
	offset = HybridScrollFrame_GetOffset(scroll);
	nButtons = #scroll.buttons;
	local numApplicants = (applicantList and #applicantList) or 0;

	for i=1, nButtons do
		button = scroll.buttons[i];
		index = offset+i;
		applicant = applicantList and applicantList[index];

		if applicant then
			local localizedClass, englishClass, localizedRace, englishRace, sex, playerName, realm = GetPlayerInfoByGUID(applicant.playerGUID);

			button.Info = applicant;
			-- level
			button.Level:SetText(applicant.level);
			-- name
			button.Name:SetText(C(englishClass:upper(),applicant.name));
			-- realm
			button.Realm:SetText(realm);
			-- class icon
			button.Class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[englishClass]));
			-- tank role icon
			buttonIconUpdate(button,"bTank",applicant.roles.TANK);
			-- healer role icon
			buttonIconUpdate(button,"bHealer",applicant.roles.HEALER);
			-- damager role icon
			buttonIconUpdate(button,"bDamage",applicant.roles.DAMAGER);
			-- comment icon
			buttonIconUpdate(button,"bComment",applicant.message and applicant.message:trim()~="");

			local ttLines = {
				UNIT_TYPE_LEVEL_TEMPLATE:format(applicant.level, localizedClass),
				" ",
				CLUB_FINDER_SPECIALIZATIONS,
				(applicant.message and applicant.message:trim()~="") or C("gray",L["No comment..."])
			};

			if #applicant.specIds == 0 then
				tinsert(ttLines,C("red",CLUB_FINDER_APPLICANT_LIST_NO_MATCHING_SPECS));
			else
				for _, specID in ipairs(applicant.specIds) do
					tinsert(ttLines, CommunitiesUtil.GetRoleSpecClassLine(applicant.classID, specID));
				end
			end
			if applicant.message ~= "" then
				tinsert(ttLines," ");
				tinsert(ttLines,C("gray",CLUB_FINDER_CLUB_DESCRIPTION:format(applicant.message)));
			end

			button.tooltip = {
				title = C(englishClass,applicant.name),
				lines = ttLines,
				point = {"RIGHT",button,"LEFT",-2,0}
			};

			button.player = nil
			button:Show();
		else
			button.Info = nil;
			button.player = nil;
			button:Hide();
		end
	end

	local height = EntryHeight + EntryOffset;
	HybridScrollFrame_Update(scroll, numApplicants * height, nButtons * height);
end


--[[ tracker frame functions mixin ]]
function GuildApplicantTrackerMixin:ToggleOffline()
	ns.print("'View offline applicants' is no longer an option");
end

function GuildApplicantTrackerMixin:ToggleMinimap()
	GuildApplicantTrackerDB.Minimap.hide = not GuildApplicantTrackerDB.Minimap.hide;
	libDBIcon:Refresh(addon);
end

function GuildApplicantTrackerMixin:Toggle(state)
	if state==nil then
		state = not self:IsShown();
	end
	GuildApplicantTrackerDB.frameShow = state;
	self:SetShown(state);
end

function GuildApplicantTrackerMixin:ToggleOptions(snd)
	if snd then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end
	if ACD.OpenFrames[addon]~=nil then
		ACD:Close(addon);
	else
		ACD:Open(addon);
		ACD.OpenFrames[addon]:SetStatusText(GAME_VERSION_LABEL..": @project-version@");
	end
end

function GuildApplicantTrackerMixin:ResetSettings()
	GuildApplicantTrackerDB = CopyTable(db_defaults);
	C_UI.Reload();
end

function GuildApplicantTrackerMixin:ResetFrame()
	self:SetUserPlaced(false);
	self:ClearAllPoints();
	self:SetPoint("RIGHT",-30,2);
	self:SetUserPlaced(true);
end

function GuildApplicantTrackerMixin:OnShow()
	self.Scroll:update();
end

function GuildApplicantTrackerMixin:OnEvent(event,msg,...)
	local update = false;
	if (event=="ADDON_LOADED") and (msg==addon) then
		-- defaults checkup
		if GuildApplicantTrackerDB==nil then
			GuildApplicantTrackerDB = CopyTable(db_defaults);
		else
			for i,v in pairs(db_defaults) do
				if GuildApplicantTrackerDB[i]==nil then
					GuildApplicantTrackerDB[i] = v;
				end
			end
			-- remove deprecated entries
			GuildApplicantTrackerDB.viewOffline = nil;
			GuildApplicantTrackerDB.PopupIfOnlineApps = nil;
		end

		if GuildApplicantTrackerDB.showAddOnLoaded then
			ns.print(L["AddonLoaded"]);
		end
	elseif event=="PLAYER_LOGIN" or event=="GAT_DUMMY_EVENT" then
		guildClubId = C_Club.GetGuildClubId()
		if guildClubId == nil then
			C_Timer.After(0.314159,function()
				self:OnEvent("GAT_DUMMY_EVENT");
			end);
			return;
		end

		dataBrokerInit();
		aceOptionsInit();

		if C_ClubFinder.IsEnabled() then
			C_ClubFinder.RequestSubscribedClubPostingIDs();
			C_ClubFinder.RequestApplicantList(Enum.ClubFinderRequestType.Guild);
		end

		if GuildApplicantTrackerDB.frameShow then
			self:Show();
		end
	elseif event=="CLUB_FINDER_RECRUIT_LIST_CHANGED" or event=="CLUB_FINDER_RECRUITS_UPDATED" then -- triggered by C_ClubFinder.RequestApplicantList and C_ClubFinder.RequestSubscribedClubPostingIDs
		updateApplicants();
	end
end

function GuildApplicantTrackerMixin:OnLoad()
	if (not self) and (self~=_G['GuildApplicantTracker']) then return end

	HybridScrollFrame_CreateButtons(self.Scroll, "GuildApplicantTrackerEntryTemplate", 0, 0, nil, nil, 0, -EntryOffset);
	EntryHeight = self.Scroll.buttons[1]:GetHeight();
	self.Scroll:update();

	self.Config:SetScript("OnClick",function(self) optionMenu(self,"TOPRIGHT","BOTTOMRIGHT") end);
	self.Config.tooltip ={
		title = SETTINGS,
		lines = {L["OptionsButtonTooltip"]}, -- "Click to open option menu"
		point = {"BOTTOM",self.Config,"TOP",0,2}
	}
	self.Close.tooltip = {
		title = CLOSE,
		point = {"BOTTOM",self.Close,"TOP",0,2}
	};

	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", self.StartMoving);
	self:SetScript("OnDragStop",  self.StopMovingOrSizing);

	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_LOGIN");
	self:RegisterEvent("CLUB_FINDER_RECRUITS_UPDATED");
	self:RegisterEvent("CLUB_FINDER_RECRUIT_LIST_CHANGED");

	GuildApplicantTrackerMixin = nil;
end

--[[ Ace option panel ]]

local options = {
	type = "group",
	name = addon,
	get = function(info)
		local key = info[#info];
		if key=="minimap" then
			return not GuildApplicantTrackerDB.Minimap.hide;
		elseif type(GuildApplicantTrackerDB[key])=="table" then
			return unpack(GuildApplicantTrackerDB[key]); -- color table or multi select
		end
		return GuildApplicantTrackerDB[key];
	end,
	set = function(info,value,...)
		local key = info[#info];
		if key=="minimap" then
			GuildApplicantTrackerDB.Minimap.hide = not value;
			libDBIcon:Refresh(addon);
			return;
		end
		if (...) then
			value = {value,...}; -- color table or multi select
		end
		GuildApplicantTrackerDB[key] = value;
	end,
	func = function(info)
		local key = info[#info];
		if key=="resetFrame" then
			GuildApplicantTracker:ResetFrame();
		elseif key=="resetConfig" then
			GuildApplicantTracker:ResetSettings();
		end
	end,
	args = {
		generalHeader = {
			type = "header", order = 0,
			name = GENERAL
		},
		showAddonLoaded = {
			type = "toggle", order = 1, width = "double",
			name = L["AddOnLoaded"], desc = L["AddOnLoadedDesc"]
		},
		minimap = {
			type = "toggle", order = 2, width = "double",
			name = L["MinimapButton"], desc = L["MinimapButtonDesc"]
		},
		popupOnNew = {
			type = "toggle", order = 3, width = "double",
			name = L["PopupOnNew"], desc = L["PopupOnNewDesc"]
		},
		resetHeader = {
			type = "header", order = 10,
			name = L["ResetOptions"]
		},
		resetFrame = {
			type = "execute", order = 11,
			name = L["ResetFrame"], desc = L["ResetFrameDesc"]
		},
		resetConfig = {
			type = "execute", order = 12,
			name = L["ResetSettings"], desc = L["ResetSettingsDesc"]
		}
	}
};

function aceOptionsInit()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addon, options);
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon);
end
