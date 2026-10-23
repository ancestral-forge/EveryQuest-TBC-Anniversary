local sourceFile = assert(io.open("EveryQuest/Everyquest.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()

local formatterSource = assert(source:match(
	"(local FUTURE_PHASE_LABELS_ENABLED.-)\nlocal function loadQuestDataAddon"
))
local formatterLoader = assert(loadstring(table.concat({
	"local L = ...",
	formatterSource,
	"return getQuestPhaseLabel, addQuestStatusLabel, FUTURE_PHASE_LABELS_ENABLED",
}, "\n")))

local locale = setmetatable({Phase = "Phase"}, {__index = function(_, key) return key end})
local getQuestPhaseLabel, addQuestStatusLabel, enabledPhases = formatterLoader(locale)

assert(getQuestPhaseLabel({p = 4}) == "", "Zul'Aman quests must no longer be labelled as future content")
assert(getQuestPhaseLabel({p = 5}) == "[Phase 5]")
assert(getQuestPhaseLabel({}) == "")
assert(getQuestPhaseLabel({p = 3}) == "")
assert(getQuestPhaseLabel({p = 6}) == "")
assert(getQuestPhaseLabel({p = "4"}) == "")

local phaseAndStatus = "[70]" .. getQuestPhaseLabel({p = 4}) .. " Zul'Aman Quest"
assert(addQuestStatusLabel(phaseAndStatus, -3) == "[70] Zul'Aman Quest (Abandoned)")
assert(addQuestStatusLabel(phaseAndStatus, -1) == "[70] Zul'Aman Quest (Failed)")

enabledPhases[4] = true
assert(getQuestPhaseLabel({p = 4}) == "[Phase 4]")
assert(getQuestPhaseLabel({p = 5}) == "[Phase 5]")
enabledPhases[4] = true
enabledPhases[5] = false
assert(getQuestPhaseLabel({p = 4}) == "[Phase 4]")
assert(getQuestPhaseLabel({p = 5}) == "")
enabledPhases[4] = false
assert(getQuestPhaseLabel({p = 4}) == "")
assert(getQuestPhaseLabel({p = 5}) == "")
enabledPhases[4] = false
enabledPhases[5] = true

local updateButtonSource = assert(source:match(
	"(function EveryQuest:UpdateButton.-)\nfunction EveryQuest:ButtonEnter"
))
local updateButtonLoader = assert(loadstring(table.concat({
	"local EveryQuest, questdisplay, sessionvars, L = ...",
	"local clearButtonTexture, setButtonText, setButtonTextColor, getDisplayedQuestStatus, getQuestPhaseLabel, addQuestStatusLabel = select(5, ...)",
	updateButtonSource,
	"return EveryQuest",
}, "\n")))

local renderedText
local renderedColor
local questdisplay = {}
local sessionvars = {zonegroup = "Raids", zoneid = 3805}
local row = {Show = function() end}
local environment = {EveryQuestTitle1 = row}
environment._G = environment
setmetatable(environment, {__index = _G})
setfenv(updateButtonLoader, environment)

local EveryQuest = {
	db = {
		profile = {view = "zone"},
		char = {history = {[3805] = {}}},
	},
}
local globalEveryQuest = _G.EveryQuest
_G.EveryQuest = EveryQuest
dofile("EveryQuest/QuestStore.lua")
_G.EveryQuest = globalEveryQuest
EveryQuest.QuestStore:SetHistoryRoot(EveryQuest.db.char.history)
function EveryQuest:QuestType()
	return ""
end
function EveryQuest:GetColor(value)
	return value
end
function EveryQuest:GetQuestApiOverlayLabel()
	return ""
end

updateButtonLoader(
	EveryQuest,
	questdisplay,
	sessionvars,
	locale,
	function() end,
	function(_, text) renderedText = text end,
	function(_, color) renderedColor = color end,
	function(_, history) return history and history.status end,
	getQuestPhaseLabel,
	addQuestStatusLabel
)

local phaseQuest = {id = 11165, n = "A Troll Among Trolls", l = 70, s = 3, p = 4}
EveryQuest.QuestStore:Configure({groupOrder = {"Raids"}})
EveryQuest.QuestStore:RegisterGroup("Raids", {[3805] = {phaseQuest}})
EveryQuest:UpdateButton(1, phaseQuest)
assert(renderedText == "[70] A Troll Among Trolls")
assert(renderedColor == "FFFFFF", "phase labels must not create a status color")

local phaseHistory = EveryQuest.QuestStore:EnsureHistoryRecord(11165, {
	zoneID = 3805,
	quest = phaseQuest,
})
assert(phaseHistory.p == nil, "phase metadata must not be persisted in history")
phaseHistory.status = -1
EveryQuest:UpdateButton(1, phaseQuest)
assert(renderedText == "[70] A Troll Among Trolls (Failed)")
assert(renderedColor == -1, "phase labels must preserve the existing status color")

EveryQuest.db.profile.view = "history"
EveryQuest:UpdateButton(1, phaseHistory)
assert(renderedText == "[70] A Troll Among Trolls (Failed)", "history rows must omit the released phase marker")
assert(renderedColor == -1, "history rows must preserve the stored Failed color")
assert(phaseHistory.p == nil, "rendering must not hydrate phase metadata into history")

phaseHistory.status = -3
EveryQuest:UpdateButton(1, phaseHistory)
assert(renderedText == "[70] A Troll Among Trolls (Abandoned)")
assert(renderedColor == -3, "history rows must preserve the stored Abandoned color")

EveryQuest.db.profile.view = "zone"
EveryQuest:UpdateButton(1, phaseQuest)
assert(renderedText == "[70] A Troll Among Trolls (Abandoned)", "zone view must remain unchanged")

function EveryQuest:GetQuestApiOverlayLabel(questID)
	assert(questID == phaseQuest.id)
	return "[?]"
end
EveryQuest:UpdateButton(1, phaseQuest)
assert(renderedText == "[70][?] A Troll Among Trolls (Abandoned)")
assert(renderedColor == -3)
EveryQuest.db.profile.view = "history"
phaseQuest.p = 5
phaseHistory.status = -1
EveryQuest:UpdateButton(1, phaseHistory)
assert(renderedText == "[70][?][Phase 5] A Troll Among Trolls (Failed)")
assert(renderedColor == -1)
assert(phaseHistory.p == nil)

EveryQuest.db.profile.view = "zone"
EveryQuest:UpdateButton(1, phaseQuest)
assert(renderedText == "[70][?][Phase 5] A Troll Among Trolls (Failed)", "zone rows must retain the future phase marker")
assert(renderedColor == -1)

local expectedPhases = {
	[9524] = 4,
	[9525] = 4,
	[11130] = 4,
	[11132] = 4,
	[11163] = 4,
	[11164] = 4,
	[11165] = 4,
	[11166] = 4,
	[11171] = 4,
	[11178] = 4,
	[11195] = 4,
	[9681] = 5,
	[9684] = 5,
	[9721] = 5,
	[9722] = 5,
	[9723] = 5,
	[9725] = 5,
	[9735] = 5,
	[9736] = 5,
	[11481] = 5,
	[11482] = 5,
	[11488] = 5,
	[11490] = 5,
	[11492] = 5,
	[11496] = 5,
	[11499] = 5,
	[11500] = 5,
	[11513] = 5,
	[11514] = 5,
	[11515] = 5,
	[11516] = 5,
	[11517] = 5,
	[11520] = 5,
	[11521] = 5,
	[11523] = 5,
	[11524] = 5,
	[11525] = 5,
	[11526] = 5,
	[11532] = 5,
	[11533] = 5,
	[11534] = 5,
	[11535] = 5,
	[11536] = 5,
	[11537] = 5,
	[11538] = 5,
	[11539] = 5,
	[11540] = 5,
	[11541] = 5,
	[11542] = 5,
	[11543] = 5,
	[11544] = 5,
	[11545] = 5,
	[11546] = 5,
	[11547] = 5,
	[11548] = 5,
	[11549] = 5,
	[11550] = 5,
	[11554] = 5,
	[11555] = 5,
	[11556] = 5,
	[11557] = 5,
	[11875] = 5,
	[11877] = 5,
	[11880] = 5,
}

local dataEnvironment = {EveryQuestData = {}}
setmetatable(dataEnvironment, {__index = _G})
local dataFiles = {
	"EveryQuest_Battlegrounds/Battlegrounds.lua",
	"EveryQuest_Classes/Classes.lua",
	"EveryQuest_Dungeons/Dungeons.lua",
	"EveryQuest_Eastern_Kingdoms/Eastern_Kingdoms.lua",
	"EveryQuest_Kalimdor/Kalimdor.lua",
	"EveryQuest_Miscellaneous/Miscellaneous.lua",
	"EveryQuest_Outland/Outland.lua",
	"EveryQuest_Professions/Professions.lua",
	"EveryQuest_Raids/Raids.lua",
	"EveryQuest_Seasonal/Seasonal.lua",
}
for _, file in ipairs(dataFiles) do
	local chunk = assert(loadfile(file))
	setfenv(chunk, dataEnvironment)
	chunk()
end

local seenExpected = {}
local phaseCounts = {[4] = 0, [5] = 0}
for group, zones in pairs(dataEnvironment.EveryQuestData) do
	for zoneID, quests in pairs(zones) do
		for _, quest in ipairs(quests) do
			local expectedPhase = expectedPhases[quest.id]
			if expectedPhase then
				assert(
					quest.p == expectedPhase,
					("quest %d in %s/%s must be Phase %d"):format(quest.id, group, tostring(zoneID), expectedPhase)
				)
				assert(getQuestPhaseLabel(quest) == (expectedPhase == 5 and "[Phase 5]" or ""),
					"unexpected release phase marker for quest " .. quest.id)
				if seenExpected[quest.id] then
					assert(seenExpected[quest.id] == quest.p, "duplicate phase metadata must agree for quest " .. quest.id)
				else
					seenExpected[quest.id] = quest.p
					phaseCounts[quest.p] = phaseCounts[quest.p] + 1
				end
			elseif quest.p ~= nil then
				error(("unexpected phase metadata on quest %d in %s/%s"):format(quest.id, group, tostring(zoneID)))
			end
		end
	end
end

for questID, phase in pairs(expectedPhases) do
	assert(seenExpected[questID] == phase, "missing reviewed phase quest " .. questID)
end
assert(phaseCounts[4] == 11, "expected 11 unique Phase 4 quests")
assert(phaseCounts[5] == 53, "expected 53 unique Phase 5 quests")

print("Future phase label tests passed.")
