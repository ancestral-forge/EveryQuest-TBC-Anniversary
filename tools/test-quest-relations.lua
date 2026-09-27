local previousEveryQuest = _G.EveryQuest
_G.EveryQuest = {}
dofile("EveryQuest/QuestRelations.lua")
local QuestRelations = _G.EveryQuest.QuestRelations
_G.EveryQuest = previousEveryQuest

local function assertArray(actual, expected, message)
	assert(#actual == #expected, (message or "array length mismatch") .. ": " .. #actual .. " ~= " .. #expected)
	for index, value in ipairs(expected) do
		assert(actual[index] == value, (message or "array mismatch") .. " at " .. index)
	end
end

local bundled = {
	[100] = {
		requiresAll = {90, 91, 90, 100, 0, 1.5, "92"},
		requiresAny = {80, 81, 80},
		breadcrumbs = {70, 90},
		exclusiveWith = {101, 101, 100},
		followUps = {110, 110, 100},
	},
	[120] = {requiresAll = {90}},
	[130] = {exclusiveWith = {131}},
}
local service = QuestRelations:Create(bundled, {getQuestieLoader = function() return nil end})

local relations = service:Get(100)
assertArray(relations.requiresAll, {90, 91}, "requiresAll normalization")
assertArray(relations.requiresAny, {80, 81}, "requiresAny normalization")
assertArray(relations.breadcrumbs, {70, 90}, "breadcrumb normalization")
assertArray(relations.exclusiveWith, {101}, "exclusive normalization")
assertArray(relations.followUps, {110}, "follow-up normalization")
assert(relations.source == "bundled")

local reverse = service:Get(90)
assertArray(reverse.followUps, {100, 120}, "reverse follow-up index")
assert(reverse.source == "bundled")
assertArray(service:Get(131).followUps, {}, "exclusivity must not imply follow-up")

relations.requiresAll[1] = 999
relations.followUps[1] = 999
local fresh = service:Get(100)
assertArray(fresh.requiresAll, {90, 91}, "callers must receive fresh prerequisite arrays")
assertArray(fresh.followUps, {110}, "callers must receive fresh follow-up arrays")

local empty = service:Get(999)
assertArray(empty.requiresAll, {})
assertArray(empty.requiresAny, {})
assertArray(empty.breadcrumbs, {})
assertArray(empty.exclusiveWith, {})
assertArray(empty.followUps, {})
assert(empty.source == nil)

local queryCalls = 0
local queryResult = 201
local currentLoader
local function validLoader()
	return {
		ImportModule = function(_, moduleName)
			assert(moduleName == "QuestieDB")
			return {
				QueryQuestSingle = function(questID, field)
					queryCalls = queryCalls + 1
					assert(field == "nextQuestInChain")
					assert(type(questID) == "number")
					return queryResult
				end,
			}
		end,
	}
end
currentLoader = validLoader()
local questie = QuestRelations:Create(nil, {
	getQuestieLoader = function() return currentLoader end,
})

local fromQuestie = questie:Get(200)
assertArray(fromQuestie.followUps, {201})
assert(fromQuestie.source == "questie")
assertArray(questie:Get(200).followUps, {201})
assert(queryCalls == 1, "only valid Questie results should be cached")

local inlineCalls = queryCalls
local inline = questie:Get(300, {nextQuestInChain = 301})
assertArray(inline.followUps, {301})
assert(inline.source == "bundled")
assert(queryCalls == inlineCalls, "inline bundled follow-up must win over Questie")

local bothCalls = queryCalls
queryResult = 401
local both = QuestRelations:Create({[400] = {requiresAll = {399}}}, {
	getQuestieLoader = function() return currentLoader end,
}):Get(400)
assertArray(both.requiresAll, {399})
assertArray(both.followUps, {401})
assert(both.source == "both")
assert(queryCalls == bothCalls + 1)

local function assertRetryableFailure(questID, brokenLoader, validResult, message)
	currentLoader = brokenLoader
	local retry = QuestRelations:Create(nil, {getQuestieLoader = function() return currentLoader end})
	assertArray(retry:Get(questID).followUps, {}, message)
	queryResult = validResult
	currentLoader = validLoader()
	assertArray(retry:Get(questID).followUps, {validResult}, message .. " must remain retryable")
end

assertRetryableFailure(500, nil, 501, "absent Questie")
assertRetryableFailure(502, false, 503, "disabled Questie")
assertRetryableFailure(504, "invalid loader", 505, "malformed Questie loader")
assertRetryableFailure(506, {ImportModule = function() error("import failure") end}, 507, "Questie import error")
assertRetryableFailure(508, {ImportModule = function() return "invalid module" end}, 509, "malformed Questie module")
assertRetryableFailure(510, {ImportModule = function() return {QueryQuestSingle = true} end}, 511, "malformed Questie query")
assertRetryableFailure(512, {ImportModule = function() return {QueryQuestSingle = function() error("query failure") end} end}, 513, "Questie query error")

local retryValue
currentLoader = {
	ImportModule = function()
		return {QueryQuestSingle = function() return retryValue end}
	end,
}
local retry = QuestRelations:Create(nil, {getQuestieLoader = function() return currentLoader end})
assertArray(retry:Get(520).followUps, {}, "nil Questie answer")
retryValue = 521
assertArray(retry:Get(520).followUps, {521}, "nil Questie answer must not be cached")

local invalidQuestIDs = {
	"530",
	{},
	false,
	0,
	-1,
	1.5,
	0 / 0,
	math.huge,
	16777216,
}
for index, invalidQuestID in ipairs(invalidQuestIDs) do
	retryValue = invalidQuestID
	local invalidService = QuestRelations:Create(nil, {getQuestieLoader = function() return currentLoader end})
	local questID = 530 + index
	assertArray(invalidService:Get(questID).followUps, {}, "invalid Questie ID must fail open")
	retryValue = questID + 100
	assertArray(invalidService:Get(questID).followUps, {questID + 100}, "invalid Questie ID must remain retryable")
end

retryValue = 600
local selfService = QuestRelations:Create(nil, {getQuestieLoader = function() return currentLoader end})
assertArray(selfService:Get(600).followUps, {}, "direct Questie self-edge must be rejected")
retryValue = 601
assertArray(selfService:Get(600).followUps, {601}, "rejected self-edge must not be cached")

local callsBeforeInvalidCurrent = queryCalls
assertArray(questie:Get("700").followUps, {})
assertArray(questie:Get(700.5).followUps, {})
assert(queryCalls == callsBeforeInvalidCurrent, "invalid current quest IDs must not query Questie")

print("Quest relations tests passed.")
