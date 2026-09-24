# Boojie Character Sheet

Boojie Character Sheet is a lightweight visual and gear-status enhancement for Blizzard's Retail character sheet. It skins the existing interface, adds configurable gear details and categorized character statistics, and remembers Reputation and Currency header expansion states. Blizzard remains authoritative for character data, equipment interactions, tooltips, model behavior, navigation, reputation, and currency.

Open the settings panel with the small gear button beside the character-sheet close button, `/bcs`, or `/boojiecharactersheet`. Character Sheet, Attributes, and Reputation and Currency settings each have their own page. The panel includes independent typography controls, gear-detail visibility, spacing, tooltip scale, colors, opacity, and section controls. When settings snapping is enabled, the panel slides from the character sheet; otherwise it remains freely movable. Use `/bcs debug` for a compact diagnostic report, or `/rl` to reload the interface.

The character tab uses a compact presentation with rarity-colored item names, item levels and optionally color-coded upgrade tracks, gem and enchant details, missing-enhancement warnings, and categorized character statistics. Titles and Equipment Manager replace the statistics view when selected, while the Transmog button opens Blizzard's own Transmog window. Gear details remain overlays around Blizzard's native equipment buttons, so normal clicks, drag-and-drop behavior, and tooltips remain Blizzard-owned.

## Moving from Boojie Collapse Keeper

To preserve remembered header states:

1. Install and enable Boojie Character Sheet.
2. Keep Boojie Collapse Keeper enabled for the first login.
3. Log in normally so Boojie Character Sheet can copy the available legacy database.
4. Reload or log out normally.
5. Disable or remove Boojie Collapse Keeper.

The legacy database is only available for import while its addon is enabled and loaded. The import copies valid entries and never modifies or deletes `BoojieCollapseKeeperDB`. If old states do not matter, Boojie Collapse Keeper can be removed immediately.

## Settings ownership

Appearance and character-specific typography are stored per character. The account database stores the optional shared typography profile, collapse states, and migration markers. Enabling account-wide typography does not overwrite character values.
