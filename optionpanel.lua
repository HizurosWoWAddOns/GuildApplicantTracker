
GuildApplicantTrackerDB = {};

local addon, ns = ...;

local wowVersion, buildVersion, buildDate, interfaceVersion = GetBuildInfo()
local L = ns.L;
local _print = print;
local function print(...) _print("|cffff4444"..addon.."|r:",...); end

local function tt_OnEnter(self)
	if (self.tooltipText) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
		GameTooltip:Show()
	end
end

local function tt_OnLeave(self)
	GameTooltip:Hide()
end

local function chkValueFunc(self)
	if (self) then
		if (self._cvar) then
			return (self._cvarTrue == GetCVar(self._cvar))
		else
			return (GuildApplicantTrackerDB[self._key])
		end
	end
end

local function chkBtn_OnClick(self)
	if (self) and (self._cvar) then
		self._current = (self:GetChecked()) and self._cvarTrue or self._cvarFalse;
	else
		self._current = (self:GetChecked())
	end
end

local panel = CreateFrame("Frame", addon .. "_Panel", InterfaceOptionsFramePanelContainer)

panel.name = addon
panel.controls = {}

function panel:okay()
	for i,v in pairs(panel.controls) do
		if v:GetObjectType()=="CheckButton" then
			if (v._key) and v._current~=nil then
				GuildApplicantTrackerDB[v._key] = v._current;
				if (v._funcOnTrue) and (v._current) then
					v._funcOnTrue()
				end
			elseif (v._cvar) and v._current~=nil then
				SetCVar(v._cvar,v._current);
			end
		end
	end
end

function panel:cancel()
	if (panel) then
		for i,v in pairs(panel.controls) do
			v._current = nil;
		end
	end
end

function panel:default()
	GuildApplicantTrackerDB = {} -- reset
end

function panel:refresh()
	if (panel) then
		for i,v in pairs(panel.controls) do
			if v:GetObjectType()=="CheckButton" then
				v:SetChecked(v._chkFunc(v));
			end
		end
	end
end

function panel:createText(args)
	local obj = panel:CreateFontString(nil,"ARTWORK",args.font)
	obj:SetText(args.text)
	obj:SetJustifyH(args.justifyH or "LEFT")
	obj:SetJustifyV(args.justifyV or "TOP")
	obj:SetPoint(unpack(args.point or {"TOPLEFT"}))
	if (args.color) then
		obj:SetTextColor(unpack(args.color))
	end
	return obj;
end

function panel:createCheckBox(args)
	local name = addon.."_"..args.name
	local obj = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
	obj.Text:SetText(args.label);
	obj:SetHitRectInsets(0, - obj.Text:GetWidth() - 1, 0, 0);
	obj.realWidth = obj:GetWidth() + obj.Text:GetWidth();
	obj:SetPoint(unpack(args.point or {"TOPLEFT"}))

	-- tooltip
	obj.tooltipText = args.tooltip;
	obj:SetScript("OnEnter",tt_OnEnter);
	obj:SetScript("OnLeave",tt_OnLeave);

	-- click state handler
	if (args.cvar) then
		obj._cvar = args.cvar;
		obj._cvarTrue = args.cvarTrue;
		obj._cvarFalse = args.cvarFalse;
	else
		obj._key = args.name;
		if args.funcOnTrue then
			obj._funcOnTrue = args.funcOnTrue;
		end
	end
	obj._chkFunc = chkValueFunc;
	obj:SetChecked(obj._chkFunc(obj));
	obj:SetScript("OnClick", chkBtn_OnClick);

	tinsert(panel.controls,obj);
	return obj;
end

function panel:createPanel()
	-- title & subtitle
	panel.title    = panel:createText({
		text  = addon..L[" - Options"],
		font  = "GameFontNormalLarge",
		point = {"TOPLEFT",16,-16}
	});

	--[[
	panel.subtitle = panel:createText({
		text  = L[""],
		font  = "GameFontHighlightSmall",
		point = {"TOPLEFT",panel.title,"BOTTOMLEFT",20,-4}
	});
	]]

	panel.label_hotfix = panel:createText({
		text  = L["Hotfixes"],
		font  = "GameFontNormalLarge",
		point = {"TOPLEFT",panel.info,"BOTTOMLEFT",-20,-20}
	});

	panel.chkbx_viewOffline = panel:createCheckBox({
		name       = "viewOffline",
		label      = L["Show/Hide offline applicants."],
		tooltip    = nil,
		funcOnTrue = nil,
		point      = {"TOPLEFT",panel.label_hotfix,"BOTTOMLEFT",20,0}
	});

	panel.chkbx_Minimap = panel:createCheckBox({
		name       = "garrison_hotfix",
		label      = L["Garrison"],
		tooltip    = L["Fix some problems with the garrison ui."],
		funcOnTrue = ns.garrison_hotfix,
		point      = {"TOPLEFT",panel.chkbx_worldmap,"BOTTOMLEFT",0,6}
	});

	panel.info_hotfix = panel:createText({
		text  = L["All hotfixes will be automaticly disabled for any new build version!"],
		font  = "GameFontNormal",
		point = {"TOPLEFT",panel.chkbx_garrison,"BOTTOMLEFT",-20,0}
	});

	-- missing options
	panel.label_missingoption = panel:createText({
		text  = L["Missing options"],
		font  = "GameFontNormalLarge",
		point = {"TOPLEFT",panel.info_hotfix,"BOTTOMLEFT",0,-20}
	});

	panel.chkbx_txt_de = panel:createCheckBox({
		name      = "locale_text",
		label     = L["German interface"],
		tooltip   = L["Changing the value of textLocale into deDE"],
		cvar      = "textLocale",
		cvarTrue  = "deDE",
		cvarFalse = "enUS",
		point     = {"TOPLEFT",panel.label_missingoption,"BOTTOMLEFT",20,0}
	});

	panel.chkbx_audio_de = panel:createCheckBox({
		name      = "locale_audio",
		label     = L["German sounds"],
		tooltip   = L["Changing the value of audioLocale into deDE"],
		cvar      = "audioLocale",
		cvarTrue  = "deDE",
		cvarFalse = "enUS",
		point     = {"TOPLEFT",panel.chkbx_txt_de,"BOTTOMLEFT",0,6}
	});

	panel.info_needrestart = panel:createText({
		text  = L["Language changes requires a restart of the client!"],
		font  = "GameFontNormal",
		color = {1, 0.1, 0.1},
		point = {"TOPLEFT",panel.chkbx_audio_de,"BOTTOMLEFT",-20,0}
	});

	-- credits
	panel.label_credit = panel:createText({
		text = L["Credits"],
		font = "GameFontNormalLarge",
		point = {"TOPLEFT",panel.info_needrestart,"BOTTOMLEFT",0, -20}
	});

	panel.info_garrison = panel:createText({
		text = L["For Garrison hotfix:|n    Thanks at Adelice (US Realm Draka) for the macro posted on Blizzard's US Forum|n    http://us.battle.net/wow/en/forum/topic/13978517999"],
		font = "GameFontHighlightSmall",
		point = {"TOPLEFT",panel.label_credit,"BOTTOMLEFT",20,-4}
	});

	-- debug mode toggle...
	panel.debug_mode = panel:createCheckBox({
		name = "debug_mode",
		label = L["debug mode"],
		tooltip = L["Displayes debug messages in general chat frame"],
		point = {"TOPRIGHT",panel,"TOPRIGHT",-80,22}
	});
end

panel:SetScript("OnShow", function()
	panel:SetScript("OnShow",panel.refresh)
	panel:createPanel()
	panel.createPanel=nil
	--panel:refresh()
end)

InterfaceOptions_AddCategory(panel);
