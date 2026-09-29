## ADDED Requirements

### Requirement: Structured runtime state
EveryQuest SHALL expose a Lua 5.1 QuestState service with separate recorded progress,
source provenance, availability, and structured reasons, without mutating history.

#### Scenario: Reading each stored progress value
- **WHEN** history contains status 0, 1, 2, -3, or -1
- **THEN** progress is in_progress, ready_to_turn_in, completed, abandoned, or failed
- **AND** the existing legacy abandoned timestamp interpretation remains applicable

#### Scenario: No stored progress
- **WHEN** no recorded progress exists, including a stored -2 availability override
- **THEN** progress is unknown, not an invented lifecycle status

#### Scenario: Read-only current snapshots
- **WHEN** a consumer reads state repeatedly or mutates a returned result
- **THEN** history/static records remain unchanged and later results are fresh
- **AND** later level, history and completion evidence is evaluated again

### Requirement: Independent structured availability reasons
QuestState SHALL return machine-readable REQUIRED_LEVEL and CHAIN_ADVANCED reasons
independently of own stored progress, and SHALL preserve all supported matching reasons.

#### Scenario: Required level not reached
- **WHEN** a valid required level exceeds the known valid player level
- **THEN** availability is unavailable and REQUIRED_LEVEL includes both levels

#### Scenario: Chain advanced
- **WHEN** a normalized follow-up is recorded active, ready, completed, or flagged completed
- **THEN** availability is unavailable and CHAIN_ADVANCED identifies that follow-up and evidence

#### Scenario: Multiple blockers with own progress
- **WHEN** level and chain evidence both block a quest with its own stored progress
- **THEN** both reasons are returned without replacing that recorded progress

#### Scenario: Insufficient evidence
- **WHEN** no supported unavailable rule matches, or optional evidence is absent or invalid
- **THEN** availability remains unknown rather than available
- **AND** missing Questie does not raise an addon error or establish availability

### Requirement: Honest state provenance without mandatory migration
EveryQuest SHALL record optional manual/automatic statusSource metadata on new status
writes, retain unknown provenance for untagged legacy progress, and preserve schema
version 1 without an eager migration.

#### Scenario: Manual and automatic observations
- **WHEN** the user assigns a status or an automatic writer observes a status
- **THEN** the corresponding source is manual or automatic, even for numeric status 0
- **AND** confirming the same numeric status records the latest observation source

#### Scenario: Legacy history
- **WHEN** existing progress lacks valid source metadata
- **THEN** its source is unknown and merely reading it does not backfill metadata

#### Scenario: Duplicate history reconciliation
- **WHEN** QuestStore merges records with conflicting statuses or source metadata
- **THEN** the selected status keeps its own source, including unknown
- **AND** an adopted status adopts only the source belonging to that status

#### Scenario: Manual Unavailable and Clear Status
- **WHEN** stored status is -2
- **THEN** availability is manual unavailable with MANUAL_OVERRIDE, separate from progress
- **AND** existing Clear Status removes the record and restores automatic evaluation

### Requirement: Numeric display compatibility
Existing status consumers SHALL use a compatibility adapter that preserves numeric
values, own-progress precedence, labels, colors and manual status behavior.

#### Scenario: Recorded progress beats derived blocking
- **WHEN** a quest has a known recorded progress and a derived unavailable reason
- **THEN** the adapter returns that progress's legacy number rather than -2

#### Scenario: No recorded progress
- **WHEN** a quest has unavailable evidence but no recorded progress
- **THEN** the adapter returns -2
- **AND** without unavailable evidence it returns nil

#### Scenario: Runtime and gameplay evidence
- **WHEN** the change is validated
- **THEN** Lua 5.1, Interface 20506, licensing, data provenance and existing SavedVariables are preserved
- **AND** automated gate results are not presented as proof of live gameplay behavior
