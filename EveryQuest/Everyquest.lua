--[[
Quest Status:
-3 = Abandoned
-2 = Unavailable
-1 = Failed
0 = In Progress
1 = Ready to Turn In
2 = Completed
--]]

local EveryQuest = EveryQuest
local L = EveryQuest_Locale
local questdisplay = {}
local MINUTE = 60
local HOUR = 3600
local DAY = 86400
local QUEST_LOG_SCAN_DELAY = 0.2
local ZONE_DROPDOWN_SUBMENU_Y_OFFSET = 14
local ZONE_DROPDOWN_SCREEN_MARGIN = 12
local BOTTOM_BUTTON_Y_OFFSET = 5
local BOTTOM_BUTTON_OVERLAP = 4
local LIST_TOGGLE_BUTTON_WIDTH = 136
local CURRENT_ZONE_BUTTON_WIDTH = 108
local BOTTOM_BUTTON_HEIGHT = 21
local QUEST_LOG_TOGGLE_TEXT_X_OFFSET = 2
local sessionvars = {}
local QuestMenuFrame
local zonemenu = { -- Dropdown Zone list
	["Eastern Kingdoms"] = {
		{36,"Alterac Mountains"},
		{45,"Arathi Highlands"},
		{3,"Badlands"},
		{25,"Blackrock Mountain"},
		{4,"Blasted Lands"},
		{46,"Burning Steppes"},
		{279,"Dalaran"},
		{41,"Deadwind Pass"},
		{2257,"Deeprun Tram"},
		{1,"Dun Morogh"},
		{10,"Duskwood"},
		{139,"Eastern Plaguelands"},
		{12,"Elwynn Forest"},
		{3430,"Eversong Woods"},
		{3433,"Ghostlands"},
		{267,"Hillsbrad Foothills"},
		{1537,"Ironforge"},
		{4080,"Isle of Quel'Danas"},
		{38,"Loch Modan"},
		{44,"Redridge Mountains"},
		{51,"Searing Gorge"},
		{3487,"Silvermoon City"},
		{130,"Silverpine Forest"},
		{1519,"Stormwind City"},
		{33,"Stranglethorn Vale"},
		{8,"Swamp of Sorrows"},
		{47,"The Hinterlands"},
		{85,"Tirisfal Glades"},
		{1497,"Undercity"},
		{28,"Western Plaguelands"},
		{40,"Westfall"},
		{11,"Wetlands"},
	},
	["Kalimdor"] = {
		{331,"Ashenvale"},
		{16,"Azshara"},
		{3524,"Azuremyst Isle"},
		{3525,"Bloodmyst Isle"},
		{148,"Darkshore"},
		{1657,"Darnassus"},
		{405,"Desolace"},
		{14,"Durotar"},
		{15,"Dustwallow Marsh"},
		{361,"Felwood"},
		{357,"Feralas"},
		{493,"Moonglade"},
		{215,"Mulgore"},
		{1637,"Orgrimmar"},
		{1377,"Silithus"},
		{406,"Stonetalon Mountains"},
		{440,"Tanaris"},
		{141,"Teldrassil"},
		{17,"The Barrens"},
		{3557,"The Exodar"},
		{400,"Thousand Needles"},
		{1638,"Thunder Bluff"},
		{1216,"Timbermaw Hold"},
		{490,"Un'Goro Crater"},
		{618,"Winterspring"},
	},
	["Outland"] = {
		{3522,"Blade's Edge Mountains"},
		{3483,"Hellfire Peninsula"},
		{3518,"Nagrand"},
		{3523,"Netherstorm"},
		{3520,"Shadowmoon Valley"},
		{3703,"Shattrath City"},
		{3679,"Skettis"},
		{3519,"Terokkar Forest"},
		{3521,"Zangarmarsh"},
	},
	["Dungeons"] = {
		{3790,"Auchenai Crypts"},
		{719,"Blackfathom Deeps"},
		{1584,"Blackrock Depths"},
		{1583,"Blackrock Spire"},
		{1941,"Caverns of Time"},
		{3905,"Coilfang Reservoir"},
		{2557,"Dire Maul"},
		{133,"Gnomeregan"},
		{3562,"Hellfire Ramparts"},
		{4095,"Magisters' Terrace"},
		{3792,"Mana-Tombs"},
		{2100,"Maraudon"},
		{2367,"Old Hillsbrad Foothills"},
		{2437,"Ragefire Chasm"},
		{722,"Razorfen Downs"},
		{491,"Razorfen Kraul"},
		{796,"Scarlet Monastery"},
		{2057,"Scholomance"},
		{3791,"Sethekk Halls"},
		{3789,"Shadow Labyrinth"},
		{209,"Shadowfang Keep"},
		{2017,"Stratholme"},
		{1417,"Sunken Temple"},
		{3845,"Tempest Keep"},
		{3846,"The Arcatraz"},
		{2366,"The Black Morass"},
		{3713,"The Blood Furnace"},
		{3847,"The Botanica"},
		{1581,"The Deadmines"},
		{3849,"The Mechanar"},
		{3714,"The Shattered Halls"},
		{3717,"The Slave Pens"},
		{3715,"The Steamvault"},
		{717,"The Stockade"},
		{3716,"The Underbog"},
		{1337,"Uldaman"},
		{718,"Wailing Caverns"},
		{978,"Zul'Farrak"},
	},
	["Raids"] = {
		{2677,"Blackwing Lair"},
		{3606,"Hyjal Summit"},
		{2562,"Karazhan"},
		{3836,"Magtheridon's Lair"},
		{2717,"Molten Core"},
		{3456,"Naxxramas"},
		{2159,"Onyxia's Lair"},
		{3429,"Ruins of Ahn'Qiraj"},
		{3428,"Temple of Ahn'Qiraj"},
		{3840,"The Black Temple"},
		{3842,"The Eye"},
		{3805,"Zul'Aman"},
		{19,"Zul'Gurub"},
	},
	["Classes"] = {
		{-263,"Druid"},
		{-261,"Hunter"},
		{-161,"Mage"},
		{-141,"Paladin"},
		{-262,"Priest"},
		{-162,"Rogue"},
		{-82,"Shaman"},
		{-61,"Warlock"},
		{-81,"Warrior"},
	},
	["Professions"] = {
		{-181,"Alchemy"},
		{-121,"Blacksmithing"},
		{-304,"Cooking"},
		{-201,"Engineering"},
		{-324,"First Aid"},
		{-101,"Fishing"},
		{-24,"Herbalism"},
		{-182,"Leatherworking"},
		{-264,"Tailoring"},
	},
	["Battlegrounds"] = {
		{-25,"Battlegrounds"},
		{3358,"Arathi Basin"},
		{2597,"Alterac Valley"},
		{3820,"Eye of the Storm"},
		{3277,"Warsong Gulch"},
	},
	["Seasonal"] = {
		{-370,"Brewfest"},
		{-1002,"Children's Week"},
		{-364,"Darkmoon Faire"},
		{-1003,"Hallow's End"},
		{-1005,"Harvest Festival"},
		{-1004,"Love is in the Air"},
		{-366,"Lunar Festival"},
		{-369,"Midsummer Fire Festival"},
		{-1006,"New Year's Eve"},
		{-1001,"Winter Veil"},
	},
	["Miscellaneous"] = {
		{-365,"Ahn'Qiraj War Effort"},
		{-1,"Epic"},
		{-344,"Legendary"},
		{-367,"Reputation"},
		{-368,"Scourge Invasion"},
		{-22,"Seasonal"},
	},
}
local zoneGroupOrder = {
	"Eastern Kingdoms",
	"Kalimdor",
	"Outland",
	"Dungeons",
	"Raids",
	"Classes",
	"Professions",
	"Battlegrounds",
	"Seasonal",
	"Miscellaneous",
}

local function concat(var)
	if type(var) == "number" then
		return var
	elseif type(var) == "string" then
		return var
	elseif type(var) == "table" then
		return "table"
	else
		return "nil"
	end
end

local function getZoneListMenu()
	return EveryQuest.ZoneListMenu or _G.EveryQuestZoneListMenu
end

local function getQuestTitleText(button)
	if not button then return end
	local name = button.GetName and button:GetName()
	local text = button.eqTitleText or (name and _G[name.."NormalText"]) or (button.GetFontString and button:GetFontString())
	if not text and button.CreateFontString then
		text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	end
	if not text then return end

	button.eqTitleText = text
	if button.SetFontString and (not button.GetFontString or button:GetFontString() ~= text) then
		button:SetFontString(text)
	end
	if GameFontNormal and text.SetFontObject then
		text:SetFontObject(GameFontNormal)
	end
	if text.SetDrawLayer then
		text:SetDrawLayer("OVERLAY", 1)
	end
	text:ClearAllPoints()
	text:SetPoint("LEFT", button, "LEFT", 4, 0)
	text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
	text:SetHeight(16)
	text:SetJustifyH("LEFT")
	if text.SetJustifyV then
		text:SetJustifyV("MIDDLE")
	end
	text:Show()
	return text
end

local function setupQuestTitleButton(button)
	if not button then return end
	button:SetSize(300, 16)
	getQuestTitleText(button)
end

local function setButtonText(button, value)
	if not button then return end
	local text = getQuestTitleText(button)
	if text then
		text:SetText(value or "")
	else
		button:SetText(value or "")
	end
end

local function setButtonTextColor(button, ...)
	local text = getQuestTitleText(button)
	if text and text.SetTextColor then
		text:SetTextColor(...)
	end
end

local function clearButtonTexture(button)
	if not button then return end
	if button.SetNormalTexture then
		button:SetNormalTexture("")
	end
end

local completedQuestFlags
local completedQuestFlagsLoaded = false

local function normalizeCompletedQuestFlags(completedQuestData)
	local completedQuestMap = {}
	for questKey, questValue in pairs(completedQuestData or {}) do
		if questValue == true or questValue == 1 then
			completedQuestMap[tonumber(questKey) or questKey] = true
		elseif type(questValue) == "number" then
			completedQuestMap[questValue] = true
		end
	end
	return completedQuestMap
end

local function getCompletedQuestFlags()
	if completedQuestFlagsLoaded then
		return completedQuestFlags
	end

	completedQuestFlagsLoaded = true
	local completedQuestData = {}

	if C_QuestLog.GetAllCompletedQuestIDs then
		local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs(completedQuestData)
		if type(completedQuestIDs) == "table" then
			completedQuestData = completedQuestIDs
		end
		completedQuestFlags = normalizeCompletedQuestFlags(completedQuestData)
	end

	return completedQuestFlags
end

local function resetCompletedQuestFlags()
	completedQuestFlags = nil
	completedQuestFlagsLoaded = false
end

local function isQuestFlaggedCompleted(questid)
	questid = tonumber(questid)
	if not questid then
		return false
	end

	local completedQuestMap = getCompletedQuestFlags()
	if completedQuestMap then
		return completedQuestMap[questid] == true
	end

	if C_QuestLog.IsQuestFlaggedCompleted then
		return C_QuestLog.IsQuestFlaggedCompleted(questid)
	end
	return false
end

EveryQuest.QuestState:Configure({
	store = EveryQuest.QuestStore,
	relations = EveryQuest.QuestRelations,
	getPlayerLevel = function() return UnitLevel and UnitLevel("player") end,
	isQuestFlaggedCompleted = isQuestFlaggedCompleted,
})

local function getDisplayedQuestStatus(quest, history)
	return EveryQuest.QuestState:ToLegacyStatus(EveryQuest.QuestState:Evaluate(quest, history))
end

-- Disable each phase label in the release that opens that phase.
local FUTURE_PHASE_LABELS_ENABLED = {
	[4] = true,
	[5] = true,
}

local function getQuestPhaseLabel(quest)
	local phase = quest and quest.p
	if type(phase) == "number" and FUTURE_PHASE_LABELS_ENABLED[phase] then
		return "[" .. L["Phase"] .. " " .. phase .. "]"
	end
	return ""
end

local function addQuestStatusLabel(text, status)
	if status == -3 then
		return text .. " (" .. L["Abandoned"] .. ")"
	elseif status == -1 then
		return text .. " (" .. L["Failed"] .. ")"
	end
	return text
end

local function getQuestDataAddonName(group)
	if type(group) ~= "string" or group == "" then
		return nil
	end
	return "EveryQuest_"..string.gsub(group, " ", "_")
end

local function loadQuestDataAddon(addon)
	if C_AddOns.IsAddOnLoaded(addon) then
		return true
	end
	if not C_AddOns.DoesAddOnExist(addon) then
		return false, "MISSING"
	end

	local playerName = UnitName("player")
	if C_AddOns.GetAddOnEnableState(addon, playerName) == Enum.AddOnEnableState.None then
		return false, "DISABLED"
	end

	return C_AddOns.LoadAddOn(addon)
end

local function getQuestLogInfo(index)
	-- TBC Anniversary is hybrid: prefer C_QuestLog, then use Blizzard globals
	-- for active quest-log entry data the client still exposes there.
	if C_QuestLog and C_QuestLog.GetInfo then
		return C_QuestLog.GetInfo(index)
	end
	if GetQuestLogTitle then
		local title, level, _, isHeader, _, isComplete, frequency, questID = GetQuestLogTitle(index)
		return {
			title = title,
			level = level,
			isHeader = isHeader,
			isComplete = isComplete,
			frequency = frequency,
			questID = questID,
			usesLegacyFrequency = true,
		}
	end
end

local function getQuestLogQuestID(index)
	local info = getQuestLogInfo(index)
	return info and tonumber(info.questID)
end

local function getZoneIDByCategory(category)
	if not category then
		return nil
	end
	for group, zones in pairs(zonemenu) do
		for _, zone in pairs(zones) do
			if zone[2] == category then
				return zone[1], group
			end
		end
	end
	return nil
end

local function rememberQuestContext(questid, category, questTitle, daily, questLevel)
	questid = tonumber(questid)
	if not questid then
		return nil
	end

	sessionvars.questContext = sessionvars.questContext or {}
	local context = sessionvars.questContext[questid] or {}
	if category then
		context.category = category
	end
	if questTitle and questTitle ~= "" then
		context.title = questTitle
	end
	if daily ~= nil then
		context.daily = daily
	end
	if questLevel then
		context.level = questLevel
	end
	sessionvars.questContext[questid] = context
	return context
end

local function getQuestContext(questid)
	questid = tonumber(questid)
	if not questid or not sessionvars.questContext then
		return nil
	end
	return sessionvars.questContext[questid]
end

local function reportRuntimeError(context, err)
	EveryQuest:Error(context .. ": " .. tostring(err))
end

local function isLegacyDailyQuest(frequency)
	if frequency == nil then
		return nil
	end
	local dailyFrequency = rawget(_G, "LE_QUEST_FREQUENCY_DAILY") or 2
	return frequency == dailyFrequency
end

local function isDailyQuest(frequency)
	if frequency == nil then
		return nil
	end
	if not Enum or not Enum.QuestFrequency then
		return nil
	end
	return frequency == Enum.QuestFrequency.Daily
end

local function isQuestLogInfoDaily(info)
	if not info then
		return nil
	end
	if info.usesLegacyFrequency then
		return isLegacyDailyQuest(info.frequency)
	end
	return isDailyQuest(info.frequency)
end

function EveryQuest:RequestFrameUpdate()
	if sessionvars.suppressFrameUpdates then
		sessionvars.frameUpdatePending = true
		return
	end
	self:UpdateFrame()
end

function EveryQuest:ScheduleQuestLogScan(reportStatus)
	sessionvars.questLogScanPending = true
	if reportStatus then
		sessionvars.questLogScanReportStatus = true
	end
	sessionvars.questLogScanElapsed = 0

	EveryQuest.QuestLogScanFrame = EveryQuest.QuestLogScanFrame or CreateFrame("Frame")
	if not sessionvars.questLogScanOnUpdate then
		EveryQuest.QuestLogScanFrame:SetScript("OnUpdate", function(_, elapsed)
			EveryQuest:RunScheduledQuestLogScan(elapsed)
		end)
		sessionvars.questLogScanOnUpdate = true
	end
end

function EveryQuest:RunScheduledQuestLogScan(elapsed)
	if not sessionvars.questLogScanPending then
		if EveryQuest.QuestLogScanFrame then
			EveryQuest.QuestLogScanFrame:SetScript("OnUpdate", nil)
		end
		sessionvars.questLogScanOnUpdate = nil
		return
	end

	sessionvars.questLogScanElapsed = (sessionvars.questLogScanElapsed or 0) + (elapsed or 0)
	if sessionvars.questLogScanElapsed < QUEST_LOG_SCAN_DELAY then
		return
	end

	local reportStatus = sessionvars.questLogScanReportStatus
	sessionvars.questLogScanPending = nil
	sessionvars.questLogScanReportStatus = nil
	sessionvars.questLogScanElapsed = nil
	if EveryQuest.QuestLogScanFrame then
		EveryQuest.QuestLogScanFrame:SetScript("OnUpdate", nil)
	end
	sessionvars.questLogScanOnUpdate = nil

	self:ScanQuestLog(reportStatus)
end

local function setZoneListText(text)
	local zoneListMenu = getZoneListMenu()
	if zoneListMenu and UIDropDownMenu_SetText then
		UIDropDownMenu_SetText(zoneListMenu, text)
	end
end

local function raiseFrame(frame)
	if frame and EveryQuestFrame and frame.SetFrameLevel and EveryQuestFrame.GetFrameLevel then
		frame:SetFrameLevel(EveryQuestFrame:GetFrameLevel() + 2)
	end
end

local function saveSelectedZone()
	if EveryQuest.db and EveryQuest.db.char and sessionvars.zoneid and sessionvars.zonegroup then
		EveryQuest.db.char.zoneid = sessionvars.zoneid
		EveryQuest.db.char.zonegroup = sessionvars.zonegroup
	end
end

local function selectZone(group, zone)
	sessionvars.zoneid = zone[1]
	sessionvars.zonegroup = group
	saveSelectedZone()
	setZoneListText(zone[2])
end

local function getZoneByID(group, zoneID)
	zoneID = tonumber(zoneID)
	if not group or not zoneID or not zonemenu[group] then
		return nil
	end
	for _, zone in pairs(zonemenu[group]) do
		if zone[1] == zoneID then
			return zone
		end
	end
	return nil
end

local function getDropdownListFrame(level)
	return _G["DropDownList" .. level] or _G["LibDropDownMenu_List" .. level]
end

local function getZoneDropdownSubmenuYOffset(button, listFrame)
	local yOffset = ZONE_DROPDOWN_SUBMENU_Y_OFFSET
	if not UIParent or not button.GetTop or not listFrame.GetHeight then
		return yOffset
	end

	local anchorTop = button:GetTop()
	local listHeight = listFrame:GetHeight()
	local screenBottom = UIParent.GetBottom and UIParent:GetBottom()
	local screenTop = UIParent.GetTop and UIParent:GetTop()
	if not anchorTop or not listHeight or not screenBottom then
		return yOffset
	end

	local bottom = anchorTop + yOffset - listHeight
	local minBottom = screenBottom + ZONE_DROPDOWN_SCREEN_MARGIN
	if bottom < minBottom then
		yOffset = yOffset + (minBottom - bottom)
	end

	if screenTop then
		local top = anchorTop + yOffset
		local maxTop = screenTop - ZONE_DROPDOWN_SCREEN_MARGIN
		if top > maxTop then
			yOffset = yOffset - (top - maxTop)
		end
	end

	return yOffset
end

local function positionZoneDropdownSubmenu(level, menuList, button)
	if level ~= 2 or not button or not menuList or not zonemenu[menuList] then
		return
	end
	local zoneListMenu = getZoneListMenu()
	if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU ~= zoneListMenu then
		return
	end

	local listFrame = getDropdownListFrame(level)
	if not listFrame or not listFrame:IsShown() then
		return
	end

	local xPoint = "TOPLEFT"
	local xRelativePoint = "TOPRIGHT"
	local xOffset = 0
	if GetScreenWidth and button.GetLeft and button.GetRight and listFrame.GetWidth then
		local buttonLeft = button:GetLeft()
		local buttonRight = button:GetRight()
		local listWidth = listFrame:GetWidth()
		if buttonLeft and buttonRight and listWidth and buttonRight + listWidth > GetScreenWidth() then
			xPoint = "TOPRIGHT"
			xRelativePoint = "TOPLEFT"
			xOffset = -11
		end
	end

	listFrame:ClearAllPoints()
	listFrame.parentLevel = button:GetParent() and button:GetParent():GetID()
	listFrame.parentID = button:GetID()
	listFrame:SetPoint(xPoint, button, xRelativePoint, xOffset, getZoneDropdownSubmenuYOffset(button, listFrame))
end

local function hookZoneDropdownSubmenuPosition()
	if sessionvars.zoneDropdownSubmenuHooked or not hooksecurefunc then
		return
	end
	sessionvars.zoneDropdownSubmenuHooked = true
	hooksecurefunc("ToggleDropDownMenu", function(level, _, _, _, _, _, menuList, button)
		positionZoneDropdownSubmenu(level, menuList, button)
	end)
end

local currentZoneAliases = {
	["City of Ironforge"] = "Ironforge",
	["City of Stormwind"] = "Stormwind City",
	["City of Silvermoon"] = "Silvermoon City",
	["The Undercity"] = "Undercity",
}

local function zoneNameMatches(menuZone, currentZone)
	if menuZone == currentZone then
		return true
	end
	local alias = currentZoneAliases[currentZone]
	if alias and menuZone == alias then
		return true
	end
	local cityName = currentZone and string.match(currentZone, "^City of (.+)$")
	return cityName ~= nil and (menuZone == cityName or menuZone == cityName .. " City")
end

local function getCurrentZoneSelection()
	local currentZone = GetRealZoneText and GetRealZoneText()
	if currentZone and currentZone ~= "" then
		for group, zones in pairs(zonemenu) do
			for _, zone in pairs(zones) do
				if zoneNameMatches(zone[2], currentZone) then
					return group, zone
				end
			end
		end
	end
	return nil, nil
end

local function updateCurrentZoneButtonState()
	local button = EveryQuest.CurrentZoneButton
	if not button then
		return
	end
	if not EveryQuest.db or not EveryQuest.db.profile then
		button:Enable()
		return
	end

	local currentGroup, currentZone = getCurrentZoneSelection()
	if currentGroup and currentZone and EveryQuest.db.profile.view == "zone" and sessionvars.zonegroup == currentGroup and sessionvars.zoneid == currentZone[1] then
		button:Disable()
	else
		button:Enable()
	end
end

function EveryQuest:SelectCurrentZone()
	local currentGroup, currentZone = getCurrentZoneSelection()
	if currentGroup and currentZone then
		selectZone(currentGroup, currentZone)
		return true
	end
	return false
end

function EveryQuest:EveryQuestInit()
	if sessionvars.initialized then
		return true
	end

	self:RegisterEvents()

	EveryQuestTitleText:SetText(L["EveryQuest Log"])

	self:CreateZoneMenu()

	-- Create the "EQ" toggle button for the questlog frame
	EveryQuest.EveryQuestToggleButton = EveryQuest.EveryQuestToggleButton or CreateFrame("Button", nil, QuestLogFrame or UIParent, "UIPanelButtonTemplate")
	EveryQuest.EveryQuestToggleButton:SetSize(28, 18)
	EveryQuest.EveryQuestToggleButton:SetText("EQ")
	local questLogToggleText = EveryQuest.EveryQuestToggleButton:GetFontString()
	if questLogToggleText then
		questLogToggleText:ClearAllPoints()
		questLogToggleText:SetPoint("CENTER", EveryQuest.EveryQuestToggleButton, "CENTER", QUEST_LOG_TOGGLE_TEXT_X_OFFSET, 0)
	end
	EveryQuest.EveryQuestToggleButton:Show()
	EveryQuest.EveryQuestToggleButton:ClearAllPoints()

	-- Create the List toggle button to toggle between quest history and quests in a category
	EveryQuest.ListToggleButton = EveryQuest.ListToggleButton or _G.EveryQuestListToggleButton or CreateFrame("Button", "EveryQuestListToggleButton", EveryQuestFrame, "UIPanelButtonTemplate")
	EveryQuest.ListToggleButton:SetSize(LIST_TOGGLE_BUTTON_WIDTH + BOTTOM_BUTTON_OVERLAP, BOTTOM_BUTTON_HEIGHT)
	EveryQuest.ListToggleButton:SetText(" ")
	EveryQuest.ListToggleButton:Show()
	raiseFrame(EveryQuest.ListToggleButton)
	EveryQuest.ListToggleButton:ClearAllPoints()
	EveryQuest.ListToggleButton:SetPoint("BOTTOMLEFT", EveryQuestFrame, "BOTTOMLEFT", 18, BOTTOM_BUTTON_Y_OFFSET)
	EveryQuest.ListToggleButton:SetScript("OnClick", function() EveryQuest:List("toggle") end)

	EveryQuest.CurrentZoneButton = EveryQuest.CurrentZoneButton or _G.EveryQuestCurrentZoneButton or CreateFrame("Button", "EveryQuestCurrentZoneButton", EveryQuestFrame, "UIPanelButtonTemplate")
	EveryQuest.CurrentZoneButton:SetSize(CURRENT_ZONE_BUTTON_WIDTH + BOTTOM_BUTTON_OVERLAP, BOTTOM_BUTTON_HEIGHT)
	EveryQuest.CurrentZoneButton:SetText(L["Current Zone"])
	EveryQuest.CurrentZoneButton:Show()
	raiseFrame(EveryQuest.CurrentZoneButton)
	EveryQuest.CurrentZoneButton:ClearAllPoints()
	EveryQuest.CurrentZoneButton:SetPoint("BOTTOMRIGHT", EveryQuestExitButton, "BOTTOMLEFT", BOTTOM_BUTTON_OVERLAP, 0)
	EveryQuest.CurrentZoneButton:SetScript("OnClick", function() EveryQuest:ShowCurrentZone() end)
	updateCurrentZoneButtonState()

	if QuestLogFrame then
		EveryQuest.EveryQuestToggleButton:SetPoint("TOPLEFT",QuestLogFrame, "TOPLEFT",68,-15)
	else
		EveryQuest.EveryQuestToggleButton:Hide()
	end
	EveryQuest.EveryQuestToggleButton:SetScript("OnClick", function() EveryQuest:Toggle()	end)

	-- Set the binding text for the key binding window
	BINDING_HEADER_eqTITLE = L["EveryQuest"]
	BINDING_NAME_eqTOGGLE = L["Toggle Frame"]

	-- Create the 27 "lines" (buttons) in to display text in the main frame
	local button = _G.EveryQuestTitle1 or CreateFrame("Button", "EveryQuestTitle1", EveryQuestFrame,"EveryQuestTitleButtonTemplate")
	button:SetID(1)
	button:Hide()
	raiseFrame(button)
	setupQuestTitleButton(button)
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", EveryQuestFrame, "TOPLEFT", 19, -75)
	for i = 2, 27 do
		button = _G["EveryQuestTitle" .. i] or CreateFrame("Button", "EveryQuestTitle" .. i, EveryQuestFrame,"EveryQuestTitleButtonTemplate")
		button:SetID(i)
		button:Hide()
		raiseFrame(button)
		setupQuestTitleButton(button)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", _G["EveryQuestTitle" .. (i-1)], "BOTTOMLEFT", 0, 1)
	end

	-- If the quest log has been scaled, lets scale our frame to match
	if QuestLogFrame and QuestLogFrame.GetScale then
		EveryQuestFrame:SetScale(QuestLogFrame:GetScale())
	end

	local faction = UnitFactionGroup("player")
	if faction == "Alliance" then
		sessionvars.faction = 1
	else
		sessionvars.faction = 2
	end
	if self.db.profile.view == "history" and (not self.db.char.history or not next(self.db.char.history)) then
		self.db.profile.view = "zone"
	end

	self:SelectInitialZone()

	sessionvars.initializingQuestData = true
	local dataSummary = self:InitializeAllQuestData()
	local scanned, added, changed, missing = self:ScanQuestLog(false)
	self:PrintInitializationSummary(dataSummary, {
		scanned = scanned,
		added = added,
		changed = changed,
		missing = missing,
	})

	-- Load the saved view
	EveryQuest:List(self.db.profile.view)
	sessionvars.initializingQuestData = nil
	sessionvars.initialized = true
	return true
end

function EveryQuest:SelectInitialZone()
	if sessionvars.zoneid and sessionvars.zonegroup then
		return
	end
	local savedZone = getZoneByID(self.db.char.zonegroup, self.db.char.zoneid)
	if savedZone then
		selectZone(self.db.char.zonegroup, savedZone)
		return
	end

	local fallbackGroup, fallbackID = "Eastern Kingdoms", 12
	if sessionvars.faction == 2 then
		fallbackGroup, fallbackID = "Kalimdor", 14
	end
	for _, zone in pairs(zonemenu[fallbackGroup]) do
		if zone[1] == fallbackID then
			selectZone(fallbackGroup, zone)
			return
		end
	end
end

function EveryQuest:CreateZoneMenu()
	-- Zone Menu creation
	EveryQuest.ZoneListMenu = getZoneListMenu() or CreateFrame("Frame", "EveryQuestZoneListMenu", EveryQuestFrame, "UIDropDownMenuTemplate")
	EveryQuest.ZoneListMenu:Show()
	raiseFrame(EveryQuest.ZoneListMenu)
	EveryQuest.ZoneListMenu:ClearAllPoints()
	EveryQuest.ZoneListMenu:SetPoint("TOPLEFT",EveryQuestFrame, "TOPLEFT", 115,-40)
	UIDropDownMenu_SetWidth(EveryQuest.ZoneListMenu, 150)
	UIDropDownMenu_SetButtonWidth(EveryQuest.ZoneListMenu, 20)
	local zoneListMenuButton = _G[EveryQuest.ZoneListMenu:GetName().."Button"] or EveryQuest.ZoneListMenu.Button
	if zoneListMenuButton then
		zoneListMenuButton:SetScript("OnClick", function()
			ToggleDropDownMenu(1, nil, EveryQuest.ZoneListMenu, EveryQuest.ZoneListMenu, 0, 0)
		end)
	end

	setZoneListText(L["-- Select --"])
	hookZoneDropdownSubmenuPosition()

	UIDropDownMenu_Initialize(EveryQuest.ZoneListMenu, function(_, level, menuList)
		EveryQuest:InitializeZoneDropdown(level, menuList)
	end)
end

function EveryQuest:InitializeZoneDropdown(level, menuList)
	level = level or 1
	if level == 1 then
		for _, group in ipairs(zoneGroupOrder) do
			if zonemenu[group] then
				local info = UIDropDownMenu_CreateInfo()
				info.text = group
				info.hasArrow = true
				info.menuList = group
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, level)
			end
		end
		local closeInfo = UIDropDownMenu_CreateInfo()
		closeInfo.text = L["Close"]
		closeInfo.notCheckable = true
		closeInfo.func = CloseDropDownMenus
		UIDropDownMenu_AddButton(closeInfo, level)
		return
	end

	local group = menuList
	for _, zone in ipairs(zonemenu[group] or {}) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = zone[2]
		info.checked = sessionvars.zoneid == zone[1]
		info.arg1 = group
		info.arg2 = zone
		info.func = function(_, selectedGroup, selectedZone)
			selectZone(selectedGroup, selectedZone)
			self:Debug("Menuclick - zoneid:"..concat(sessionvars.zoneid).." zonegroup:"..concat(sessionvars.zonegroup))
			CloseDropDownMenus()
			self:UpdateFrame()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

function EveryQuest:RegisterEvents()
	if sessionvars.eventsRegistered then
		return
	end
	sessionvars.eventsRegistered = true
	self:Debug("RegisterEvents")
	-- Register Events
	self:RegisterEvent("QUEST_PROGRESS")
	self:RegisterEvent("QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("QUEST_FAILED")
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:RegisterEvent("QUEST_REMOVED")
	self:RegisterEvent("QUEST_TURNED_IN")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_LOGOUT")

	-- Quest abandon is tracked through QUEST_REMOVED; leave Blizzard popup handling intact.
	-- Quest turn-in is tracked through QUEST_TURNED_IN; leave Blizzard reward handling intact.
end

function EveryQuest:Toggle()
	if not sessionvars.initialized then
		self:EveryQuestInit()
	end
	if EveryQuestFrame:IsShown() then
		EveryQuestFrame:Hide()
	else
		EveryQuestFrame:Show()
	end
end

function EveryQuest:ShowCurrentZone()
	local currentZone = GetRealZoneText and GetRealZoneText()
	if not self:SelectCurrentZone() then
		self:Print("EveryQuest: current zone is not available: " .. concat(currentZone))
		return
	end
	self.db.profile.view = "zone"
	if EveryQuest.ListToggleButton then
		EveryQuest.ListToggleButton:SetText(L["Show Quest History"])
	end
	self:NewZone()
end

function EveryQuest:SavePosition()
	local Left = EveryQuestFrame:GetLeft()
	local Top = EveryQuestFrame:GetTop()
	if Left and Top then
		self.db.char.saved.eqlogposx = Left
		self.db.char.saved.eqlogposy = Top
	end
end

function EveryQuest_OnShow()
	if EveryQuest.db.char.saved.eqlogposx and EveryQuest.db.char.saved.eqlogposy then
		EveryQuestFrame:ClearAllPoints()
		EveryQuestFrame:SetPoint("TOPLEFT","UIParent", "BOTTOMLEFT", EveryQuest.db.char.saved.eqlogposx, EveryQuest.db.char.saved.eqlogposy)
	end
	EveryQuest:UpdateFrame()
end

function EveryQuest:NewZone()
	if sessionvars.zoneid ~= nil and sessionvars.zonegroup ~= nil then
		self:Debug("NewZone view:"..concat(self.db.profile.view).." zoneid:"..concat(sessionvars.zoneid).." zonegroup:"..concat(sessionvars.zonegroup))
	else
		self:Debug("NewZone - zoneid and zonegroup are empty")
	end
	if EveryQuestListScrollFrame then
		EveryQuestListScrollFrame:SetVerticalScroll(0)
	end
	self:UpdateFrame()
end

function EveryQuest_ScrollFrame_Update()
	--self:Debug("ScrollFrame_Update")
	EveryQuest:UpdateFrame()
end

function EveryQuest:timeDiff(timestamp)
    local now = time()
	local amount = now - timestamp
	local minutes, hours, days
    --If the difference is positive "ago" - negative "away"

	--amount = amount + DAY + HOUR*5

	if amount >= (DAY * 10) then
		return date("%m/%d/%y %I%p", timestamp)
	end

	if (amount >= DAY) and (amount < (DAY * 10)) then
		-- between one day and 30 days
		days = math.floor(amount/DAY)
		if days ~= 1 then days = days .. L[" days "] else days = days .. L[" day "] end
		hours = amount%DAY
		hours = math.floor(hours/HOUR)
		if hours ~= 0 then hours = hours .. L[" hr "] else hours = "" end
		return days .. hours .. L["ago"]
		--return "between one day and 30 days"
	end

	if (amount < DAY) and (amount >= HOUR) then
		-- between one hour and one day
		--value = string.format("%H hr %M min ago", amount)
		hours = math.floor(amount/HOUR)
		minutes = amount%HOUR
		minutes = math.floor(minutes/MINUTE +.5)
		if minutes ~= 0 then minutes = minutes .. L[" min "] else minutes = "" end
		return hours .. L[" hr "] .. minutes .. L["ago"]
		--return  .. " between one hour and one day"
	end

	if (amount < HOUR and amount >= MINUTE) then
		-- between one minute and one hour
		if EveryQuest:round(amount / MINUTE) > 1 then
			return EveryQuest:round(amount / MINUTE) .. L[" minutes ago"]
		else
			return L["1 minute ago"]
		end
	end

	if amount > 1 then
		return amount .. L[" seconds ago"]
	else
		return amount .. L[" second ago"]
	end
end

function EveryQuest:round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Get a Quest Data from a LOD module and return the table and the Category
function EveryQuest:GetQuestData(questid, category)
	self:Debug("GetQuestData - questid:"..concat(questid).." category:"..concat(category))
	questid = tonumber(questid)
	if not questid then
		return false
	end
	local zoneid, zonegroup = getZoneIDByCategory(category)
	local quest, resolvedGroup, resolvedZoneID = self.QuestStore:GetStaticQuest(questid, zonegroup, zoneid)
	if quest then
		local history, historyZoneID = self.QuestStore:GetHistory(questid, resolvedZoneID)
		if history and historyZoneID == resolvedZoneID then
			self:Debug("GetQuestData - from history - questid:"..concat(questid).." zonegroup:"..concat(resolvedGroup).." zoneid:"..concat(resolvedZoneID))
			return history, resolvedZoneID
		end
		self:Debug("GetQuestData - from data - questid:"..concat(questid).." zonegroup:"..concat(resolvedGroup).." zoneid:"..concat(resolvedZoneID))
		return quest, resolvedZoneID
	end
	return false
end

function EveryQuest:GetQuestZoneData(zonegroup, zoneid, view)
	if view == nil then
		view = self.db.profile.view
	end
	if view == "zone" then
		-- Initial rendering must not retry failed groups or consume their UI error.
		if sessionvars.initializingQuestData then
			local groupdata = EveryQuestData and EveryQuestData[zonegroup]
			return groupdata and groupdata[zoneid] or false
		end
		local groupdata = self:LoadQuestData(zonegroup)
		if groupdata ~= false then
			return groupdata[zoneid]
		end
		return false
	end

	if self.db.char.history and self.db.char.history[zoneid] then
		return self.db.char.history[zoneid]
	else
		return false
	end
end

function EveryQuest:ShowListMessage(message)
	for j = 1, 27, 1 do
		questdisplay[j] = nil
	end
	local frame = _G.EveryQuestTitle1
	if frame then
		clearButtonTexture(frame)
		setButtonText(frame, message)
		setButtonTextColor(frame, self:GetColor("FFFFFF"))
		frame:Show()
	end
	for j = 2, 27, 1 do
		local listFrame = _G["EveryQuestTitle"..j]
		if listFrame then
			listFrame:Hide()
		end
	end
end

function EveryQuest:HydrateQuestHistoryForGroup(group)
	if not group or not EveryQuestData or not EveryQuestData[group] or not self.db.char.history then
		return 0
	end

	self.QuestStore:RegisterGroup(group, EveryQuestData[group])
	local hydrated = 0
	local seen = {}
	for _, occurrence in ipairs(self.QuestStore:GetGroupOccurrences(group)) do
		local questid = tonumber(occurrence.quest and occurrence.quest.id)
		if questid and not seen[questid] then
			seen[questid] = true
			local savedQuest, _, moved, staticQuest = self.QuestStore:MoveHistoryToCanonicalLocation(questid)
			local changed = moved
			if savedQuest and self.QuestStore:ApplyStaticHistoryMetadata(savedQuest, staticQuest) then
				changed = true
			end
			if savedQuest and changed then
				hydrated = hydrated + 1
			end
		end
	end
	return hydrated
end

function EveryQuest:SyncCompletedQuestFlagsForGroup(group, reportStatus)
	if not group or not EveryQuestData or not EveryQuestData[group] then
		return 0, 0, 0, 0
	end
	self.QuestStore:RegisterGroup(group, EveryQuestData[group])

	sessionvars.completedSyncGroups = sessionvars.completedSyncGroups or {}
	if sessionvars.completedSyncGroups[group] then
		return 0, 0, 0, 0
	end
	sessionvars.completedSyncGroups[group] = true

	if self.db.char.history == nil then
		self.db.char.history = {}
		self.QuestStore:SetHistoryRoot(self.db.char.history)
	end

	local checked, completed, added, changed = 0, 0, 0, 0
	for zoneid, quests in pairs(EveryQuestData[group]) do
		if type(quests) == "table" then
			for _, quest in pairs(quests) do
				local questid = tonumber(quest and quest.id)
				if questid then
					checked = checked + 1
					if isQuestFlaggedCompleted(questid) then
						completed = completed + 1
						local staticQuest, _, staticZoneID = self.QuestStore:GetStaticQuest(questid)
						local history, wasAdded = self.QuestStore:EnsureHistoryRecord(questid, {
							zoneID = staticZoneID or zoneid,
							quest = staticQuest or quest,
						})
						if wasAdded then
							added = added + 1
						elseif history.status ~= 2 then
							changed = changed + 1
						end
						history.status = 2
						history.statusSource = "automatic"
						history.abandoned = nil
						history.failed = nil
					end
				end
			end
		end
	end

	if reportStatus then
		self:Print(("EveryQuest: %s completed quest sync: %d checked, %d completed, %d added, %d changed."):format(group, checked, completed, added, changed))
	end
	return checked, completed, added, changed
end

function EveryQuest:EnsureQuestDataLoaded(group)
	if type(group) ~= "string" or group == "" then
		return nil, "INVALID_GROUP", false
	end

	if EveryQuestData and type(EveryQuestData[group]) == "table" then
		self:Debug("Module "..concat(group).." is loaded")
		return EveryQuestData[group], nil, false
	end

	local addon = getQuestDataAddonName(group)
	local wasLoaded = C_AddOns.IsAddOnLoaded(addon)
	self:Debug("Loading single module: "..concat(addon))
	self:Debug("Module "..concat(group).." not loaded")
	local succ, reason = loadQuestDataAddon(addon)
	local newlyLoaded = not wasLoaded and succ == true
	if not succ then
		return nil, reason or "LOAD_FAILED", false
	end
	if EveryQuestData and type(EveryQuestData[group]) == "table" then
		return EveryQuestData[group], nil, newlyLoaded
	end
	return nil, "NO_DATA", newlyLoaded
end

function EveryQuest:PrepareQuestDataGroup(group)
	local stats = {
		newlyLoaded = false,
		alreadyPrepared = false,
		hydrated = 0,
		checked = 0,
		completed = 0,
		added = 0,
		changed = 0,
	}

	if type(group) == "string"
		and sessionvars.preparedGroups
		and sessionvars.preparedGroups[group]
		and EveryQuestData
		and type(EveryQuestData[group]) == "table" then
		stats.alreadyPrepared = true
		return EveryQuestData[group], nil, stats
	end

	local groupData, reason, newlyLoaded = self:EnsureQuestDataLoaded(group)
	stats.newlyLoaded = newlyLoaded == true
	if not groupData then
		return nil, reason, stats
	end

	stats.hydrated = self:HydrateQuestHistoryForGroup(group)
	stats.checked, stats.completed, stats.added, stats.changed = self:SyncCompletedQuestFlagsForGroup(group, false)

	sessionvars.preparedGroups = sessionvars.preparedGroups or {}
	sessionvars.preparedGroups[group] = true
	return groupData, nil, stats
end

local function reportQuestDataLoadFailure(group, reason)
	if type(group) ~= "string" or group == "" then
		return
	end

	sessionvars.questDataLoadFailures = sessionvars.questDataLoadFailures or {}
	if sessionvars.questDataLoadFailures[group] then
		return
	end
	sessionvars.questDataLoadFailures[group] = true

	local addon = getQuestDataAddonName(group)
	if reason == "MISSING" then
		EveryQuest:Print(L["Requires LOD Module: "] .. addon)
	elseif reason == "DISABLED" then
		EveryQuest:Print(L["Disabled LOD Module: "] .. addon)
	else
		EveryQuest:Print(L["Could not load "] .. group .. L[" Quest Data"] .. ": " .. concat(reason))
	end
end

function EveryQuest:LoadQuestData(group)
	local groupData, reason = self:PrepareQuestDataGroup(group)
	if not groupData then
		reportQuestDataLoadFailure(group, reason)
		return false
	end
	--for k,v in pairs(EveryQuestData) do self:Debug(k) end
	return groupData --questdata[varname] and varname
end

function EveryQuest:GetStatus(displayid, queststatus)
	local quest = displayid and questdisplay[displayid]
	local zoneid = sessionvars.zoneid
	local history, historyZoneID
	if quest then
		history, historyZoneID = self.QuestStore:GetHistory(quest.id, zoneid)
	end
	if history and historyZoneID == zoneid then
		return getDisplayedQuestStatus(quest, history) == queststatus
	end
	return quest ~= nil and getDisplayedQuestStatus(quest) == queststatus
end

local function getNumQuestLogEntries()
	local numEntries
	-- TBC Anniversary is hybrid: prefer C_QuestLog, then use the Blizzard
	-- global when the client has no equivalent C_QuestLog entry-count call.
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		numEntries = C_QuestLog.GetNumQuestLogEntries()
	elseif GetNumQuestLogEntries then
		numEntries = GetNumQuestLogEntries()
	end
	return numEntries or 0
end

local function statusFromQuestLog(isComplete)
	if isComplete == 1 or isComplete == true then
		return 1
	elseif isComplete == -1 then
		return -1
	end
	return 0
end

function EveryQuest:FindQuestLogEntryByID(questid)
	questid = tonumber(questid)
	if not questid then return end

	local category
	for index = 1, getNumQuestLogEntries() do
		local info = getQuestLogInfo(index)
		if info and info.title then
			if info.isHeader then
				category = info.title
			else
				local currentQuestID = tonumber(info.questID)
				if currentQuestID == questid then
					local daily = isQuestLogInfoDaily(info)
					local level = tonumber(info.level)
					rememberQuestContext(currentQuestID, category, info.title, daily, level)
					return index, category, info.title, statusFromQuestLog(info.isComplete), daily, level
				end
			end
		end
	end
end

function EveryQuest:FindQuestLogEntryByName(questName)
	if not questName then return end

	local category
	for index = 1, getNumQuestLogEntries() do
		local info = getQuestLogInfo(index)
		if info and info.title then
			if info.isHeader then
				category = info.title
			elseif info.title == questName then
				local questid = tonumber(info.questID)
				local daily = isQuestLogInfoDaily(info)
				local level = tonumber(info.level)
				rememberQuestContext(questid, category, info.title, daily, level)
				return index, category, questid, statusFromQuestLog(info.isComplete), daily, level
			end
		end
	end
end

function EveryQuest:GetHistoryByQuestID(questid)
	return self.QuestStore:GetHistory(questid)
end

local canonicalQuestSearchGroups = {
	"Classes",
	"Professions",
	"Dungeons",
	"Raids",
	"Battlegrounds",
	"Seasonal",
	"Miscellaneous",
	"Eastern Kingdoms",
	"Kalimdor",
	"Outland",
}

function EveryQuest:InitializeAllQuestData()
	local summary = {
		totalGroups = #canonicalQuestSearchGroups,
		preparedGroups = 0,
		newlyLoadedGroups = 0,
		alreadyPreparedGroups = 0,
		failedGroups = 0,
		failures = {},
		hydrated = 0,
		checked = 0,
		completed = 0,
		added = 0,
		changed = 0,
	}
	for _, group in ipairs(canonicalQuestSearchGroups) do
		local groupData, reason, stats = self:PrepareQuestDataGroup(group)
		if groupData then
			summary.preparedGroups = summary.preparedGroups + 1
		else
			reason = reason or "LOAD_FAILED"
			summary.failedGroups = summary.failedGroups + 1
			table.insert(summary.failures, {group = group, reason = reason})
			self:Debug("Quest data preparation failed: " .. group .. ": " .. reason)
		end
		if stats.newlyLoaded then
			summary.newlyLoadedGroups = summary.newlyLoadedGroups + 1
		end
		if stats.alreadyPrepared then
			summary.alreadyPreparedGroups = summary.alreadyPreparedGroups + 1
		end
		summary.hydrated = summary.hydrated + stats.hydrated
		summary.checked = summary.checked + stats.checked
		summary.completed = summary.completed + stats.completed
		summary.added = summary.added + stats.added
		summary.changed = summary.changed + stats.changed
		self:Debug(("Quest data preparation: %s; %d hydrated, %d checked, %d completed, %d added, %d changed."):format(
			group, stats.hydrated, stats.checked, stats.completed, stats.added, stats.changed))
	end
	return summary
end

function EveryQuest:PrintInitializationSummary(dataSummary, questLogSummary)
	local failed = dataSummary.failedGroups
	local missing = questLogSummary.missing or 0
	local scanFailed = questLogSummary.scanned == false
	local status = (failed > 0 or missing > 0 or scanFailed) and "Ready with warnings" or "Ready"
	local active = "quest log scan failed"
	if not scanFailed then
		local scanned = questLogSummary.scanned
		active = ("%d active %s"):format(scanned, scanned == 1 and "quest" or "quests")
	end
	local message = ("EveryQuest: %s — %d/%d quest data groups; %s"):format(
		status, dataSummary.preparedGroups, dataSummary.totalGroups, active)
	if failed > 0 then
		message = message .. ("; %d %s failed"):format(failed, failed == 1 and "group" or "groups")
	end
	if missing > 0 then
		message = message .. ("; %d active %s unmapped"):format(missing, missing == 1 and "quest" or "quests")
	end
	self:Print(message .. ".")
end

local function loadQuestDataForStaticLookup(group)
	if not group then
		return nil
	end
	return EveryQuest:EnsureQuestDataLoaded(group)
end

EveryQuest.QuestStore:Configure({
	loader = loadQuestDataForStaticLookup,
	groupOrder = canonicalQuestSearchGroups,
})

function EveryQuest:ReconcileQuestHistoryForZone(group, zoneid)
	if not zoneid or not self.db.char.history then
		return 0
	end
	local zoneHistory = self.db.char.history[zoneid]
	if type(zoneHistory) ~= "table" then
		return 0
	end

	local questIDs = {}
	for questid in pairs(zoneHistory) do
		table.insert(questIDs, questid)
	end

	local reconciled = 0
	for _, questid in ipairs(questIDs) do
		questid = tonumber(questid)
		if questid then
			local savedQuest, staticZoneID, moved, staticQuest = self.QuestStore:MoveHistoryToCanonicalLocation(questid, {
				groupHint = group,
				zoneHint = zoneid,
			})
			if staticZoneID then
				local changed = moved
				if savedQuest and staticQuest and self.QuestStore:ApplyStaticHistoryMetadata(savedQuest, staticQuest) then
					changed = true
				end
				if changed then
					reconciled = reconciled + 1
				end
			end
		end
	end
	return reconciled
end

function EveryQuest:SaveQuestHistoryByID(questid, category, qstatus, questTitle, daily, questLevel)
	if self.db.char.history == nil then
		self.db.char.history = {}
		self.QuestStore:SetHistoryRoot(self.db.char.history)
	end
	questid = tonumber(questid)
	if not questid then
		return false
	end

	local history, historyZoneID = self:GetHistoryByQuestID(questid)
	local added, changed = false, false
	local context = getQuestContext(questid)
	if context then
		category = category or context.category
		questTitle = questTitle or context.title
		if daily == nil then
			daily = context.daily
		end
		questLevel = questLevel or context.level
	end
	rememberQuestContext(questid, category, questTitle, daily, questLevel)
	local categoryZoneID, categoryGroup = getZoneIDByCategory(category)
	local canonicalHistory, staticZoneID, moved, staticQuest = self.QuestStore:MoveHistoryToCanonicalLocation(questid, {
		groupHint = categoryGroup,
		zoneHint = categoryZoneID,
	})
	if staticZoneID then
		categoryZoneID = staticZoneID
	end
	if canonicalHistory then
		history = canonicalHistory
		historyZoneID = categoryZoneID
		changed = moved
	elseif history and categoryZoneID then
		history, moved = self.QuestStore:MoveHistoryToZone(questid, categoryZoneID)
		historyZoneID = categoryZoneID
		changed = moved
	end

	if not history then
		local zoneid = categoryZoneID
		if not zoneid then
			return false
		end
		local historySource = staticQuest or {
			id = questid,
			n = questTitle or ("Quest " .. questid),
			s = 3,
		}
		history, added = self.QuestStore:EnsureHistoryRecord(questid, {
			zoneID = zoneid,
			quest = historySource,
		})
		historyZoneID = zoneid
	end

	if staticQuest and self.QuestStore:ApplyStaticHistoryMetadata(history, staticQuest) then
		changed = not added
	end
	if questTitle and questTitle ~= "" then
		history.n = questTitle
	end
	if questLevel then
		history.l = questLevel
	end
	if daily then
		if history.d ~= 1 then
			history.d = 1
			changed = not added
		end
	elseif daily == false and history.d ~= nil then
		history.d = nil
		changed = not added
	end
	if qstatus ~= nil then
		if history.status ~= qstatus then
			history.status = qstatus
			changed = not added
		end
		history.statusSource = "automatic"
	end

	self:RequestFrameUpdate()
	return questid, historyZoneID, history.d, added, changed
end

function EveryQuest:AddQuestByID(questid, category, qstatus)
	if self.db.char.history == nil then
		self.db.char.history = {}
		self.QuestStore:SetHistoryRoot(self.db.char.history)
	end
	questid = tonumber(questid)
	if not questid then
		return false
	end

	local _, foundCategory, _, foundStatus = self:FindQuestLogEntryByID(questid)
	category = category or foundCategory
	if qstatus == nil then
		qstatus = foundStatus
	end

	local history, historyZoneID = self:GetHistoryByQuestID(questid)
	if history and not category then
		if qstatus ~= nil then
			history.status = qstatus
			history.statusSource = "automatic"
		end
		self:RequestFrameUpdate()
		return questid, historyZoneID, history.d
	end

	local quest, zoneid = self:GetQuestData(questid, category)
	if quest == false then
		return false
	end
	self:Debug("AddQuestByID - questid:"..concat(questid) .. " zoneid:"..concat(zoneid))
	if zoneid ~= nil then
		if quest ~= nil then
			history = self.QuestStore:EnsureHistoryRecord(questid, {
				zoneID = zoneid,
				quest = quest,
			})
			if qstatus ~= nil then
				history.status = qstatus
				history.statusSource = "automatic"
			end
			self:RequestFrameUpdate()
			return questid, zoneid, history.d
		else
			return false
		end
	else
		self:RequestFrameUpdate()
		return false
	end
end

function EveryQuest:MarkQuestByID(questid, status, timestampField, category, questTitle, daily, questLevel)
	local savedQuestID, zoneid = self:SaveQuestHistoryByID(questid, category, status, questTitle, daily, questLevel)
	if savedQuestID ~= nil and savedQuestID ~= false and zoneid ~= nil then
		local history = self.QuestStore:GetHistory(savedQuestID, zoneid)
		history.status = status
		history.statusSource = "automatic"
		if timestampField == "failed" then
			history.abandoned = nil
		elseif timestampField == "abandoned" then
			history.failed = nil
		end
		if timestampField then
			history[timestampField] = time()
		end
		self:Debug("MarkQuestByID - questid:"..concat(savedQuestID).." zoneid:"..concat(zoneid).." status:"..concat(status))
		self:UpdateFrame()
		return savedQuestID, zoneid
	end
	return false
end

function EveryQuest:MarkQuestByName(questName, status, timestampField)
	local questindex, category, questid, _, daily, questLevel = self:FindQuestLogEntryByName(questName)
	if questid then
		return self:MarkQuestByID(questid, status, timestampField, category, questName, daily, questLevel)
	elseif questindex then
		local savedQuestID, zoneid = self:SaveQuestHistoryByID(self:GetQID(questindex), category, status, questName)
		if savedQuestID and zoneid then
			local history = self.QuestStore:GetHistory(savedQuestID, zoneid)
			history.status = status
			history.statusSource = "automatic"
			if timestampField == "failed" then
				history.abandoned = nil
			elseif timestampField == "abandoned" then
				history.failed = nil
			end
			if timestampField then
				history[timestampField] = time()
			end
			self:UpdateFrame()
			return savedQuestID, zoneid
		end
	end
	return false
end

function EveryQuest:ScanQuestLog(reportStatus)
	local flushFrameUpdate = not sessionvars.suppressFrameUpdates
	sessionvars.suppressFrameUpdates = true

	local ok, scannedResult, addedResult, changedResult, missingResult = pcall(function()
		local category
		local scanned, added, changed, missing = 0, 0, 0, 0
		local missingQuests = {}
		if reportStatus then
			self:Print("EveryQuest: updating quest history from the quest log...")
		end
		for index = 1, getNumQuestLogEntries() do
			local info = getQuestLogInfo(index)
			if info and info.title then
				if info.isHeader then
					category = info.title
				else
					local questid = tonumber(info.questID)
					if questid then
						scanned = scanned + 1
						local status = statusFromQuestLog(info.isComplete)
						local daily = isQuestLogInfoDaily(info)
						local level = tonumber(info.level)
						rememberQuestContext(questid, category, info.title, daily, level)
						local savedQuestID, zoneid, _, wasAdded, wasChanged = self:SaveQuestHistoryByID(
							questid,
							category,
							status,
							info.title,
							daily,
							level
						)
						if savedQuestID ~= nil and savedQuestID ~= false and zoneid ~= nil then
							if wasAdded then
								added = added + 1
							elseif wasChanged then
								changed = changed + 1
							end
						else
							missing = missing + 1
							table.insert(missingQuests, {
								id = questid,
								title = info.title,
								category = category,
							})
						end
					end
				end
			end
		end
		if reportStatus then
			self:Print(
				("EveryQuest: quest history updated: %d active, %d added, %d changed, %d missing zone mappings."):format(
					scanned,
					added,
					changed,
					missing
				)
			)
			for _, missingQuest in ipairs(missingQuests) do
				local categoryText = missingQuest.category and (" (" .. missingQuest.category .. ")") or ""
				self:Print(("EveryQuest: unmapped quest %d - %s%s"):format(missingQuest.id, missingQuest.title or L["Unknown"], categoryText))
			end
		end
		return scanned, added, changed, missing
	end)

	if not ok then
		reportRuntimeError("EveryQuest quest log sync failed", scannedResult)
	end

	if flushFrameUpdate then
		sessionvars.suppressFrameUpdates = nil
		if sessionvars.frameUpdatePending then
			sessionvars.frameUpdatePending = nil
			self:UpdateFrame()
		end
	end

	if not ok then
		return false
	end
	return scannedResult, addedResult, changedResult, missingResult
end

function EveryQuest:QUEST_ACCEPTED(questLogIndex, questid)
	questid = tonumber(questid)
	if not questid and questLogIndex then
		questid = getQuestLogQuestID(questLogIndex) or tonumber(questLogIndex)
	end
	if not questid then
		self:Debug("QUEST_ACCEPTED - waiting for QUEST_LOG_UPDATE")
		return
	end

	local _, category, questTitle, _, daily, questLevel = self:FindQuestLogEntryByID(questid)
	local savedQuestID, zoneid = self:SaveQuestHistoryByID(questid, category, 0, questTitle, daily, questLevel)
	if savedQuestID ~= nil and savedQuestID ~= false and zoneid ~= nil then
		self:Debug("QUEST_ACCEPTED - questid:"..concat(savedQuestID).." zoneid:"..concat(zoneid))
	else
		self:Debug("QUEST_ACCEPTED - waiting for zone mapping for questid:"..concat(questid))
	end
end

function EveryQuest:QUEST_COMPLETE()
	local questtitle = GetTitleText()
	if questtitle then
		local questid, zoneid = self:MarkQuestByName(questtitle, 1)
		if questid then
			self:Debug("QUEST_COMPLETE - questid:"..concat(questid).." zoneid:"..concat(zoneid))
		end
	end
end

function EveryQuest:QUEST_FAILED(questName)
	questName = questName or GetTitleText()
	if questName then
		local questid, zoneid = self:MarkQuestByName(questName, -1, "failed")
		if questid then
			self:Debug("QUEST_FAILED - questid:"..concat(questid).." zoneid:"..concat(zoneid))
		end
	end
end

function EveryQuest:QUEST_REMOVED(questid)
	questid = tonumber(questid)
	if not questid then
		return
	end

	local history = self:GetHistoryByQuestID(questid)
	if history and history.status == 2 then
		return
	end

	resetCompletedQuestFlags()
	if isQuestFlaggedCompleted(questid) then
		local questtitle = GetTitleText and GetTitleText()
		self:QuestTurnedIn(questtitle, questid)
		return
	end

	self:MarkQuestByID(questid, -3, "abandoned")
end

function EveryQuest:QUEST_TURNED_IN(questid)
	questid = tonumber(questid)
	local questtitle = GetTitleText and GetTitleText()
	if questid then
		self:QuestTurnedIn(questtitle, questid)
		return
	end

	if questtitle then
		self:QuestTurnedIn(questtitle)
	end
end

function EveryQuest:QUEST_LOG_UPDATE()
	self:ScheduleQuestLogScan()
end

function EveryQuest:ZONE_CHANGED_NEW_AREA()
	updateCurrentZoneButtonState()
end

function EveryQuest:PLAYER_LOGOUT()
	saveSelectedZone()
end

function EveryQuest:QUEST_PROGRESS()
	local questtitle = GetTitleText()
	if questtitle then
		local questid, zoneid = self:MarkQuestByName(questtitle, 0)
		self:Debug("QUEST_PROGRESS - questid:"..concat(questid).." zoneid:"..concat(zoneid))
	end
end

function EveryQuest:QuestTurnedIn(questName, questid)
	-- history: Update Status: Quest completed, add completed timestamp
	resetCompletedQuestFlags()
	local category, daily, questLevel
	if not questid and questName then
		local _, foundCategory, foundQuestID, _, foundDaily, foundLevel = self:FindQuestLogEntryByName(questName)
		category = foundCategory
		questid = foundQuestID
		daily = foundDaily
		questLevel = foundLevel
	end
	if questid then
		local existingHistory = self:GetHistoryByQuestID(questid)
		local alreadyTurnedIn = existingHistory and existingHistory.status == 2
		local savedQuestID, zoneid, savedDaily = EveryQuest:SaveQuestHistoryByID(questid, category, 2, questName, daily, questLevel)
		if savedQuestID ~= nil and savedQuestID ~= false and zoneid ~= nil then
			self:Debug("QuestTurnedIn - questid:"..concat(savedQuestID).." zoneid:"..concat(zoneid))
			local history = self.QuestStore:GetHistory(savedQuestID, zoneid)
			history.status = 2
			history.statusSource = "automatic"
			history.completed = time()
			history.abandoned = nil
			history.failed = nil
			if savedDaily and not alreadyTurnedIn then
				if history.count ~= nil then
					history.count = history.count +1
				else
					history.count = 1
				end
			end
		else
			self:Debug("QuestTurnedIn - waiting for zone mapping for questid:"..concat(questid))
		end
	end
	self:UpdateFrame()
end

function EveryQuest:AddQuest(questindex, category, qstatus)
	if questindex then
		local questid = self:GetQID(questindex)
		if qstatus == nil then
			local _, _, _, foundStatus = self:FindQuestLogEntryByID(questid)
			qstatus = foundStatus
		end
		return self:AddQuestByID(questid, category, qstatus)
	end
end

function EveryQuest:UpdateStatus(displayid, queststatus)
	local quest = questdisplay[displayid]
	if not quest then return end
	local questid = quest.id
	local zoneid = sessionvars.zoneid
	if queststatus == nil then
		self.QuestStore:RemoveHistoryRecord(questid, zoneid)
		self:UpdateFrame()
		return
	end
	local history = self.QuestStore:EnsureHistoryRecord(questid, {
		zoneID = zoneid,
		quest = quest,
	})
	history.status = queststatus
	history.statusSource = "manual"
	history.abandoned = nil
	history.failed = nil
	if queststatus ~= 2 then
		history.completed = nil
	end
	self:UpdateFrame()
end

function EveryQuest:UpdateFrame()
	if EveryQuestFrame:IsShown() then
		updateCurrentZoneButtonState()
		for j = 1, 27, 1 do
			questdisplay[j] = nil
			local listFrame = _G["EveryQuestTitle"..j]
			if listFrame then
				listFrame:Hide()
			end
		end
		--self:Debug("UpdateFrame")
		local buttonid = 1
		local controli = 0
		local questlist
		if not sessionvars.zonegroup or not sessionvars.zoneid then
			FauxScrollFrame_Update(EveryQuestListScrollFrame,0,27,16)
			self:ShowListMessage(L["Select a zone to show quests"])
			return
		end
		if self.db.profile.view == "history" then
			self:ReconcileQuestHistoryForZone(sessionvars.zonegroup, sessionvars.zoneid)
		end
		--if self.db.profile.view == "zone" then
			--self:Debug("GetQuestData - zone zoneid:"..sessionvars["zoneid"].." zonegroup:"..sessionvars.zonegroup)
			questlist = self:GetQuestZoneData(sessionvars["zonegroup"], sessionvars["zoneid"])
		--else
			--self:Debug("GetQuestData - history zoneid:"..sessionvars.zoneid.." zonegroup:"..sessionvars.zonegroup)
		--	questlist = self.db.char.history[sessionvars.zoneid]
		--end
		--self:Debug("questlist is type:"..type(questlist))
		local questcount = 0
		local historylist = {}
		if questlist then
			for _, v in pairs (questlist) do
				if v.s then
					if v.s == sessionvars.faction or v.s == 3 or v.s == 0 then
						questcount = questcount +1
						table.insert(historylist, v.id)
					end
				end
			end
		end
		if questcount == 0 then
			FauxScrollFrame_Update(EveryQuestListScrollFrame,0,27,16)
			self:ShowListMessage(L["No quests to display"])
			return
		end
		if self.db.profile.view == "zone" then
			table.sort(questlist, function(a,b) return EveryQuest:SortTable(a,b) end)
		else
			table.sort(historylist, function(a,b) return EveryQuest:SortTable(a,b,questlist) end)
		end
		--self:Debug("QuestCount:"..questcount)
		FauxScrollFrame_Update(EveryQuestListScrollFrame,questcount,27,16)
		local scrolloffset = FauxScrollFrame_GetOffset(EveryQuestListScrollFrame)

		if questlist then
			if self.db.profile.view == "zone" then
				for k, quest in pairs (questlist) do
					if quest["s"] then
						if quest["s"] == sessionvars.faction or quest["s"] == 3 or quest["s"] == 0 then
							controli = controli + 1
							if controli > scrolloffset then
								if buttonid > 27 then
									break
								end
								self:UpdateButton(buttonid, quest, k)
								buttonid = buttonid +1
							end
						end
					end
				end
			else
				for k, id in pairs (historylist) do
					if questlist[id] and questlist[id]["s"] then
						if questlist[id]["s"] == sessionvars.faction or questlist[id]["s"] == 3 or questlist[id]["s"] == 0 then
							controli = controli + 1
							if controli > scrolloffset then
								if buttonid > 27 then
									break
								end
								self:UpdateButton(buttonid, questlist[id], k)
								buttonid = buttonid +1
							end
						end
					end
				end
			end
		end
		for j = buttonid, 27 ,1 do
			questdisplay[j] = nil
			local listFrame = _G["EveryQuestTitle"..j]
			listFrame:Hide()
		end
	end
end

function EveryQuest:SortTable(a,b,questlist)
	local sorta, sortb
	if questlist ~= nil then
		--self:Debug("sort:history")
		sorta = questlist[a]
		sortb = questlist[b]
	else
		--self:Debug("sort:zone")
		sorta = a
		sortb = b
	end
	local adaily = sorta.d or 0
	local bdaily = sortb.d or 0
	local atype = sorta.t or 9999
	local btype = sortb.t or 9999
	local alevel = sorta.l or sorta.r or 0
	local blevel = sortb.l or sortb.r or 0
	if adaily == bdaily then
		if atype == btype then
			if (alevel == blevel) then-- or (alevel == d.r) or (c.r == d.r) or (c.r == d.r) then
				if sorta.n == sortb.n then
					return false
				elseif sorta.n < sortb.n then
					return true
				elseif sorta.n > sortb.n then
					return false
				end
			elseif alevel > blevel then
				return true
			elseif alevel < blevel then
				return false
			end
		elseif atype < btype then
			return true
		elseif atype > btype then
			return false
		end
	elseif adaily > bdaily then
		return true
	elseif adaily < bdaily then
		return false
	end
end

function EveryQuest:UpdateButton(buttonid, quest, arrayid)
	local view = self.db.profile.view
	if view == "history" or view == "zone" then
		local displayQuest = quest
		if view == "history" then
			local staticQuest = self.QuestStore:GetStaticQuest(quest.id, sessionvars.zonegroup, sessionvars.zoneid)
			if staticQuest then
				displayQuest = staticQuest
			end
		end
		local listFrame = _G["EveryQuestTitle"..buttonid]
		clearButtonTexture(listFrame)
		setButtonText(listFrame, "")
		if questdisplay[buttonid] ~= displayQuest then
			questdisplay[buttonid] = displayQuest
		end
		--questdisplay[buttonid].arrayid = arrayid
		local qTag
		if displayQuest["t"] then
			--self:Debug("questtype:"..displayQuest.t)
			qTag = self:QuestType(displayQuest["t"]) or ""
		else
			qTag = ""
		end
		if displayQuest["d"] then
			--if qTag == nil then qTag = "" end
			qTag = qTag .. L["Y"]
		end
		local level
		if displayQuest["l"] then
			level = displayQuest["l"]
		else
			if displayQuest["r"] then
				level = "r"..displayQuest["r"]
			else
				level = "--"
			end
		end
		local history, historyZoneID = self.QuestStore:GetHistory(displayQuest.id, sessionvars.zoneid)
		if historyZoneID ~= sessionvars.zoneid then
			history = nil
		end
		local status = getDisplayedQuestStatus(displayQuest, history)
		local text = "["..level..qTag.."]"..self:GetQuestApiOverlayLabel(displayQuest.id)
			..getQuestPhaseLabel(displayQuest).." "..displayQuest["n"]
		text = addQuestStatusLabel(text, status)
		setButtonText(listFrame, text)
		if status ~= nil then
			setButtonTextColor(listFrame, self:GetColor(status))
		else
			setButtonTextColor(listFrame, self:GetColor("FFFFFF"))
		end
		--ListFrame:SetTextColor(r,g,b) --ListFrame:SetTextColor(GetDifficultyColor(history[j].Level).r,GetDifficultyColor(history[j].Level).g,GetDifficultyColor(history[j].Level).b)
		listFrame:Show()
	end
end

function EveryQuest:ButtonEnter(frame)
	local index = frame:GetID()
	local isCollected = false
	local quest = questdisplay[index]
	if not quest or not quest.id then return end
	local zoneid = sessionvars.zoneid
	if not zoneid then return end
	local questid = quest.id
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)
	GameTooltip:SetHyperlink("quest:"..quest.id)
	local queststatus = L["Unknown"]
	local history, historyZoneID = self.QuestStore:GetHistory(questid, zoneid)
	if historyZoneID ~= zoneid then
		history = nil
	end
	if history then
		isCollected = true
	end
	local status = getDisplayedQuestStatus(quest, history)
	if status == -1 then
		queststatus = L["Failed"]
	elseif status == -3 then
		queststatus = L["Abandoned"]
	elseif status == -2 then
		queststatus = L["Unavailable"]
	elseif status == 0 then
		queststatus = L["In Progress"]
	elseif status == 1 then
		queststatus = L["Ready to Turn In"]
	elseif status == 2 then
		queststatus = L["Completed"]
	else
		status = 99
	end
	GameTooltip:AddLine(" ", self:GetColor("FFFFFF"))
	--self:Debug("ButtonEnter - buttonid:"..index.." queststatus:"..queststatus.." status:"..status)
	GameTooltip:AddLine(L["Status: "] .. queststatus,self:GetColor(status))
	if isCollected then
		if history.completed then
			local completedline = L["Completed"]
			if history.count then
				completedline = completedline .. " ("..history.count.." "..L["Times"]..")"
			end
			completedline = completedline .. ": "..EveryQuest:timeDiff(history.completed)
			GameTooltip:AddLine(completedline,self:GetColor("FFFFFF"))

		elseif status == -1 then
			if history.failed then
				GameTooltip:AddLine(L["Failed: "] .. EveryQuest:timeDiff(history.failed),self:GetColor("FFFFFF"))
			end
		elseif status == -3 then
			if history.abandoned then
				GameTooltip:AddLine(L["Abandoned: "] .. EveryQuest:timeDiff(history.abandoned),self:GetColor("FFFFFF"))
			end
		end
	end
	GameTooltip:Show()
end

function EveryQuest:BuildQuestMenu(displayID)
	local function statusLine(text, status)
		return {
			text = text,
			checked = self:GetStatus(displayID, status),
			isNotRadio = false,
			func = function()
				self:UpdateStatus(displayID, status)
				CloseDropDownMenus()
			end,
		}
	end

	return {
		{
			text = L["Change Status"],
			isTitle = true,
			notCheckable = true,
		},
		statusLine(L["Completed"], 2),
		statusLine(L["Ready to Turn In"], 1),
		statusLine(L["In Progress"], 0),
		statusLine(L["Unavailable"], -2),
		statusLine(L["Abandoned"], -3),
		statusLine(L["Failed"], -1),
		statusLine(L["Clear Status"], nil),
		{
			text = L["Close"],
			notCheckable = true,
			func = function()
				CloseDropDownMenus()
			end,
		},
	}
end

local function initializeQuestDropdown(frame, level, menuItems)
	menuItems = menuItems or frame.menuItems
	for index, item in ipairs(menuItems or {}) do
		if item.text then
			item.index = index
			UIDropDownMenu_AddButton(item, level)
		end
	end
end

function EveryQuest:OpenQuestMenu(displayID)
	QuestMenuFrame = QuestMenuFrame or CreateFrame("Frame", "EveryQuestStatusMenu", UIParent, "UIDropDownMenuTemplate")
	local menuItems = self:BuildQuestMenu(displayID)
	QuestMenuFrame.displayMode = "MENU"
	QuestMenuFrame.menuItems = menuItems
	UIDropDownMenu_Initialize(QuestMenuFrame, initializeQuestDropdown, "MENU", nil, menuItems)
	ToggleDropDownMenu(1, nil, QuestMenuFrame, "cursor", 0, 0, menuItems)
end

function EveryQuest:ButtonClick(frame, button)
	local clickedID = frame:GetID()
	local quest = questdisplay[clickedID]
	if not quest or not quest.id then return end

	if button == "LeftButton" then
		if IsModifiedClick() then
			local editBox = ChatEdit_GetActiveWindow()
			if IsModifiedClick("CHATLINK") and editBox and editBox:IsVisible() then
				local questLink = self:CreateQuestLink(quest.id, quest.n, quest.l)
				if questLink then
					ChatEdit_InsertLink(questLink)
				end
			end
		end
	elseif button == "RightButton" then
		self:OpenQuestMenu(clickedID)
	end
end

function EveryQuest:List(value)
	--self:Debug("List()")
	if value == "toggle" then
		if self.db.profile.view == "zone" then value = "history" elseif self.db.profile.view == "history" then value = "zone" end
	end
	if value == nil then
		if self.db.profile.view ~= nil then
			value = self.db.profile.view
		else
			value = "history"
		end
	end
	if value == "history" then
		self.db.profile.view = "history"
		self:Debug("ListToggle(history)")
		EveryQuest.ListToggleButton:SetText(L["Show Zone Quests"])
		self:NewZone()
	elseif value == "zone" then
		self.db.profile.view = "zone"
		self:Debug("ListToggle(zone)")
		EveryQuest.ListToggleButton:SetText(L["Show Quest History"])
		self:NewZone()
	end
end

function EveryQuest:GetQID(index)
	if not index then return end

	return getQuestLogQuestID(index)
end

function EveryQuest:CreateQuestLink(questid, questname, questlevel)
	if questlevel == nil then questlevel = 1 end
	self:Debug("CreateQuestLink - quest:"..concat(questid)..":"..concat(questlevel))
	return "\124cffffff00\124Hquest:"..questid..":"..questlevel.."\124h["..questname.."]\124h\124r"
end

function EveryQuest:Debug(string)
	if self.db.profile.debug then
		self:Print("EveryQuest: "..string)
	end
end

function EveryQuest:Error(string)
	self:Print("EveryQuest: "..string)
end

function EveryQuest:GetColor(hex)
	if hex == 1 then
		return 0,1,0
	elseif hex == -2 then
		return .5,.5,.5
	elseif hex == -1 then
		return 1,0,0
	elseif hex == -3 then
		return 1,0,0
	elseif hex == 2 then
		return 0,.807,.019
	elseif hex == 0 then
		return 1,1,0
	elseif hex == 99 then -- Unknown
		return 1,1,1
	end
	local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
	return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
end

function EveryQuest:QuestType(qtype)
	if qtype == 1 then
		return L["G"], L["Group"]
	elseif qtype == 62 then
		return L["R"], L["Raid"]
	elseif qtype == 85 then
		return L["H"], L["Heroic"]
	elseif qtype == 81 then
		return L["D"], L["Dungeon"]
	elseif qtype == 41 then
		return L["P"], L["PvP"]
	elseif qtype == 84 then
		return L["E"], L["Escort"]
	end
	return ""
end
