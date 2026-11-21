# Changelog — unofficial fork

These notes cover changes made by this fork, not releases by GryllsAddons.

## 1.4.4-fork — 2026-11-21

- Recover partial sync transfers by retaining received fragments and requesting only missing fragments after a no-progress interval.
- Retry missing inventory and initial record requests up to three times per request stage before timing out.
- Cache a stable serialized record while retransmitting to avoid mixing enriched record versions.
- Slow normal channel transmission to one packet every three seconds.
- Release session snapshots at completion/abandonment and report retransmissions, timeouts, and fragment progress.
- Test recovery from selectively dropped data fragments and inventory requests within the same synchronization session.

## 1.4.3-fork — 2026-11-21

- Replace unsafe pipe-separated ordinary-chat envelopes with colon framing; both peers must update.
- Prioritize discovery/handshake/request packets over bulk data so they do not time out while queued.
- Tolerate case-folded envelope and player-name routing without changing record payload bytes.
- Add `/hcd sync check` and `/hcd sync status`, including channel membership, send/receive/echo counters, transfer stages, imports, filters, validation failures, and shareable log counts.
- Save the latest compact synchronization diagnostic snapshot and surface errors in the GUI hover.
- Capture previously discarded send failures, retry with a delay, and contain client API/runtime errors.
- Extend multi-client tests to reject pipe markup, fold envelope casing, and simulate send failures.

## 1.4.2-fork — 2026-11-21

- Fix grave-coordinate capture on Lua 5.0, where `math.huge` is unavailable and negating it raised an error.
- Remove all dependencies on `math.huge` from addon numeric validation.
- Add regression coverage with `math.huge` deliberately absent.

## 1.4.1-fork — 2026-11-21

- Improve grave recording retries to cover delayed UI/log availability, and allow completion of uniquely matched unknown levels.
- Read verified current-zone map coordinates directly; correctly distinguish actually visible maps from shown children of hidden UI parents.
- Show raw-only observer coordinates in tooltips rather than hiding numeric position data when map coordinates are unavailable.
- Add `/hcd grave check` and `/hcd grave status`, including missing-module, parsing, no-match, ambiguity, known-field conflict and coordinate/API diagnostics.
- Save only the latest grave diagnostic snapshot; contain client API errors and replace malformed coordinate bundles atomically.

## 1.4.0-fork — 2026-11-21

- Add a saved-death cap, unlimited by default, enforced on login and both local/shared record intake.
- Add a log-management dialog for the cap and one-time deletion below a level, older than a number of days, or beyond a desired newest-entry count.
- Use UTC receipt timestamps for oldest-first cleanup, removing unknown-date entries first for count limits and retaining them for age cleanup.
- Save compact local cleanup cutoffs to prevent deleted historical entries returning through sharing; future direct death recording remains enabled.
- Stabilize synchronization inventory references across deletions, skip removed transfers, expire snapshots, and bound fingerprint caches when a cap is enabled.
- Keep GUI feedback inside its dialog and add equivalent slash commands.

## 1.3.0-fork — 2026-11-21

- Add automatic observations of OctoReplayGraveFrame using the diagnosed name/level/race/class/killer text.
- Attach observer coordinates only to one unambiguous matching saved death; fill unknown descriptive fields without creating death records.
- Preserve the original death location/time, label the observation separately, and show observer/map/time details in the log tooltip.
- Restore hidden-map selection after coordinate reads; retain raw UnitPosition values and skip unavailable positions.
- Share validated observer-coordinate bundles atomically through protocol/channel V2. All sharing peers must upgrade from 1.2.0.

## 1.2.0-fork — 2026-11-21

- Add default-on automatic log sharing through a dedicated hidden custom channel, without manual peer selection.
- Discover same-realm/faction peers, compare record fingerprints, and transfer unfamiliar record versions in paced, bounded fragments.
- Merge by name/level/type with compatible killer/location and a five-minute timestamp tolerance; fill only unknown facts and retain direct repeat deaths.
- Identify shared records and supplemented details in tooltips; import history without sounds, toasts, or lookup requests.
- Add an automatic-sharing checkbox, hover status, and `/hcd sync`; retain silent GUI operations.
- Sort the log display by receipt time without rearranging the stored transport indices.
- Preserve local recording during channel failures; add timeout/retry, size validation, queue limits, and sender rate limits.
- Mark this as experimental until tested with real Octo clients. Sharing is same-faction, best effort, and unauthenticated.

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
