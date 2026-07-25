# Breakout Game

A modern, browser-based implementation of the classic Breakout arcade game built with vanilla JavaScript and HTML5 Canvas.

## Features

- 🎮 **Smooth Gameplay**: 60 FPS animation with responsive controls
- 🎨 **Modern Visual Design**: Vibrant neon color palette with gradient backgrounds and glow effects
- 🔊 **Dynamic Audio**: Programmatic sound effects using Web Audio API (no external files needed)
- 📈 **Progressive Difficulty**: Ball speed increases as bricks are destroyed
- ⚙️ **Fully Configurable**: All game parameters easily customizable via `config.js`
- 📱 **Responsive Layout**: Centered canvas with clean UI that adapts to different screen sizes

## How to Play

1. **Open the game**: Simply open `index.html` in any modern web browser
2. **Start**: Press **SPACE** to launch the ball
3. **Move paddle**: Use **LEFT** and **RIGHT** arrow keys
4. **Objective**: Destroy all bricks without losing all lives

## Controls

- **← →** Arrow Keys: Move paddle left/right
- **SPACE**: Start game / Restart after game over

## Customization

Edit `config.js` to customize game behavior:

```javascript
// Adjust difficulty
ball: {
    initialSpeed: 4,        // Starting ball speed
    speedIncrement: 0.15,   // Speed increase per brick
    maxSpeed: 10            // Maximum ball speed
}

// Modify brick layout
bricks: {
    rows: 6,
    columns: 10,
    colors: ['#ff006e', '#fb5607', '#ffbe0b', ...] // Custom colors
}

// Change paddle settings
paddle: {
    width: 120,
    speed: 8
}
```

## Project Structure

```
/
├── index.html          # Main HTML entry point
├── styles.css          # Game styling and layout
├── config.js           # All game constants and settings
├── audio.js            # Audio manager for sound effects
├── game.js             # Game engine (Paddle, Ball, Brick, Game classes)
└── README.md           # This file
```

## Technical Details

- **No dependencies**: Pure vanilla JavaScript, no frameworks or libraries
- **No build process**: Works directly in the browser
- **Modular architecture**: Separate concerns (config, audio, game logic, styling)
- **Class-based OOP**: Clean, maintainable code structure

## Browser Compatibility

Works in all modern browsers that support:
- HTML5 Canvas API
- Web Audio API
- ES6 Classes

## License

Feel free to use and modify for your own projects!

## Native iPhone App: Prismabrique

This repository also contains **Prismabrique**, a standalone native SwiftUI iOS 26 app
inspired by this same web game — 50 config-driven levels, touch controls, progression
persistence, accessibility settings, and an optional privacy-respecting location-based
ambient theme. It is a separate Xcode project and does not modify or depend on the web
files above.

See [`Prismabrique/README.md`](Prismabrique/README.md) for details on opening, building,
and testing the iOS app, and [`Prismabrique/PRIVACY.md`](Prismabrique/PRIVACY.md) for its
privacy policy.
