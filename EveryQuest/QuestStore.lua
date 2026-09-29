EveryQuest = EveryQuest or {}
local EveryQuest = EveryQuest

local QuestStore = {}
QuestStore.__index = QuestStore

local questMetadataFields = {"id", "n", "l", "r", "s", "t", "d"}

local function compareValues(left, right)
	if type(left) == "number" and type(right) == "number" then
		return left < right
	end
	return tostring(left) < tostring(right)
end

local function copyMissingFields(target, source)
	local changed = false
	local hasStatus = target.status ~= nil
	for field, value in pairs(source) do
		if field ~= "statusSource" and target[field] == nil then
			target[field] = value
			changed = true
		end
	end
	-- Provenance belongs to the adopted status, never to a losing record.
	if not hasStatus and source.status ~= nil and target.statusSource ~= source.statusSource then
		target.statusSource = source.statusSource
		changed = true
	end
	return changed
end

function QuestStore:Create(historyRoot, options)
	local store = setmetatable({
		historyRoot = {},
		historyByID = {},
		staticByID = {},
		groupOccurrences = {},
		indexedGroups = {},
		groupOrder = {},
		groupRank = {},
	}, QuestStore)
	store:Configure(options)
	store:SetHistoryRoot(historyRoot)
	return store
end

function QuestStore:Configure(options)
	options = options or {}
	if options.loader ~= nil then
		self.loader = options.loader
	end
	if options.groupOrder then
		self.groupOrder = {}
		self.groupRank = {}
		for rank, group in ipairs(options.groupOrder) do
			self.groupOrder[rank] = group
			self.groupRank[group] = rank
		end
		for _, occurrences in pairs(self.staticByID or {}) do
			self:SortStaticOccurrences(occurrences)
		end
	end
	return self
end

function QuestStore:SortHistoryOccurrences(occurrences)
	table.sort(occurrences, function(left, right)
		if left.zoneID ~= right.zoneID then
			return compareValues(left.zoneID, right.zoneID)
		end
		return compareValues(left.key, right.key)
	end)
end

function QuestStore:SortStaticOccurrences(occurrences)
	table.sort(occurrences, function(left, right)
		local leftRank = self.groupRank[left.group] or math.huge
		local rightRank = self.groupRank[right.group] or math.huge
		if leftRank ~= rightRank then
			return leftRank < rightRank
		end
		if left.group ~= right.group then
			return compareValues(left.group, right.group)
		end
		if left.zoneID ~= right.zoneID then
			return compareValues(left.zoneID, right.zoneID)
		end
		local leftName = left.quest and left.quest.n or ""
		local rightName = right.quest and right.quest.n or ""
		return compareValues(leftName, rightName)
	end)
end

function QuestStore:RebuildHistoryIndex()
	self.historyByID = {}
	for zoneID, zoneHistory in pairs(self.historyRoot) do
		if type(zoneHistory) == "table" then
			for key, history in pairs(zoneHistory) do
				local questID = type(history) == "table" and tonumber(history.id) or nil
				questID = questID or tonumber(key)
				if questID and type(history) == "table" then
					local occurrences = self.historyByID[questID] or {}
					self.historyByID[questID] = occurrences
					table.insert(occurrences, {
						history = history,
						key = key,
						zoneID = zoneID,
					})
				end
			end
		end
	end
	for _, occurrences in pairs(self.historyByID) do
		self:SortHistoryOccurrences(occurrences)
	end
end

function QuestStore:SetHistoryRoot(historyRoot)
	self.historyRoot = type(historyRoot) == "table" and historyRoot or {}
	self:RebuildHistoryIndex()
	return self
end

function QuestStore:GetHistoryOccurrences(questID)
	questID = tonumber(questID)
	local indexed = questID and self.historyByID[questID]
	local occurrences = {}
	for index, occurrence in ipairs(indexed or {}) do
		occurrences[index] = {
			history = occurrence.history,
			key = occurrence.key,
			zoneID = occurrence.zoneID,
		}
	end
	return occurrences
end

function QuestStore:GetHistory(questID, zoneHint)
	questID = tonumber(questID)
	local occurrences = questID and self.historyByID[questID]
	if not occurrences or #occurrences == 0 then
		return nil
	end
	if zoneHint ~= nil then
		for _, occurrence in ipairs(occurrences) do
			if occurrence.zoneID == zoneHint then
				return occurrence.history, occurrence.zoneID
			end
		end
	end
	return occurrences[1].history, occurrences[1].zoneID
end

function QuestStore:CreateHistoryRecord(quest)
	local history = {}
	for _, field in ipairs(questMetadataFields) do
		if quest and quest[field] ~= nil then
			history[field] = quest[field]
		end
	end
	return history
end

function QuestStore:ApplyStaticHistoryMetadata(history, quest)
	if type(history) ~= "table" or type(quest) ~= "table" then
		return false
	end
	local changed = false
	for _, field in ipairs(questMetadataFields) do
		if quest[field] ~= nil and history[field] ~= quest[field] then
			history[field] = quest[field]
			changed = true
		elseif field == "d" and quest[field] == nil and history[field] ~= nil then
			history[field] = nil
			changed = true
		end
	end
	return changed
end

function QuestStore:IndexHistoryRecord(questID, zoneID, history, key)
	local occurrences = self.historyByID[questID] or {}
	self.historyByID[questID] = occurrences
	table.insert(occurrences, {
		history = history,
		key = key or questID,
		zoneID = zoneID,
	})
	self:SortHistoryOccurrences(occurrences)
end

function QuestStore:MoveHistoryToZone(questID, targetZoneID)
	questID = tonumber(questID)
	if not questID or targetZoneID == nil or type(self.historyRoot) ~= "table" then
		return nil, false
	end

	local occurrences = self.historyByID[questID]
	if not occurrences or #occurrences == 0 then
		return nil, false
	end

	local target
	for _, occurrence in ipairs(occurrences) do
		if occurrence.zoneID == targetZoneID and occurrence.key == questID then
			target = occurrence.history
			break
		end
	end
	if not target then
		for _, occurrence in ipairs(occurrences) do
			if occurrence.zoneID == targetZoneID then
				target = occurrence.history
				break
			end
		end
	end
	target = target or occurrences[1].history

	local changed = false
	for _, occurrence in ipairs(occurrences) do
		if occurrence.history ~= target and copyMissingFields(target, occurrence.history) then
			changed = true
		end
	end

	for _, occurrence in ipairs(occurrences) do
		local keep = occurrence.zoneID == targetZoneID
			and occurrence.key == questID
			and occurrence.history == target
		if not keep then
			local zoneHistory = self.historyRoot[occurrence.zoneID]
			if type(zoneHistory) == "table" and zoneHistory[occurrence.key] == occurrence.history then
				zoneHistory[occurrence.key] = nil
				changed = true
			end
		end
	end

	local zoneHistory = self.historyRoot[targetZoneID]
	if type(zoneHistory) ~= "table" then
		zoneHistory = {}
		self.historyRoot[targetZoneID] = zoneHistory
		changed = true
	end
	if zoneHistory[questID] ~= target then
		zoneHistory[questID] = target
		changed = true
	end
	self.historyByID[questID] = {{history = target, key = questID, zoneID = targetZoneID}}
	return target, changed
end

function QuestStore:EnsureHistoryRecord(questID, context)
	questID = tonumber(questID)
	context = context or {}
	local zoneID = context.zoneID
	local quest = context.quest
	if questID and (zoneID == nil or quest == nil) then
		local staticQuest, _, staticZoneID = self:GetStaticQuest(
			questID,
			context.groupHint,
			context.zoneHint or zoneID
		)
		quest = quest or staticQuest
		zoneID = staticZoneID or zoneID
	end
	if not questID or zoneID == nil or type(self.historyRoot) ~= "table" then
		return nil, false
	end

	local history, historyZoneID = self:GetHistory(questID, zoneID)
	if history then
		if historyZoneID ~= zoneID or #self:GetHistoryOccurrences(questID) > 1 then
			history = self:MoveHistoryToZone(questID, zoneID)
		end
		return history, false
	end

	local zoneHistory = self.historyRoot[zoneID]
	if type(zoneHistory) ~= "table" then
		zoneHistory = {}
		self.historyRoot[zoneID] = zoneHistory
	end

	history = self:CreateHistoryRecord(quest)
	history.id = questID
	if history.n == nil then
		history.n = context.title or ("Quest " .. questID)
	end
	if history.s == nil then
		history.s = context.faction or 3
	end
	zoneHistory[questID] = history
	self:IndexHistoryRecord(questID, zoneID, history, questID)
	return history, true
end

function QuestStore:RemoveHistoryRecord(questID, zoneID)
	questID = tonumber(questID)
	if not questID or zoneID == nil then
		return false
	end

	local occurrences = self.historyByID[questID] or {}
	local retained = {}
	local removed = false
	for _, occurrence in ipairs(occurrences) do
		if occurrence.zoneID == zoneID then
			local zoneHistory = self.historyRoot[zoneID]
			if type(zoneHistory) == "table" and zoneHistory[occurrence.key] == occurrence.history then
				zoneHistory[occurrence.key] = nil
				removed = true
			end
		else
			table.insert(retained, occurrence)
		end
	end
	if #retained > 0 then
		self.historyByID[questID] = retained
	else
		self.historyByID[questID] = nil
	end
	return removed
end

function QuestStore:RemoveRegisteredGroup(group)
	for questID, occurrences in pairs(self.staticByID) do
		local retained = {}
		for _, occurrence in ipairs(occurrences) do
			if occurrence.group ~= group then
				table.insert(retained, occurrence)
			end
		end
		if #retained > 0 then
			self.staticByID[questID] = retained
		else
			self.staticByID[questID] = nil
		end
	end
	self.groupOccurrences[group] = nil
	self.indexedGroups[group] = nil
end

function QuestStore:RegisterGroup(group, groupData)
	if not group or type(groupData) ~= "table" then
		return false
	end
	if self.indexedGroups[group] == groupData then
		return false
	end
	if self.indexedGroups[group] then
		self:RemoveRegisteredGroup(group)
	end

	local groupOccurrences = {}
	local affectedQuestIDs = {}
	for zoneID, quests in pairs(groupData) do
		if type(quests) == "table" then
			for _, quest in pairs(quests) do
				local questID = type(quest) == "table" and tonumber(quest.id) or nil
				if questID then
					local occurrence = {quest = quest, group = group, zoneID = zoneID}
					local occurrences = self.staticByID[questID] or {}
					self.staticByID[questID] = occurrences
					table.insert(occurrences, occurrence)
					table.insert(groupOccurrences, occurrence)
					affectedQuestIDs[questID] = true
				end
			end
		end
	end
	self.indexedGroups[group] = groupData
	self.groupOccurrences[group] = groupOccurrences
	for questID in pairs(affectedQuestIDs) do
		self:SortStaticOccurrences(self.staticByID[questID])
	end
	self:SortStaticOccurrences(groupOccurrences)
	return true
end

function QuestStore:GetGroupOccurrences(group)
	local result = {}
	for index, occurrence in ipairs(self.groupOccurrences[group] or {}) do
		result[index] = occurrence
	end
	return result
end

function QuestStore:GetStaticOccurrences(questID)
	questID = tonumber(questID)
	local result = {}
	for index, occurrence in ipairs(questID and self.staticByID[questID] or {}) do
		result[index] = occurrence
	end
	return result
end

function QuestStore:SelectStaticOccurrence(occurrences, groupHint, zoneHint)
	if not occurrences or #occurrences == 0 then
		return nil
	end
	if groupHint and zoneHint ~= nil then
		for _, occurrence in ipairs(occurrences) do
			if occurrence.group == groupHint and occurrence.zoneID == zoneHint then
				return occurrence
			end
		end
	end
	if groupHint then
		for _, occurrence in ipairs(occurrences) do
			if occurrence.group == groupHint then
				return occurrence
			end
		end
	end
	if zoneHint ~= nil then
		for _, occurrence in ipairs(occurrences) do
			if occurrence.zoneID == zoneHint then
				return occurrence
			end
		end
	end
	return occurrences[1]
end

function QuestStore:LoadGroup(group)
	if not group then
		return nil
	end
	if self.indexedGroups[group] then
		return self.indexedGroups[group]
	end
	if type(self.loader) ~= "function" then
		return nil
	end
	local groupData = self.loader(group)
	if type(groupData) == "table" then
		self:RegisterGroup(group, groupData)
		return groupData
	end
	return nil
end

function QuestStore:GetStaticQuest(questID, groupHint, zoneHint)
	questID = tonumber(questID)
	if not questID then
		return nil
	end

	if groupHint and not self.indexedGroups[groupHint] then
		self:LoadGroup(groupHint)
	end
	local occurrence = self:SelectStaticOccurrence(self.staticByID[questID], groupHint, zoneHint)
	if occurrence then
		return occurrence.quest, occurrence.group, occurrence.zoneID
	end

	local searched = {}
	if groupHint then
		searched[groupHint] = true
	end
	for _, group in ipairs(self.groupOrder) do
		if not searched[group] then
			searched[group] = true
			self:LoadGroup(group)
			occurrence = self:SelectStaticOccurrence(self.staticByID[questID], groupHint, zoneHint)
			if occurrence then
				return occurrence.quest, occurrence.group, occurrence.zoneID
			end
		end
	end
	return nil
end

function QuestStore:GetQuestLocation(questID, groupHint, zoneHint)
	local quest, group, zoneID = self:GetStaticQuest(questID, groupHint, zoneHint)
	if not quest then
		return nil
	end
	return group, zoneID, quest
end

function QuestStore:MoveHistoryToCanonicalLocation(questID, hints)
	hints = hints or {}
	local quest, group, zoneID = self:GetStaticQuest(questID, hints.groupHint, hints.zoneHint)
	if not quest or zoneID == nil then
		return nil, nil, false
	end
	local history, changed = self:MoveHistoryToZone(questID, zoneID)
	return history, zoneID, changed, quest, group
end

EveryQuest.QuestStore = QuestStore:Create()
