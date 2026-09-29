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
- [ ] 3.3 Inspect the complete resulting diff and all changed functions; verify no unrelated data, XML, version, packaging, permanent workflow or schema-version changes.
- [ ] 3.4 Push only the task branch, open a PR for #48, verify its exact remote head and independently check normal PR CI.
- [ ] 3.5 Human TBC Anniversary smoke test with script errors enabled: zone/history rows, all manual statuses/Clear Status, Questie on/off, accept/ready/turn-in/abandon/fail.

## Evidence boundaries

Local container full gate: unavailable (no GitHub clone/network and no Lua 5.1,
Luacheck or OpenSpec). Local supplemental checks, if run, are not Lua 5.1 evidence.
Actions execution is remote technical evidence, not local execution or live WoW.
No install, package, merge, tag, publication, release or archive is authorized here.
The temporary branch preparation workflow is removed from the final PR tree.
