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

- Adds a settings GUI covering all 13 existing command operations, plus a help button.
- Adds a draggable minimap launcher: left-click for Settings, right-click for the death log.
- Replaces the latest-50 display with a newest-first log showing **20 entries per page**.
- Makes every saved PvE/PvP death accessible through page buttons or the mouse wheel. No addon-imposed total record cap is added.
- Hides the log on first installation/upgrade and after Reset. Subsequent visibility choices are saved; hidden logs continue recording.
- Validates numeric settings and accepts decimal scales.
- Retains original toast behavior, death parsing, saved-variable names, and bundled media. Reset does not delete deaths.

See [CHANGELOG.md](CHANGELOG.md) for the fork's release notes.

## Requirements and installation

- **Octo WoW / WoW 1.12** is the primary target; addon code uses Lua 5.0-compatible syntax and APIs.
- Other 1.12 servers may work if their announcements and APIs are compatible; compatibility is not guaranteed. The addon does not reject a client simply because Turtle-specific target-frame globals are absent.
- No additional addon libraries are required.
- Extract the **HCDeaths** folder into `Interface/AddOns/`.
- The resulting path must be `Interface/AddOns/HCDeaths/HCDeaths.toc`. If downloaded from GitHub, rename the repository's extracted folder to **HCDeaths** when necessary.
- This fork replaces the original HCDeaths installation; do not load duplicate copies side by side.
- Existing `HCDeaths`, `HCDeaths_Settings`, and `HCDeaths_LastWords` saved variables are reused. Existing deaths are retained.

## GUI and controls

Open Settings using `/hcd`, `/hcdeaths`, `/hcd gui`, or the minimap icon's left-click.

Settings contains the original command operations: system messages, log visibility, toasts, level progress, ring colors, death sounds, level sounds, roar selection, log scale, toast scale, toast duration, movable-toast preview, and Reset.

- Numeric fields: press **Apply** or Enter. Scale range: **0.25–3**. Toast duration: greater than **0** and at most **300 seconds**.
- Minimap icon: left-click Settings; right-click toggle log; drag around the minimap.
- Log: **Newer / Older** buttons or mouse wheel; drag the background/title to move it. Hover a row for death details.
- Toast: Ctrl + Shift + drag to move; Ctrl + Shift + right-click to reset its position. Use the movable-toast preview to position it outside a death notification.
- Reset restores settings and log/toast/minimap positions. It does **not** clear recorded deaths.

## Chat commands

| Command | Action |
| --- | --- |
| `/hcd` or `/hcd gui` | Open/close Settings |
| `/hcd help` | Print command help |
| `/hcd message` | Toggle system death messages |
| `/hcd move` | Show/hide movable-toast preview |
| `/hcd log` | Toggle death log |
| `/hcd log scale number` | Set log scale |
| `/hcd log minlevel number` | Set minimum recorded death level (1–60, default 10) |
| `/hcd toast` | Toggle death toasts |
| `/hcd toast scale number` | Set toast scale |
| `/hcd toast time seconds` | Set toast duration |
| `/hcd progress` | Toggle level-progress toasts |
| `/hcd color` | Toggle toast ring colors |
| `/hcd deathsound` | Toggle death sounds |
| `/hcd levelsound` | Toggle level-progress sounds |
| `/hcd roar` | Toggle death roars instead of the raid alert |
| `/hcd reset` | Reset settings and positions; preserve deaths |

`/hcdeaths` is an alias for `/hcd`.

## Minimum recorded death level

The default minimum level is **10** (inclusive). Change **Minimum recorded level** in Settings and press Apply, or use `/hcd log minlevel 20`. Valid values are whole numbers **1–60**; use **1** to record all normal player death levels.

The threshold is captured when a new death notice arrives and applies when saving that PvE/PvP death. Existing saved logs are not hidden or deleted when the threshold changes. System messages, death toasts, sounds, and level-progress notifications continue following their own settings; this option controls log storage only. Reset restores the minimum to **10**.

## Level-up toasts

The parser supports Octo announcements such as `Rogue Notogii of guild Hell Fire has reached level 20. As they ascend towards immortality, their glory grows! However, so too does the danger they face.` It extracts the player's name and reached level correctly even when a guild name contains spaces. The equivalent format without a guild, and the original Turtle-style announcements, are also supported.

Enable **Death toast popups** and **Level progress toasts** for milestone toasts. **Level-up sounds** controls their sound separately. Player race/class enrichment still uses the original `/who` flow, so a successful player lookup is required. The minimum death-log recording level does not filter milestone toasts.

## Death locations

For current messages such as `Hardcore character Witch (level 32) has fallen to Torn Fin Tidehunter (level 32) in Western Strand`, the announced place is stored in a separate `location` field and shown in the log, tooltip, and toast. The broad `/who` zone remains in `zone` and is shown separately in the tooltip when different. Older entries without a saved location continue showing their zone; historical precise locations cannot be reconstructed from zone-only records.

The current PvE message format above was supplied as a real example. Equivalent natural-cause and PvP formats are supported by parser tests but have not been verified against live messages. Legacy messages remain supported.

## Timestamps

Each log row shows the recorded date and time as `YYYY/MM/DD HH:MM:SS` in **UTC**. Hovering a row also shows the timestamp. These are the original addon's locally recorded UTC receipt times, not authoritative server death times. Existing records with `sdate` and `stime` display their saved timestamps; no dates are invented for missing fields (`----/--/-- --:--:--`). New records retain the same UTC storage format.

## Saved logs and limits

Normal logout or `/reload` writes the saved data to:

```text
WTF/Account/ACCOUNTNAME/SavedVariables/HCDeaths.lua
```

The page browser covers all recorded PvE/PvP deaths. It cannot recover events that were never recorded. There is no fixed total record limit in this fork, but available memory, disk space, and saved-variable load/save time still apply.

## Testing and reporting issues

The fork has passed mocked frame/API tests covering startup, default visibility, settings, minimap clicks, more than 100 log entries, pagination, tooltips, reset behavior, and retained visibility. Actual Octo WoW client behavior and visual layout have not yet been verified. Other server environments are unverified as well.

Please report issues to this fork's repository, rather than asking the original author to support these changes. Include client version, the error text, and reproduction steps. Do not attach account data or personal chat logs unnecessarily.

## License

Distributed under the **MIT License**; see [LICENSE](LICENSE). The original copyright notice is retained unchanged:

```text
Copyright (c) 2023 GryllsAddons
```

The fork's changes are also distributed under the MIT License. Keep the original copyright and complete license text when redistributing this addon. The original software is provided without warranty, as stated in LICENSE.
