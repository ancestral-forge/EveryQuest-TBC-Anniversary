EveryQuest = EveryQuest or {}
local EveryQuest = EveryQuest

local QuestState = {}
QuestState.__index = QuestState

local progressNames = {
	[-3] = "abandoned",
	[-1] = "failed",
	[0] = "in_progress",
	[1] = "ready_to_turn_in",
	[2] = "completed",
}
local progressNumbers = {}
for number, name in pairs(progressNames) do
	progressNumbers[name] = number
end

local function positiveInteger(value, maximum)
	if type(value) ~= "number" and type(value) ~= "string" then
		return nil
	end
	value = tonumber(value)
	if not value or value ~= value or value <= 0 or value == math.huge
		or value ~= math.floor(value) or (maximum and value > maximum) then
		return nil
	end
	return value
end

local function optionalValue(callback, ...)
	if type(callback) == "function" then
		local ok, value = pcall(callback, ...)
		if ok then
			return value
		end
	end
end

local function storedSource(history)
	local source = history and history.statusSource
	if source == "manual" or source == "automatic" then
		return source
	end
	return "unknown"
end

function QuestState:Create(options)
	local service = setmetatable({}, QuestState)
	return service:Configure(options)
end

function QuestState:Configure(options)
	for key, value in pairs(options or {}) do
		if key == "store" or key == "relations" or key == "getPlayerLevel"
			or key == "isQuestFlaggedCompleted" then
			self[key] = value
		end
	end
	return self
end

function QuestState:GetStoredStatus(history)
	if type(history) ~= "table" then
		return nil
	end
	-- Preserve old -1 records without changing their persisted value.
	if history.status == -1 and history.abandoned then
		local abandonedAt = tonumber(history.abandoned) or 0
		local failedAt = tonumber(history.failed) or 0
		if not history.failed or abandonedAt > failedAt then
			return -3
		end
	end
	return history.status
end

function QuestState:Evaluate(quest, history)
	quest = type(quest) == "table" and quest or nil
	history = type(history) == "table" and history or quest
	local status = self:GetStoredStatus(history)
	local progress = progressNames[status]
	local result = {
		questID = positiveInteger(quest and quest.id or history and history.id, 16777215),
		progress = {
			status = progress or "unknown",
			source = progress and storedSource(history) or "unknown",
		},
		availability = {state = "unknown", reasons = {}},
	}
	local availability = result.availability
	local reasons = availability.reasons

	if status == -2 then
		availability.state = "unavailable"
		availability.source = "manual"
		table.insert(reasons, {code = "MANUAL_OVERRIDE"})
	end

	local requiredLevel = positiveInteger(quest and quest.r)
	if requiredLevel then
		local playerLevel = positiveInteger(optionalValue(self.getPlayerLevel))
		if playerLevel and playerLevel < requiredLevel then
			table.insert(reasons, {
				code = "REQUIRED_LEVEL",
				requiredLevel = requiredLevel,
				playerLevel = playerLevel,
			})
		end
	end

	if self.relations then
		local relations = self.relations:Get(result.questID, quest)
		for _, nextQuestID in ipairs(relations.followUps) do
			local nextHistory = self.store and self.store:GetHistory(nextQuestID)
			local nextStatus = self:GetStoredStatus(nextHistory)
			local evidence
			if nextStatus == 0 or nextStatus == 1 or nextStatus == 2 then
				evidence = "history"
			else
				local completed = optionalValue(self.isQuestFlaggedCompleted, nextQuestID)
				if completed == true or completed == 1 then
					evidence = "completed_flag"
				end
			end
			if evidence then
				table.insert(reasons, {
					code = "CHAIN_ADVANCED",
					questID = nextQuestID,
					source = evidence,
					relationSource = relations.source,
				})
			end
		end
	end

	if #reasons > 0 then
		availability.state = "unavailable"
		availability.source = availability.source or "derived"
	end
	return result
end

function QuestState:Get(questID, groupHint, zoneHint)
	questID = positiveInteger(questID, 16777215)
	if not questID then
		return self:Evaluate(nil)
	end
	if not self.store then
		return self:Evaluate({id = questID})
	end
	local quest = self.store:GetStaticQuest(questID, groupHint, zoneHint)
	local history = self.store:GetHistory(questID, zoneHint)
	return self:Evaluate(quest or history or {id = questID}, history)
end

function QuestState:ToLegacyStatus(state)
	local progress = state and state.progress
	local number = progress and progressNumbers[progress.status]
	if number ~= nil then
		return number
	end
	if state and state.availability and state.availability.state == "unavailable" then
		return -2
	end
	return nil
end

EveryQuest.QuestState = QuestState:Create()

function EveryQuest:GetQuestState(questID, groupHint, zoneHint)
	return self.QuestState:Get(questID, groupHint, zoneHint)
end
