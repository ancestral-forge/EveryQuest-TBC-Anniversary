local sourceFile = assert(io.open("EveryQuest/Everyquest.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()

local previousEveryQuest = _G.EveryQuest
_G.EveryQuest = {}
dofile("EveryQuest/QuestStore.lua")
dofile("EveryQuest/QuestRelations.lua")
dofile("EveryQuest/QuestState.lua")
local addon = _G.EveryQuest
_G.EveryQuest = previousEveryQuest

local quest = {id = 200, n = "State test", r = 11, s = 3}
local data = {Test = {[10] = {quest}}}
addon.db = {char = {history = {[10] = {}}}}
addon.QuestStore:SetHistoryRoot(addon.db.char.history)
addon.QuestStore:Configure({groupOrder = {"Test"}})
addon.QuestStore:RegisterGroup("Test", data.Test)
addon.QuestRelations:Configure({getQuestieLoader = function() return nil end})
function addon:GetHistoryByQuestID(id) return self.QuestStore:GetHistory(id) end
function addon:FindQuestLogEntryByID() end
function addon:GetQuestData(id) return self.QuestStore:GetStaticQuest(id), 10 end
function addon:RequestFrameUpdate() end
function addon:UpdateFrame() end
function addon:Debug() end

local completed = false
local environment = setmetatable({
	UnitLevel = function() return 10 end,
	time = function() return 123 end,
	concat = tostring,
}, {__index = _G})
-- Only existing WoW-bound adapters are extracted; state internals load via dofile.
local wiring = assert(source:match("(EveryQuest%.QuestState:Configure.-)\n%-%- Disable each phase"))
local adapterLoader = assert(loadstring("local EveryQuest, isQuestFlaggedCompleted = ...\n" .. wiring .. "\nreturn getDisplayedQuestStatus"))
setfenv(adapterLoader, environment)
local displayed = adapterLoader(addon, function() return completed end)
assert(displayed(quest) == -2)
assert(displayed(quest, {status = 0}) == 0)
assert(addon:GetQuestState(200).availability.reasons[1].code == "REQUIRED_LEVEL")

local function fragment(first, following)
	return assert(source:match("(function EveryQuest:" .. first .. ".-)\nfunction EveryQuest:" .. following))
end
local loader = assert(loadstring(table.concat({
	"local EveryQuest, questdisplay, sessionvars, EveryQuestData, isQuestFlaggedCompleted = ...",
	"local function getQuestContext() end",
	"local function rememberQuestContext() end",
	"local function getZoneIDByCategory() return 10, 'Test' end",
	"local function resetCompletedQuestFlags() end",
	fragment("SaveQuestHistoryByID", "AddQuestByID"),
	fragment("AddQuestByID", "MarkQuestByID"),
	fragment("MarkQuestByID", "MarkQuestByName"),
	fragment("QuestTurnedIn", "AddQuest"),
	fragment("UpdateStatus", "UpdateFrame"),
	fragment("SyncCompletedQuestFlagsForGroup", "EnsureQuestDataLoaded"),
}, "\n")))
setfenv(loader, environment)
local session = {zoneid = 10}
loader(addon, {[1] = quest}, session, data, function() return completed end)

addon:UpdateStatus(1, 0)
local history = addon.QuestStore:GetHistory(200)
assert(history.status == 0 and history.statusSource == "manual")
local _, _, _, added, changed = addon:SaveQuestHistoryByID(200, "Test", 0)
assert(not added and not changed, "source metadata must not change progress counters")
assert(history.statusSource == "automatic", "same-status automatic observations replace provenance")
addon:UpdateStatus(1, 1)
addon:AddQuestByID(200, nil, 1)
assert(history.status == 1 and history.statusSource == "automatic")
addon:UpdateStatus(1, -1)
addon:MarkQuestByID(200, -3, "abandoned", "Test")
assert(history.status == -3 and history.statusSource == "automatic" and history.abandoned == 123)
addon:QuestTurnedIn("State test", 200)
assert(history.status == 2 and history.statusSource == "automatic" and history.completed == 123)
addon:UpdateStatus(1, 2)
completed = true
addon:SyncCompletedQuestFlagsForGroup("Test", false)
assert(history.statusSource == "automatic", "completed-flag sync must tag its observation")
addon:UpdateStatus(1, -2)
assert(addon:GetQuestState(200).availability.source == "manual")
addon:UpdateStatus(1, nil)
assert(addon.QuestStore:GetHistory(200) == nil)
assert(addon:GetQuestState(200).availability.source == "derived")
assert(quest.status == nil and quest.statusSource == nil)

print("Quest state writer and production adapter tests passed.")
