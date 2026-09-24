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
- Configurable equipment spacing and tooltip size
- Movable character sheet and settings panel
- Optional snapped settings panel with opening and closing animations
- Account-wide or character-specific typography
- Compatibility support for commonly used character-sheet addons

## Installation

1. Download or clone this repository.
2. Place the `BoojieCharacterSheet` folder in your World of Warcraft Retail addon directory:

   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   ```

3. Confirm the final path is:

   ```text
   Interface/AddOns/BoojieCharacterSheet/BoojieCharacterSheet.toc
   ```

4. Restart World of Warcraft or reload the interface.
5. Enable **Boojie Character Sheet** from the AddOns menu on the character-selection screen.

## Usage

Open the character sheet normally or with the addon's minimap button. Open the settings panel with the small gear button beside the character-sheet close button, by right-clicking the minimap button, or with either slash command:

```text
/bcs
/boojiecharactersheet
```

Settings are organized into **Character Sheet**, **Attributes**, and **Reputation and Currency** pages. Use the icons above the statistics panel to switch between Character Stats, Titles, Equipment Manager, and Transmog.

Use `/bcs debug` for a compact diagnostic report. The addon also provides `/rl` as a shortcut for reloading the interface.

## Moving from Boojie Collapse Keeper

To preserve remembered Reputation and Currency header states:

1. Install and enable Boojie Character Sheet.
2. Keep Boojie Collapse Keeper enabled for the first login.
3. Log in normally so Boojie Character Sheet can copy the available legacy database.
4. Reload or log out normally.
5. Disable or remove Boojie Collapse Keeper.

The import copies valid entries and never modifies or deletes `BoojieCollapseKeeperDB`. If preserving old states is unnecessary, Boojie Collapse Keeper can be removed immediately.

## Saved Data

Appearance, layout, and character-specific typography are stored in `BoojieCharacterSheetCharDB`. Account-wide typography, minimap placement, snapping preferences, and remembered Reputation and Currency states are stored in `BoojieCharacterSheetDB`.

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
