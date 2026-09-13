## Why

EveryQuest conflates failed and abandoned quests, cannot clear a manual status,
and uses ambiguous completion labels. It also cannot identify a skipped quest
that became unavailable after a player advanced its chain.

## What Changes

- Make Completed, Ready to Turn In, In Progress, Unavailable, Abandoned, and
  Failed mutually exclusive statuses, with a Clear Status action.
- Preserve existing status `1` and `2` SavedVariables while clarifying their UI
  labels, and distinguish legacy abandoned records from failed records by their
  existing timestamps.
- Keep Failed and Abandoned red while adding explicit row labels.
- Derive Unavailable for skipped chain predecessors when a later quest is
  active or completed, while allowing stored/manual state to override the
  derived result.
- Use Questie chain metadata only as an optional, fail-open provider with strict
  result validation and without copying or owning Questie data.

## Capabilities

### New Capabilities

- `quest-status-model`: Defines stored and displayed status semantics, manual
  overrides and clearing, skipped-chain detection, lifecycle precedence, and
  optional Questie provider behavior.

### Modified Capabilities

None.

## Impact

- Runtime code: `EveryQuest/Everyquest.lua`.
- UI strings: `EveryQuest/localization.lua`.
- Optional dependency metadata: `EveryQuest/EveryQuest.toc`.
- Existing `EveryQuestDBPC` quest-history records remain readable; numeric
  statuses `1` and `2` are relabeled without migration, and new abandoned
  records use a distinct negative value.
- Local Lua regression tests and `tools/verify-addon.sh` are required before
  publication. Actual accept, complete, turn-in, abandon, fail, clear, and
  skipped-chain behavior requires separate human verification in the TBC
  Anniversary client.

## Non-goals

- Do not copy Questie data into EveryQuest or make Questie mandatory.
- Do not redesign quest history storage or add a broad SavedVariables migration.
- Do not replace Blizzard quest or reward UI handlers.
- Do not add compatibility layers for non-Anniversary clients or unrelated
  status, quest-data, packaging, installation, or release changes.
