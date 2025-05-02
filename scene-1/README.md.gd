# Mangrove 3D Game Project

## Setup Instructions

1. Open the `main_game.tscn` scene in the Godot editor
2. Attach the `main_game.gd` script to the root node of the scene
3. Play the scene to test the basic 3D environment

## Project Structure

- `scenes/`: Contains all game scenes
  - `main_game.tscn`: Main game scene with environment setup
  - `game_world.tscn`: Alternative game world (under development)
  
- `scripts/`: Contains all GDScript files
  - `main_game.gd`: Main game scene controller
  - `player_controller.gd`: Character movement and camera controls
  
## Controls

- WASD: Move the character
- Space: Jump
- Mouse: Look around
- Escape: Toggle mouse capture

## Next Steps for Development

1. Add more detailed environment elements
2. Implement game-specific mechanics
3. Add proper 3D models for characters and objects
4. Develop UI elements
5. Add sound effects and music

## Tips for 3D Development in Godot

- Use CSG nodes for prototyping
- Consider using a GridMap for level design
- Add post-processing effects through the WorldEnvironment
- Use proper lighting to enhance the visual appeal
- Consider implementing Level of Detail (LOD) for optimization
