# Changelog

All notable changes to EveryQuest TBC Anniversary are documented in this file.

This changelog covers the Ancestral Forge continuation. Original EveryQuest
release-5 provenance is documented in `SVN_IMPORT_NOTES.md`.

## [Unreleased]

## [2026.3.7] - 2026-09-17

### Fixed

- Label future Phase 4 and Phase 5 quests in zone and history lists, including
  older saved history records that have no phase metadata.
- Keep saved quest history and manual statuses anchored to canonical quest
  records as quest data modules load, reducing stale or misplaced status data in
  zone lists, history lists, and tooltips.
- Prepare quest-data groups once during login/reload and report one startup
  summary, keeping later zone browsing free of repetitive loading and
  completed-sync messages.

## [2026.3.6] - 2026-08-27

### Fixed

- Route quest-log history for known quest IDs through EveryQuest's canonical
  quest bucket, keeping profession quests such as Alliance Trauma out of
  unrelated city headers like Ironforge.
- Preserve legacy quest-log levels and clear stale daily markers when history is
  refreshed from quest-log or static metadata.

## [2026.3.5] - 2026-08-23

### Fixed

- Make quest-type sorting return an explicit result in both comparison
  directions for zone and history lists.
- Clear visible quest rows before drawing a replacement list so a rendering
  error cannot leave stale history and zone entries mixed together.
- Read active quest-log headers, completion state, frequency, and quest IDs from
  the correct `GetQuestLogTitle` return positions on the Anniversary client.
- Keep Failed and Abandoned mutually exclusive, allow quests to be marked
  Unavailable, and provide an option to clear a manually stored status.
- Call an objective-complete quest `Ready to Turn In` and reserve `Completed`
  for a quest that has actually been turned in.
- Append `(Failed)` or `(Abandoned)` to affected quest rows without changing
  their existing status colors.
- When Questie is enabled, mark a quest Unavailable if its next quest in the
  chain is already active or completed; an explicit manual status overrides
  that automatic result.
- Open the quest status menu on right-click without relying on the unavailable
  global `EasyMenu` helper.
- Prevent zone quest lists from failing to render when a legacy quest type lacks
  a display tag.
- Display legacy Escort quest type `84` with the `E` tag.
- Restore missing names, levels, faction, and quest-type metadata in saved quest
  history when the matching static data module is loaded.
- Keep unknown quest lifecycle events unmapped until quest-log or loaded static
  data can resolve their canonical zone.

## [2026.3.4] - 2026-08-20

### Added

- Add optional Lava support links and GitHub funding metadata for Ancestral
  Forge.
- Add maintainer-facing contribution and release documentation.
- Add reusable Lua 5.1 compatibility checks for pull requests and releases.

### Changed

- Clarify the current Anniversary hybrid quest-log API bridge in project
  documentation.
- Ignore legacy/root-shaped SavedVariables unless they already use the current
  Anniversary schema, starting incompatible saved data from fresh defaults.
- Keep quest-list lookup, sorting, tooltip, and status-menu scratch state local
  to EveryQuest functions, reducing accidental WoW global namespace leakage.

### Fixed

- Preserve the selected zone across reloads instead of resetting the browser to
  the player's current zone.
- Route the `Current Zone`, `Show Quest History`, and `Show Zone Quests` button
  labels through the existing locale table.
- Record quest lifecycle updates from quest-log event data without lazy-loading
  static quest data modules, and avoid double-counting repeated completions when
  adjacent turn-in events report the same quest.

## [2026.3.3] - 2026-08-18

### Fixed

- Wait for the quest log to expose accepted quest categories before saving new
  quest history, keeping newly accepted quests synced to the correct zone.
- Keep the legacy zone dropdown under the selector while nudging long submenus
  upward just enough to keep their bottom edge on screen.
- Disable the `Current Zone` button when EveryQuest is already showing the
  player's current zone.

### Removed

- Remove the imported release-5 SVN changelog file from the addon tree.

## [2026.3.2] - 2026-08-16

### Added

- Add a `Current Zone` button that switches the EveryQuest browser to the
  player's current zone on demand, including city-name aliases such as
  `City of Ironforge` -> `Ironforge`.

### Changed

- Prefer the Anniversary `C_QuestLog` API for completed-quest state and
  supported quest-log calls.
- Remove unused legacy quest-counting code and empty XML script hooks.
- Remove old optional integration hooks for `LightHeaded` and `beql`.
- Remove the imported SVN `$Revision` runtime version fields.
- Use a strict Anniversary SavedVariables schema while migrating root-shaped
  legacy data.

### Fixed

- Avoid false abandoned quest timestamps when the Anniversary client emits
  `QUEST_REMOVED` during quest turn-in.
- Stop overriding Blizzard's `CloseSpecialWindows`; Esc closing now uses
  `UISpecialFrames`.
- Stop overriding Blizzard's quest abandon confirmation popup; quest abandon
  tracking now relies on `QUEST_REMOVED`.
- Stop overriding Blizzard's quest reward button; quest turn-in tracking now
  relies on the `QUEST_TURNED_IN` event.
- Coalesce `QUEST_LOG_UPDATE` quest-log scans and batch frame refreshes.
- Respect disabled quest data modules instead of enabling them during lazy load.
- Preserve existing quest history when migrating old root-shaped SavedVariables
  into the strict Anniversary schema.
- Handle TBC Anniversary's hybrid quest-log API: prefer `C_QuestLog`, but read
  active quest-log entries through the still-present Blizzard globals where the
  current client lacks equivalent `C_QuestLog` entry calls.
- Replace legacy global `gsub` and `sort` calls with namespaced Lua APIs to
  avoid login sync failures.

## [2026.3.1] - 2026-08-16

### Added

- WoW TBC Anniversary support for interface `20506`.
- Native addon initialization, saved-variable setup, event registration, and
  slash-command handling.
- Quest completion synchronization through `C_QuestLog`.
- Missing quest log entry reporting for quests not present in the bundled data.
- Project documentation, GPLv2 license text, and Ancestral Forge branding.

### Changed

- Modernized quest log rendering for the Anniversary client.
- Replaced legacy addon loading with `C_AddOns`.
- Reworked quest row rendering and texture clearing to avoid stale icons and
  unsafe texture state.
- Updated addon metadata to publish the current version under Ancestral Forge
  while preserving kandarz as the original author.

### Removed

- Obsolete Ace2-era runtime dependencies and compatibility shims.
- Legacy `embeds.xml` packaging path.
- Unused `modules.xml` import artifact.
- Misleading `/eq` alias and legacy commented Rock/LibRockConfig references.

### Fixed

- Startup hook ordering on the Anniversary client.
- Slash command registration.
- Frame initialization and quest list update errors.
- Completed quest flag sync and quest history updates.
