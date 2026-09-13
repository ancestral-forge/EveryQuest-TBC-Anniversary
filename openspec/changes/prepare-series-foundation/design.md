## Context

See `proposal.md` for motivation and `specs/addon-runtime/spec.md` for the
behavioral contract. Checkpoint 1 merged through PR #37 as `7e872ee`; checkpoint
2 merged through PR #38 as `3414e7b`. For this evidence cleanup, current
`origin/main` is `3fd9d80`. The old checkpoint source branches are historical
evidence and MUST NOT be reused for another checkpoint.

Checkpoint 2 made `QuestStore` the indexed boundary for history lookup, static
lookup, hydration, and canonical movement. Chain availability is still
implemented by local functions in `Everyquest.lua`, and the associated tests
extract those functions from source text by matching their relative positions.
Future-phase metadata (`p`) remains static-only and continues to render in both
zone and history views.

The addon remains a Lua 5.1, Interface `20506` application with ten existing
load-on-demand quest-data groups. Static data, schema version 1 character
history, optional Questie metadata, lifecycle events, and the legacy UI must
continue to work independently.

## Goals / Non-Goals

**Goals:**

- Establish one ownership boundary for static quest records, character history,
  quest locations, and load-on-demand quest-ID lookup.
- Make the relationship and state logic directly testable through small
  dependency-injected Lua modules.
- Preserve current status numbers, precedence, UI output, lifecycle event
  ownership, and load-on-demand behavior while exposing richer runtime results
  for a later Series feature.
- Allow four reviewable implementation checkpoints that leave the addon valid
  after each checkpoint.

**Non-Goals:**

- Do not implement graph traversal, a Series panel, or a complete bundled
  relationship dataset.
- Do not turn all existing UI and lifecycle functions into modules merely to
  eliminate every source-extraction test.
- Do not make runtime indexes persistent or introduce a new SavedVariables
  shape.
- Do not change data-module ownership, quest-data provenance, or the Blizzard
  event and secure-UI boundary.

### Continuation across checkpoints

Every remaining checkpoint starts from the latest `origin/main` in a new clean
worktree and task-named branch. The squash-merged
`prepare-series-foundation` branch is historical evidence only; continuing it
would reintroduce already merged commits and omit later main changes.

Checkpoint 2 was limited to indexed `QuestStore` behavior and compatibility
adapters. It recorded its main base, ran the unchanged baseline gate, covered
the future-phase history-render regression caused by the static/history
ownership boundary, and merged through PR #38. `QuestRelations`, `QuestState`,
and Series UI remain separate later checkpoints.

## Decisions

### Use three small factory-backed modules with production instances

Add `QuestStore.lua`, `QuestRelations.lua`, and `QuestState.lua` after
`Core.lua` in the main TOC and before `Everyquest.xml`. Each file attaches its
module to the existing `EveryQuest` table, exposes a constructor for isolated
tests, and creates or accepts a production instance wired by `Everyquest.lua`.
Dependencies that vary between WoW and tests, such as group loading, current
player level, completion flags, and optional Questie access, are passed as
callbacks rather than hidden behind test-only globals.

This makes `dofile()` tests stable under function movement and keeps the
production files compatible with WoW's script loader. A new framework or Ace3
container was rejected because three explicit Lua tables are sufficient and do
not justify another dependency.

### Make QuestStore the only creator and location index for history

`QuestStore` owns runtime-only static occurrence indexes, history indexes, and
`indexedGroups`. It is bound to the schema version 1 history root after database
defaults exist, rebuilds its history index whenever that root is replaced, and
exposes the following boundary:

- `RegisterGroup(group, groupData)` indexes references to every valid static
  quest occurrence together with its group and zone. Registration is
  idempotent and never chooses canonical ownership from load order.
- `GetStaticQuest(questID, groupHint, zoneHint)` checks indexed occurrences
  first, prefers an exact valid hint, then asks the configured loader for the
  hinted group and established ordered fallback groups. Unhinted selection uses
  the existing canonical group precedence.
- `GetHistory(questID, zoneHint)` returns the exact hinted saved occurrence
  when available, otherwise a deterministic primary record and zone.
- `GetHistoryOccurrences(questID)` returns every indexed saved occurrence so
  canonical reconciliation cannot lose duplicate legacy locations.
- `GetQuestLocation(questID, groupHint, zoneHint)` uses the same deterministic
  occurrence selection as static lookup.
- `CreateHistoryRecord(quest)` copies only persisted history fields `id`, `n`,
  `l`, `r`, `s`, `t`, and `d` into a fresh table. Static-only `p` and all
  relationship metadata remain excluded.
- `ApplyStaticHistoryMetadata(history, quest)` owns whitelist hydration,
  including the existing stale-daily clearing rule, so the whitelist is not
  duplicated in `Everyquest.lua`.
- `EnsureHistoryRecord(questID, context)` reuses existing history or creates a
  fresh record at the selected static location or an explicit fallback zone
  from current quest-log context. The faction fallback is named `faction`, not
  `source`, reserving `source` for relation/state provenance.
- `MoveHistoryToCanonicalLocation(questID, hints)` preserves and merges existing
  progress and metadata while moving all conflicting records, then atomically
  updates the history index.
- Explicit removal and reindex operations keep Clear Status and legacy record
  reconciliation from leaving stale runtime entries.

The store indexes table references, not copies of the entire static database,
so memory growth is one small occurrence descriptor per loaded static record
and one descriptor per saved history occurrence. The existing ordered group
list remains the fallback order; this change does not generate or load a global
quest map at login. Duplicate IDs are retained as occurrences and resolved by
hints plus canonical precedence instead of being overwritten by registration
order.

History remains the source of character progress, while static records remain
the source of current presentation and relation metadata. A history-view row
therefore joins its saved status/timestamps with the matching static record for
fields such as phase `p`; it does not copy `p` into SavedVariables.

Current public methods such as `GetQuestData`, `GetHistoryByQuestID`,
`SaveQuestHistoryByID`, and `ReconcileQuestHistoryForZone` remain compatibility
adapters. All creation, direct assignment, deletion, and movement paths are
audited to call the store, including completed-flag sync, `AddQuestByID`, and
manual status changes. Keeping parallel scanners was rejected because it would
leave Series callers unsure which lookup preserves canonical history behavior.

### Keep load-on-demand ownership outside the data modules

The ten existing data modules continue to assign `EveryQuestData[group]` and
remain unaware of the store. The established loader returns a successfully
loaded group table to the store, which registers it before hydration and
completed-flag sync. Already loaded groups are also registered on first use.
This avoids edits across every generated/static data addon and preserves their
provenance surface.

The store does not call `EveryQuest:LoadQuestData` recursively. One narrow
loader callback performs the existing addon availability/enable/load checks
and returns group data; UI loading then performs its existing messages,
hydration, sync, and garbage-collection behavior around that boundary.

### Normalize relations through bundled and Questie adapters

`QuestRelations` accepts a bundled relation table and an optional Questie
adapter. Its result always contains `requiresAll`, `requiresAny`,
`breadcrumbs`, `exclusiveWith`, and `followUps` arrays plus source provenance.
IDs are finite integers in `1..16777215`, duplicate and direct self edges are
discarded, and callers receive fresh result arrays so they cannot mutate cached
provider data.

Bundled records store forward facts only. During registration,
`requiresAll`, `requiresAny`, and `breadcrumbs` produce the reverse
`followUps` index, so both directions are not maintained by hand.
`exclusiveWith` remains an explicit constraint and does not imply a follow-up.
For each relationship field, valid bundled data wins; Questie is consulted only
for a missing follow-up and maps its guarded `nextQuestInChain` value into the
normalized `followUps` array. The result records whether bundled, Questie, both,
or neither contributed.

Only successful valid Questie answers are cached. Missing loaders, inaccessible
members, import/query errors, nil, invalid IDs, and empty answers remain
retryable and yield an empty relationship rather than an exception. This
preserves the current fail-open contract. Copying Questie data, requiring
Questie, or inferring relationships from static list order was rejected.

Multi-node cycle detection belongs to future graph traversal, where a visited
set is available. This foundation rejects direct self edges and provides clean
adjacency data but does not claim to validate an entire graph that has not been
loaded.

### Represent progress and availability separately at runtime

`QuestState` is constructed with the store, relations service, player-level
resolver, and completed-flag resolver. `Get(questID)` returns:

```lua
{
    progress = { status = nil },
    availability = {
        state = "unknown",
        source = nil,
        reasons = {},
    },
}
```

Stored `0`, `1`, `2`, `-1`, and `-3` map to progress names while preserving
the existing legacy abandoned timestamp interpretation. Stored `-2` becomes an
availability state with source `manual`. With no stored status, known derived
rules may set availability to `unavailable` with source `derived` and reasons
such as `REQUIRED_LEVEL` or `CHAIN_ADVANCED` (including the relevant follow-up
quest ID). No matching rule remains `unknown`, because the foundation does not
yet have enough relationship data to assert universal availability.

The legacy adapter maps progress back to its existing number first and returns
`-2` only for unavailable state. Existing rows, menus, filters, and tooltips use
that adapter, so stored/lifecycle progress continues to beat derived
availability. Returning only a richer table directly to the old UI was rejected
because it would force a broad UI rewrite before Series exists.

### Preserve event and UI ownership

Existing Blizzard event handlers continue to decide when a quest is accepted,
ready, failed, abandoned, or turned in. They update history through the store
adapters but are not moved into the new services. `UpdateFrame`, XML, the 27-row
display, colors, sorting, zone controls, context-menu layout, Blizzard quest
completion, and reward selection remain unchanged.

This keeps the foundation reversible and lets automated tests prove data and
adapter behavior. A human client run is still required to prove visual and
lifecycle parity; the local gate cannot substitute for it.

### Test modules through public constructors and retain narrow integration tests

Add direct Lua 5.1 tests for store isolation/index maintenance, relation
normalization/provider recovery, and structured-state precedence/reasons.
Update chain and status regressions to use the modules rather than extracting
their local helpers from `Everyquest.lua`. Existing source-fragment harnesses
may remain only where they exercise unchanged UI/event adapters that cannot be
loaded without the WoW frame environment; they must not reach into the new
modules' private implementation.

The required final automated evidence is the focused tests plus
`tools/verify-addon.sh` and `openspec validate --all`. Direct test loading was
chosen over a new test framework because the repository gate already discovers
all `tools/test-*.lua` files under Lua 5.1.

## Risks / Trade-offs

- [A legacy path mutates history without notifying the index] → Audit every
  direct history assignment, deletion, and move; provide store removal/reindex
  methods; cover Clear Status, canonical moves, sync, save, and add paths.
- [A load callback recursively enters lookup or duplicates sync work] → Keep the
  raw addon-load callback separate from UI hydration/sync and make group
  registration idempotent.
- [Indexes add memory proportional to loaded data] → Store references and
  location scalars only, and preserve load-on-demand group loading.
- [Duplicate static quest IDs make canonical ownership load-order dependent] →
  Index all occurrences, prefer exact group/zone hints, use the established
  canonical group precedence for unhinted lookup, and regression-test opposite
  registration orders. Treat conflicting static metadata as a separate data
  correction rather than silently merging records.
- [Static-only phase metadata disappears in history view] → Keep `p` out of
  SavedVariables and resolve it from the selected static occurrence during row
  rendering; cover zone and history views with the same status-preservation
  assertions.
- [Questie changes its module API or returns corrupt values] → Guard member
  access and calls, validate IDs, cache successes only, and fail open.
- [Structured state changes legacy precedence accidentally] → Keep one numeric
  adapter and regression-test every existing stored status, level gating, chain
  advancement, and manual override.
- [No bundled relation dataset means standalone Series is not ready] → Treat
  this change only as the service boundary; future verified data and Series UI
  remain separate reviewed changes.

## Migration Plan

1. Completed in PR #37: add the store with fresh flat record creation and route
   all history creation paths through it without changing schema version 1.
2. From a fresh branch based on the latest main, enable static/history indexes
   and replace the existing scans with public
   compatibility adapters while preserving load-on-demand fallback.
3. Add normalized relationship providers and route current chain-derived
   Unavailable behavior through them.
4. Add structured state and make the legacy numeric resolver its only UI-facing
   adapter.
5. Run focused Lua 5.1 regressions, the complete addon gate, OpenSpec
   validation, and final diff inspection. Live WoW verification remains a
   separate human evidence layer.

No SavedVariables migration or install action runs. Rollback is a normal Git
revert of the modules, TOC entries, adapters, tests, and OpenSpec delta. Because
new writes retain the old flat schema and exclude relation fields, rollback
requires no data downgrade. Existing user history is not deleted or rewritten.
