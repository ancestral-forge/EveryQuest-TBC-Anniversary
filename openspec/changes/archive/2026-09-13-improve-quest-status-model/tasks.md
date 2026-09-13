## 1. Work State and Contract

- [x] 1.1 Confirm the clean `fix-quest-status-model` worktree, current `origin/main` merge base, issue #31 scope, and relevant addon-runtime and quest-status specs with git and OpenSpec status output.

## 2. Status Model and Lifecycle

- [x] 2.1 Implement mutually exclusive stored statuses, legacy abandoned-record interpretation, and Clear Status, verified by `tools/test-quest-status-model.lua` under Lua 5.1.
- [x] 2.2 Update row labels, tooltip/menu terminology, lifecycle precedence, localization, and changelog text, verified by the status-model and context-menu regression tests.

## 3. Skipped Chain Detection

- [x] 3.1 Derive Unavailable from a later active or completed quest while preserving manual and lifecycle overrides, verified by `tools/test-quest-chain-status.lua`.
- [x] 3.2 Guard optional Questie module access, validate returned quest IDs, and cache only valid relationships, verified by disabled/error/nil/garbage fault-injection cases.

## 4. Local Validation

- [x] 4.1 Run `tools/verify-addon.sh` successfully after implementation and retain its Lua 5.1, Luacheck, XML, TOC, whitespace, and regression-test evidence.
- [x] 4.2 Run `openspec validate --all` successfully and inspect the complete `origin/main...HEAD` diff for scope and compatibility.

## 5. Delivery and Runtime Evidence

- [x] 5.1 Verify accept, complete, turn-in, abandon, fail, clear, simultaneous-chain, skipped-chain, and faulty/disabled Questie behavior in the live TBC Anniversary client with script errors enabled.
- [x] 5.2 Verify merged PR #32 targeted `main`, closed issue #31, and produced merge commit `6a90ac11fc9e4eb164172ed4fa4f6b670a8eb4e6`.
- [x] 5.3 Verify the pull request and post-merge `main` CI results separately from local and live-client evidence.

## Completion Evidence

- Live TBC Anniversary, 2026-09-13 (user-reported): the full checkpoint 1
  smoke suite passed with script errors enabled. EveryQuest remained usable
  with Questie enabled and disabled; History and zone lists rendered correctly;
  manual status assignment and Clear Status behaved as specified; and accept,
  complete, turn-in, abandon, and fail lifecycle events produced the expected
  mutually exclusive states. Simultaneous-chain and skipped-chain behavior also
  passed. No addon error was reported during the smoke suite.
- Delivery: [PR #32](https://github.com/ancestral-forge/everyquest-tbc-anniversary/pull/32)
  merged to `main` on 2026-08-22 as
  `6a90ac11fc9e4eb164172ed4fa4f6b670a8eb4e6` and closed
  [issue #31](https://github.com/ancestral-forge/everyquest-tbc-anniversary/issues/31).
- Remote CI: PR Linter run
  [32596568284](https://github.com/ancestral-forge/everyquest-tbc-anniversary/actions/runs/32596568284)
  passed Lua lint and OpenSpec validation. Post-merge `main` Linter run
  [32597472973](https://github.com/ancestral-forge/everyquest-tbc-anniversary/actions/runs/32597472973)
  also passed at the exact merge SHA. GitLab mirror runs passed separately.
- This evidence update records the completed live and delivery state. It does
  not claim a new installation, package, release, or independently observed
  client run by the agent.
