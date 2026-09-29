-- Exercise the real login, preparation, scan, and browsing paths with client API stubs.
local function noop() end

local function getUpvalue(fn, name)
	for index = 1, 100 do
		local key, value = debug.getupvalue(fn, index)
		if key == name then return value end
		if not key then break end
	end
	error("Missing runtime upvalue: " .. name)
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

local function equal(actual, expected)
	assert(type(actual) == type(expected), "different value types")
	if type(expected) ~= "table" then
		assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
		return
	end
	for key, value in pairs(expected) do equal(actual[key], value) end
	for key in pairs(actual) do assert(expected[key] ~= nil, "unexpected field " .. tostring(key)) end
end

local function newHarness(failures, entries)
	local h = {printed = {}, attempts = {}, states = {}, hydrated = 0, synced = 0, scans = 0, lists = 0}
	local env = setmetatable({
		SlashCmdList = {},
		EveryQuest_Locale = setmetatable({}, {__index = function(_, key) return key end}),
		Enum = {AddOnEnableState = {None = 0, All = 2}},
		UnitName = function() return "Tester" end,
		UnitFactionGroup = function() return "Alliance" end,
		UIDropDownMenu_SetWidth = noop,
		UIDropDownMenu_SetButtonWidth = noop,
		UIDropDownMenu_SetText = noop,
		UIDropDownMenu_Initialize = noop,
		FauxScrollFrame_Update = noop,
		FauxScrollFrame_GetOffset = function() return 0 end,
	}, {__index = _G})
	env._G = env
	local frameMethods = {}
	for _, name in ipairs({"SetSize", "SetText", "ClearAllPoints", "SetPoint", "Show", "Hide", "SetID",
		"SetFrameLevel", "SetHeight", "SetJustifyH", "SetJustifyV", "SetDrawLayer", "SetTextColor",
		"SetNormalTexture", "SetVerticalScroll", "RegisterEvent", "UnregisterEvent", "Enable", "Disable"}) do
		frameMethods[name] = noop
	end
	function frameMethods:GetName() return self.name end
	function frameMethods:GetFontString() return self end
	function frameMethods:GetFrameLevel() return 1 end
	function frameMethods:IsShown() return true end
	function frameMethods:SetScript(event, handler) self.scripts[event] = handler end
	function env.CreateFrame(_, name)
		local frame = setmetatable({name = name, scripts = {}}, {__index = frameMethods})
		if name then env[name] = frame end
		return frame
	end
	for _, name in ipairs({"EveryQuestFrame", "EveryQuestTitleText", "EveryQuestExitButton", "EveryQuestListScrollFrame"}) do
		env.CreateFrame("Frame", name)
	end
	env.DEFAULT_CHAT_FRAME = {AddMessage = function(_, message) table.insert(h.printed, message) end}
	env.C_AddOns = {
		IsAddOnLoaded = function(addon) return h.states[addon] and h.states[addon].loaded == true end,
		DoesAddOnExist = function(addon) return h.states[addon] and h.states[addon].failure ~= "MISSING" end,
		GetAddOnEnableState = function(addon) return h.states[addon].failure == "DISABLED" and 0 or 2 end,
		LoadAddOn = function(addon)
			local state = assert(h.states[addon])
			state.loads = (state.loads or 0) + 1
			if state.failure == "BROKEN" then return false, "BROKEN" end
			if state.failure == "LOAD_FAILED" then return false end
			state.loaded = true
			if state.failure ~= "NO_DATA" then env.EveryQuestData[state.group] = state.data end
			return true
		end,
	}
	h.entries = entries or {
		{title = "Unknown header", isHeader = true},
		{title = "Active progress", questID = 101, level = 10, isComplete = 0},
		{title = "Active ready", questID = 102, level = 10, isComplete = 1},
	}
	env.C_QuestLog = {
		GetAllCompletedQuestIDs = function() return {101, 102, 900} end,
		GetNumQuestLogEntries = function() return #h.entries end,
		GetInfo = function(index) return h.entries[index] end,
	}
	for _, file in ipairs({"Core", "QuestStore", "QuestRelations", "QuestState", "Everyquest"}) do
		local chunk = assert(loadfile("EveryQuest/" .. file .. ".lua"))
		setfenv(chunk, env)()
	end
	local eq = env.EveryQuest
	h.eq, h.env = eq, env
	h.session = getUpvalue(eq.EveryQuestInit, "sessionvars")
	h.order = copy(eq.QuestStore.groupOrder)
	assert(table.concat(h.order, ",") == "Classes,Professions,Dungeons,Raids,Battlegrounds,Seasonal,Miscellaneous,Eastern Kingdoms,Kalimdor,Outland")
	for index, group in ipairs(h.order) do
		local zoneID = group == "Eastern Kingdoms" and 12 or index
		local data = {[zoneID] = {{id = 100 + index, n = group, l = 10, r = 8, s = 3}}}
		if group == "Classes" or group == "Outland" then
			data[zoneID][2] = {id = 900, n = group .. " duplicate", l = 1, s = 3}
		end
		h.states["EveryQuest_" .. group:gsub(" ", "_")] = {group = group, data = data, failure = failures and failures[group]}
	end
	eq.CreateOptions = noop
	eq.UpdateButton = noop -- Pixel drawing is outside this runtime test; List/UpdateFrame still run.
	eq:ADDON_LOADED("EveryQuest")
	eq.db.char.zonegroup, eq.db.char.zoneid = "Eastern Kingdoms", 12
	eq.db.char.history[2] = {[102] = {id = 102, n = "Quest 102", s = 3, status = 0}}
	eq.QuestStore:SetHistoryRoot(eq.db.char.history)

	local prepare, hydrate, sync = eq.PrepareQuestDataGroup, eq.HydrateQuestHistoryForGroup, eq.SyncCompletedQuestFlagsForGroup
	function eq:PrepareQuestDataGroup(group)
		table.insert(h.attempts, group)
		local data, reason, stats = prepare(self, group)
		return data, reason, stats
	end
	function eq:HydrateQuestHistoryForGroup(group)
		h.hydrated = h.hydrated + 1
		return hydrate(self, group)
	end
	function eq:SyncCompletedQuestFlagsForGroup(group, reportStatus)
		assert(reportStatus == false)
		h.synced = h.synced + 1
		return sync(self, group, reportStatus)
	end
	local initialize, scan, reporter, list = eq.InitializeAllQuestData, eq.ScanQuestLog, eq.PrintInitializationSummary, eq.List
	function eq:InitializeAllQuestData()
		assert(h.session.zonegroup == "Eastern Kingdoms" and h.session.zoneid == 12, "initial zone must precede preparation")
		h.summary = initialize(self)
		return h.summary
	end
	function eq:ScanQuestLog(reportStatus)
		h.scans = h.scans + 1
		assert(reportStatus == false, "automatic scan must be quiet")
		equal(h.attempts, h.order)
		assert(h.session.initialized == nil and #h.printed == 0)
		for _, group in ipairs(h.order) do
			if not (failures and failures[group]) then assert(h.session.preparedGroups[group]) end
		end
		return scan(self, reportStatus)
	end
	function eq:PrintInitializationSummary(data, log)
		assert(h.scans == 1 and h.lists == 0 and h.session.initialized == nil)
		h.logSummary = copy(log)
		return reporter(self, data, log)
	end
	function eq:List(view)
		h.lists = h.lists + 1
		assert(h.scans == 1 and #h.printed == 1 and h.session.initialized == nil)
		return list(self, view)
	end
	h.scan, h.reporter, h.initialize = scan, reporter, initialize
	h.compat = eq.LoadQuestData
	function eq:LoadQuestData() error("startup must not call the compatibility adapter") end
	function h:login()
		eq:PLAYER_LOGIN()
		assert(h.session.initialized == true and h.session.initializingQuestData == nil)
		assert(h.scans == 1 and h.lists == 1 and #h.printed == 1)
		assert(h.session.questDataLoadFailures == nil, "startup must not consume user failure messages")
		equal(h.attempts, h.order)
		eq.LoadQuestData = h.compat
	end
	return h
end

local h = newHarness()
local records = {}
for _, state in pairs(h.states) do
	for _, quests in pairs(state.data) do
		for _, quest in ipairs(quests) do records[quest] = copy(quest) end
	end
end
h:login()
equal(h.summary, {
	totalGroups = 10, preparedGroups = 10, newlyLoadedGroups = 10, alreadyPreparedGroups = 0,
	failedGroups = 0, failures = {}, hydrated = 1, checked = 12, completed = 4, added = 2, changed = 1,
})
assert(h.printed[1] == "EveryQuest: Ready — 10/10 quest data groups; 2 active quests.")
assert(h.eq:GetHistoryByQuestID(101).status == 0, "active In Progress must follow completed sync")
assert(h.eq:GetHistoryByQuestID(102).status == 1, "active Ready to Turn In must follow completed sync")
local duplicate, group = h.eq.QuestStore:GetStaticQuest(900)
assert(group == "Classes" and duplicate.n == "Classes duplicate", "canonical duplicate precedence must be retained")
assert(h.env.EveryQuestDB.schemaVersion == 1 and h.env.EveryQuestDBPC.schemaVersion == 1)
for quest, snapshot in pairs(records) do equal(quest, snapshot) end

assert(h.eq:GetQuestZoneData("Eastern Kingdoms", 12, "zone"))
assert(h.eq:GetQuestZoneData("Eastern Kingdoms", 12, "zone"))
assert(h.hydrated == 10 and h.synced == 10 and #h.printed == 1, "browsing must reuse preparation quietly")
local repeated = h.initialize(h.eq)
assert(repeated ~= h.summary and repeated.failures ~= h.summary.failures)
equal(repeated, {
	totalGroups = 10, preparedGroups = 10, newlyLoadedGroups = 0, alreadyPreparedGroups = 10,
	failedGroups = 0, failures = {}, hydrated = 0, checked = 0, completed = 0, added = 0, changed = 0,
})
assert(h.hydrated == 10 and h.synced == 10 and #h.printed == 1)
h.eq:PLAYER_LOGIN()
assert(h.scans == 1 and h.lists == 1 and #h.printed == 1, "initialized session must not run startup twice")

h = newHarness()
h.eq.db.profile.view = "history"
h:login()
assert(h.eq.db.profile.view == "history", "saved history view must be preserved")

-- Missing saved-zone data must stay quiet even when the real saved view renders.
local failureModes = {"MISSING", "DISABLED", "BROKEN", "LOAD_FAILED", "NO_DATA"}
for _, reason in ipairs(failureModes) do
	h = newHarness({["Eastern Kingdoms"] = reason})
	h:login()
	assert(h.summary.failedGroups == 1 and h.summary.preparedGroups == 9)
	assert(h.summary.newlyLoadedGroups == (reason == "NO_DATA" and 10 or 9))
	equal(h.summary.failures, {{group = "Eastern Kingdoms", reason = reason}})
	assert(not h.session.preparedGroups["Eastern Kingdoms"])
	assert(h.printed[1] == "EveryQuest: Ready with warnings — 9/10 quest data groups; 2 active quests; 1 group failed.")
	assert(h.eq:GetQuestZoneData("Eastern Kingdoms", 12, "zone") == false)
	assert(h.session.questDataLoadFailures["Eastern Kingdoms"] and #h.printed == 2)
	assert(h.eq:GetQuestZoneData("Eastern Kingdoms", 12, "zone") == false and #h.printed == 2)
	local state = h.states.EveryQuest_Eastern_Kingdoms
	state.failure, state.loaded = nil, false
	assert(h.eq:GetQuestZoneData("Eastern Kingdoms", 12, "zone") == state.data[12])
	assert(h.session.preparedGroups["Eastern Kingdoms"] and h.hydrated == 10 and h.synced == 10)
	assert(#h.printed == 2, "successful retry must remain quiet")
	h.summary.failures[1].group = "mutated result"
	assert(h.session.preparedGroups["Eastern Kingdoms"], "summary must not expose internal state")
end

h = newHarness({Classes = "MISSING", Professions = "DISABLED"}, {
	{title = "Unknown header", isHeader = true},
	{questID = 99998, title = "Unknown one"},
	{questID = 99999, title = "Unknown two"},
})
h:login()
assert(h.summary.failedGroups == 2 and h.summary.preparedGroups == 8)
assert(h.logSummary.scanned == 2 and h.logSummary.missing == 2)
assert(h.printed[1] == "EveryQuest: Ready with warnings — 8/10 quest data groups; 2 active quests; 2 groups failed; 2 active quests unmapped.")
-- Explicit reporting callers retain both status lines and individual unmapped details.
h.scan(h.eq, true)
assert(#h.printed == 5 and h.printed[2]:find("updating quest history", 1, true))
assert(h.printed[4]:find("unmapped quest 99998", 1, true) and h.printed[5]:find("unmapped quest 99999", 1, true))

h = newHarness(nil, {{questID = 99999, title = "Unknown"}})
h:login()
assert(h.printed[1] == "EveryQuest: Ready with warnings — 10/10 quest data groups; 1 active quest; 1 active quest unmapped.")
h = newHarness(nil, {})
h:login()
assert(h.printed[1] == "EveryQuest: Ready — 10/10 quest data groups; 0 active quests.")
h.printed = {}
h.reporter(h.eq, h.summary, {scanned = false})
assert(#h.printed == 1 and h.printed[1] == "EveryQuest: Ready with warnings — 10/10 quest data groups; quest log scan failed.")

-- Direct initialization itself stays silent; diagnostic details use the existing Debug gate.
h = newHarness({Classes = "MISSING"})
local summary = h.initialize(h.eq)
assert(summary.failedGroups == 1 and #h.printed == 0)
h.eq.db.profile.debug = true
h.initialize(h.eq)
local failureDebugged = false
for _, message in ipairs(h.printed) do
	if message:find("Quest data preparation failed: Classes: MISSING", 1, true) then failureDebugged = true end
end
assert(failureDebugged and h.session.questDataLoadFailures == nil)

print("Quest data startup tests passed.")
