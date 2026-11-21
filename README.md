# HCDeaths — Unofficial GUI Fork

An unofficial, MIT-licensed fork of **HCDeaths**, originally created by **Grylls / GryllsAddons** for Turtle WoW. **This fork primarily targets Octo WoW.** It adds a settings GUI, a minimap launcher, a paged death log, and support for Octo WoW announcement formats. Other compatible 1.12 servers may work, but are not verified.

This is an independently modified version, not an official GryllsAddons release. The original author is credited for the original addon; changes and support for this fork are separate. No endorsement by GryllsAddons, Octo WoW, Turtle WoW, or Blizzard Entertainment is implied.

## Credits and source history

- Original addon: **HCDeaths**.
- Original author: **Grylls**, identified as **GryllsAddons** in the upstream copyright notice.
- Original repository reference: [GryllsAddons/HCDeaths](https://github.com/GryllsAddons/HCDeaths). This is a historical reference; the supplied archive's README states that the original repository was deleted.
- This fork was based on the supplied `HCDeaths.zip` archive, containing the `HCDeaths-main` directory. The archive's ZIP comment identifies revision `15e16fa4ad80c3b89f4b0dc27318ca6362faa713`.
- The archive mirror's repository URL was not included in the supplied files and has not been established. The revision above identifies the supplied snapshot; it is not claimed to be a verified original-author revision.
- The unmodified README from that snapshot is retained as [README.upstream.md](README.upstream.md) for provenance. Its archive-maintainer statements and screenshots describe the upstream archive, not this fork's maintenance status or current GUI.

## What this fork changes

- Adds a settings GUI covering the original commands, automatic sharing, and command help on hover.
- Adds a draggable minimap launcher: left-click for Settings, right-click for the death log.
- Replaces the latest-50 display with a newest-first log showing **20 entries per page**.
- Makes every saved PvE/PvP death accessible through page buttons or the mouse wheel. Storage defaults to unlimited, with an optional user-defined cap and manual cleanup controls.
- Hides the log on first installation/upgrade and after Reset. Subsequent visibility choices are saved; hidden logs continue recording.
- Validates numeric settings and accepts decimal scales.
- Retains saved-variable names and bundled media, with reliable recording and expanded announcement parsing. Reset does not delete deaths.

See [CHANGELOG.md](CHANGELOG.md) for the fork's release notes.

## Requirements and installation

- **Octo WoW / WoW 1.12** is the primary target; addon code uses Lua 5.0-compatible syntax and APIs.
- Other 1.12 servers may work if their announcements and APIs are compatible; compatibility is not guaranteed. The addon does not reject a client simply because Turtle-specific target-frame globals are absent.
- No additional addon libraries are required.
- Extract the **HCDeaths** folder into `Interface/AddOns/`.
- The resulting path must be `Interface/AddOns/HCDeaths/HCDeaths.toc`. If downloaded from GitHub, rename the repository's extracted folder to **HCDeaths** when necessary.
- This fork replaces the original HCDeaths installation; do not load duplicate copies side by side.
- Existing `HCDeaths`, `HCDeaths_Settings`, and `HCDeaths_LastWords` saved variables are reused; compact cleanup cutoffs use `HCDeaths_PruneRules`. Existing deaths are retained.

## GUI and controls

Open Settings using `/hcd`, `/hcdeaths`, `/hcd gui`, or the minimap icon's left-click.

GUI and minimap operations do not print chat feedback. Command help appears on hover; direct slash commands retain their chat feedback.

Settings contains the original command operations: system messages, log visibility, toasts, level progress, ring colors, death sounds, level sounds, roar selection, log scale, toast scale, toast duration, movable-toast preview, and Reset.

- Numeric fields: press **Apply** or Enter. Scale range: **0.25–3**. Toast duration: greater than **0** and at most **300 seconds**.
- Minimap icon: left-click Settings; right-click toggle log; drag around the minimap.
- Log: **Newer / Older** buttons or mouse wheel; drag the background/title to move it. Hover a row for death details.
- Toast: Ctrl + Shift + drag to move; Ctrl + Shift + right-click to reset its position. Use the movable-toast preview to position it outside a death notification.
- Reset restores settings (including an unlimited record cap) and log/toast/minimap positions. It does **not** clear recorded deaths or the compact rules that prevent deleted history being restored by synchronization.

## Chat commands

| Command | Action |
| --- | --- |
| `/hcd` or `/hcd gui` | Open/close Settings |
| `/hcd help` | Print command help |
| `/hcd message` | Toggle system death messages |
| `/hcd move` | Show/hide movable-toast preview |
| `/hcd log` | Toggle death log |
| `/hcd log scale number` | Set log scale |
| `/hcd grave check` | Retry the open grave window and print recording diagnostics |
| `/hcd grave status` | Print the latest grave recording result |
| `/hcd log max number` | Set saved death cap; 0 = unlimited; apply immediately |
| `/hcd prune level number` | Delete deaths strictly below the specified level |
| `/hcd prune days number` | Delete deaths strictly older than this many 24-hour periods |
| `/hcd prune keep number` | One-time cleanup to keep at most this many newest deaths; 0 deletes all |
| `/hcd toast` | Toggle death toasts |
| `/hcd toast scale number` | Set toast scale |
| `/hcd toast time seconds` | Set toast duration |
| `/hcd progress` | Toggle level-progress toasts |
| `/hcd color` | Toggle toast ring colors |
| `/hcd deathsound` | Toggle death sounds |
| `/hcd levelsound` | Toggle level-progress sounds |
| `/hcd roar` | Toggle death roars instead of the raid alert |
| `/hcd sync` | Toggle automatic log sharing (default on) |
| `/hcd reset` | Reset settings and positions; preserve deaths |

`/hcdeaths` is an alias for `/hcd`.

## Reliable death recording

Every recognized death notice is stored immediately, regardless of level or `/who` availability. Missing information is saved as `Unknown`; a question-mark icon represents an unknown class or race. A later successful `/who` response enriches the saved record. Lookups are queued, spaced at least 10 seconds apart, and time out after 5 seconds. Failed lookups never delete a death. These timings do not guarantee a server response.

There is no minimum recorded level setting. Previously saved thresholds are discarded on startup. Existing records are preserved.

## Level-up toasts

The parser supports Octo announcements such as `Rogue Notogii of guild Hell Fire has reached level 20. As they ascend towards immortality, their glory grows! However, so too does the danger they face.` It extracts the player's name and reached level correctly even when a guild name contains spaces. The equivalent format without a guild, and the original Turtle-style announcements, are also supported.

Enable **Death toast popups** and **Level progress toasts** for milestone toasts. **Level-up sounds** controls their sound separately. Toasts use the class, name, and reached level from the announcement without waiting for `/who`. Text following the level is ignored, including challenge descriptions such as `while enduring the Slow and steady challenge.` Unknown race or guild information does not block the toast.

## Death locations

For current messages such as `Hardcore character Witch (level 32) has fallen to Torn Fin Tidehunter (level 32) in Western Strand`, the announced place is stored in a separate `location` field and shown in the log, tooltip, and toast. The broad `/who` zone remains in `zone` and is shown separately in the tooltip when different. Older entries without a saved location continue showing their zone; historical precise locations cannot be reconstructed from zone-only records.

The current PvE message format above was supplied as a real example. Equivalent natural-cause and PvP formats are supported by parser tests but have not been verified against live messages. Legacy messages remain supported.

## Storage limit and manual cleanup (1.4.0)

Open Settings, then **Manage saved logs**. These controls operate on saved PvE/PvP death entries. GUI actions and validation messages appear in the dialog, without chat feedback. Direct slash commands retain their chat feedback.

| Control | Behavior |
| --- | --- |
| Maximum entries | **0 = unlimited (default)**. Applying a positive whole number immediately deletes the oldest excess deaths and enforces that cap on login, locally received death notices, and imported shared history. |
| Delete below level | One-time deletion of entries whose known player level is **strictly less** than the entered value. Whole values 1–61 are accepted; e.g. 10 retains level 10. Unknown levels remain. |
| Delete older than days | One-time deletion of entries whose UTC receipt timestamp is **strictly earlier** than the current time minus N × 24 hours. Whole values 1–36500 are accepted; entries exactly on the boundary or with missing/invalid dates remain. |
| Keep newest | One-time deletion of excess entries, oldest first. **0 deletes all saved deaths**. This does not change the persistent maximum-entry setting. |

Maximum/keep values accept whole numbers 0–2147483647. Maximum **0 means unlimited**, while a one-time keep value of **0 means delete all**. A cap limits the number of death entries, not an exact file size. Existing observations and other fields contribute to each record's size.

Oldest-first operations compare saved UTC receipt timestamps rather than array order. Unknown/invalid timestamps are removed first; equal timestamps use the earlier saved entry first. The stored order of surviving entries is retained, and the page browser clamps to the remaining pages. For safety, pressing Enter in a one-time cleanup input only ends editing; use the explicitly labeled deletion button to run the cleanup.

Deletions are local and are not sent as commands to delete other users' logs. Compact realm/faction-specific cutoffs in `HCDeaths_PruneRules` prevent the deleted old history from being automatically imported again. Level cleanup remembers the operation time for the affected levels; age cleanup remembers the age boundary; oldest-first cleanup remembers the deleted timestamp boundary. These are compact cutoffs rather than a growing list of deleted names. Consequently, unfamiliar shared history on the discarded side of those boundaries may also be ignored. Current retained records can still receive missing details.

These cleanup actions do not establish a minimum level for future death recording. New direct server notices continue to be recorded, subject to the configured count cap. Reset restores the cap to unlimited but does not undo deletions or clear the anti-restoration cutoffs. Applying a cap or a deletion has an immediate effect; it is not an undoable preview.

Synchronization uses stable per-session inventory references so that deletions cannot change an advertised index to point at a different death. Deleted requests are skipped by updated peers. When a cap is enabled, the synchronization fingerprint cache is also bounded. The transport remains compatible with protocol V2 peers; older peers may time out and retry if an entry is deleted during a transfer.

## Automatic log sharing (1.3.0, experimental)

Sharing is enabled by default. No player-name entry, grouping, or manual sync command is needed. The addon joins the custom channel **HCDeathsSyncV2**, discovers another compatible user after a randomized startup delay, and periodically reconciles saved PvE/PvP logs. This transport targets **the same realm and faction**. Opposite-faction sharing is not implemented. It requires other users running version 1.3.0 or a compatible protocol version, and a server that permits custom-channel traffic. Actual Octo channel behavior must still be tested in game.

- Discovery repeats approximately every 5–6 minutes when idle. A randomized offer delay suppresses redundant peer responses. Synchronization is eventual, not instantaneous.
- Peers compare compact record fingerprints, request unfamiliar versions in small pages, and transfer records in bounded fragments. New deaths and later class/race/guild/last-words enrichment become available during subsequent passes.
- A client sends at most one channel packet every **1.5 seconds**. Large histories can take substantial time. Disconnects or missing packets time out; later passes try again. No complete-history guarantee is made when peers leave before synchronization finishes.
- The matching rule requires the same name (case insensitive), level, death type, realm/faction when known, UTC receipt times within **5 minutes**, and no conflicting known killer name, killer level, or precise location. `Unknown` values do not prevent matching. This is a heuristic: clocks more than five minutes apart may produce duplicates, and otherwise indistinguishable repeat deaths may be ambiguous. Directly received repeat death notices are saved separately. Ambiguous matches are retained separately rather than silently collapsed.
- Imported facts only fill unknown fields; known local values are retained. A direct server notice arriving after an imported record upgrades it to a locally received record. Incoming history does not trigger death sounds, toasts, or `/who` lookups. Log display is sorted by recorded UTC time; unknown timestamps are placed last.
- Tooltips identify imported records and records supplemented by a peer. These are **peer-supplied, unauthenticated data**, not server-certified history. The dedicated channel is not private or encrypted. Shared fields include names, levels, death cause/place, class/race/guild, last words, and receipt timestamps.
- Existing untagged logs are adopted into the realm/faction of the first sync-enabled login. If an old account-wide log already mixed several realms or factions, those original origins cannot be recovered automatically. New records carry explicit realm/faction tags. Records with invalid/missing timestamps or fields exceeding transport limits remain available locally but are not shared.
- Normal chat windows hide this channel's protocol traffic and channel notices. Settings has **Automatically share death logs** and a **Sync status (hover)** indicator. Uncheck it (or use `/hcd sync`) to stop sending/receiving and leave the channel. Reset restores sharing to on. Recording local server notices works independently of sharing.

The protocol uses length-prefixed plain data, strict size/type checks, per-sender limits, bounded queues, and no execution of received Lua. The server's channel limits, moderation, or channel availability can prevent sharing; local death recording continues.

## Gravestone observations (1.3.0)

Opening Octo's **OctoReplayGraveFrame** automatically reads its displayed name, level, race/class and killer/level. This uses the actual frame name and English text format confirmed by the supplied diagnostic log, rather than interpreting undocumented numeric IDs in `OWLDTH` messages. GraveProbe is no longer needed for normal use.

A saved PvE/PvP death is eligible when name matches, a known level agrees, known killer/race/class facts do not conflict, and a known realm matches. A uniquely matched unknown level can be filled from the grave. Whitespace differences are normalized. There must be exactly **one** candidate. No record is created from a grave and no ambiguous record is updated. Because this window contains no death date, two otherwise identical historical deaths cannot be disambiguated. No recent-time limit is applied to grave lookup, so old graves can supplement old logs.

The addon fills unknown race/class/killer facts and stores a separate **observer-position bundle**, leaving the original announced location and death receipt timestamp intact. It retains the first recorded bundle rather than replacing it with later visits. Tooltip lines show the visit zone/subzone, map coordinates as percentages when available, observer, and observation time in UTC. These coordinates are **the player's position while inspecting a grave**, not a measured tombstone position or exact death position.

Detection checks only the named frame approximately every 0.1 seconds. It does not invoke Watch Death, replace frame handlers, or scan all UI frames. Keep the window open briefly before starting the death replay: a replay or immediate movement can change the player's position before observation. If the window is already open during addon loading it may also be observed at that time.

When the currently selected map can be verified as the current zone, its coordinates are read directly. Otherwise, for a world map that is not actually visible, the addon briefly selects the current-zone map and then restores the prior continent/zone selection. Visibility checks include hidden parents used by UI replacements. A visible map of another zone is left alone; raw `UnitPosition` values are saved if available. Raw-only observations are now also displayed in the tooltip, so a missing map coordinate is distinguishable from a missing observation. `(0, 0)` map results are treated as unavailable. Raw coordinates retain the API's returned order without guessing DLL-specific axis meanings. If neither map nor raw coordinates are available, the observation is skipped.

Valid coordinate bundles are automatically shared and merged as one unit, preventing X/Y/map values from different observations being mixed. **Version 1.3.0 uses protocol/channel V2; 1.2.0 peers do not synchronize with it. Both users must update.** Existing saved logs and settings are retained. No chat message or toast is generated for grave observations.

### Troubleshooting grave recording (1.4.2)

Version 1.4.2 fixes the Lua 5.0 `math.huge` error that prevented coordinate capture. Install the complete HCDeaths folder, including `HCDeathsGraves.lua`, and `/reload`. Open a grave window, keep it open, and run:

```text
/hcd grave check
```

This retries the observation and prints the result, parsed identity, count of same-name/matching saved entries, known-field conflicts, and any map/raw API problem. `/hcd grave status` prints the last attempt. Automatic operation remains silent. A grave with no matching saved death does not create an entry; multiple matches are deliberately left unchanged.

Automatic matching now retries for up to 30 seconds rather than stopping after approximately half a second, using the initially captured observer position when available. This covers delayed UI/log availability. Optional client API errors are contained and written as diagnostic messages instead of silently losing the attempt. The latest bounded diagnostic snapshot is saved as `HCDeaths_GraveStatus` in the addon's SavedVariables file after `/reload` or normal logout. It contains grave text/identity, match reasons and position diagnostics, not a full UI dump.

If an older observation has only raw coordinates, map coordinates can be added only when the raw positions demonstrably coincide. Invalid old bundles can be replaced as a unit. An existing valid observation is otherwise retained.

## Last words

Octo's follow-up system notice `Name's last words: "message"` updates that player's latest death received during the current session. The words are stored in `lastWords` and shown in the log tooltip and toast, including a toast already on screen. Queued toasts use the updated record. Without a follow-up notice, the value remains `Unknown`. Ordinary chat is no longer used to guess last words. Unmatched notices and repeated copies do not create death records or modify historical records loaded at login.

## Timestamps

Each log row shows the recorded date and time as `YYYY/MM/DD HH:MM:SS` in **UTC**. Hovering a row also shows the timestamp. These are the original addon's locally recorded UTC receipt times, not authoritative server death times. Existing records with `sdate` and `stime` display their saved timestamps; no dates are invented for missing fields (`----/--/-- --:--:--`). New records retain the same UTC storage format.

## Saved logs and limits

Normal logout or `/reload` writes the saved data to:

```text
WTF/Account/ACCOUNTNAME/SavedVariables/HCDeaths.lua
```

The page browser covers all recorded PvE/PvP deaths. It cannot recover events that were never recorded. The default total record limit is unlimited; the optional cap and cleanup controls above can reduce saved deaths. Available memory, disk space, and saved-variable load/save time still apply.

## Testing and reporting issues

The fork has passed mocked frame/API tests covering startup, default visibility, settings, minimap clicks, more than 100 log entries, pagination, tooltips, reset behavior, and retained visibility. Two- and multi-client transport simulations additionally cover discovery, missing-field merges, timeouts/recovery, packet limits, source tracking, opt-out, and realm isolation. Actual Octo WoW client behavior, channel transport, and visual layout have not yet been verified. Other server environments are unverified as well.

Please report issues to this fork's repository, rather than asking the original author to support these changes. Include client version, the error text, and reproduction steps. Do not attach account data or personal chat logs unnecessarily.

## License

Distributed under the **MIT License**; see [LICENSE](LICENSE). The original copyright notice is retained unchanged:

```text
Copyright (c) 2023 GryllsAddons
```

The fork's changes are also distributed under the MIT License. Keep the original copyright and complete license text when redistributing this addon. The original software is provided without warranty, as stated in LICENSE.
