## 1. Work state and planning

- [x] 1.1 Inspect main SHA, issue #48, current state rules, repository agent contract, addon skill, canonical specs and existing foundation design; pin base 7be2c1c5bef9796c5c5ff62a6f76b7e7f0154141.
- [x] 1.2 Write proposal, design, delta requirements and this evidence checklist before runtime implementation.
- [x] 1.3 Inspect branch/SHA/worktrees/dirty state in a clean Actions worktree based on pinned main and run the unchanged baseline tools/verify-addon.sh successfully.

## 2. Implementation

- [x] 2.1 Add directly loadable QuestState, dependency injection, named progress/source, independent reasons, conservative unknown availability, legacy abandoned interpretation and numeric adapter; run focused Lua 5.1 tests.
- [x] 2.2 Wire the adapter into existing UI consumers and add the TOC entry; run chain, status, context-menu and phase regressions without extracting new module internals.
- [x] 2.3 Record optional source metadata in manual/automatic write paths and preserve its pairing during history merges; run lifecycle/source and duplicate-history regressions.

## 3. Validation and delivery

- [x] 3.1 Run the complete final tools/verify-addon.sh in the Actions worktree, retaining output for Luacheck, Lua 5.1, XML, TOC and all regression tests.
- [x] 3.2 Run openspec validate --all using the repository-pinned CLI version 1.10.0.
- [x] 3.3 Inspect the complete resulting diff and all changed functions; verify no unrelated data, XML, version, packaging, permanent workflow or schema-version changes.
- [ ] 3.4 Push only the task branch, open a PR for #48, verify its exact remote head and independently check normal PR CI.
- [ ] 3.5 Human TBC Anniversary smoke test with script errors enabled: zone/history rows, all manual statuses/Clear Status, Questie on/off, accept/ready/turn-in/abandon/fail.

## Automated evidence

The successful [Actions preparation run](https://github.com/ancestral-forge/EveryQuest-TBC-Anniversary/actions/runs/36546658025)
checked the unchanged main baseline in a detached worktree, then applied the
bounded integration patch and ran the complete addon gate plus
`npx --yes @fission-ai/openspec@1.10.0 validate --all` in a separate clean
implementation worktree. It committed the validated result as
`074c09cbe16dfb2a4600555ba83eb42ad249902b` on the task branch. The earlier
preparation attempt found a startup-test harness that did not load the newly
required module; the successful run includes that harness correction.

Diff review of that implementation head against the pinned main confirmed the
QuestState module, the single numeric adapter, all eight status-write sites,
status/source merge pairing, the TOC load order, the direct state and chain tests,
writer/adapter coverage, and the existing startup/status harness adjustments.
The final tree has no temporary preparation script or workflow. Static quest
data, XML, translations, version, licensing and schema-version declarations are
unchanged. No checks were removed or weakened.

PR: [#60](https://github.com/ancestral-forge/EveryQuest-TBC-Anniversary/pull/60).
Normal PR CI on the delivered branch is tracked separately from the preparation
run; this documentation commit triggers that independent gate.

## Evidence boundaries

Local container full gate: unavailable (no GitHub clone/network and no Lua 5.1,
Luacheck or OpenSpec). Actions execution is remote technical evidence, not local
execution or live WoW. No install, package, merge, tag, publication, release or
archive was performed. The change remains open for the human smoke-test evidence.
