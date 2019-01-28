
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
local libDropDownMenu = LibStub("LibDropDownMenu");

-- Local variables
local addon, ns = ...;
local L = ns.L;
local C = libColors.color;
local Update={doIt=false,active=false,ticker_extra_timeout=false};
local UpdateFrame = false;
local applicants = {online={},offline={},names={}};
local GetFriendInfo,GetGuildApplicantInfo = GetFriendInfo,GetGuildApplicantInfo;
local AddOrRemoveFriend,RemoveFriend = AddOrRemoveFriend,RemoveFriend;
local currentRealm = gsub(GetRealmName()," ","");
local Pattern = {};
local EntryHeight,optionMenu;
local EntryOffset = 2;
local Enabled = nil;
local new,State = {},{};
local name_realm, level, class, bQuest, bDungeon, bRaid, bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer, bDamage, comment, timeSince, timeLeft = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16; -- index list for GetGuildApplicantInfo
local name, realm, bComment, bFriend, bOnline = 17,18,19,20,21; -- add by applicantInfoToTable()
local DoAddNew = false;
local db_defaults = {
	showAddonLoaded = true,
	viewOffline       = false,
	Minimap           = {hide=false},
	frameShow         = true,
	PopupIfOnlineApps  = true,
	--frameLock         = true,
	--frameDock         = false,
}


--[[ misc functions ]]
function ns.print(...)
	local colors,t,c = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"},{},1;
	for i,v in ipairs({...}) do
		v = tostring(v);
		if i==1 and v~="" then
			tinsert(t,"|cff0099ff"..addon.."|r:"); c=2;
		end
		if not v:match("||c") then
			v,c = "|cff"..colors[c]..v.."|r", c<#colors and c+1 or 1;
		end
		tinsert(t,v);
	end
	print(unpack(t));
end

local debugMode = "@project-version@"=="@".."project-version".."@";
function ns.debug(...)
	if debugMode then
		ns.print("<debug>",...);
	end
end

local function whisperToApplicant(self,button)
	if (not self.player) or (button~="LeftButton") then return; end
	SetItemRef("player:"..self.player,("|Hplayer:%1$s|h[%1$s]|h"):format(self.player), "LeftButton");
end

local function GetGuildApplicantInfoExtended(index)
	local data = {GetGuildApplicantInfo(index)};
	local n,r=strsplit("-",data[name_realm]);
	if (not r) then
		r=currentRealm;
		data[name_realm] = n.."-"..r;
	end
	tinsert(data,n); -- [17]
	tinsert(data,r); -- [18]
	tinsert(data, data[comment] and strlen(data[comment])>0); -- [19]
	tinsert(data,false); -- [20]
	tinsert(data,false); -- [21]
	return data;
end

local function addToFriendList()
	if (DoAddNew) then
		if not Update.InfoMsgPosted then
			ns.print(L["Adding applicants to your friend list to track their online status."]);
			Update.InfoMsgPosted=true;
		end
		local tmp,count,added={},0;
		for i,v in pairs(new) do
			if added==nil then
				AddOrRemoveFriend(i,"[GuildApplicant]");
				added = i;
			else
				tmp[i]=v;
				count=count+1;
			end
		end
		new = tmp;
		if count==0 then
			wipe(new);
			DoAddNew = false;
			Update.InfoMsgPosted=false;
		end
		Update.timer_extra_timeout = 2;
		Update.doIt=true;
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
				if (button=="LeftButton") then
					GuildApplicantTracker_Toggle()
				elseif (button=="RightButton") then
					optionMenu(self,"TOP","BOTTOM");
				end
			end,
			--OnDoubleClick = nil,
			OnTooltipShow = function(self)
				self:AddDoubleLine(L[addon],("%s/%s"):format(C("green",#applicants.online),GetNumGuildApplicants()))

				if (#applicants.online>0) then
					self:AddLine(" ")
					for i,v in ipairs(applicants.online) do
						local _realm = "";
						if (currentRealm~=v[realm]) then _realm = "("..v[realm]..")"; end
						self:AddDoubleLine(v[level].." "..C(v[class],v[name]).._realm, C("green",GUILD_ONLINE_LABEL))
					end
				end

				if (#applicants.offline>0) then
					self:AddLine(" ")
					for i,v in ipairs(applicants.offline) do
						self:AddDoubleLine(v[level].." "..C(v[class],v[name]), PLAYER_OFFLINE)
					end
				end

				if (#applicants.online==0) and (#applicants.offline==0) then
					self:AddLine(" ");
					self:AddLine(L["Currently no applicants found"]);
				end

				self:AddLine(" ");
				self:AddDoubleLine(L["Left-click || to toggle tracker frame"]);
				self:AddDoubleLine(L["Right-click || to open option menu"]);
			end
		})

		if (libDBIcon) then
			libDBIcon:Register(addon,obj,GuildApplicantTrackerDB.Minimap);
		end
	end
end


--[[ Static Popups ]]
StaticPopupDialogs["GUILDAPPLICANTINVITE"] = {
	text = "",
	button1 = INVITE,
	button2 = CANCEL,
	OnShow = function(self)
		self.text:SetText(L["You want to invite %s into this guild?"]:format(self.data))
	end,
	OnAccept = function(self)
		GuildInvite(self.data)
	end,
	OnHide = function(self)
		self.data = nil
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["GUILDAPPLICANTDECLINE"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self)
		self.text:SetText(L["Do you really want to decline %s's guild application?"]:format(self.data))
	end,
	OnAccept = function(self)
		for i=1, GetNumGuildApplicants() do
			local name = GetGuildApplicantInfo(i);
			if (not name:find("-")) then name = name.."-"..currentRealm; end
			if (name == self.data) then
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

local function GuildApplicantTracker_Invite(self)
	local name = self:GetParent().player;
	-- 5 times... its no longer save in 6.0 which param transport into the popup as "self.data"
	StaticPopup_Show("GUILDAPPLICANTINVITE",nil,nil,name);
end

local function GuildApplicantTracker_Decline(self)
	local name = self:GetParent().player;
	StaticPopup_Show("GUILDAPPLICANTDECLINE",nil,nil,name);
end


--[[ update function ]]
local function Lists_Update()
	local _,tmp

	local friends,numFriends,_,fName,fOnline,fNote = {},GetNumFriends();
	for i=1, numFriends do
		local fName,_,_,_,fOnline,_,fNote = GetFriendInfo(i);
		if (fName) then
			if (not fName:find("-")) then fName = fName.."-"..currentRealm; end
			friends[fName] = { (fNote~=nil and fNote:find("%[GuildApplicant%]")==1) , fOnline };
		end
	end

	local _applicants = {online={},offline={},names={}};
	local add = false;

	for i=1, GetNumGuildApplicants() do
		tmp = GetGuildApplicantInfoExtended(i);
		if (friends[tmp[name_realm]]) then
			tmp[bFriend]=true;
			if (friends[tmp[name_realm]][2]==true) then
				tmp[bOnline]=true;
			end
			friends[tmp[name_realm]] = nil;
		else
			new[tmp[name_realm]] = true;
			DoAddNew = true;
			Update.doIt=true;
		end
		tinsert(_applicants[(tmp[bOnline]) and "online" or "offline"],tmp);
		_applicants.names[tmp[name_realm]] = true;
	end

	for i,v in pairs(friends) do
		if (v~=nil) and (v[1]==true) then
			RemoveFriend(gsub(i,"-"..currentRealm,""));
		end
	end

	applicants = _applicants;

	if(#applicants.online>0 and GuildApplicantTrackerDB.PopupIfOnlineApps)then
		GuildApplicantTracker:Toggle(true);
	end

	if (libDataBroker) then
		local obj = libDataBroker:GetDataObjectByName(addon)
		obj.text = ("%s/%s"):format(C("green",#applicants.online),GetNumGuildApplicants());
	end

	GuildApplicantTracker:ListUpdate();
end


--[[ tooltip functions ]]
GuildApplicantTrackerTooltipMixin = {};
function GuildApplicantTrackerTooltipMixin:OnEnter(self)
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

--[[ option menu ]]
local separator = { text="", dist=0, isTitle=true, notCheckable=true, isNotRadio=true, sUninteractable=true, iconOnly=true, icon="Interface\\Common\\UI-TooltipDivider-Transparent", tCoordLeft=0, tCoordRight=1, tCoordTop=0, tCoordBottom=1, tFitDropDownSizeX=true, tSizeX=0, tSizeY=8, iconInfo={tCoordLeft=0, tCoordRight=1, tCoordTop=0, tCoordBottom=1, tFitDropDownSizeX=true, tSizeX=0, tSizeY=8} };
local MenuList,MenuFrame = {
	{ text = SETTINGS, isTitle=true, isNotRadio = true, notCheckable = true },
	separator,
	{ text = L["Show/Hide GuildApplicantTracker"], func = GuildApplicantTracker_Toggle, isNotRadio = true, notCheckable = true },
	separator,
	{ text = L["Show minimap button"], tooltipTitle = L["Minimap"], tooltipText = L["Show or hide minimap button"], checked = function() return not GuildApplicantTrackerDB.Minimap.hide; end, func = GuildApplicantTracker_ToggleMinimap, isNotRadio = true, notCheckable = true },
	{ text = L["Show offline applicants"], tooltipTitle = L["Offline applicants"], tooltipText = L["Show or hide offline applicants"], checked = function() return GuildApplicantTrackerDB.viewOffline; end, func = GuildApplicantTracker_ToggleOffline, isNotRadio = true, notCheckable = true },
	{ text = L["Popup frame if applicant online"], checked = function() return GuildApplicantTrackerDB.PopupIfOnlineApps; end, func = function() GuildApplicantTrackerDB.PopupIfOnlineApps = not GuildApplicantTrackerDB.PopupIfOnlineApps; end, isNotRadio = true, notCheckable = true },
	separator,
	{ text = L["Reset frame position"], tooltipTitle = L["Reset frame position"], tooltipText = L["If the frame out of screen, you can reset its position with this option"], func = GuildApplicantTracker_ResetFrame, isNotRadio = true, notCheckable = true },
	{ text = L["Reset addon settings"], func = GuildApplicantTracker_Reset, isNotRadio = true, notCheckable = true },
};

function optionMenu(parent,point,relativePoint)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	if not MenuFrame then
		MenuFrame = libDropDownMenu.Create_DropDownMenu("GuildApplicantTracker_LibDropDownMenu",UIParent);
	end
	MenuFrame.point = point or "TOPLEFT";
	MenuFrame.relativePoint = relativePoint or "BOTTOMLEFT";
	libDropDownMenu.EasyMenu(MenuList, MenuFrame, parent, 0, 0, "MENU");
end

--[[ tracker frame functions ]]
GuildApplicantTrackerMixin = {};

function GuildApplicantTrackerMixin:ToggleOffline(button)
	GuildApplicantTrackerDB.viewOffline = not GuildApplicantTrackerDB.viewOffline;
	GuildApplicantTracker:ListUpdate();
end

function GuildApplicantTrackerMixin:ToggleMinimap()
	GuildApplicantTrackerDB.Minimap.hide = not GuildApplicantTrackerDB.Minimap.hide;
	libDBIcon:Show(addon);
end

function GuildApplicantTrackerMixin:Toggle(state)
	if state==nil then
		state = not GuildApplicantTracker:IsShown();
	end
	GuildApplicantTracker:SetShown(state);
	GuildApplicantTrackerDB.frameShow = state;
end

function GuildApplicantTrackerMixin:ToggleOption(key,force)
	if force~=nil then
		GuildApplicantTrackerDB[key] = force;
	else
		GuildApplicantTrackerDB[key] = not GuildApplicantTrackerDB[key];
	end
	return GuildApplicantTrackerDB[key];
end

function GuildApplicantTrackerMixin:Reset()
	GuildApplicantTrackerDB = db_defaults;
end

function GuildApplicantTrackerMixin:ResetFrame()
	local f=GuildApplicantTracker;
	f:SetUserPlaced(false);
	f:ClearAllPoints();
	f:SetPoint("RIGHT",-30,2);
	f:SetUserPlaced(true);
end

function GuildApplicantTrackerMixin:ListUpdate()
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
			button.Level:SetText(applicant[level]);
			-- name
			button.Name:SetText(C(applicant[class],applicant[name]));
			-- realm
			button.Realm:SetText(applicant[realm]);
			-- class icon
			button.Class:SetTexCoord(unpack(CLASS_ICON_TCOORDS[applicant[class]]));
			-- selected icons
			for key,Index in pairs({bTank=bTank,bHealer=bHealer,bDamage=bDamage,bComment=bComment,bPvP=bPvP,bRaid=bRaid,bDungeon=bDungeon,bQuest=bQuest --[[,bRP=bRP,bWeekdays=bWeekdays,bWeekends=bWeekends]]}) do
				if (button[key]) then
					if (applicant[Index]) then
						button[key]:SetAlpha(1);
						button[key]:SetDesaturated(false);
					else
						button[key]:SetAlpha(0.40);
						button[key]:SetDesaturated(true);
					end
				end
			end

			if Enabled then
				if (applicant[bOnline]) then
					button.Status:Hide();
					button.Invite:Show();
					button:SetScript("OnClick",whisperToApplicant);
				else
					button.Status:SetText("("..C("white","Offline")..")");
					button.Status:Show();
					button.Invite:Hide();
					button:SetScript("OnClick",nil);
				end
				button.Invite:SetScript("OnClick",GuildApplicantTracker_Invite);
				button.Decline:SetScript("OnClick",GuildApplicantTracker_Decline);
			else
				button.Status:Hide();
				button.Invite:Hide();
				button.Invite:SetScript("OnClick",nil);
				button.Decline:SetScript("OnClick",nil);
			end

			button.tooltip = {
				title = C(applicant[class],applicant[name]),
				lines = { (applicant[bComment]) and applicant[comment] or C("gray",L["No comment..."])},
				point = {"RIGHT",button,"LEFT",-2,0}
			};

			button.player = applicant[name_realm]; -- for whisperToApplicant, GuildApplicantTracker_Invite and GuildApplicantTracker_Decline
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

function GuildApplicantTrackerMixin:OnShow()
	Update.doIt=true;
end

local function GuildApplicantTracker_Ticker()
	if Update.doIt==true then
		if Update.ticker_extra_timeout~=false then
			Update.ticker_extra_timeout=Update.ticker_extra_timeout-1;
			if Update.ticker_extra_timeout<=0 then
				Update.ticker_extra_timeout = false;
			end
			return nil;
		end
		if(DoAddNew)then
			addToFriendList();
		else
			Lists_Update();
		end
	end
end

function GuildApplicantTrackerMixin:OnEvent(event,msg,...)
	local update = false;
	if (event=="ADDON_LOADED") and (msg==addon) then
		-- defaults checkup
		if GuildApplicantTrackerDB==nil then
			GuildApplicantTrackerDB = CopyTable(db_defaults);
		else
			if GuildApplicantTrackerDB.Minimap and GuildApplicantTrackerDB.Minimap.enabled~=nil then
				GuildApplicantTrackerDB.Minimap.hide = not GuildApplicantTrackerDB.Minimap.enabled;
				GuildApplicantTrackerDB.Minimap.enabled=nil
			end
			for i,v in pairs(db_defaults) do
				if (GuildApplicantTrackerDB[i]==nil) then
					GuildApplicantTrackerDB[i] = v;
				end
			end
		end

		-- prepare pattern strings
		for _,v in ipairs({"ERR_FRIEND_ONLINE_SS","ERR_FRIEND_OFFLINE_S","ERR_FRIEND_REMOVED_S","ERR_GUILD_INVITE_S",
			"ERR_GUILD_DECLINE_AUTO_S","ERR_GUILD_DECLINE_S","ERR_GUILD_JOIN_S","ERR_FRIEND_ADDED_S"}) do
			if(_G[v]:find("\12Hplayer"))then
				Pattern[v] = strtrim(gsub(_G[v],"%[%%s%]","%%[(%%s+)%%]"));
			else
				Pattern[v] = strtrim(gsub(_G[v],"%%s","(%%s+)"))
			end
		end

		Update.timer_extra_timeout = 3; -- for 3. fallback C_Timer.After

		if GuildApplicantTrackerDB.showAddOnLoaded then
			ns.print(L["Addon loaded..."]);
		end
	elseif (event=="PLAYER_LOGIN") then
		-- databroker & minimap
		dataBrokerInit();

		-- set events
		self:RegisterEvent("LF_GUILD_RECRUITS_UPDATED");
		self:RegisterEvent("CHAT_MSG_SYSTEM");
		self:RegisterEvent("FRIENDLIST_UPDATE");
		self:RegisterEvent("GUILD_RANKS_UPDATE");

		if GuildApplicantTrackerDB.frameShow then
			self:Show();
		end

		C_Timer.NewTicker(1, GuildApplicantTracker_Ticker);

		RequestGuildRecruitmentSettings();
		RequestGuildApplicantsList();
	elseif event=="LF_GUILD_RECRUIT_LIST_CHANGED" then
		RequestGuildApplicantsList();
	elseif event=="GUILD_RANKS_UPDATE" then
		if not IsInGuild() and State.IsInGuild~=false then
			if Enabled then
				ns.print(L["Invite function disabled"],"("..L["You've left the guild."]..")");
			else
				ns.print(L["Invite function disabled"],"("..L["You are not in a guild."]..")");
			end
			State.IsInGuild = false;
			Enabled = false;
		elseif not CanGuildInvite() and State.CanGuildInvite~=false then
			if Enabled then
				ns.print(L["Invite function disabled"],"("..L["You've lost the right to invite players."]..")");
			else
				ns.print(L["Invite function disabled"],"("..L["You've not the right to invite players."]..")");
			end
			State.CanGuildInvite = false;
			Enabled = false;
		elseif IsInGuild() and CanGuildInvite() then
			Enabled = true;
			State.IsInGuild = true;
			State.CanGuildInvite = true;
		end
	elseif event=="LF_GUILD_RECRUITS_UPDATED" or event=="FRIENDLIST_UPDATE" then
		update = true;
	elseif event=="CHAT_MSG_SYSTEM" then
		local pattern,name = chkChatMsg(msg);
		if name and applicants.names[name] then
			if pattern=="ERR_FRIEND_ONLINE_SS" or pattern=="ERR_FRIEND_OFFLINE_S" or pattern=="ERR_GUILD_INVITE_S" or pattern=="ERR_GUILD_JOIN_S" or pattern=="ERR_FRIEND_ADDED_S" then
				update = true;
			elseif (pattern=="ERR_GUILD_DECLINE_AUTO_S") then
				ns.print(L["Warning:"],name,L["has decline your invitation automaticly (by interface option)..."]);
			elseif (pattern=="ERR_GUILD_DECLINE_S") then
				ns.print(L["Warning:"],name,L["has decline your invitation..."]);
			end
		end
	end
	if (update) then
		Update.doIt=true;
	end
end

function GuildApplicantTrackerMixin:OnLoad()
	if (not self) and (self~=_G['GuildApplicantTracker']) then return end

	self.Scroll.update = GuildApplicantTrackerMixin.ListUpdate;
	HybridScrollFrame_CreateButtons(self.Scroll, "GuildApplicantTrackerEntryTemplate", 0, 0, nil, nil, 0, -EntryOffset);
	EntryHeight = self.Scroll.buttons[1]:GetHeight();
	if (select(4,GetBuildInfo())<60000) then
		self.Scroll.buttons[2]:SetPoint("TOPLEFT",self.Scroll.buttons[1],"BOTTOMLEFT",1,(-EntryOffset) - 1)
	end
	self:ListUpdate();

	self.Config:SetScript("OnClick",function(self) optionMenu(self,"TOPRIGHT","BOTTOMRIGHT") end);
	self.Config.tooltip ={
		title = SETTINGS,
		lines = {L["Click to open option menu"]},
		point = {"BOTTOM",self.Config,"TOP",0,2}
	}
	self.Close.tooltip = {
		title = CLOSE,
		lines = {L["Close %s"]:format(addon)},
		point = {"BOTTOM",self.Close,"TOP",0,2}
	};

	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", self.StartMoving);
	self:SetScript("OnDragStop",  self.StopMovingOrSizing);

	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_LOGIN");

	GuildApplicantTrackerMixin = nil;
end
