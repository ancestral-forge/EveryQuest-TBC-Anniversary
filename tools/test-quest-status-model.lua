local sourceFile = assert(io.open("EveryQuest/Everyquest.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()

local statusHelperSource = assert(source:match(
	"(local function getStoredQuestStatus.-)\nlocal function loadQuestDataAddon"
))
local getStatusSource = assert(source:match(
	"(function EveryQuest:GetStatus.-)\nlocal function getNumQuestLogEntries"
))
local markStatusSource = assert(source:match(
	"(function EveryQuest:MarkQuestByID.-)\nfunction EveryQuest:MarkQuestByName"
))
local updateStatusSource = assert(source:match(
	"(function EveryQuest:UpdateStatus.-)\nfunction EveryQuest:UpdateFrame"
))
local menuSource = assert(source:match(
	"(function EveryQuest:BuildQuestMenu.-)\nlocal function initializeQuestDropdown"
))

local loader = assert(loadstring(table.concat({
	"local EveryQuest, questdisplay, sessionvars, L, CloseDropDownMenus = ...",
	statusHelperSource,
	getStatusSource,
	markStatusSource,
	updateStatusSource,
	menuSource,
	"return EveryQuest",
}, "\n")))

local now = 100
local closeCount = 0
local quest = {id = 42, n = "A Test Quest", s = 3, relations = {followUps = {43}}}
local questdisplay = {[8] = quest}
local sessionvars = {zoneid = 15}
local locale = setmetatable({}, {__index = function(_, key) return key end})
local EveryQuest = {
	db = {
		char = {
			history = {
				[15] = {
					[42] = {id = 42, status = -1, abandoned = 90},
				},
			},
		},
	},
}

local previousEveryQuest = _G.EveryQuest
_G.EveryQuest = EveryQuest
dofile("EveryQuest/QuestStore.lua")
dofile("EveryQuest/QuestRelations.lua")
_G.EveryQuest = previousEveryQuest
EveryQuest.QuestStore:SetHistoryRoot(EveryQuest.db.char.history)

function EveryQuest:UpdateFrame()
	self.frameUpdates = (self.frameUpdates or 0) + 1
end

function EveryQuest:Debug() end

local environment = {
	concat = tostring,
	time = function() return now end,
}
setmetatable(environment, {__index = _G})
setfenv(loader, environment)
loader(EveryQuest, questdisplay, sessionvars, locale, function()
	closeCount = closeCount + 1
end)

assert(EveryQuest:GetStatus(8, -3), "legacy abandoned records must resolve to Abandoned")
assert(not EveryQuest:GetStatus(8, -1), "legacy abandoned records must not also resolve to Failed")

local menu = EveryQuest:BuildQuestMenu(8)
assert(#menu == 9, "status menu must include Unavailable and Clear Status")
assert(menu[2].text == "Completed" and menu[3].text == "Ready to Turn In")
assert(menu[5].text == "Unavailable" and menu[6].text == "Abandoned" and menu[7].text == "Failed")
assert(menu[8].text == "Clear Status")
assert(menu[6].checked and not menu[7].checked, "only Abandoned must be selected")
assert(menu[5].isNotRadio == false, "status choices must use radio-button behavior")

menu[7].func()
local history = EveryQuest.db.char.history[15][42]
assert(history ~= quest, "manual status history must not alias static quest data")
assert(history.relations == nil and quest.status == nil, "manual status must not copy relations or mutate static data")
assert(history.status == -1, "Failed must use its own stored status")
assert(history.abandoned == nil and history.failed == nil, "manual status changes must clear stale event timestamps")

menu = EveryQuest:BuildQuestMenu(8)
assert(menu[7].checked and not menu[6].checked, "Failed and Abandoned must be mutually exclusive")
menu[6].func()
assert(history.status == -3, "Abandoned must use a distinct stored status")

menu = EveryQuest:BuildQuestMenu(8)
menu[5].func()
assert(history.status == -2, "Unavailable must be stored when selected")
assert(EveryQuest:GetStatus(8, -2), "stored Unavailable status must be selected")

menu = EveryQuest:BuildQuestMenu(8)
menu[8].func()
assert(EveryQuest.db.char.history[15][42] == nil, "Clear Status must remove the stored history entry")
assert(EveryQuest:GetStatus(8, nil), "Clear Status must be selected when no status is stored")
assert(closeCount == 4 and EveryQuest.frameUpdates == 4)

local lifecycle = {id = 42, status = -3, abandoned = 80}
EveryQuest.db.char.history[15][42] = lifecycle
EveryQuest.QuestStore:SetHistoryRoot(EveryQuest.db.char.history)
function EveryQuest:SaveQuestHistoryByID()
	return 42, 15
end

EveryQuest:MarkQuestByID(42, -1, "failed")
assert(lifecycle.status == -1 and lifecycle.failed == 100 and lifecycle.abandoned == nil)
now = 200
EveryQuest:MarkQuestByID(42, -3, "abandoned")
assert(lifecycle.status == -3 and lifecycle.abandoned == 200 and lifecycle.failed == nil)

print("Quest status model tests passed.")
