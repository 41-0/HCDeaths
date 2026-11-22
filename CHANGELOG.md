# Changelog — unofficial fork

These notes cover changes made by this fork, not releases by GryllsAddons.

## 1.5.4-fork — 2026-11-22

- Consolidate unknown-date grave observations with uniquely matching dated deaths on direct recording, shared import, enrichment, inspection and login.
- Require all mutually known semantic facts to agree, compare last words exactly, and preserve ambiguous/conflicting observations. Do not match deaths recorded after the first inspection.
- Preserve valid grave coordinates and first/last inspection times before removing an unknown-date observation; retain the normal death timestamp and source. Reconcile before startup retention limits and never remove observations for filtered imports.
- Read grave last words from labelled/quoted visible text, including child frames and late text; preserve original message bytes and avoid guessing among ambiguous quotes.
- Show matched-grave provenance and inspection timestamps in the normal log tooltip.
- Test exact message capture, per-field conflict rejection, ambiguity on either side, migration, direct/shared/enrichment paths, grave metadata preservation and existing regressions with mocked clients.

## 1.5.3-fork — 2026-11-22

- Close the normal/unknown-date log window with Esc through the standard WoW special-frame mechanism.
- Keep the saved visibility setting and GUI checkbox in sync when the window closes.

## 1.5.2-fork — 2026-11-22

- Add a prominent persistent request feedback banner for validation failures, exact remaining request cooldown, delivery delays, decline/expiry, cancellation, approval and completion.
- Explain that delivery/approval can take minutes and that the window can be closed while the user keeps playing.
- Check chat APIs and queue capacity before accepting a request; failed requests do not consume another cooldown. Report receiver rejection instead of silently ignoring a new request when pending limits are reached.
- Compact the consent notification, add the HCDeaths title, and default to the bottom-right corner with a small margin.
- Save dragged consent positions across logins, validate restored anchors/coordinates, and restore the default through Reset settings / positions.
- Test request error banners, cooldown seconds, background guidance, chat silence, compact panel/title/default anchor, position restoration and reset, alongside existing synchronization and grave-log regressions.

## 1.5.1-fork — 2026-11-22

- Let explicit full-history requests interrupt automatic receiving/discovery, and accept requests even if the capability advertisement was lost.
- Acknowledge delivery and retry missing request/approval replies within the existing paced transport. Preserve per-transfer consent and combat deferral; handle 0/1 combat API results explicitly.
- Redraw consent independently from transport, give the notification explicit text dimensions and a visible frame layer, and report UI errors in sync diagnostics.
- Add a live sync status/progress panel with entry/fragment counters, queue/send delays, request phases and completion feedback.
- Save directly inspected unrecorded graves in a separate local-only unknown-death-date list. Track first/last inspection UTC without inventing a death time or PvE/PvP cause type.
- Add a top-left log switch and newest-inspected sorting with pagination; reuse matching observations on repeat visits.
- Apply retention and manual cleanup across both lists, using inspection time for undated graves.
- Test missing request/approval recovery, capability-loss and discovery paths, numeric combat states, live notification, unknown-date creation/revisit/sorting/pagination/retention and existing regressions with mocked clients. In-game verification remains necessary.

## 1.5.0-fork — 2026-11-21

- Limit automatic grants to the newest 100 shareable entries, independent of local retention settings; bound automatic intake from legacy senders too.
- Skip unchanged peer inventories using recent-history digests, enlarge negotiated inventory pages within the packet limit, and space idle discovery at 10–12 minutes.
- Add a dedicated full-history request/cancel dialog and per-transfer sender approval. Keep full-history transfers paced, validated and subject to retention rules.
- Show a small draggable top-right consent panel without sound or focus capture; defer it during combat and guard the approval action itself.
- Bound and consolidate pending requests, rate-limit repeated requests, expire unanswered requests after 10 minutes, and support decline/cancellation.
- Preserve automatic interoperability with 1.4.5/1.4.6; require 1.5.0+ for manual full history.
- Verify mocked multi-client consent, combat deferral, newest-100 enforcement, unchanged skipping, cancellation, expiry and existing regression suites. Actual 1.12 UI verification remains necessary.

## 1.4.6-fork — 2026-11-21

- Negotiate compact transfers between updated peers while retaining full-format fallback for older versions.
- Omit unknown fields, preserve known empty values and original text bytes, use case-fold-safe base32, and fit larger fragments within the 240-byte packet limit.
- Start syncing after the first peer offer instead of waiting out the full discovery deadline.
- Keep the chat pacing, cooldown/backoff, partial-transfer retry and retention behavior intact.
- Show imported/enriched counts, send queue, transfer mode and fragment progress in the sync hover.
- Test compact/full round trips, all-byte encoding, missing-fragment recovery and mixed 1.4.5/1.4.6 peers; the sample data transfer shrinks from five packets to two.

## 1.4.5-fork — 2026-11-21

- Reduce normal sync traffic to one packet every 10–12 seconds initially.
- Recognize server chat cooldown warnings and channel THROTTLED notices, pause automatically, and adapt spacing up to 60 seconds.
- Leave a quiet interval after the player's normal chat traffic.
- Extend no-progress retries and discovery waits to suit slow transmission; freeze active timers during cooldowns and keep active transfer sessions alive.
- Deduplicate queued packets and avoid retrying requests that have not yet been sent.
- Show send spacing/cooldown in sync status and GUI hover, and test recovery with a server-enforced speech cooldown.

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
