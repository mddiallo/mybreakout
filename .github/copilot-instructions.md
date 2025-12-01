# Breakout Game - AI Coding Instructions

## Project Overview

This is a browser-based Breakout game built with vanilla JavaScript using the HTML5 Canvas API. The architecture is modular, config-driven, and uses class-based OOP patterns for game entities.

## Architecture

### Core Components

- **`config.js`**: Central configuration file containing all game constants (dimensions, speeds, colors, difficulty settings). Always modify settings here rather than hardcoding values.
- **`audio.js`**: Web Audio API manager for programmatic sound generation. Provides methods like `playPaddleHit()`, `playBrickHit()`, `playGameOver()`, etc.
- **`game.js`**: Main game engine with four classes:
  - `Paddle`: Player-controlled paddle with boundary checking
  - `Ball`: Ball physics with speed progression
  - `Brick`: Individual brick entities with color and visibility state
  - `Game`: Master controller managing game loop, collision detection, state, and UI updates

### Game Loop Pattern

Uses `requestAnimationFrame` for smooth 60 FPS animation:
1. `update()`: Physics and collision logic (only runs when game is active)
2. `draw()`: Renders all entities to canvas (runs every frame)
3. `gameLoop()`: Recursive RAF call

### Collision Detection

- **Wall collisions**: Simple boundary checks with ball radius
- **Paddle collision**: AABB detection with dynamic bounce angle based on hit position (center = straight up, edges = angled)
- **Brick collision**: AABB with side-detection algorithm to determine which face was hit, affecting ball direction

### Difficulty Progression

Ball speed increases by `CONFIG.ball.speedIncrement` per brick destroyed when `CONFIG.game.difficultyProgression` is true. Speed is capped at `CONFIG.ball.maxSpeed`.

## Color Palette

All colors defined in `CONFIG` object:
- Paddle: `#00ff88` (neon green)
- Ball: `#00d4ff` (cyan)
- Bricks: 6-color gradient array (pink, orange, yellow, purple, blue, cyan)
- Background: Dark gradient (`#1a1a2e` to `#16213e`)

UI uses glassmorphism effects (backdrop-filter blur) and neon glow shadows.

## Development Workflow

**Running the game**: Simply open `index.html` in any modern browser. No build process or dependencies required.

**Testing changes**:
1. Edit relevant file (`config.js` for tuning, `game.js` for logic)
2. Refresh browser (hard refresh with Cmd+Shift+R / Ctrl+F5 if needed)
3. Press SPACE to start game

**Audio debugging**: Audio context requires user interaction to initialize. First sound plays after SPACE key pressed.

## Key Conventions

- **No inline scripts**: All JS is external and modular
- **Config-first design**: Never hardcode game values; use `CONFIG` object
- **Class-based entities**: Each game object is a class with `draw()` and `update()` methods
- **Immutable collision logic**: Collision functions modify entity velocity but not position directly during detection
- **Audio lazy init**: `audioManager.init()` called on first user interaction to comply with browser autoplay policies

## Common Tasks

**Adding new brick rows**: Modify `CONFIG.bricks.rows` and optionally add colors to `CONFIG.bricks.colors` array

**Adjusting difficulty**: Change `CONFIG.ball.initialSpeed`, `CONFIG.ball.speedIncrement`, or `CONFIG.ball.maxSpeed`

**Customizing controls**: Edit `initControls()` method in `Game` class (currently uses ArrowLeft/Right + Space)

**New sound effects**: Add method to `AudioManager` class with `playBeep(frequency, duration, volume)` or custom oscillator logic

## File Structure

```
/
├── index.html          # Main entry point with canvas and UI elements
├── styles.css          # Responsive styling with gradient backgrounds
├── config.js           # All game constants and settings
├── audio.js            # Web Audio API sound manager
├── game.js             # Game engine (Paddle, Ball, Brick, Game classes)
├── .gitignore          # Standard web project excludes
└── README.md           # User-facing documentation
```
