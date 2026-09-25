# Boojie Character Sheet

Boojie Character Sheet is a visual and gear-status enhancement for World of Warcraft Retail's character sheet. It preserves Blizzard's equipment interactions, tooltips, character model, navigation, reputation, and currency data while presenting them in a cleaner, configurable layout.

## Features

- Configurable gear names, item levels, upgrade tracks, gems, and enchants
- Distinct colors for Adventurer, Veteran, Champion, Hero, and Myth upgrade tracks
- Optional hiding of completed upgrade tracks
- Categorized General, Attributes, Secondary, Attack, and Defense statistics
- Reorderable and collapsible statistics sections
- Separate typography and color controls for headings and attribute values
- Embedded Titles and Equipment Manager views
- Shortcut to Blizzard's native Transmog window
- Remembered Reputation and Currency collapse states
- Optional ElvUI General texture for reputation progress bars
- Configurable equipment spacing and tooltip size
- Persistent mouse-wheel scaling from 75% to 100%
- Attached Settings window that matches the character sheet's height and scale
- Fixed character-sheet position beside the minimap
- Customizable interface accent, backgrounds, borders, and text colors
- Account-wide or character-specific typography
- Optional SharedMedia font discovery with safe Blizzard fallbacks
- LibDataBroker minimap button with a visibility setting and WindTools compatibility
- Full configuration entry under `Settings > AddOns`
- Compatibility support for commonly used character-sheet addons

## Important

Boojie Character Sheet works without ElvUI or SharedMedia. Optional font choices depend on enabled addons that register them through LibSharedMedia. If a saved font is unavailable, the addon safely uses a Blizzard fallback.

The character sheet is anchored beside the minimap and cannot be dragged. Scroll the mouse wheel over the character sheet to resize it. The attached Settings window follows the same size automatically. An optional addon, **MoveAny on CurseForge**, can be used to move the character frame window.

## Settings

Open Settings using the gear button on the character sheet, right-clicking the minimap button, typing `/bcs` or `/boojiecharactersheet`, or visiting `Settings > AddOns > Boojie Character Sheet`.

Settings are organized into Character Sheet, Attributes, and Reputation and Currency pages. They include gear details, typography, colors, equipment spacing, minimap visibility, statistics sections, and the optional ElvUI Reputation texture.

Use `/bcs debug` for a compact diagnostic report. The addon also provides `/rl` as a shortcut for reloading the interface.

## Installation

1. Download the zip file and unarchive it.
2. Place the `BoojieCharacterSheet` folder inside:

   `World of Warcraft/_retail_/Interface/AddOns/`

3. Ensure it is properly installed by checking:

   `World of Warcraft/_retail_/Interface/AddOns/BoojieCharacterSheet/BoojieCharacterSheet.toc`

4. Enable Boojie Character Sheet from the AddOns menu on the character-selection screen.
5. Log in or type `/reload`.

## Moving from Boojie Collapse Keeper (now obsolete)

To preserve remembered Reputation and Currency header states:

1. Install and enable Boojie Character Sheet.
2. Keep Boojie Collapse Keeper enabled for the first login.
3. Log in normally so Boojie Character Sheet can copy the available legacy database.
4. Reload or log out normally.
5. Disable or remove Boojie Collapse Keeper.

The import copies valid entries and never modifies or deletes `BoojieCollapseKeeperDB`. If preserving old states is unnecessary, Boojie Collapse Keeper can be removed immediately.

## Saved Data

Appearance and character-specific typography are stored in `BoojieCharacterSheetCharDB`. Account-wide typography, window scale, minimap placement, and remembered Reputation and Currency states are stored in `BoojieCharacterSheetDB`.

All data remains local to your World of Warcraft installation and is not transmitted anywhere.

## Compatibility

- World of Warcraft Retail
- Interface version: `120100`
- Pawn is optional
- Class Codex is optional
- ElvUI and ElvUI WindTools are optional
- SharedMedia_MyMedia is optional
- Warband Nexus frames and data are not modified

## Feedback and Issues

If you find a bug or have an idea for an improvement, open an issue on this repository with a clear description and the steps needed to reproduce the behavior.

## Author

Created by **BoojiePanda (SilverRavyn)**.
