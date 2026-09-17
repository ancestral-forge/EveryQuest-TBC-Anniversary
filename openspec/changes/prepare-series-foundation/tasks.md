## 1. Work State and Contract

- [x] 1.1 Confirm the first `prepare-series-foundation` checkpoint used a clean separate worktree based on its then-current `origin/main`; verify with `git status --short --branch`, `git rev-parse HEAD`, `git rev-parse origin/main`, and `git worktree list --porcelain`.
- [x] 1.2 Re-read this change's proposal, addon-runtime delta, design, and apply instructions, then run the unchanged baseline `tools/verify-addon.sh` successfully before the first implementation checkpoint.
- [ ] 1.3 For every remaining checkpoint, create a new clean worktree and task-named branch from the latest `origin/main`; do not reuse the squash-merged `prepare-series-foundation` source branch.

## 2. Isolate Character History from Static Data

- [x] 2.1 Add the directly loadable Lua 5.1 `QuestStore` module and TOC entry with `CreateHistoryRecord` and `EnsureHistoryRecord`; verify `tools/test-quest-store.lua` proves records are fresh tables containing only `id`, `n`, `l`, `r`, `s`, `t`, and `d` from static data.
- [x] 2.2 Route completed-flag sync, `AddQuestByID`, manual `UpdateStatus`, save, and removal paths through store-owned history creation/removal; verify the focused test mutates history status and proves the static quest is unchanged and relation fields are absent.
- [x] 2.3 Preserve schema version 1 and existing flat history fields without an eager migration; verify store and existing history/status regressions pass under Lua 5.1.
- [x] 2.4 Create the review checkpoint `refactor: isolate character history from static quest data` and verify the commit contains only the OpenSpec foundation plus the history-isolation implementation and tests.
- [x] 2.5 Deliver checkpoint 1 through PR #37, verify the PR head passed Lua and OpenSpec CI, and merge it to main as `7e872ee` after explicit authorization.
- [x] 2.6 In a human-run TBC Anniversary client on current main with script errors enabled, complete the checkpoint-1 smoke test for Questie enabled/disabled, zone/history rendering, manual status, Clear Status, and representative lifecycle paths; record live evidence separately from CI and install parity.

## 3. Introduce Indexed Quest Lookup

- [x] 3.1 Create a clean `introduce-indexed-quest-store` worktree and branch from the latest `origin/main`, record its exact base SHA, re-read the updated OpenSpec artifacts, and run the unchanged baseline `tools/verify-addon.sh` successfully.
- [x] 3.2 Centralize persisted history metadata copying and hydration in `QuestStore`, keep `p` and relation fields static-only, and rename the unused `context.source` faction fallback so `source` remains available for provider provenance; verify schema version 1 and existing daily-clearing behavior remain unchanged.
- [x] 3.3 Extend `QuestStore` with history-root rebinding, duplicate-safe history occurrence indexing, deterministic `GetHistory`, complete `GetHistoryOccurrences`, idempotent loaded-group registration, all-occurrence static indexing, and indexed static/history/location lookup; verify repeated hits, root replacement, duplicate saved locations, and stale-index cases in `tools/test-quest-store.lua`.
- [x] 3.4 Preserve hint-first and ordered load-on-demand fallback without editing the ten data modules; verify exact group/zone hints, opposite duplicate-registration orders, canonical precedence, single registration of loaded groups, unresolved IDs, and no loader call after an indexed hit.
- [x] 3.5 Move and merge history through store-owned canonical-location operations so status, count, timestamps, and metadata survive while every old index/location entry is removed; verify idempotent reconciliation and duplicate-history cases.
- [x] 3.6 Convert `GetQuestData`, `GetHistoryByQuestID`, canonical lookup, hydration, save, add, Clear Status, and reconciliation paths into store consumers or compatibility adapters; verify `tools/test-unmapped-quest-history.lua`, `tools/test-history-hydration.lua`, and `tools/test-quest-status-model.lua` pass.
- [x] 3.7 Make history rows resolve static-only presentation metadata through indexed lookup, and add a regression proving a Phase 4/5 marker renders in history view although `p` is absent from the saved history record while the existing status color/suffix is preserved.
- [x] 3.8 Run focused tests, `tools/verify-addon.sh`, and `openspec validate --all`; inspect the complete diff, then deliver the review checkpoint through PR #38 as `refactor: introduce indexed quest store`, merged to `main` as `3414e7be4485efdce62fc7af8f0698671b6a512f`, with no QuestRelations, QuestState, Series UI, version, XML, localization, or quest-data scope.
- [x] 3.9 Record the history-view phase-label correction under `CHANGELOG.md` `[Unreleased]` in this PR; reconcile the checkpoint's changelog scope with `CONTRIBUTING.md` and OpenSpec guidance, then run `tools/verify-addon.sh`, `openspec validate --all`, and `git diff --check`.

## 4. Extract Normalized Quest Relations

- [ ] 4.1 After checkpoint 2 is merged, create a fresh `extract-quest-relations` worktree and branch from the latest `origin/main`, record the base SHA, and pass the unchanged baseline gate.
- [ ] 4.2 Add the directly loadable Lua 5.1 `QuestRelations` module with normalized `requiresAll`, `requiresAny`, `breadcrumbs`, `exclusiveWith`, and `followUps` arrays, bundled source provenance, deduplication, direct-self rejection, and reverse follow-up indexing; verify these cases in `tools/test-quest-relations.lua`.
- [ ] 4.3 Add the guarded optional Questie adapter for `nextQuestInChain`; verify valid successes are cached while absent, disabled, malformed, throwing, nil, non-finite, fractional, zero, negative, and out-of-range results fail open and remain retryable.
- [ ] 4.4 Route the current skipped-chain Unavailable lookup through `QuestRelations` without changing status precedence; verify the standalone relations test and updated `tools/test-quest-chain-status.lua` preserve every current Questie and embedded-data scenario without extracting relation helpers from source text.
- [ ] 4.5 Run focused tests, the full addon gate, and OpenSpec validation; create the review checkpoint PR `refactor: extract current chain lookup into quest relations service` with no Series UI or imported relationship dataset.

## 5. Expose Structured Quest State

- [ ] 5.1 After checkpoint 3 is merged, create a fresh `expose-structured-quest-state` worktree and branch from the latest `origin/main`, record the base SHA, and pass the unchanged baseline gate.
- [ ] 5.2 Add the directly loadable Lua 5.1 `QuestState` module with separate progress and availability results, manual versus derived sources, `REQUIRED_LEVEL` and `CHAIN_ADVANCED` reasons, legacy abandoned interpretation, and a numeric legacy adapter; verify `tools/test-quest-state.lua` covers every stored status and derived rule.
- [ ] 5.3 Make rows, filters, tooltips, and context-menu status checks consume the legacy adapter while lifecycle handlers continue to own stored progress; verify updated chain/status/context-menu regressions preserve numeric precedence, labels, colors, and Clear Status behavior without extracting state helpers from source text.
- [ ] 5.4 Verify QuestState returns unknown availability and the legacy adapter returns nil when no stored status or valid unavailable reason exists, including with Questie absent.
- [ ] 5.5 Run focused tests, the full addon gate, and OpenSpec validation; create the review checkpoint PR `refactor: expose structured quest state` with no Series UI.

## 6. Local Validation and Diff Review

- [ ] 6.1 For each remaining checkpoint, run its focused Lua 5.1 tests plus all affected existing regressions, including `tools/test-future-phase-labels.lua`, `tools/test-quest-store.lua`, `tools/test-quest-chain-status.lua`, `tools/test-quest-status-model.lua`, `tools/test-unmapped-quest-history.lua`, and `tools/test-history-hydration.lua` as applicable.
- [ ] 6.2 Run the required local gate `tools/verify-addon.sh` successfully for each checkpoint and retain its Luacheck, Lua 5.1, XML, TOC, whitespace, and full regression-test evidence.
- [ ] 6.3 Run `openspec validate --all` successfully after each OpenSpec-backed implementation checkpoint.
- [ ] 6.4 Inspect `git diff origin/main...HEAD`, every complete changed function, commit history, and final `git status --short --branch`; verify schema version 1, Interface `20506`, optional Questie, original attribution/provenance, existing data modules, XML/UI layout, lifecycle ownership, and packaging workflows remain unchanged outside the approved adapters and TOC load order.
- [ ] 6.5 For every remaining checkpoint with user-visible changes or bug fixes, include an accurate `CHANGELOG.md` `[Unreleased]` entry in the same PR; do not defer it to a release or present existing behavior as a new feature.

## 7. External Evidence and Delivery

- [x] 7.1 Complete and record the checkpoint-1 live smoke test described in task 2.6; static checks, remote CI, and install parity do not satisfy this task.
- [x] 7.2 For checkpoint 1, sync only the `EveryQuest*` addon directories after explicit authorization and prove repository/client parity without modifying SavedVariables.
- [x] 7.3 For checkpoint 1, push and open PR #37 after explicit authorization, verify its remote head SHA, and verify both remote CI jobs succeeded.
- [x] 7.4 Merge checkpoint 1 after separate explicit authorization; the resulting main commit is `7e872ee`.
- [ ] 7.5 For each remaining checkpoint, treat install parity, live client behavior, push, PR, remote CI, and merge as separate evidence/actions and perform only those explicitly authorized.
- [ ] 7.6 Package, tag, publish, or release only after separate explicit authorization once the intended releasable set is complete; verify each resulting state independently.

## Checkpoint 1 Live Evidence

- TBC Anniversary, 2026-09-13 (user-reported): the checkpoint-1 smoke suite
  passed on current `main` with script errors enabled. EveryQuest worked with
  Questie enabled and disabled; History and zone lists rendered correctly;
  manual status assignment and Clear Status behaved correctly; and the tested
  accept, complete, turn-in, abandon, and fail lifecycle paths produced the
  expected status updates. No Lua error was reported during the smoke suite.
- This is live client evidence supplied by the user. It is recorded separately
  from checkpoint-1 install parity, local validation, remote CI, and merge
  evidence above. No new installation, package, tag, publication, or release is
  claimed by this update.
