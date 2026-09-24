# Boojie Character Sheet compatibility

- **Pawn:** Native equipment buttons and their scripts are preserved; Boojie Character Sheet only adds non-interactive label text.
- **Warband Nexus:** Its frames and data are not modified.
- **Midnight Helper:** The built-in dock reports only equipped item level and lowest durability by default, avoiding duplicated extended character information.
- **Class Codex:** Its frame ownership, position, and scripts are untouched.
- **ElvUI / ElvUI WindTools:** Blizzard CharacterFrame objects remain in place. Styling is additive and does not replace native frame update methods.
- **SharedMedia:** Fonts are discovered through LibSharedMedia when it is available. Built-in fonts remain the fallback.
- **Boojie Collapse Keeper:** This is a migration-only coexistence case. When loaded, the legacy addon retains collapse-restoration ownership for that session while Boojie Character Sheet imports valid state and continues its visual features.

The addon uses secure post-hooks and deferred, coalesced restoration. It does not overwrite Blizzard update or row-toggle methods and does not poll permanently.
