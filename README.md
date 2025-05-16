# GigaBooster

GigaBooster is a World of Warcraft addon that tracks your character's Mythic Keystone, item level, and Mythic+ rating, and stores this information locally for all your characters.

## Features

- **Automatically saves your current Mythic Keystone** (dungeon, level, and item link) whenever it changes.
- **Tracks your average item level** (both total and equipped).
- **Records your Mythic+ rating**.
- **Stores data for all your characters** on the same account and realm.
- **Simple slash command** to view all your characters' keystones.

## How It Works

GigaBooster listens for relevant in-game events (like logging in, getting a new keystone, completing a dungeon, or changing equipment) and updates your character's data automatically. All data is saved in the `GigaBoosterDB` saved variable.

## Usage

### Viewing All Keystones

To see a list of all your characters' current keystones, type in the chat:

```
/gb keys
```
or
```
/gigabooster keys
```

This will print a list of all characters with their current keystone dungeon and level.

### Example Output

```
=== GigaBooster: All Character Keystones ===
MyChar-Realm: The Rookery (10)
AltChar-Realm: Theater of Pain (15)
```

## Installation

1. Download or clone this repository.
2. Place the `GigaBooster` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory.
3. Restart WoW or reload your UI.

## File Overview

- **GigaBooster.lua**: Main addon logic.
- **GigaBooster.toc**: Addon metadata.
- **exampleKeyStoneItemLinks.txt**: Example keystone item links for reference.

## Notes

- The addon uses the `/gb` or `/gigabooster` slash commands.
- Data is stored per character and persists between sessions.
- Only works with Shadowlands and later keystones (item ID: 180653).

## Developer Notes
To populate interface in toc file, use the following command in the WoW console:
```lua
/dump select(4, GetBuildInfo())
```