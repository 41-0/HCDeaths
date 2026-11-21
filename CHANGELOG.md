# Changelog — unofficial fork

These notes cover changes made by this fork, not releases by GryllsAddons.

## 1.1.2-fork — 2026-11-21

- Silence chat feedback for GUI and minimap operations while preserving slash-command feedback.
- Show GUI command help in a hover tooltip instead of printing it to chat.

## 1.1.1-fork — 2026-11-21

- Capture Octo's separate last-words system notice and attach it to the player's latest death received in this session.
- Refresh active and queued death toasts and log details with the received words.
- Leave missing last words as `Unknown`; stop using potentially stale ordinary chat as last words.

## 1.1.0-fork — 2026-11-21

- Save every recognized death immediately, using `Unknown` for unavailable information.
- Separate queued `/who` enrichment from saving and toast display; timeouts never remove records.
- Show unknown class/race icons safely and retain announced levels when enriching records.
- Parse class, name, and level independently of trailing challenge descriptions in milestone announcements.
- Remove minimum recorded level filtering, its GUI control, and its command; discard the obsolete setting on startup.

## 1.0.5-fork — 2026-11-20

- Fix numeric field rendering with explicit opaque black backgrounds and borders.
- Use template-independent edit boxes with explicit fonts, padding, and dimensions for log scale, toast scale, toast duration, and minimum recorded level.
- Preserve existing input validation and Apply/Enter behavior.

## 1.0.4-fork — 2026-11-20

- Fix level-up announcement parsing for Octo's `Class Name of guild Guild Name has reached level N.` format, including multi-word guild names.
- Support the equivalent no-guild format and retain legacy milestones; correctly assign level 60 to legacy immortality notices.
- Identify Octo WoW as the fork's primary target in README, addon metadata, and settings title; describe other servers as unverified.
- Remove the startup gate based on Turtle-specific target-frame globals, which are not required by the addon.

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

- Original author's copyright and MIT License, unchanged.
- Original bundled media, saved-variable names, death parsing, and toast functionality.

### Validation

- Mocked API/frame regression tests passed; actual Turtle WoW client testing remains outstanding.
