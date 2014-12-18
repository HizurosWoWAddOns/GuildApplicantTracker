
--[[
	Name: GuildApplicantTracker
	Author: Hizuro (hizuro at gmx.net)
	License: GPL 2.0
]]

-- SavedVariables
GuildApplicantTrackerDB = {}

-- Libs
local libColors = LibStub("LibColors-1.0");
local libDataBroker = LibStub("LibDataBroker-1.1");
local libDBIcon = LibStub("LibDBIcon-1.0");

-- Local variables
local addon, ns = ...;
local L = ns.L;
local C = libColors.color;
local applicants = {online={},offline={},names={}};
local GetFriendInfo,GetGuildApplicantInfo = GetFriendInfo,GetGuildApplicantInfo;
local AddOrRemoveFriend,RemoveFriend = AddOrRemoveFriend,RemoveFriend;
local currentRealm = gsub(GetRealmName()," ","");
local _print = print;
local Pattern = {};
local EntryHeight = nil;
local EntryOffset = 2;
local Enabled = true;
local new = {};
local DoAddNew = false;
local db_defaults = {
	viewOffline       = false,
	Minimap           = {enabled=true},
	frameShow         = true,
	--frameLock         = true,
	--frameDock         = false,
}

-- predeclare local function names...
local Tracker_Update


--[[ miac functions ]]
local function print(...)
	local args,colors,result = {...},{"ff44ff44","ff44aaff","ffffff44","ffff44ff","ffff8833"},{"|cffff4444"..addon.."|r:"}
	for i,v in ipairs(args) do tinsert(result,C((colors[i] or "ffffffff"),tostring(v))) end
	_print(unpack(result));
end

local function whisperToApplicant(self,button)
	if (not self.player) or (button~="LeftButton") then return; end
	SetItemRef("player:"..self.player,("|Hplayer:%1$s|h[%1$s]|h"):format(self.player), "LeftButton");
end

local function applicantInfoToTable(i,na,le,cl,bQu,bDu,bRa,bPv,bRP,bWd,bWe,bTa,bHe,bDa,co,ts,tl,re)
	na, re = strsplit("-",na);
	if (not re) then re = currentRealm; end
	return{index=i,name=na,realm=re, name_realm=na.."-"..gsub(re," ",""), level=le,class=cl,bQuest=bQu,bDungeon=bDu,bRaid=bRa,
			bPvP=bPv,bRP=bRP,bWeekdays=bWd,bWeekends=bWe,bTank=nTa,bHealer=bHe,bDamage=bDa,
			comment=co,timesince=ts,timeleft=tl,bNotes=(strlen(co)>0),bFriend=false,bOnline=false};
end

local function addToFriendList()
	if (DoAddNew) then
		for i,v in pairs(new) do
			if (v==true) then
				print((L["Adding applicant %s to your friendlist."]):format(i));
				AddOrRemoveFriend(i,"[GuildApplicant]");
				new[i] = false;
			end
		end
		wipe(new);
		DoAddNew = false;
	end
end

local function chkChatMsg(msg)
	local name;
	for i,v in pairs(Pattern) do
		name = msg:match(v);
		-- %|Hplayer:%%s%|h%[%%s%]%|h
		if (name) then
			return i, name;
		end
	end
	return false;
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
				GuildApplicantTracker_Toggle()
			end,
			--OnDoubleClick = nil,
			OnTooltipShow = function(self)
				self:AddDoubleLine(L[addon],("%s/%s"):format(C("green",#applicants.online),GetNumGuildApplicants()))
				self:AddLine(" ")
				for i,v in ipairs(applicants.online) do
					local realm = "";
					if (currentRealm~=v.realm) then realm = "("..v.realm..")"; end
					self:AddDoubleLine(v.level.." "..C(v.class,v.name)..realm, C("green",GUILD_ONLINE_LABEL))
				end
				if (#applicants.online>0) and (#applicants.offline>0) then
					self:AddLine(" ")
				end
				for i,v in ipairs(applicants.offline) do
					self:AddDoubleLine(v.level.." "..C(v.class,v.name), PLAYER_OFFLINE)
				end
			end
		})

		if (libDBIcon) then
			libDBIcon:Register(L[addon],obj,GuildApplicantTrackerDB.Minimap)
			if (not GuildApplicantTrackerDB.Minimap.enabled) then
				libDBIcon:Hide(L[addon]);
			end
		end
	end
end


--[[ Static Popups ]]
StaticPopupDialogs["GUILDAPPLICANTTRACKER_INVITE"] = {
	text = "",
	button1 = INVITE,
	button2 = CANCEL,
	OnShow = function(self, data)
		self.text:SetText(L["You want to invite %s into this guild?"]:format(data))
	end,
	OnAccept = function(self, data)
		GuildInvite(data)
	end,
	OnHide = function(self)
		self.data = nil
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["GUILDAPPLICANTTRACKER_DECLINE"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self, data)
		self.text:SetText(L["Do you really want to decline %s's guild application?"]:format(data))
	end,
	OnAccept = function(self,data)
		for i=1, GetNumGuildApplicants() do
			local name = GetGuildApplicantInfo(i);
			if (not name:find("-")) then name = name.."-"..currentRealm; end
			if (name == data) then
				DeclineGuildApplicant(i);
				return;
			end
		end
	end,
	OnHide = function(self)
		self.data = nil
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

local function Tracker_Invite(self)
	local x = self:GetParent().player;
	-- 5 times... its no longer save in 6.0 which param transport into the popup as "self.data"
	StaticPopup_Show("GUILDAPPLICANTTRACKER_INVITE",x,x,x,x,x);
end

local function Tracker_Decline(self)
	local x = self:GetParent().player;
	StaticPopup_Show("GUILDAPPLICANTTRACKER_DECLINE",x,x,x,x,x);
end


--[[ update function ]]
local function Lists_Update()
	local _,name,online,note,level,class,bQuest,bDungeon,bRaid,bPvP,bRP,bWeekdays,bWeekends,bTank,bHealer,bDamage,comment,timesince,timeleft

	local friends = {};
	for i=1, GetNumFriends() do
		name,_,_,_,online,_,note = GetFriendInfo(i);
		if (name) then
			if (not name:find("-")) then name = name.."-"..currentRealm; end
			friends[name] = { (note~=nil and note:find("%[GuildApplicant%]")==1) , online };
		end
	end

	local _applicants = {online={},offline={},names={}};
	local add = false;

	for i=1, GetNumGuildApplicants() do
		tmp = applicantInfoToTable(i, GetGuildApplicantInfo(i));
		if (friends[tmp.name_realm]) then
			tmp.bFriend=true;
			if (friends[tmp.name_realm][2]==true) then
				tmp.bOnline=true;
			end
			friends[tmp.name_realm] = nil;
		else
			new[tmp.name_realm] = true;
			DoAddNew = true;
		end
		tinsert(_applicants[(tmp.bOnline) and "online" or "offline"],tmp);
		_applicants.names[tmp.name_realm] = true;
	end

	for i,v in pairs(friends) do
		if (v~=nil) and (v[1]==true) then
			RemoveFriend(gsub(i,"-"..currentRealm,""));
		end
	end

	applicants = _applicants;

	if (libDataBroker) then
		local obj = libDataBroker:GetDataObjectByName(addon)
		obj.text = ("%s/%s"):format(C("green",#applicants.online),GetNumGuildApplicants());
	end
end


--[[ tooltip functions ]]
function GuildApplicantTrackerTooltip_OnEnter(self)
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

function GuildApplicantTrackerTooltip_OnLeave()
	GameTooltip:Hide();
end


--[[ global control functions ]]
function GuildApplicantTracker_ToggleOffline(self,button)
	GuildApplicantTrackerDB.viewOffline = self:GetChecked();
	Tracker_Update();
end

function GuildApplicantTracker_ToggleMinimap()
	if (GuildApplicantTrackerDB.Minimap.enabled) then
		GuildApplicantTrackerDB.Minimap.enabled = false;
		libDBIcon:Hide(L[addon]);
	else
		GuildApplicantTrackerDB.Minimap.enabled = true;
		libDBIcon:Show(L[addon]);
	end
end

function GuildApplicantTracker_Toggle(self,button)
	if (GuildApplicantTrackerFrame:IsShown()) then
		GuildApplicantTrackerFrame:Hide();
		GuildApplicantTrackerDB.frameShow = false;
	else
		GuildApplicantTrackerFrame:Show();
		GuildApplicantTrackerDB.frameShow = true;
	end
end

function GuildApplicantTracker_Reset()
	GuildApplicantTrackerDB = db_defaults;
end


--[[ trackerframe functions ]]
function Tracker_Update()
	local scroll = GuildApplicantTrackerContainer;
	local button, index, offset, nButtons, nOnline, applicant;
	offset = HybridScrollFrame_GetOffset(scroll);
	nButtons = #scroll.buttons;
	nOnline = #applicants.online;

	for i=1, nButtons do
		button = scroll.buttons[i];
		index = offset+i;

		applicant=nil;
		if (applicants.online[index]) then
			applicant = applicants.online[index];
		elseif (applicants.offline[index-nOnline]) and (GuildApplicantTrackerDB.viewOffline) then
			applicant = applicants.offline[index-nOnline];
		end

		if (applicant) then
			-- level
			button.Level:SetText(applicant.level);
			-- name
			button.Name:SetText(C(applicant.class,applicant.name));
			-- realm
			button.Realm:SetText(applicant.realm);
			-- class icon
			button.Class:SetTexCoord(unpack(CLASS_BUTTONS[applicant.class]));
			-- selected icons
			for _,v in ipairs({"bTank","bHealer","bDamage","bNotes","bPvP","bRaid","bDungeon","bQuest" --[[,"bRP","bWeekdays","bWeekends"]]}) do
				if (button[v]) then
					local tex = button[v]:GetTexture()
					if (applicant[v]) then
						tex = gsub(tex,"Deselected","Selected");
						button[v]:SetAlpha(1);
					else
						tex = gsub(tex,"Selected","Deselected");
						button[v]:SetAlpha(0.35);
					end
					button[v]:SetTexture(tex);
				end
			end

			if (applicant.bOnline) then
				button.Status:Hide();
				button.Invite:Show();
				button:SetScript("OnClick",whisperToApplicant);
			else
				button.Status:SetText("("..C("white","Offline")..")");
				button.Status:Show();
				button.Invite:Hide();
				button:SetScript("OnClick",nil);
			end
			button.Invite:SetScript("OnClick",Tracker_Invite);
			button.Decline:SetScript("OnClick",Tracker_Decline);

			button.tooltip = {
				title = C(applicant.class,applicant.name),
				lines = { (applicant.bNotes) and applicant.comment or C("gray",L["No comment..."])},
				point = {"RIGHT",button,"LEFT",-2,0}
			};

			button.player = applicant.name_realm; -- for whisperToApplicant, Tracker_Invite and Tracker_Decline
			button:Show();
		else
			button:Hide();
		end
	end

	local visibleEntries = #applicants.online;
	if (GuildApplicantTrackerDB.viewOffline) then
		visibleEntries = visibleEntries + #applicants.offline;
	end
	local height = EntryHeight + EntryOffset;
	HybridScrollFrame_Update(scroll, visibleEntries * height, nButtons * height);
end

local function Tracker_OnEvent(self, event, msg, ...)
	local update = false;
	if (event=="ADDON_LOADED") and (msg==addon) then
		print(L["Addon loaded..."]);
	elseif (event=="PLAYER_ENTERING_WORLD") then
		-- defaults checkup
		for i,v in pairs(db_defaults) do
			if (GuildApplicantTrackerDB[i]==nil) then
				GuildApplicantTrackerDB[i] = v;
			end
		end

		-- databroker & minimap
		dataBrokerInit();

		-- view offline state
		self.Offline:SetChecked(GuildApplicantTrackerDB.viewOffline);

		-- unset event
		self:UnregisterEvent(event);

		-- set events
		self:RegisterEvent("LF_GUILD_RECRUITS_UPDATED");
		self:RegisterEvent("CHAT_MSG_SYSTEM");
		self:RegisterEvent("FRIENDLIST_UPDATE");

--	elseif event=="PLAYER_ENTERING_WORLD" then
		if (not IsInGuild()) then
			print(L["Addon inactive."],L["You are not in a guild."]);
			Enabled = false;
		elseif (not CanGuildInvite()) then
			print(L["Addon inactive."],L["You can not invite players."]);
			Enabled = false;
		end
		if (Enabled) and (GuildApplicantTrackerDB.frameShow) then
			self:Show();
		end
	elseif (Enabled) and (event=="LF_GUILD_RECRUITS_UPDATED" or event=="FRIENDLIST_UPDATE") then
		update = true;
	elseif (Enabled) and event=="CHAT_MSG_SYSTEM" then
		local pattern,name = chkChatMsg(msg);
		if (name) and (not applicants.names[name]) then
			-- ignore
		elseif (pattern=="ERR_FRIEND_ONLINE_SS") then
			update = true;
		elseif (pattern=="ERR_FRIEND_OFFLINE_S") then
			update = true;
		elseif (pattern=="ERR_GUILD_INVITE_S") then
			update = true;
		elseif (pattern=="ERR_GUILD_DECLINE_AUTO_S") then
			print(L["Warning:"],name,L["has decline your invitation automaticly (by interface option)..."]);
		elseif (pattern=="ERR_GUILD_DECLINE_S") then
			print(L["Warning:"],name,L["has decline your invitation..."]);
		elseif (pattern=="ERR_GUILD_JOIN_S") then
			update = true;
		elseif (pattern=="ERR_FRIEND_ADDED_S") then
			update = true;
		end
	end
	if (update) then
		Lists_Update();
		Tracker_Update();
	end
end

local function Tracker_OnShow()
	--Lists_Update();
	Tracker_Update();
end

local Tracker_OnUpdate;
do
	local eclipsed = 0;
	function Tracker_OnUpdate(self,eclipse)
		eclipsed = eclipsed + eclipse;
		if (eclipsed>0) then
			eclipsed = 0;
			if (DoAddNew) then
				addToFriendList();
			end
		end
	end
end

function GuildApplicantTracker_OnLoad(self)
	if (not self) and (self~=_G['GuildApplicantTrackerFrame']) then return end

	for _,v in ipairs({"ERR_FRIEND_ONLINE_SS","ERR_FRIEND_OFFLINE_S","ERR_FRIEND_REMOVED_S","ERR_GUILD_INVITE_S",
		"ERR_GUILD_DECLINE_AUTO_S","ERR_GUILD_DECLINE_S","ERR_GUILD_JOIN_S","ERR_FRIEND_ADDED_S"}) do
		Pattern[v] = strtrim(gsub(gsub(_G[v],"%|Hplayer:%%s%|h%[%%s%]%|h",".*%%[(.+)%%].*"),"%%s","(.+)"))
	end

	self.Scroll.update = Tracker_Update;
	HybridScrollFrame_CreateButtons(self.Scroll, "GuildApplicantTrackerEntryTemplate", 0, 0, nil, nil, 0, -EntryOffset);
	EntryHeight = self.Scroll.buttons[1]:GetHeight();
	if (select(4,GetBuildInfo())<60000) then
		self.Scroll.buttons[2]:SetPoint("TOPLEFT",self.Scroll.buttons[1],"BOTTOMLEFT",1,(-EntryOffset) - 1)
	end

	self.Offline.tooltip = {
		title = PLAYER_OFFLINE,
		lines = {L["Show/Hide offline applicants."]},
		point = {"BOTTOM",self.Offline,"TOP",0,2}
	};
	self.Close.tooltip = {
		title = CLOSE,
		lines = {L["Close %s."]:format(addon)},
		point = {"BOTTOM",self.Close,"TOP",0,2}
	};

	self:SetScript("OnShow", Tracker_OnShow);
	self:SetScript("OnEvent", Tracker_OnEvent);
	self:SetScript("OnUpdate", Tracker_OnUpdate);

	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
end
