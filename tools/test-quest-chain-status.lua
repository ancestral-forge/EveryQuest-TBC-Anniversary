local previousEveryQuest = _G.EveryQuest
_G.EveryQuest = {}
dofile("EveryQuest/QuestRelations.lua")
dofile("EveryQuest/QuestState.lua")
local addon = _G.EveryQuest
_G.EveryQuest = previousEveryQuest

local histories, completed = {}, {}
local chain = {[100] = 101}
local queryCalls = 0
local questieLoader = {
	ImportModule = function(_, moduleName)
		assert(moduleName == "QuestieDB")
		return {
			QueryQuestSingle = function(questID, field)
				queryCalls = queryCalls + 1
				assert(field == "nextQuestInChain")
				return chain[questID]
			end,
		}
	end,
}
local relations = addon.QuestRelations:Create(nil, {
	getQuestieLoader = function() return questieLoader end,
})
local state = addon.QuestState:Create({
	store = {GetHistory = function(_, questID) return histories[questID] end},
	relations = relations,
	getPlayerLevel = function() return 70 end,
	isQuestFlaggedCompleted = function(questID) return completed[questID] == true end,
})
local function evaluate(quest, history)
	local result = state:Evaluate(quest, history)
	return state:ToLegacyStatus(result), result
end
local firstQuest = {id = 100, n = "First Quest", r = 1}
assert(evaluate(firstQuest) == nil)
assert(queryCalls == 1)
assert(evaluate(firstQuest) == nil)
assert(queryCalls == 1, "valid relations remain cached in QuestRelations, not state")

histories[101] = {id = 101, status = 0}
local legacy, result = evaluate(firstQuest)
assert(legacy == -2 and result.availability.reasons[1].code == "CHAIN_ADVANCED")
assert(result.availability.reasons[1].questID == 101)
assert(result.availability.reasons[1].relationSource == "questie")
assert(evaluate(firstQuest, {id = 100, status = 1, statusSource = "manual"}) == 1)

histories[101] = nil
completed[101] = true
assert(evaluate(firstQuest) == -2)
completed[101] = false
assert(evaluate(firstQuest) == nil, "changing completion evidence must not need reload")

local embeddedCalls = queryCalls
histories[201] = {id = 201, status = 2}
assert(evaluate({id = 200, nextQuestInChain = 201, r = 1}) == -2)
assert(queryCalls == embeddedCalls, "bundled follow-ups take precedence over Questie")

questieLoader = nil
local unrelated = {id = 300, r = 1}
legacy, result = evaluate(unrelated)
assert(legacy == nil and result.availability.state == "unknown")
questieLoader = {ImportModule = function() error("Questie not ready") end}
assert(evaluate(unrelated) == nil, "faulty optional provider must fail open")
questieLoader = {
	ImportModule = function()
		return {QueryQuestSingle = function() return 301 end}
	end,
}
histories[301] = {status = 1}
assert(evaluate(unrelated) == -2, "failed lookups must recover without a reload")

print("Quest chain status tests passed.")
