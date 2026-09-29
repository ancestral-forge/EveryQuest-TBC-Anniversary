## ADDED Requirements

### Requirement: Static quest and character history isolation
EveryQuest SHALL treat bundled quest records as immutable source data and SHALL
create new `EveryQuestDBPC.history` records by copying only the persisted flat
history fields `id`, `n`, `l`, `r`, `s`, `t`, and `d`. Mutating status,
timestamps, counts, or other character progress in history MUST NOT mutate the
static record, and relationship metadata MUST NOT be persisted into character
history.

#### Scenario: New history from a quest with relationships
- **WHEN** EveryQuest creates history for a static quest that also contains
  relationship metadata
- **THEN** the new history record contains the available whitelisted flat quest
  metadata
- **AND** the history record does not contain relationship tables or share its
  table identity with the static quest

#### Scenario: Character progress changes
- **WHEN** EveryQuest updates status or lifecycle timestamps on the new history
  record
- **THEN** the corresponding fields on the static quest remain unchanged

#### Scenario: Existing schema version 1 history is opened
- **WHEN** a character already has flat schema version 1 history records
- **THEN** EveryQuest reads and updates those records without an eager rewrite
  or schema-version increment
- **AND** existing progress and metadata fields remain available

#### Scenario: History rendering uses static-only presentation metadata
- **WHEN** a schema version 1 history record has no phase `p` field and its
  corresponding static quest record has reviewed future-phase metadata
- **THEN** a history row resolves the phase marker from the static quest record
- **AND** phase `p` remains absent from the history record and SavedVariables
- **AND** the row's stored status and lifecycle display remain unchanged

### Requirement: Quest lookup preserves load-on-demand behavior
EveryQuest SHALL provide one quest-ID lookup boundary for loaded static data and
character history. All loaded occurrences of a quest ID SHALL be indexed so
selection is deterministic under group and zone hints rather than dependent on
module registration order. Repeated lookups for an indexed quest SHALL return
its selected record and location without rescanning unrelated indexed zones,
while quests in unloaded groups SHALL retain the existing load-on-demand
fallback.

#### Scenario: Repeated lookup in an indexed group
- **WHEN** a loaded quest group has been indexed and the same quest ID is looked
  up more than once
- **THEN** each lookup returns the same static quest, group, and canonical zone
- **AND** the later lookup does not enumerate unrelated zones to rediscover it

#### Scenario: Duplicate static quest occurrences are indexed
- **WHEN** the same quest ID is present in more than one loaded group or zone
- **THEN** EveryQuest retains every loaded occurrence in the runtime index
- **AND** an exact group or zone hint selects the matching occurrence when one
  exists
- **AND** an unhinted lookup uses the established canonical group precedence
  rather than whichever data module happened to register first

#### Scenario: Lookup in an unloaded group
- **WHEN** a quest ID is not present in currently indexed groups and a hinted or
  fallback EveryQuest data group can be loaded
- **THEN** EveryQuest loads that existing data module through the established
  load-on-demand path
- **AND** registers the group so subsequent lookup uses the index

#### Scenario: History root is rebound
- **WHEN** database initialization or a compatibility path replaces the history
  root table
- **THEN** QuestStore rebuilds its history index from the new root
- **AND** no indexed record from the previous root remains reachable
- **AND** duplicate saved locations remain available through the indexed
  occurrence set for canonical reconciliation rather than being silently
  discarded during indexing

#### Scenario: History moves to its canonical location
- **WHEN** an existing history record is reconciled from a conflicting zone to
  the static quest's canonical zone
- **THEN** quest-ID history lookup returns the preserved record at the canonical
  zone
- **AND** no stale index entry continues to identify the old zone

#### Scenario: Quest remains unresolved
- **WHEN** no loaded or loadable EveryQuest data group contains the quest ID
- **THEN** lookup returns no static result without inventing a group or zone
- **AND** existing unknown-quest fallback behavior remains available to callers

### Requirement: Normalized optional quest relationships
EveryQuest SHALL expose quest relationships as normalized collections for
required-all, required-any, breadcrumb, mutually-exclusive, and follow-up quest
IDs. Verified bundled relationships SHALL take priority for the fields they
provide, Questie SHALL remain an optional fallback, and unavailable or invalid
provider data SHALL fail open.

#### Scenario: Bundled relationship is available
- **WHEN** verified bundled data defines a relationship for a quest ID
- **THEN** EveryQuest returns the valid normalized quest IDs from bundled data
- **AND** does not replace those values with Questie data for the same
  relationship field

#### Scenario: Relationship collections are normalized
- **WHEN** bundled relationship input contains duplicate IDs, malformed IDs,
  or a direct self relationship
- **THEN** EveryQuest returns only unique finite integer quest IDs in
  `1..16777215`
- **AND** the direct self edge is omitted
- **AND** each lookup returns fresh collections that cannot mutate cached
  provider data

#### Scenario: Reverse follow-ups are derived from forward facts
- **WHEN** a bundled quest declares `requiresAll`, `requiresAny`, or
  `breadcrumbs` relationships
- **THEN** each valid prerequisite can resolve that quest through the reverse
  `followUps` index
- **AND** `exclusiveWith` remains a constraint and does not create a
  follow-up edge

#### Scenario: Relationship provenance is reported
- **WHEN** bundled data, Questie, both providers, or neither provider
  contributes valid relationship data
- **THEN** the normalized result reports source provenance as `bundled`,
  `questie`, `both`, or no source respectively

#### Scenario: Questie supplies a valid follow-up
- **WHEN** bundled data has no follow-up for a valid quest ID and optional
  Questie returns a valid `nextQuestInChain` ID
- **THEN** EveryQuest returns that ID in the normalized follow-up collection
- **AND** a later lookup may use the cached successful relationship

#### Scenario: Optional provider is absent or faulty
- **WHEN** Questie is disabled, absent, malformed, throws an error, returns nil,
  or returns a non-finite, fractional, zero, negative, or out-of-range quest ID
- **THEN** EveryQuest returns no relationship from that provider without a Lua
  error or an availability false positive
- **AND** the failed or invalid result is not cached, so a later valid response
  can recover

#### Scenario: No provider has relationship data
- **WHEN** neither bundled data nor Questie has valid relationships for a quest
- **THEN** EveryQuest returns all normalized relationship collections as empty
  and identifies no source

### Requirement: Structured quest state with legacy display parity
EveryQuest SHALL resolve stored quest progress separately from manual or derived
availability and SHALL expose machine-readable reasons for derived
unavailability. Existing numeric status consumers SHALL continue to receive the
same effective status precedence and visual result through a legacy adapter.

#### Scenario: Stored progress overrides derived availability
- **WHEN** a quest has stored In Progress, Ready to Turn In, Completed,
  Abandoned, or Failed progress and also matches a derived unavailable rule
- **THEN** the structured state reports the stored progress
- **AND** the legacy adapter returns its existing numeric progress status rather
  than automatic `-2`

#### Scenario: Stored manual Unavailable is read
- **WHEN** a schema version 1 history record stores status `-2`
- **THEN** structured state reports an unavailable manual override rather than
  treating `-2` as quest progress
- **AND** the legacy adapter continues to return `-2`

#### Scenario: Level makes a quest unavailable
- **WHEN** the player's positive level is below a quest's positive required
  level and no stored status overrides the result
- **THEN** structured state reports derived unavailability with a level reason
- **AND** the legacy adapter returns `-2`

#### Scenario: Chain progress makes a predecessor unavailable
- **WHEN** a valid follow-up quest is active, ready to turn in, completed, or
  flagged complete and the predecessor has no stored override
- **THEN** structured state reports derived unavailability with the follow-up
  quest ID in its reason
- **AND** the legacy adapter returns `-2`

#### Scenario: Quest remains available or unknown
- **WHEN** no stored status or valid unavailable reason exists
- **THEN** the legacy adapter returns no status exactly as before
- **AND** existing row text, color, context-menu selection, and lifecycle event
  behavior remain visually unchanged in TBC Anniversary Interface `20506`

### Requirement: Foundation runtime compatibility
The foundation modules and their consumers SHALL run under Lua 5.1 on TBC
Anniversary Interface `20506`, SHALL preserve Blizzard ownership of secure quest
and reward UI, and SHALL not introduce a required external dependency.

#### Scenario: Addon loads without Questie
- **WHEN** EveryQuest loads on Interface `20506` with Questie disabled or absent
- **THEN** quest storage, history lookup, status rendering, and lifecycle event
  handling continue without a Lua error
- **AND** only relationship information unavailable from EveryQuest's own data
  remains unknown

#### Scenario: Existing quest UI path is exercised
- **WHEN** the player opens EveryQuest and uses current history, zone, status,
  and quest lifecycle paths
- **THEN** the foundation does not replace Blizzard-owned completion or reward
  handlers
- **AND** static validation or install parity is reported separately from live
  gameplay evidence
