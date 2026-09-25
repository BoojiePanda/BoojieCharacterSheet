# Changelog

## 0.6.0

- Rebuilt Settings initialization so a failed control cannot leave the panel half-created or cause later refresh errors.
- Restored proper font-dropdown arrows and removed the stray `Aa` from font controls.
- Made the retained three-tab styling permanent, removed only the top tab borders, and fixed tab labels disappearing after reloads and refreshes.
- Added safe first-install defaults based on Silverravyn's configuration while keeping Blizzard's built-in Friz Quadrata as the guaranteed font fallback.
- Added live SharedMedia discovery with safe Blizzard fallbacks when an optional media provider is unavailable.
- Added a clear chat warning when ElvUI or WindTools is also configured to skin the Character Sheet.
- Added an option to use ElvUI's General texture on Reputation progress bars, with Blizzard's texture retained when ElvUI is unavailable.
- Added the new BCS icon, a LibDataBroker and LibDBIcon minimap launcher, WindTools compatibility, and a complete entry under `Settings > AddOns`.
- Matched the Settings window height to the character sheet and added persistent mouse-wheel scaling from 75% to 100% without moving its fixed anchor.
- Added the TOC version to the Settings title and made ElvUI's color-picker Default button restore Boojie defaults correctly.
- Expanded the Accent color setting across the addon's interface chrome while preserving the branded title and icon colors.
- Preserved every existing character's saved configuration while applying the new defaults only to fresh installations.

## 0.5.29

- Reorganized settings into dedicated Character Sheet, Attributes, and Reputation and Currency pages with compact multi-column controls.
- Added independent fonts, sizes, and colors for attribute headings and values, plus heading-size control for Reputation and Currency.
- Added configurable gear names, upgrade levels, gems, enchants, upgrade-track colors, and completed-upgrade hiding.
- Added distinct Adventurer, Veteran, Champion, Hero, and Myth upgrade-track colors and removed the redundant `Upgrade Level:` prefix.
- Added a Transmog shortcut that opens Blizzard's native Transmog window.
- Embedded Titles and Equipment Manager inside the character statistics panel instead of separate fly-out windows.
- Added snapped-only opening and closing animations for the Settings panel.
- Added separate Character, Guild, Gear Name, and Gear Detail typography controls.
- Restored static Speed display and the Movement label, with mount-speed rows appearing when relevant.
- Improved window exclusivity so Settings, Titles, and Equipment Manager close one another correctly.
- Improved persistence for snapped-window and Reputation/Currency collapse states.
- Corrected the max-upgrade option so completed upgrade tracks are hidden reliably.
- Reduced background work and memory churn by removing permanent polling, coalescing refreshes, caching row data, and deleting obsolete compatibility and gear-summary code.

## 0.4.35

- Replaced native red Reputation and Currency collapse controls with dark Boojie buttons using accent-colored borders and plus/minus symbols.
- Measures the three bottom tabs from their configured font and keeps enough padding to display each full label.
- Guards tab widths while the character sheet is visible so Blizzard's asynchronous layout updates cannot randomly shorten them.

## 0.4.34

- Reapplies configured Currency and Reputation row typography immediately after Blizzard's mouse-enter and mouse-leave handlers change it.
- Prevents hovered category headers from remaining yellow until the next reload.

## 0.4.33

- Restyles every visible Reputation and Currency row after Blizzard's virtualized ScrollBox updates.
- Applies configured accent typography to category headers and configured body typography to ordinary entries.
- Keeps fonts and colors consistent after scrolling, expanding, filtering, and reopening either tab.

## 0.4.32

- Compacted the Reputation and Currency filter header from 42 to 34 units.
- Aligned the Currency dropdown and Transfer Log button on the same top row.
- Raised the Reputation and Currency lists and scrollbars ten units to remove the unused gap below the filter header.

## 0.4.31

- Moved the Currency filter dropdown eight units left of the Transfer Log button, with a safe fallback offset when that button is unavailable.
- Left the Reputation filter position unchanged.

## 0.4.30

- Added accent-colored inset dividers between each Settings section with equal 18-unit margins from both content edges.

## 0.4.29

- Reorganized Settings into compact Live Appearance, Equipment Spacing, Typography, and Panel Appearance sections.
- Moved the account-wide font toggle into Typography.
- Removed redundant main-panel Copy, Paste, and Class Color actions already provided by the color picker.
- Reduced the settings canvas height from 915 to 730 units while retaining clear separation between every control.

## 0.4.28

- Registers the expanded 870-by-650 CharacterFrame dimensions with Blizzard's UI panel manager.
- Restores the shared outer geometry synchronously during bottom-tab clicks and subframe changes, before the next rendered frame.
- Retains the delayed layout pass only for child controls Blizzard updates after the transition.

## 0.4.27

- Constrained the actual sidebar icon regions to 22 units inside their 26-unit buttons without altering atlas texture coordinates.
- Prevents icon artwork from extending above the button border and overlapping the header divider.

## 0.4.26

- Restored Blizzard's actual sidebar icon regions after the prior texture normalization exposed tiny atlas artwork.
- Fit the icon group into 26-unit buttons and recentered it between the header divider and statistics border without touching either line.

## 0.4.25

- Normalized all three sidebar icon textures to the same centered 26-unit artwork inside identical 30-unit buttons.
- Removed remaining native selected/active icon chrome that made the Character icon appear larger than Titles and Gear.
- Lowered the centered icon row six units so it clears the header divider cleanly.

## 0.4.24

- Shifted the three PaperDoll sidebar icons 46 UI units left, centering the complete icon group over the 250-unit statistics panel.

## 0.4.23

- Increased the color picker from 61% to 67% scale for another readability improvement.

## 0.4.22

- Increased the reduced color picker from 55% to 61% scale to improve button-label readability.

## 0.4.21

- Reduced the complete color picker by 45% while preserving proportional wheel, swatch, field, and button geometry.

## 0.4.20

- Removed the native Title Manager pane's inset, background, border, and NineSlice chrome from inside Boojie Titles.
- Narrowed Boojie Titles from 460 to 400 UI units.
- Tightened the title list beneath the Boojie header while preserving alternating row backgrounds.

## 0.4.19

- Simplified the identity header to `Name Lvl 90`.
- Raised and height-constrained the guild line and expanded the header band so guild information cannot bleed into the black equipment area.

## 0.4.18

- Added a centered `Guild Name - Rank` line directly beneath the character identity header.
- The guild line uses body typography, refreshes with guild roster changes, and remains hidden for unguilded characters.

## 0.4.17

- Reordered the identity header to `Race : Faction : Name : Lvl : Class : Spec` with consistently spaced colon separators.

## 0.4.16

- Replaced the separate character name and level/class line with one centered `Faction Name Level Race Class Spec` identity header.
- The complete identity header follows the Character name size typography setting.
- Refreshes the identity header when the character's name, level, or specialization changes.

## 0.4.15

- Fixed Character name size targeting the unused frame member instead of Retail's visible `CharacterFrameTitleText` font string.

## 0.4.14

- Added an independent Character name size control to Typography.
- Character-name sizing follows the existing per-character or account-wide typography selection.
- Expanded and reflowed the scrollable Settings canvas to keep the additional control from overlapping lower rows.

## 0.4.13

- Added a per-character `Show live character view` setting.
- Disabling the live view hides both the character model and its zoom, rotate, and reset controls above the model.

## 0.4.12

- Clicking the active Titles or Equipment Manager sidebar icon a second time now closes its side window.
- Clicking any bottom character-sheet tab closes both side windows, preventing an empty Titles or Gear shell from remaining beside Reputation or Currency.

## 0.4.11

- Fixed WoW's independent screen clamping displacing windows whose persisted snap state was active.
- Reapplies saved snap anchors whenever Settings, Titles, or Gear opens, refreshes, or changes through a sidebar tab.
- Restores screen clamping only after a window is explicitly unlocked.

## 0.4.10

- Centered the main-hand and off-hand pair horizontally beneath the live character model without changing its vertical position or internal spacing.

## 0.4.9

- Replaced Blizzard's conflicting color-picker footer with independent Boojie Save and Cancel buttons.
- Reasserts the full picker size after Blizzard's show layout and reconnects the checkerboard background to the alpha gradient.
- Removed the native header artwork that was protruding above the custom picker frame.

## 0.4.8

- Reasserts the Settings snap anchor whenever the window opens or refreshes so its green lock state cannot disagree with its position.
- Separated the Settings reset row from the color-action row and enlarged the scroll canvas accordingly.
- Rebuilt the color-picker geometry around a properly scaled wheel, contained every control inside the frame, and removed native artwork from the skinned Save and Cancel buttons.

## 0.4.7

- Rebuilt the circular picker into a compact Boojie layout with current/original swatches, brightness and alpha controls, Copy, Paste, Class, Default, RGBA values, hex input, and full-width Save/Cancel controls.

## 0.4.6

- Replaced the individual RGB editor with the circular color wheel while retaining opacity and hex controls.
- Skinned the color-wheel frame and renamed its confirmation control to `Save`.
- Closing Settings or the character sheet now always closes the color picker and prevents it from becoming stranded onscreen.

## 0.4.5

- Matched the Settings window height to the character sheet and moved its taller controls into a scrollable canvas.
- Added a skinned scrollbar against the Settings window's inner-right edge.
- Added the same persistent snap control and linked-drag behavior used by the Titles and Gear windows.

## 0.4.4

- Added descriptive locked and unlocked tooltips to the side-window snap controls.

## 0.4.3

- Moved item-quality borders to dedicated high-level overlays so equipped-item textures cannot cover them.
- Added persistent snap controls beside the close buttons on Boojie Titles and Boojie Gear.
- Snapped windows align to and move with the character sheet; their controls illuminate light green while active, and only clicking the control again unlocks them.
- Dragging either the character sheet or its snapped side window moves the pair together.

## 0.4.2

- Narrowed the Titles side window and added centered `Boojie Titles` and `Boojie Gear` headers.
- Permanently suppresses Blizzard's restored rounded equipment borders and icon masks.
- Crops equipped-item textures cleanly and leaves only a one-pixel item-quality border around each icon.

## 0.4.1

- Replaced Blizzard's color picker with a fully skinned, movable live RGBA editor with numeric sliders, `RRGGBBAA` hex input, copy/paste, and class-color controls.
- Forced equipped-item tooltip backgrounds to full opacity and retained configurable tooltip scaling and numeric gear-slot labels.
- Removed remaining native equipment-button chrome and replaced both gear and sidebar borders with uniform one-pixel texture outlines.
- Set the top-right sidebar order explicitly to Character, Titles, then Equipment Manager from left to right.
- Raised Equipment Manager creation and icon-selection dialogs above Boojie settings and side panels.

## 0.4.0

- Added a standalone gear-tooltip skin, adjustable gear-tooltip scale, and the numeric equipment slot at the bottom of equipped-item tooltips.
- Removed native equipment-button chrome in favor of item-quality outline borders.
- Moved and outlined the three PaperDoll sidebar icons with the configured border color and reserved clear space above the statistics panel.
- Added alpha-enabled color picking, persistent color copy/paste, and Use Class Color for the selected swatch.
- Separated Reputation and Currency filter controls into dedicated top header strips and raised dropdown menus above all skin layers.
- Added the `/rl` reload shortcut to Boojie Character Sheet, Boojie Notebook, Boojie Friend Dots, Boojie Clear Chat, and Boojie Collapse Keeper.

## 0.3.0

- Removed the surviving CharacterModelScene/inset outline from the standalone skin.
- Hides the native CharacterStatsPane when custom character statistics are disabled instead of revealing it.
- Made restrained tab styling a real visual toggle between the custom minimal tabs and Blizzard tab textures.
- Expanded fallback font discovery from two to eight fonts, including both installed Bellota faces without requiring LibSharedMedia.
- Raised and repositioned Reputation and Currency filters and their legacy dropdown menus above the skinned header.
- Added independent top and bottom equipment-icon padding controls with no exterior padding before the top pair or after the bottom weapon pair.
- Added independently movable, persistent Titles and Equipment Manager side windows using Blizzard's native panes.
- Extended Reset Window Positions to all four movable windows.

## 0.2.2

- Fixed CharacterFrame returning to Blizzard's narrow panel width when switching Character, Reputation, or Currency tabs.
- Hooks the actual subframe transition and every bottom tab, then reapplies one coalesced shared-canvas layout after the transition completes.
- Separated main-hand and off-hand annotations so their gear details no longer overlap.
- Refreshes active and loot specialization values when specialization data becomes available or changes.

## 0.2.1

- Fixed Blizzard's panel manager resetting only the character-sheet width after the skin layout ran.
- Reapplies the complete layout after Blizzard finishes opening the panel.
- Added independent dragging and saved positions for the character sheet and live settings window.
- Added a Reset Window Positions control.
- Explicitly expands Reputation and Currency frames, scroll boxes, and scrollbars to the skinned canvas.
- Reduced the final sheet height and statistics panel height to eliminate stretched empty space.

## 0.2.0

- Replaced the Blizzard Settings redirect with an attached character-sheet settings panel that stays open for live preview.
- Added a scrollable font picker populated from built-in and LibSharedMedia fonts.
- Added live body, header, and gear-detail font-size controls.
- Added account-wide typography switching, panel opacity, and text, accent, panel, and border color controls.
- Added a complete standalone dark/pink frame skin, custom chrome, inset cleanup, restrained tabs, and quality-colored equipment borders without requiring ElvUI.
- Rebalanced the Chonky-inspired sheet geometry and added power, GCD, active specialization, and loot specialization information.

## 0.1.3

- Fixed the `FontString:SetText(): Font not set` initialization failure shown by the live client.
- Gave all generated equipment and statistics labels safe Blizzard font templates before assigning text.
- Enlarged and reflowed the sheet to match the effective Chonky-style footprint and eliminate the compact overlap seen at high UI scaling.
- Improved initialization errors so future failures report their actual Lua message rather than `nil`.

## 0.1.2

- Fixed CharacterFrame visual modules not starting when Blizzard's character UI loaded before or after Boojie Character Sheet.
- Added explicit character-UI loading and a shared readiness dispatcher.
- Expanded `/bcs debug` to report CharacterFrame and settings-button initialization.

## 0.1.1

- Added a small gear button beside the character-sheet close button to open Boojie Character Sheet settings.
- Expanded the character sheet into a compact Chonky-inspired layout.
- Added rarity-colored item names, equipped item levels, upgrade-track text, enchant names, and missing-enchant warnings beside native equipment slots.
- Reworked the information dock into an integrated Attributes, Secondary, and General statistics column.

## 0.1.0

- Initial Boojie Character Sheet implementation.
- Added additive CharacterFrame styling, item-level labels, gear-status dock, and Settings integration.
- Integrated account-wide Reputation and Currency collapse-state persistence with nested stable keys.
- Added safe Boojie Collapse Keeper database migration and deterministic coexistence behavior.
- Added Pawn, Warband Nexus, Midnight Helper, Class Codex, ElvUI, and SharedMedia compatibility boundaries.
