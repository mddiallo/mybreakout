// Game Configuration
const CONFIG = {
    // Canvas dimensions
    canvas: {
        width: 800,
        height: 600
    },

    // Paddle settings
    paddle: {
        width: 120,
        height: 15,
        speed: 8,
        color: '#00ff88',
        shadowColor: 'rgba(0, 255, 136, 0.5)',
        shadowBlur: 15
    },

    // Ball settings
    ball: {
        radius: 8,
        initialSpeed: 4,
        maxSpeed: 10,
        speedIncrement: 0.15, // Speed increase per brick destroyed
        color: '#00d4ff',
        shadowColor: 'rgba(0, 212, 255, 0.6)',
        shadowBlur: 20
    },

    // Brick settings
    bricks: {
        rows: 6,
        columns: 10,
        width: 70,
        height: 25,
        padding: 5,
        offsetTop: 60,
        offsetLeft: 35,
        colors: [
            '#ff006e', // Pink
            '#fb5607', // Orange
            '#ffbe0b', // Yellow
            '#8338ec', // Purple
            '#3a86ff', // Blue
            '#06ffa5'  // Cyan
        ]
    },

    // Game settings
    game: {
        initialLives: 3,
        pointsPerBrick: 10,
        // Progressive difficulty: ball speed increases as bricks are destroyed
        difficultyProgression: true
    },

    // Color palette
    colors: {
        background: '#1a1a2e',
        text: '#ffffff',
        score: '#00ff88',
        lives: '#ff006e'
    }
};
