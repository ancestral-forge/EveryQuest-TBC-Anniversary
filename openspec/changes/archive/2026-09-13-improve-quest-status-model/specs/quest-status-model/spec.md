## Purpose

Define stable quest-status semantics, manual overrides, lifecycle precedence,
and safe optional chain detection for EveryQuest users on TBC Anniversary.

## ADDED Requirements

### Requirement: Distinct quest statuses
EveryQuest SHALL represent Completed, Ready to Turn In, In Progress,
Unavailable, Abandoned, and Failed as mutually exclusive displayed statuses.

#### Scenario: Choosing a manual status
- **WHEN** the user chooses one status from the quest context menu
- **THEN** EveryQuest stores and selects only that status
- **AND** stale failed or abandoned timestamps do not cause another status to appear selected

#### Scenario: Distinguishing red statuses
- **WHEN** a quest is displayed as Failed or Abandoned
- **THEN** the quest keeps the existing red status color
- **AND** its row includes `(Failed)` or `(Abandoned)` respectively

### Requirement: Clearable manual status
EveryQuest SHALL provide a Clear Status action that removes the stored override
and restores automatic display-state evaluation.

#### Scenario: Clearing a status
- **WHEN** the user chooses Clear Status for a quest with stored history
- **THEN** the stored status override and its stale lifecycle timestamps are removed
- **AND** the quest is displayed from current automatic evidence

### Requirement: Completion terminology and lifecycle precedence
EveryQuest SHALL display status `1` as Ready to Turn In and status `2` as
Completed, and SHALL let the quest's own recorded lifecycle state take
precedence over derived Unavailable.

#### Scenario: Completing objectives
- **WHEN** an accepted quest becomes complete in the Blizzard quest log
- **THEN** EveryQuest displays it as Ready to Turn In

#### Scenario: Turning in a quest
- **WHEN** Blizzard emits `QUEST_TURNED_IN` for that quest
- **THEN** EveryQuest records and displays it as Completed
- **AND** Blizzard remains responsible for quest completion and reward UI

#### Scenario: Turning in a later quest first
- **WHEN** two chain quests are active or ready and the later quest is turned in first
- **THEN** the earlier quest retains its own In Progress or Ready to Turn In status
- **AND** turning in the earlier quest later changes it to Completed

### Requirement: SavedVariables compatibility
EveryQuest SHALL read existing `EveryQuestDBPC` quest-history records without a
destructive or mandatory migration.

#### Scenario: Reading existing completion values
- **WHEN** existing history contains numeric status `1` or `2`
- **THEN** it is displayed as Ready to Turn In or Completed respectively

#### Scenario: Reading a legacy abandoned record
- **WHEN** existing history uses status `-1` and its abandonment timestamp is the applicable latest failure-state timestamp
- **THEN** EveryQuest displays the record as Abandoned rather than Failed

### Requirement: Derived skipped-chain status
EveryQuest SHALL derive Unavailable for an otherwise unrecorded quest when a
known next quest in its chain is In Progress, Ready to Turn In, or Completed.

#### Scenario: Skipped predecessor
- **WHEN** a quest has no stored status and its known next quest is active, ready, or completed
- **THEN** EveryQuest displays the current quest as Unavailable

#### Scenario: Manual correction
- **WHEN** the user assigns a status to an automatically unavailable quest
- **THEN** the stored status overrides derived Unavailable
- **AND** clearing the stored status restores derived Unavailable when the chain evidence remains

### Requirement: Optional fail-open chain provider
EveryQuest SHALL remain usable without Questie and SHALL treat Questie chain
metadata as optional, untrusted input rather than owned quest history.

#### Scenario: Questie is absent or faulty
- **WHEN** Questie is disabled, unavailable, malformed, throws an error, or returns `nil` or invalid data
- **THEN** EveryQuest continues without an addon error
- **AND** it does not derive a chain-based status from that answer

#### Scenario: Questie returns a relationship
- **WHEN** Questie returns a finite positive integer quest ID in the supported range
- **THEN** EveryQuest may use and cache that relationship

#### Scenario: Questie later recovers
- **WHEN** an earlier lookup failed or returned a dubious answer and a later lookup returns a valid relationship
- **THEN** EveryQuest accepts the later relationship without requiring a reload

### Requirement: Runtime and provenance constraints
The quest-status implementation SHALL remain compatible with Lua 5.1 and WoW
TBC Anniversary Interface `20506`, preserve GPL-2.0-only attribution and data
provenance, and SHALL NOT copy Questie data into EveryQuest.

#### Scenario: Validating the change
- **WHEN** the local addon gate runs
- **THEN** the changed Lua, XML, TOC, and regression tests satisfy the repository checks
- **AND** that static result is reported separately from live gameplay evidence
