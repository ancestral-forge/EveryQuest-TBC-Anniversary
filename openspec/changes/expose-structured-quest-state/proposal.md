## Why

Issue #48 is the structured-state checkpoint after QuestRelations (PR #59,
main `7be2c1c5bef9796c5c5ff62a6f76b7e7f0154141`). The numeric UI currently
combines recorded progress and derived Unavailable, losing the reason for a
blocked quest. Future Series and eligibility callers need an honest runtime
contract without changing existing player-facing behavior.

## What Changes

- Add a directly loadable, dependency-injected Lua 5.1 QuestState service.
- Expose recorded progress, its known source, independent availability, and
  structured REQUIRED_LEVEL / CHAIN_ADVANCED reasons through a read-only API.
- Route existing display consumers through one numeric compatibility adapter.
- Record optional flat `statusSource` metadata on future manual/automatic writes;
  leave untagged legacy history source unknown and retain SavedVariables version 1.
- Add direct model tests and retain focused UI/lifecycle integration regressions.

## Capabilities

### New Capabilities

None; this extends the existing quest-status-model capability.

### Modified Capabilities

- `quest-status-model`: structured progress/availability, provenance, reason codes,
  and backward-compatible numeric projection.

## Impact

Affected: EveryQuest/QuestState.lua, Everyquest.lua, QuestStore.lua, the main TOC,
focused Lua tests, and this OpenSpec change. No data import, runtime dependency,
XML/layout, localization, version, or release change. This is an internal API
refactor with preserved UI behavior, not a new player-facing feature; no changelog
entry is required under CONTRIBUTING.md.

## Non-goals

No Series UI, graph traversal, prerequisites/race/class/reputation/profession/phase/
breadcrumb/exclusivity eligibility engine, positive availability assertion,
Questie data copying, destructive migration, new override precedence, or broad
lifecycle/UI refactor. No installation, merge, tag, packaging, or publication.

## Evidence

Require focused tests, the full addon gate, OpenSpec validation, and final diff
review. Human TBC Anniversary smoke verification is separate and remains pending.
The assistant container cannot clone GitHub or obtain the Lua 5.1/OpenSpec toolchain.
Use a clean GitHub Actions worktree from the pinned main base for implementation
and full validation; disclose this exception to local execution. A temporary,
branch-scoped preparation workflow is removed from the final tree and may write
only the task branch, never main. Verify normal PR CI independently afterward.
