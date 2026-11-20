# Changelog — unofficial fork

These notes cover changes made by this fork, not releases by GryllsAddons.

## 1.0.3-fork — 2026-11-20

- Add a minimum recorded death level, default **10**, editable in Settings or `/hcd log minlevel N` (whole numbers 1–60).
- Apply the threshold captured when a death notice arrives; preserve previously saved entries.
- Keep toast and system-message settings independent of the recording threshold.
- Reset restores the minimum to 10. Level 1 allows all normal player death levels.

## 1.0.2-fork — 2026-11-20

- Parse current death notices with `Name (level N) has fallen to Enemy (level N) in Place`.
- Save the announced place separately from the broad zone returned by `/who`.
- Show the precise place in log rows, details, and toasts; retain the broad zone in details.
- Retain victim levels from death notices instead of replacing them with later `/who` levels.
- Keep legacy death-message parsing and zone-only log compatibility.

## 1.0.1-fork — 2026-11-20

- Show the saved UTC date and time in every log row and its detail tooltip.
- Widen the log window to fit the timestamp column.
- Display placeholders for legacy records missing date/time without modifying those records.
- Preserve the original UTC recording format and saved-variable compatibility.

## 1.0.0-fork — 2026-11-20

### Added

- Settings window exposing all original command operations.
- Draggable minimap launcher with settings and log shortcuts.
- Twenty-row pages covering all recorded PvE/PvP deaths, newest first.
- Buttons, mouse-wheel page navigation, page counts, and an empty state.
- Input validation for numeric settings and decimal scales.
- Explicit fork attribution, source-snapshot history, and the preserved upstream README.

### Changed

- Removed the latest-50 display restriction.
- Log starts hidden on first installation/upgrade and after Reset; subsequent visibility choices are preserved.
- Bare `/hcd` and `/hcdeaths` now toggle Settings; `/hcd help` prints commands.
- Reset also restores the minimap position and the first log page, while retaining recorded deaths.
- Unsupported-client message no longer calls an addon object before it exists.

### Preserved
