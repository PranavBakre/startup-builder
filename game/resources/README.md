# Resources Directory

This directory contains Godot resource files (.tres, .res) used by the game.

## tiles.tres

TileSet resource for the game's tile map. This needs to be configured in the Godot editor:

1. Open `resources/tiles.tres` in Godot
2. The tile textures are already loaded
3. You need to manually configure:
   - Create tile sources for each texture
   - Set tile size to 1024×1024 (to match generated sprites)
   - Define collision shapes for walls and props
   - Assign tile IDs

Or alternatively, in world.tscn:
1. Select the TileMapLayer node
2. Assign `resources/tiles.tres` to the TileSet property
3. Configure tiles in the TileSet editor

The tiles correspond to:
- ID 0: ground.png (walkable pavement)
- ID 1: ground_grass.png (walkable grass)
- ID 2: wall.png (blocking building walls)
- ID 3: tree.png (blocking prop)
- ID 4: bench.png (blocking prop)
