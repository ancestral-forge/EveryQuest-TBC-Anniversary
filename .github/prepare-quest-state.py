"""Temporary issue-48 codemod, removed before delivery; never writes outside this checkout."""
from pathlib import Path
import hashlib
import re

root = Path.cwd()
main = root / "EveryQuest/Everyquest.lua"
s = main.read_text()
blob = hashlib.sha1(f"blob {len(s.encode())}\0".encode() + s.encode()).hexdigest()
assert blob == "e89159b308d15a818d0dc7e87d526ded7078526c", blob
start = s.index("local function getStoredQuestStatus")
end = s.index("-- Disable each phase", start)
s = s[:start] + '''EveryQuest.QuestState:Configure({
	store = EveryQuest.QuestStore,
	relations = EveryQuest.QuestRelations,
	getPlayerLevel = function() return UnitLevel and UnitLevel("player") end,
	isQuestFlaggedCompleted = isQuestFlaggedCompleted,
})

local function getDisplayedQuestStatus(quest, history)
	return EveryQuest.QuestState:ToLegacyStatus(EveryQuest.QuestState:Evaluate(quest, history))
end

''' + s[end:]

writes = []
def tag_write(match):
    indent, value = match.groups()
    assert value in {"qstatus", "status", "queststatus", "2"}, value
    writes.append(value)
    kind = "manual" if value == "queststatus" else "automatic"
    return f'{indent}history.status = {value}\n{indent}history.statusSource = "{kind}"'
s = re.sub(r'^(\t+)history\.status = ([^\n]+)$', tag_write, s, flags=re.M)
assert len(writes) == 8, writes
old = '''	if qstatus ~= nil and history.status ~= qstatus then
		history.status = qstatus
		history.statusSource = "automatic"
		changed = not added
	end'''
new = '''	if qstatus ~= nil then
		if history.status ~= qstatus then
			history.status = qstatus
			changed = not added
		end
		history.statusSource = "automatic"
	end'''
assert s.count(old) == 1
s = s.replace(old, new)
main.write_text(s)

store_path = root / "EveryQuest/QuestStore.lua"
s = store_path.read_text()
old = '''local function copyMissingFields(target, source)
	local changed = false
	for field, value in pairs(source) do
		if target[field] == nil then
			target[field] = value
			changed = true
		end
	end
	return changed
end'''
new = '''local function copyMissingFields(target, source)
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
end'''
assert s.count(old) == 1
store_path.write_text(s.replace(old, new))

toc = root / "EveryQuest/EveryQuest.toc"
s = toc.read_text()
assert s.count("QuestRelations.lua\n") == 1
toc.write_text(s.replace("QuestRelations.lua\n", "QuestRelations.lua\nQuestState.lua\n"))

status_test = root / "tools/test-quest-status-model.lua"
s = status_test.read_text()
assert s.count("local function getStoredQuestStatus") == 1
s = s.replace("local function getStoredQuestStatus", "local function getDisplayedQuestStatus")
needle = 'dofile("EveryQuest/QuestRelations.lua")\n'
assert s.count(needle) == 1
s = s.replace(needle, needle + 'dofile("EveryQuest/QuestState.lua")\nEveryQuest.QuestState:Configure({store = EveryQuest.QuestStore, relations = EveryQuest.QuestRelations})\n')
s = s.replace('assert(history.status == -2,', 'assert(history.statusSource == "manual", "context-menu status source must be manual")\nassert(history.status == -2,')
s = s.replace('assert(lifecycle.status == -1', 'assert(lifecycle.statusSource == "automatic", "lifecycle source must be automatic")\nassert(lifecycle.status == -1')
status_test.write_text(s)

preparation_test = root / "tools/test-quest-data-preparation.lua"
s = preparation_test.read_text()
assert s.count("local function getStoredQuestStatus") == 1
s = s.replace("local function getStoredQuestStatus", "EveryQuest%.QuestState:Configure")
preparation_test.write_text(s)

# No state test may keep extracting the moved private implementation.
for test in (root / "tools").glob("test-*.lua"):
    assert "local function getStoredQuestStatus" not in test.read_text(), test

(root / ".github/workflows/prepare-quest-state.yml").unlink()
(root / ".github/prepare-quest-state.py").unlink()
print("Applied the bounded issue-48 codemod; temporary runner files removed.")
