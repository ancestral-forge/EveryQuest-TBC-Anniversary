## Context

QuestStore owns indexed static/history lookup. QuestRelations owns normalized,
optional relation providers. Everyquest.lua still contains the stored-status and
Unavailable rules. Existing history does not distinguish manual from automatic
writes, so absence of timestamps is not evidence of either source.

## Goals / Non-Goals

Expose a shared read-only state contract and preserve the current numeric UI.
Do not implement Series, change Blizzard event ownership, infer availability from
missing restrictions, or make Questie mandatory.

## Decisions

### One small service and an explicit compatibility projection

Load QuestState after QuestRelations and before Everyquest.xml. `Create(options)`
and `Configure(options)` accept `store`, `relations`, `getPlayerLevel`, and
`isQuestFlaggedCompleted`. Production wiring uses existing completion-flag caching.
`Get(questID, groupHint, zoneHint)` joins current indexed static/history records;
`Evaluate(quest, history)` accepts an already selected row without extra static
loads. The latter preserves the old `history or quest` fallback exactly.

Results contain `questID`, `progress = {status, source}`, and
`availability = {state, source, reasons}`. Progress names are unknown,
in_progress, ready_to_turn_in, completed, abandoned, and failed. Source is manual,
automatic, or unknown. Availability is unknown or unavailable in this checkpoint;
its source is nil, derived, or manual. `ToLegacyStatus(state)` projects progress
first, then unavailable to -2, otherwise nil. All results and reason records are
fresh; state reads never write history or cache player-dependent conclusions.

### Independent reasons, conservative availability

Evaluate a finite positive required level against a known finite positive player
level. REQUIRED_LEVEL includes requiredLevel and playerLevel. Evaluate normalized
followUps against history statuses 0/1/2 or a positive completion flag.
CHAIN_ADVANCED includes the follow-up questID, evidence source (history or
completed_flag), and relationSource. Preserve all matching reasons in deterministic
level-then-follow-up order, even when own progress wins the numeric display.
Missing/invalid optional level or completion callbacks provide no evidence.
QuestRelations continues to guard Questie and retry unsuccessful lookups.

Meeting a level requirement or having no known follow-up does not prove eligibility.
No match therefore means unknown, including for completed or active quests. Future
reason families can extend the reason list without changing numeric callers.

### Provenance without migration or guessed history

Future writers add optional flat `statusSource = "manual" | "automatic"` alongside
status. The context menu is manual; existing scans, sync and lifecycle writers are
automatic, including observations that confirm the same numeric status. Older
untagged progress remains source unknown. Stored -2 is a manual availability
override, not progress, and supplies MANUAL_OVERRIDE in addition to derived reasons.
No eager rewrite, schema bump, persistent state cache, or timestamp heuristic for
provenance is introduced. Clear Status still removes the record.

When QuestStore merges duplicate history, the winning status and its provenance
must remain paired. An untagged winning status must not inherit a losing record's
source. An adopted status adopts only its own source. All other missing-field merge
semantics stay unchanged.

### Preserve runtime ownership and rollback

Blizzard events remain responsible for progress observations and Blizzard retains
secure quest/reward UI ownership. New source metadata does not prevent automatic
observations overwriting manual values where they already did so. Labels, colors,
phase markers, filter/context-menu comparisons and ordering stay unchanged.
Existing numeric and legacy abandoned timestamp interpretation remain compatible.

Rollback is a normal revert of module, adapters, TOC, tests and metadata writes.
Old clients ignore optional statusSource; no history downgrade or deletion is needed.
Lua 5.1, Interface 20506, GPL-2.0-only and existing data provenance are unchanged.

## Risks / Trade-offs

- False availability: return unknown without positive evidence; do not implement
  an available state merely because initial blockers did not match.
- Provenance overclaim: retain unknown for legacy progress and merge status/source
  together; do not guess from timestamps or zero-valued status.
- UI drift: retain one numeric adapter and run existing row/menu/phase tests.
- Test harness drift: state tests use dofile and public constructors; extraction
  remains only for existing WoW-bound UI/event adapters and production wiring.
- Local environment unavailable: execute baseline and final gates in a clean
  Actions worktree; distinguish remote evidence from local execution and live WoW.

## Migration Plan

Plan first, add module and focused tests, replace state helpers with the adapter,
tag existing write paths, preserve duplicate merge provenance, then run full gates.
Deliver a reviewable PR without merging or archiving this change. Live smoke testing
must cover zone/history rows, all manual statuses/Clear Status, Questie on/off, and
accept/ready/turn-in/abandon/fail with script errors enabled.
