# Backasa Farmer — playable prototype

Godot 4.3+ project. Open `project.godot` and press Play.

## Controls
- WASD / Arrow keys: move
- 1: Hoe (till a plot)
- 2: Seeds (plant)
- 3: Water
- 4: Harvest (when crop is mature)
- E: use selected tool near a garden plot
- F: sleep (only inside the house)
- E at the front door: enter the house; E at the door inside: leave; E at the bed: sleep
- L: save

## Gameplay
A short story intro starts the game. Till soil, plant parsnip seeds, water them, grow them, and harvest for coins. There are 12 garden plots. Crops progress while watered; sleeping advances the day. Save data is stored in Godot's `user://farm_save.json`.

## Reference
The project follows the broad systems from Rapid Vectors' tutorial series: top-down pixel farm, directional player animations, tool selection, crop stages, day progression, inventory, and saving. The original project assets are retained.

## Audio
`Audio/walking.mp3` loops while the player moves, `Audio/dig.mp3` plays when tilling, `Audio/wateringcan.mp3` when watering, `Audio/harvest.mp3` when harvesting. `Audio/nature_ambient.mp3` is the background noise and loops forever. Harvested plots return to untilled dirt.

## Storms, house and sleeping
- The house is solid. Stand below the front door and press E to go in. Inside, press E at the bed (or F) to sleep, or E at the door to leave.
- Sleeping fades to black, starts a new day and shows a banner about what happened overnight. Staying up until midnight makes you collapse into bed.
- Every 10th day (10, 20, 30...) a storm hits in the night, randomly:
  - Rain: all crops are watered overnight and every lemon harvest is doubled that day.
  - Wind: every ripe lemon on the vines is damaged (drawn duller). Damaged lemons are counted separately in the HUD and sell for half price.
- Tweak `DISASTER_INTERVAL`, `LEMON_PRICE` and `CLOCK_SPEED` at the top of `Scripts/farm_game.gd`.
