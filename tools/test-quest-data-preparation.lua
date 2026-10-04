local sourceFile = assert(io.open("EveryQuest/Everyquest.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()

EveryQuest = {}
EveryQuestData = {}
EveryQuest_Locale = setmetatable({}, {__index = function(_, key) return key end})
rawset(_G, "Enum", {AddOnEnableState = {None = 0, All = 2}})

local harnessSessionVars = {}
local printed = {}
local addonStates = {}
local completedQuestIDs = {}

rawset(_G, "UnitName", function()
	return "Tester"
end)

rawset(_G, "C_QuestLog", {
	GetAllCompletedQuestIDs = function()
		return completedQuestIDs
	end,
})

rawset(_G, "C_AddOns", {
	IsAddOnLoaded = function(addon)
		return addonStates[addon] and addonStates[addon].loaded == true
	end,
	DoesAddOnExist = function(addon)
		local state = addonStates[addon]
		return state and state.exists ~= false
	end,
	GetAddOnEnableState = function(addon)
		local state = addonStates[addon]
		if state and state.disabled then
			return Enum.AddOnEnableState.None
		end
		return Enum.AddOnEnableState.All
	end,
	LoadAddOn = function(addon)
		local state = addonStates[addon] or {}
		state.attempts = (state.attempts or 0) + 1
		addonStates[addon] = state
		if state.loadOK == false then
			return false, state.reason
		end
		state.loaded = true
		if state.group and state.data then
			EveryQuestData[state.group] = state.data
		end
		return true
	end,
})

dofile("EveryQuest/QuestStore.lua")

local concatSource = assert(source:match("(local function concat.-)\nlocal function getZoneListMenu"))
local completedSource = assert(source:match("(local completedQuestFlags.-)\nEveryQuest%.QuestState:Configure"))
local loaderSource = assert(source:match("(local function getQuestDataAddonName.-)\nlocal function getQuestLogInfo"))
local prepSource = assert(source:match("(function EveryQuest:HydrateQuestHistoryForGroup.-)\nfunction EveryQuest:GetStatus"))
local staticLookupSource = assert(source:match("(local canonicalQuestSearchGroups.-)\nfunction EveryQuest:ReconcileQuestHistoryForZone"))

assert(loadstring(table.concat({
	"local L = EveryQuest_Locale",
	"local sessionvars = ...",
	concatSource,
	completedSource,
	"function EveryQuest:ResetCompletedQuestFlagsForTest() resetCompletedQuestFlags() end",
	loaderSource,
	prepSource,
	staticLookupSource,
}, "\n")))(harnessSessionVars)

function EveryQuest:Debug()
end

function EveryQuest:Print(message)
	table.insert(printed, message)
end

local originalHydrateQuestHistoryForGroup = EveryQuest.HydrateQuestHistoryForGroup
local originalSyncCompletedQuestFlagsForGroup = EveryQuest.SyncCompletedQuestFlagsForGroup

local function clearTable(target)
	for key in pairs(target) do
		target[key] = nil
	end
end

local function cloneQuestData()
	return {
		Kalimdor = {
			[15] = {
				{id = 100, n = "Completed Static", l = 10, r = 8, s = 1},
				{id = 101, n = "Hydrated Static", l = 11, r = 9, s = 1},
			},
		},
		Dungeons = {
			[2100] = {
				{id = 300, n = "Indexed Completed", l = 42, r = 39, s = 1, t = 81},
				{id = 301, n = "Indexed Hydrated", l = 43, r = 40, s = 1},
			},
		},
	}
end

local registerCalls
local hydrateCalls
local syncCalls

local function resetHarness()
	clearTable(harnessSessionVars)
	clearTable(printed)
	clearTable(addonStates)
	clearTable(completedQuestIDs)
	EveryQuestData = {}
	EveryQuest.db = {
		profile = {debug = false},
		char = {
			history = {},
		},
	}
	EveryQuest.QuestStore = EveryQuest.QuestStore:Create(EveryQuest.db.char.history, {
		groupOrder = {
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
		},
	})
	EveryQuest.QuestStore:Configure({
		loader = function(group)
			return EveryQuest:EnsureQuestDataLoaded(group)
		end,
	})
	EveryQuest:ResetCompletedQuestFlagsForTest()

	registerCalls = 0
	hydrateCalls = 0
	syncCalls = 0

	local store = EveryQuest.QuestStore
	local storePrototype = getmetatable(store).__index
	local baseRegisterGroup = storePrototype.RegisterGroup
	function store:RegisterGroup(group, groupData)
		registerCalls = registerCalls + 1
		return baseRegisterGroup(self, group, groupData)
	end

	function EveryQuest:HydrateQuestHistoryForGroup(group)
		hydrateCalls = hydrateCalls + 1
		return originalHydrateQuestHistoryForGroup(self, group)
	end

	function EveryQuest:SyncCompletedQuestFlagsForGroup(group, reportStatus)
		assert(reportStatus == false, "preparation must suppress per-group completed sync output")
		syncCalls = syncCalls + 1
		return originalSyncCompletedQuestFlagsForGroup(self, group, reportStatus)
	end
end

local allData = cloneQuestData()
resetHarness()
completedQuestIDs[1] = 100
EveryQuest.db.char.history[15] = {
	[101] = {
		id = 101,
		n = "Quest 101",
		s = 3,
		status = -1,
	},
}
EveryQuest.QuestStore:SetHistoryRoot(EveryQuest.db.char.history)
addonStates.EveryQuest_Kalimdor = {
	group = "Kalimdor",
	data = allData.Kalimdor,
}

local data, reason, newlyLoaded = EveryQuest:EnsureQuestDataLoaded("Kalimdor")
assert(data == allData.Kalimdor)
assert(reason == nil and newlyLoaded == true)
assert(addonStates.EveryQuest_Kalimdor.attempts == 1)
assert(registerCalls == 0 and hydrateCalls == 0 and syncCalls == 0, "ensure must not prepare data")
assert(#printed == 0, "ensure success must be quiet")

local again, againReason, againNewlyLoaded = EveryQuest:EnsureQuestDataLoaded("Kalimdor")
assert(again == data and againReason == nil and againNewlyLoaded == false)
assert(addonStates.EveryQuest_Kalimdor.attempts == 1, "already loaded data must be returned without reloading")

local prepared, prepReason, stats = EveryQuest:PrepareQuestDataGroup("Kalimdor")
assert(prepared == allData.Kalimdor and prepReason == nil)
assert(stats.newlyLoaded == false and stats.alreadyPrepared == false)
assert(stats.hydrated == 1, "first preparation must hydrate saved records")
assert(stats.checked == 2 and stats.completed == 1 and stats.added == 1 and stats.changed == 0)
assert(registerCalls == 2 and hydrateCalls == 1 and syncCalls == 1)
assert(harnessSessionVars.preparedGroups.Kalimdor == true)
assert(EveryQuest.db.char.history[15][101].n == "Hydrated Static")
assert(EveryQuest.db.char.history[15][100].status == 2)
assert(allData.Kalimdor[15][1].status == nil, "static quest records must not receive completed status")

local preparedAgain, secondReason, secondStats = EveryQuest:PrepareQuestDataGroup("Kalimdor")
assert(preparedAgain == prepared and secondReason == nil)
assert(secondStats.alreadyPrepared == true and secondStats.newlyLoaded == false)
assert(secondStats.hydrated == 0 and secondStats.checked == 0 and secondStats.completed == 0)
assert(registerCalls == 2 and hydrateCalls == 1 and syncCalls == 1, "second preparation must be a cheap no-op")

local loaded = EveryQuest:LoadQuestData("Kalimdor")
local loadedAgain = EveryQuest:LoadQuestData("Kalimdor")
assert(loaded == allData.Kalimdor and loadedAgain == allData.Kalimdor)
assert(#printed == 0, "successful compatibility loads must not print ordinary chat output")

local staticQuest, staticGroup, staticZone = EveryQuest.QuestStore:GetStaticQuest(100, "Kalimdor", 15)
assert(staticQuest == allData.Kalimdor[15][1] and staticGroup == "Kalimdor" and staticZone == 15)
local history, historyZone = EveryQuest.QuestStore:GetHistory(100, 15)
assert(history.status == 2 and historyZone == 15, "indexed lookup and history behavior must remain available")

resetHarness()
allData = cloneQuestData()
completedQuestIDs[1] = 300
EveryQuest.db.char.history[2100] = {
	[301] = {
		id = 301,
		n = "Quest 301",
		s = 3,
		status = -1,
	},
}
EveryQuest.QuestStore:SetHistoryRoot(EveryQuest.db.char.history)
addonStates.EveryQuest_Dungeons = {
	group = "Dungeons",
	data = allData.Dungeons,
}
local indexedQuest = EveryQuest.QuestStore:GetStaticQuest(300, "Dungeons", 2100)
assert(indexedQuest == allData.Dungeons[2100][1], "QuestStore loader must still index static data")
local registerAfterLookup = registerCalls
local preparedIndexed, indexedReason, indexedStats = EveryQuest:PrepareQuestDataGroup("Dungeons")
assert(preparedIndexed == allData.Dungeons and indexedReason == nil)
assert(indexedStats.newlyLoaded == false and indexedStats.alreadyPrepared == false)
assert(indexedStats.hydrated == 1 and indexedStats.checked == 2 and indexedStats.completed == 1)
assert(hydrateCalls == 1 and syncCalls == 1)
assert(registerCalls > registerAfterLookup, "preparation must register or confirm already indexed data")
EveryQuest:PrepareQuestDataGroup("Dungeons")
assert(hydrateCalls == 1 and syncCalls == 1, "QuestStore-preloaded group must be prepared exactly once")

resetHarness()
addonStates.EveryQuest_Outland = {
	loadOK = false,
	reason = "BROKEN",
}
assert(EveryQuest:LoadQuestData("Outland") == false)
assert(EveryQuest:LoadQuestData("Outland") == false)
assert(addonStates.EveryQuest_Outland.attempts == 2, "duplicate failure suppression must not suppress retries")
assert(#printed == 1)
assert(printed[1] == "Could not load Outland Quest Data: BROKEN")
addonStates.EveryQuest_Outland.loadOK = true
addonStates.EveryQuest_Outland.group = "Outland"
addonStates.EveryQuest_Outland.data = {
	[3483] = {
		{id = 400, n = "Successful Retry", l = 60, r = 58, s = 3},
	},
}
local retryData = EveryQuest:LoadQuestData("Outland")
assert(retryData == addonStates.EveryQuest_Outland.data)
assert(harnessSessionVars.preparedGroups.Outland == true, "later successful retry must prepare normally")
assert(#printed == 1, "successful retry must remain quiet")

resetHarness()
addonStates.EveryQuest_Classes = {exists = false}
addonStates.EveryQuest_Professions = {disabled = true}
addonStates.EveryQuest_Battlegrounds = {loadOK = false, reason = "BROKEN"}
addonStates.EveryQuest_Seasonal = {}
assert(EveryQuest:LoadQuestData("Classes") == false)
assert(EveryQuest:LoadQuestData("Professions") == false)
assert(EveryQuest:LoadQuestData("Battlegrounds") == false)
assert(EveryQuest:LoadQuestData("Seasonal") == false)
assert(printed[1] == "Requires LOD Module: EveryQuest_Classes")
assert(printed[2] == "Disabled LOD Module: EveryQuest_Professions")
assert(printed[3] == "Could not load Battlegrounds Quest Data: BROKEN")
assert(printed[4] == "Could not load Seasonal Quest Data: NO_DATA")

local invalidData, invalidReason, invalidNewlyLoaded = EveryQuest:EnsureQuestDataLoaded(nil)
assert(invalidData == nil and invalidReason == "INVALID_GROUP" and invalidNewlyLoaded == false)

print("Quest data preparation tests passed.")
