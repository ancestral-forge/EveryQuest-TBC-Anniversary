## Context

See `proposal.md` for motivation and
`specs/quest-status-model/spec.md` for observable behavior. Existing history
uses numeric quest statuses and optional lifecycle timestamps. The implementation
must preserve those records, use native Blizzard lifecycle events, remain Lua
5.1-compatible, and treat Questie as an optional data provider.

## Goals / Non-Goals

**Goals:**

- Centralize stored-versus-derived status resolution so menus, rows, and
  tooltips agree.
- Preserve old completion values without a SavedVariables rewrite.
- Derive skipped-chain Unavailable conservatively and fail open when chain data
  is absent or invalid.

**Non-Goals:**

- Persist automatically derived Unavailable values.
- Build or import a second chain database.
- Change Blizzard quest or reward UI ownership.
- Generalize the addon for other WoW clients.

## Decisions

### Preserve numeric completion values and add distinct negative states

Keep `0` for In Progress, `1` for Ready to Turn In, and `2` for Completed.
Use `-1` for Failed, `-2` for Unavailable, and `-3` for Abandoned. Existing
status `1` and `2` records need no migration; legacy status `-1` records with an
applicable abandonment timestamp are interpreted as Abandoned at read time.

This is preferred over rewriting all SavedVariables because interpretation at
the boundary is reversible and avoids a versioned migration for a label and
negative-state split.

### Resolve one displayed status before rendering

Resolve explicit history first, then derive Unavailable only when no stored
status exists. Use the same resolved value for context-menu selection, row
color/text, and tooltip output.

This is preferred over independent UI checks because independent checks caused
Failed and Abandoned to appear selected together and allowed display paths to
disagree.

### Keep lifecycle ownership in Blizzard events

Quest-log completion records Ready to Turn In. `QUEST_TURNED_IN` records
Completed. A quest's stored active, ready, or completed state wins over derived
chain status, so simultaneously available quests remain independently
completable. EveryQuest only observes state and does not replace Blizzard-owned
buttons or reward handlers.

### Derive but do not persist skipped-chain Unavailable

When a known next quest is active or completed, an unrecorded predecessor is
displayed as Unavailable. A manual status is stored as an override; Clear Status
removes the history entry and re-enables derivation.

This is preferred over persisting automatic Unavailable because server or addon
chain data can be wrong and the player must be able to correct the display.

### Treat Questie as a guarded optional provider

Declare Questie as an optional dependency, import its database module only when
available, and protect module lookup and query calls. Accept only finite integer
quest IDs from `1` through `16777215`. Cache only validated successful
relationships; never cache errors, nil, or dubious values.

This is preferred over a mandatory dependency or copied chain data because it
keeps EveryQuest functional alone and preserves separate data ownership.

## Risks / Trade-offs

- [Questie has no valid relationship] → Skip chain derivation and leave the
  quest otherwise unchanged.
- [Questie data is temporarily unavailable] → Do not cache the failure, allowing
  a later lookup to recover.
- [A server permits a nonstandard chain order] → Allow a manual status override
  and make Clear Status reversible.
- [Legacy `-1` data is ambiguous] → Use existing timestamps only for compatible
  read-time interpretation; do not rewrite the record.
- [Automatic state differs from live gameplay] → Require separate human client
  checks and do not treat the local gate as gameplay proof.

## Migration Plan

No eager migration runs. Existing records remain in place and are interpreted
compatibly. New abandoned events and manual choices use the distinct `-3`
value. Rollback consists of reverting the code and TOC change; existing `-3`
records would be unknown to the older version, so rollback should restore the
new version or manually clear those specific overrides rather than bulk-editing
SavedVariables.
