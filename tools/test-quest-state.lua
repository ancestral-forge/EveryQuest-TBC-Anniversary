local previousEveryQuest = _G.EveryQuest
_G.EveryQuest = {}
dofile("EveryQuest/QuestStore.lua")
dofile("EveryQuest/QuestRelations.lua")
dofile("EveryQuest/QuestState.lua")
local addon = _G.EveryQuest
_G.EveryQuest = previousEveryQuest

local root = {[10] = {}}
local store = addon.QuestStore:Create(root, {groupOrder = {"Test"}})
local relations = addon.QuestRelations:Create(nil, {getQuestieLoader = function() return nil end})
local level = 10
local completed = {}
local service = addon.QuestState:Create({
	store = store,
	relations = relations,
	getPlayerLevel = function() return level end,
	isQuestFlaggedCompleted = function(id) return completed[id] end,
})
local quest = {id = 100, r = 11, followUps = {101, 102}}
store:RegisterGroup("Test", {[10] = {quest}})

local function save(id, status, source)
	local history = store:EnsureHistoryRecord(id, {zoneID = 10, quest = {id = id}})
	history.status = status
	history.statusSource = source
	return history
end

local names = {[-3] = "abandoned", [-1] = "failed", [0] = "in_progress", [1] = "ready_to_turn_in", [2] = "completed"}
for status, name in pairs(names) do
	for _, source in ipairs({"manual", "automatic", "unknown"}) do
		local history = {id = 100, status = status, statusSource = source ~= "unknown" and source or nil}
		local state = service:Evaluate(quest, history)
		assert(state.progress.status == name and state.progress.source == source)
		assert(state.availability.state == "unavailable", "progress must not suppress independent reasons")
		assert(state.availability.reasons[1].code == "REQUIRED_LEVEL")
		assert(service:ToLegacyStatus(state) == status, "own progress must retain numeric precedence, including zero")
		assert(history.status == status and quest.status == nil, "state reads must not mutate inputs")
	end
end

local state = service:Evaluate(quest)
assert(state.progress.status == "unknown" and state.progress.source == "unknown")
assert(state.availability.source == "derived")
assert(state.availability.reasons[1].requiredLevel == 11 and state.availability.reasons[1].playerLevel == 10)
assert(service:ToLegacyStatus(state) == -2)

local abandoned = {id = 100, status = -1, abandoned = "20", failed = "10"}
assert(service:Evaluate(quest, abandoned).progress.status == "abandoned")
assert(abandoned.status == -1 and abandoned.statusSource == nil)
abandoned.failed = 20
assert(service:Evaluate(quest, abandoned).progress.status == "failed", "equal timestamps favor Failed")
abandoned.failed = nil
assert(service:GetStoredStatus(abandoned) == -3)
abandoned.abandoned = "invalid"
assert(service:GetStoredStatus(abandoned) == -3, "preserve legacy timestamp fallback")
assert(service:GetStoredStatus(false) == nil)

local manual = service:Evaluate(quest, {status = -2})
assert(manual.progress.status == "unknown" and manual.availability.source == "manual")
assert(manual.availability.reasons[1].code == "MANUAL_OVERRIDE")
assert(manual.availability.reasons[2].code == "REQUIRED_LEVEL")
assert(service:ToLegacyStatus(manual) == -2)
assert(service:Evaluate(quest, {status = 0, statusSource = "bad"}).progress.source == "unknown")

level = 11
assert(service:Evaluate(quest).availability.state == "unknown", "meeting level alone does not prove availability")
level = 70
assert(service:ToLegacyStatus(service:Evaluate(quest)) == nil)
for _, invalid in ipairs({0, -1, math.huge, -math.huge, 0/0, false, "bad", 1.5}) do
	level = invalid
	assert(service:Evaluate(quest).availability.state == "unknown", "invalid level is not blocking evidence")
end
level = nil
assert(service:Evaluate(quest).availability.state == "unknown")
level = 10
for _, invalid in ipairs({0, -1, math.huge, -math.huge, 0/0, false, "bad", 10.5}) do
	assert(service:Evaluate({id = 200, r = invalid}).availability.state == "unknown")
end
assert(service:Evaluate({id = 200, r = "11"}).availability.state == "unavailable")
assert(service:Evaluate({id = 200}).availability.state == "unknown")
service:Configure({getPlayerLevel = function() error("not ready") end})
assert(service:Evaluate(quest).availability.state == "unknown")
service:Configure({getPlayerLevel = function() return level end})

level = 70
for _, status in ipairs({-3, -2, -1, 0, 1, 2}) do
	save(101, status)
	state = service:Evaluate(quest)
	local advanced = status == 0 or status == 1 or status == 2
	assert((state.availability.state == "unavailable") == advanced)
	if advanced then
		local reason = state.availability.reasons[1]
		assert(reason.code == "CHAIN_ADVANCED" and reason.questID == 101 and reason.source == "history")
		assert(reason.relationSource == "bundled")
	end
end
store:RemoveHistoryRecord(101, 10)
completed[101] = true
state = service:Evaluate(quest)
assert(state.availability.reasons[1].source == "completed_flag")
completed[101] = false
assert(service:Evaluate(quest).availability.state == "unknown")
service:Configure({isQuestFlaggedCompleted = function() error("API unavailable") end})
assert(service:Evaluate(quest).availability.state == "unknown")
service:Configure({isQuestFlaggedCompleted = function(id) return completed[id] end})

level = 10
save(101, 0, "automatic")
save(102, 2, "automatic")
state = service:Evaluate(quest, {status = 1, statusSource = "manual"})
assert(#state.availability.reasons == 3)
assert(state.availability.reasons[1].code == "REQUIRED_LEVEL")
assert(state.availability.reasons[2].questID == 101 and state.availability.reasons[3].questID == 102)
assert(service:ToLegacyStatus(state) == 1)
state.availability.reasons[1].requiredLevel = 999
state.progress.status = "failed"
assert(service:Evaluate(quest).availability.reasons[1].requiredLevel == 11, "results must not alias previous snapshots")
assert(quest.r == 11 and root[10][101].status == 0)

local ownHistory = save(100, 0, "manual")
assert(service:Get("100", "Test", 10).progress.source == "manual")
assert(service:Get(100).questID == 100)
assert(ownHistory.status == 0 and ownHistory.statusSource == "manual")
store:RemoveHistoryRecord(100, 10)
assert(service:Get(100).progress.status == "unknown", "Clear Status must not leave a cached override")
for _, invalid in ipairs({0, -1, math.huge, 0/0, false, {}, "bad", 1.5, 16777216}) do
	assert(service:Get(invalid).availability.state == "unknown")
end
assert(service:Get(nil).availability.state == "unknown")
assert(service:Get(999).questID == 999 and service:Get(999).availability.state == "unknown")
assert(addon.QuestState:Create():Evaluate(nil).availability.state == "unknown")
assert(service:ToLegacyStatus(nil) == nil)

-- Hints retain occurrence-specific static and history selection.
local duplicateRoot = {[10] = {[100] = {id = 100, status = 1}}, [20] = {[100] = {id = 100, status = 2}}}
local duplicateStore = addon.QuestStore:Create(duplicateRoot, {groupOrder = {"Test"}})
duplicateStore:RegisterGroup("Test", {[10] = {{id = 100, r = 5}}, [20] = {{id = 100, r = 60}}})
local duplicateService = addon.QuestState:Create({store = duplicateStore, getPlayerLevel = function() return 10 end})
assert(duplicateService:Get(100, "Test", 10).progress.status == "ready_to_turn_in")
assert(duplicateService:Get(100, "Test", 10).availability.state == "unknown")
assert(duplicateService:Get(100, "Test", 20).progress.status == "completed")
assert(duplicateService:Get(100, "Test", 20).availability.reasons[1].requiredLevel == 60)

-- Provenance follows the winning status, not the missing-field iteration order.
local mergeRoot = {
	[10] = {[1] = {id = 1, status = 1}, [2] = {id = 2, count = 5, statusSource = "manual"}},
	[20] = {[1] = {id = 1, status = 2, statusSource = "automatic", count = 3}, [2] = {id = 2, status = 0}},
}
local mergeStore = addon.QuestStore:Create(mergeRoot)
local merged = mergeStore:MoveHistoryToZone(1, 10)
assert(merged.status == 1 and merged.statusSource == nil and merged.count == 3)
merged = mergeStore:MoveHistoryToZone(2, 10)
assert(merged.status == 0 and merged.statusSource == nil and merged.count == 5)
local taggedRoot = {[10] = {[3] = {id = 3}}, [20] = {[3] = {id = 3, status = 2, statusSource = "automatic"}}}
mergeStore:SetHistoryRoot(taggedRoot)
merged = mergeStore:MoveHistoryToZone(3, 10)
assert(merged.status == 2 and merged.statusSource == "automatic")

print("Quest state tests passed.")
