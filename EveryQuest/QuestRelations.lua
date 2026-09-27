EveryQuest = EveryQuest or {}
local EveryQuest = EveryQuest

local QuestRelations = {}
QuestRelations.__index = QuestRelations

local MAX_QUEST_ID = 16777215
local RELATION_FIELDS = {"requiresAll", "requiresAny", "breadcrumbs", "exclusiveWith", "followUps"}
local REVERSE_FIELDS = {"requiresAll", "requiresAny", "breadcrumbs"}

local function normalizeQuestID(value)
	if type(value) ~= "number"
		or value ~= value
		or value < 1
		or value > MAX_QUEST_ID
		or value ~= math.floor(value) then
		return nil
	end
	return value
end

local function appendQuestID(target, seen, ownerQuestID, value)
	local questID = normalizeQuestID(value)
	if not questID or questID == ownerQuestID or seen[questID] then
		return false
	end
	seen[questID] = true
	table.insert(target, questID)
	return true
end

local function appendCollection(target, seen, ownerQuestID, values)
	if type(values) ~= "table" then
		return false
	end
	local changed = false
	for _, value in ipairs(values) do
		if appendQuestID(target, seen, ownerQuestID, value) then
			changed = true
		end
	end
	return changed
end

local function makeEmptyResult()
	return {
		requiresAll = {},
		requiresAny = {},
		breadcrumbs = {},
		exclusiveWith = {},
		followUps = {},
		source = nil,
	}
end

local function hasRelationships(result)
	for _, field in ipairs(RELATION_FIELDS) do
		if #result[field] > 0 then
			return true
		end
	end
	return false
end

local function defaultQuestieLoader()
	return _G and _G.QuestieLoader or nil
end

function QuestRelations:Create(bundled, options)
	local service = setmetatable({
		bundledByID = {},
		reverseFollowUps = {},
		questieCache = {},
		getQuestieLoader = defaultQuestieLoader,
	}, QuestRelations)
	service:Configure(options)
	service:SetBundledRelations(bundled)
	return service
end

function QuestRelations:Configure(options)
	options = options or {}
	if options.getQuestieLoader ~= nil then
		self.getQuestieLoader = options.getQuestieLoader
		self.questieCache = {}
	end
	return self
end

function QuestRelations:SetBundledRelations(bundled)
	self.bundledByID = {}
	self.reverseFollowUps = {}
	if type(bundled) ~= "table" then
		return self
	end

	for rawQuestID, record in pairs(bundled) do
		local questID = normalizeQuestID(rawQuestID)
		if questID and type(record) == "table" then
			local normalized = makeEmptyResult()
			local seen = {}
			for _, field in ipairs(RELATION_FIELDS) do
				seen[field] = {}
				appendCollection(normalized[field], seen[field], questID, record[field])
			end
			appendQuestID(normalized.followUps, seen.followUps, questID, record.nextQuestInChain)
			if hasRelationships(normalized) then
				self.bundledByID[questID] = normalized
			end
		end
	end

	local reverseSeen = {}
	for questID, record in pairs(self.bundledByID) do
		for _, field in ipairs(REVERSE_FIELDS) do
			for _, prerequisiteID in ipairs(record[field]) do
				local followUps = self.reverseFollowUps[prerequisiteID] or {}
				self.reverseFollowUps[prerequisiteID] = followUps
				local seen = reverseSeen[prerequisiteID] or {}
				reverseSeen[prerequisiteID] = seen
				if not seen[questID] then
					seen[questID] = true
					table.insert(followUps, questID)
				end
			end
		end
	end
	for _, followUps in pairs(self.reverseFollowUps) do
		table.sort(followUps)
	end
	return self
end

function QuestRelations:QueryQuestieFollowUp(questID)
	local cached = self.questieCache[questID]
	if cached then
		return cached
	end
	if type(self.getQuestieLoader) ~= "function" then
		return nil
	end

	local loaderOK, questieLoader = pcall(self.getQuestieLoader)
	if not loaderOK or type(questieLoader) ~= "table" then
		return nil
	end
	local importLookupOK, importModule = pcall(function()
		return questieLoader.ImportModule
	end)
	if not importLookupOK or type(importModule) ~= "function" then
		return nil
	end
	local importOK, questieDB = pcall(importModule, questieLoader, "QuestieDB")
	if not importOK or type(questieDB) ~= "table" then
		return nil
	end
	local queryLookupOK, queryQuestSingle = pcall(function()
		return questieDB.QueryQuestSingle
	end)
	if not queryLookupOK or type(queryQuestSingle) ~= "function" then
		return nil
	end
	local queryOK, nextQuestID = pcall(queryQuestSingle, questID, "nextQuestInChain")
	if not queryOK then
		return nil
	end

	nextQuestID = normalizeQuestID(nextQuestID)
	if not nextQuestID or nextQuestID == questID then
		return nil
	end
	self.questieCache[questID] = nextQuestID
	return nextQuestID
end

function QuestRelations:Get(questID, inlineRecord)
	questID = normalizeQuestID(questID)
	local result = makeEmptyResult()
	if not questID then
		return result
	end

	local seen = {}
	for _, field in ipairs(RELATION_FIELDS) do
		seen[field] = {}
	end

	local bundled = self.bundledByID[questID]
	if bundled then
		for _, field in ipairs(RELATION_FIELDS) do
			appendCollection(result[field], seen[field], questID, bundled[field])
		end
	end
	appendCollection(result.followUps, seen.followUps, questID, self.reverseFollowUps[questID])

	if type(inlineRecord) == "table" then
		for _, field in ipairs(RELATION_FIELDS) do
			appendCollection(result[field], seen[field], questID, inlineRecord[field])
		end
		appendQuestID(result.followUps, seen.followUps, questID, inlineRecord.nextQuestInChain)
	end

	local bundledContributed = hasRelationships(result)
	local questieContributed = false
	if #result.followUps == 0 then
		local nextQuestID = self:QueryQuestieFollowUp(questID)
		if nextQuestID and appendQuestID(result.followUps, seen.followUps, questID, nextQuestID) then
			questieContributed = true
		end
	end

	if bundledContributed and questieContributed then
		result.source = "both"
	elseif bundledContributed then
		result.source = "bundled"
	elseif questieContributed then
		result.source = "questie"
	end
	return result
end

EveryQuest.QuestRelations = QuestRelations:Create()
