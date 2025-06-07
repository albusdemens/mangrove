# Project Mangrove

[![Mangrove first half](https://img.youtube.com/vi/rCvSwxU-kUI/maxresdefault.jpg)](https://youtu.be/rCvSwxU-kUI)

Project Mangrove is a 3D collaborative survival game, developed by Alberto Cereser and Volker Hartmann. Game engine: <img src="./assets/Godot_icon.png" alt="Godot 4.4" width="20" height="20"> Godot 4.4 <img src="./assets/Godot_icon.png" alt="Godot 4.4" width="20" height="20">.

The current goal for Project Mangrove is to make a gameplay video. 

## Gameplay video scenes

All footage is in the Google Drive folder. 

- ✅ Scene 1 - note: for these scenes, check the Scene1 branch
  - ✅ Overview zeppelin
  - ✅ Zeppelin crashes against the mountain
- ✅ Scene 2 & 3
  - ✅ Camera movement along the mountain (top to bottom)
  - ✅ View of the mountain top, with 16 characters - no characters, too complex
  - ✅ Show mountain top split in four quadrants
  - ✅ The characters start moving; illustrate movements (far away and 3rd person)
- ⏳ Scene 4
- ⏳ Scene 5
- ⏳ Scene 6
- ⏳ Intro page
- ⏳ Credits

## Notebook folder

In this folder you can find scripts and Jupyter notebooks. 

## Scene-specific notes

### Scene 2 - Mountain slicing 🔪⛰️

A core element of the mountain structure is that it's divided in 4 regions, forming a cross when see from above (scenes 2 and 3). Instead of using shaders, we divide the mountain obj in four parts using two orthogonal planes passing by the highest point of the mountain. Steps:

- In Blender, load and select the mountain obj and then run `mountain_cutting.blend` (script location:  `blender` folder). This will generate 4 obj files
- To make the generated objs compatible with Godot, run `python obj_parsing.py Quadrant_name.obj Output_file.obj` (script location: `notebooks` folder)

### Scene 3 - Gameplay introduction

Scale of the players ⛹️: 0.1

Scale of the gems 💎: 0.5 

Scale of the flowers 🪷: 0.75
