// Paddle class
class Paddle {
    constructor(canvas) {
        this.canvas = canvas;
        this.width = CONFIG.paddle.width;
        this.height = CONFIG.paddle.height;
        this.speed = CONFIG.paddle.speed;
        this.x = (canvas.width - this.width) / 2;
        this.y = canvas.height - this.height - 20;
        this.dx = 0;
    }

    draw(ctx) {
        ctx.save();
        ctx.shadowColor = CONFIG.paddle.shadowColor;
        ctx.shadowBlur = CONFIG.paddle.shadowBlur;
        ctx.fillStyle = CONFIG.paddle.color;
        ctx.fillRect(this.x, this.y, this.width, this.height);
        ctx.restore();
    }

    update() {
        this.x += this.dx;
        
        // Boundary checking
        if (this.x < 0) this.x = 0;
        if (this.x + this.width > this.canvas.width) {
            this.x = this.canvas.width - this.width;
        }
    }

    moveLeft() {
        this.dx = -this.speed;
    }

    moveRight() {
        this.dx = this.speed;
    }

    stop() {
        this.dx = 0;
    }
}

// Ball class
class Ball {
    constructor(canvas) {
        this.canvas = canvas;
        this.radius = CONFIG.ball.radius;
        this.speed = CONFIG.ball.initialSpeed;
        this.reset();
    }

    reset() {
        this.x = this.canvas.width / 2;
        this.y = this.canvas.height - 80;
        const angle = Math.PI / 4 + Math.random() * (Math.PI / 2);
        this.dx = this.speed * Math.cos(angle);
        this.dy = -this.speed * Math.sin(angle);
    }

    draw(ctx) {
        ctx.save();
        ctx.shadowColor = CONFIG.ball.shadowColor;
        ctx.shadowBlur = CONFIG.ball.shadowBlur;
        ctx.fillStyle = CONFIG.ball.color;
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
    }

    update() {
        this.x += this.dx;
        this.y += this.dy;
    }

    increaseSpeed() {
        if (CONFIG.game.difficultyProgression) {
            const currentSpeed = Math.sqrt(this.dx * this.dx + this.dy * this.dy);
            if (currentSpeed < CONFIG.ball.maxSpeed) {
                const speedMultiplier = 1 + (CONFIG.ball.speedIncrement / currentSpeed);
                this.dx *= speedMultiplier;
                this.dy *= speedMultiplier;
            }
        }
    }

    reverseX() {
        this.dx = -this.dx;
    }

    reverseY() {
        this.dy = -this.dy;
    }
}

// Brick class
class Brick {
    constructor(x, y, row) {
        this.x = x;
        this.y = y;
        this.width = CONFIG.bricks.width;
        this.height = CONFIG.bricks.height;
        this.color = CONFIG.bricks.colors[row % CONFIG.bricks.colors.length];
        this.visible = true;
    }

    draw(ctx) {
        if (!this.visible) return;
        
        ctx.save();
        ctx.fillStyle = this.color;
        ctx.fillRect(this.x, this.y, this.width, this.height);
        
        // Add highlight effect
        ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
        ctx.fillRect(this.x, this.y, this.width, this.height / 3);
        
        ctx.restore();
    }
}

// Game class
class Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.canvas.width = CONFIG.canvas.width;
        this.canvas.height = CONFIG.canvas.height;
        
        this.paddle = new Paddle(this.canvas);
        this.ball = new Ball(this.canvas);
        this.bricks = [];
        
        this.score = 0;
        this.lives = CONFIG.game.initialLives;
        this.gameStarted = false;
        this.gameOver = false;
        this.gameWon = false;
        
        this.keys = {};
        
        this.initBricks();
        this.initControls();
        this.updateUI();
        this.showMessage('BREAKOUT', 'Press SPACE to start');
        this.gameLoop();
    }

    initBricks() {
        for (let row = 0; row < CONFIG.bricks.rows; row++) {
            for (let col = 0; col < CONFIG.bricks.columns; col++) {
                const x = col * (CONFIG.bricks.width + CONFIG.bricks.padding) + CONFIG.bricks.offsetLeft;
                const y = row * (CONFIG.bricks.height + CONFIG.bricks.padding) + CONFIG.bricks.offsetTop;
                this.bricks.push(new Brick(x, y, row));
            }
        }
    }

    initControls() {
        document.addEventListener('keydown', (e) => {
            this.keys[e.key] = true;
            
            if (e.key === ' ') {
                e.preventDefault();
                if (!this.gameStarted && !this.gameOver && !this.gameWon) {
                    this.startGame();
                } else if (this.gameOver || this.gameWon) {
                    this.restart();
                }
            }
            
            if (e.key === 'ArrowLeft') this.paddle.moveLeft();
            if (e.key === 'ArrowRight') this.paddle.moveRight();
        });

        document.addEventListener('keyup', (e) => {
            this.keys[e.key] = false;
            
            if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
                if (!this.keys['ArrowLeft'] && !this.keys['ArrowRight']) {
                    this.paddle.stop();
                } else if (this.keys['ArrowLeft']) {
                    this.paddle.moveLeft();
                } else if (this.keys['ArrowRight']) {
                    this.paddle.moveRight();
                }
            }
        });
    }

    startGame() {
        this.gameStarted = true;
        this.hideMessage();
        audioManager.init(); // Initialize audio on first user interaction
    }

    restart() {
        this.score = 0;
        this.lives = CONFIG.game.initialLives;
        this.gameStarted = false;
        this.gameOver = false;
        this.gameWon = false;
        
        this.ball = new Ball(this.canvas);
        this.bricks = [];
        this.initBricks();
        this.updateUI();
        this.showMessage('BREAKOUT', 'Press SPACE to start');
    }

    checkCollisions() {
        // Wall collisions
        if (this.ball.x + this.ball.radius > this.canvas.width || this.ball.x - this.ball.radius < 0) {
            this.ball.reverseX();
            audioManager.playWallHit();
        }
        
        if (this.ball.y - this.ball.radius < 0) {
            this.ball.reverseY();
            audioManager.playWallHit();
        }

        // Bottom boundary (life lost)
        if (this.ball.y + this.ball.radius > this.canvas.height) {
            this.lives--;
            this.updateUI();
            audioManager.playLifeLost();
            
            if (this.lives <= 0) {
                this.endGame(false);
            } else {
                this.ball.reset();
                this.gameStarted = false;
                this.showMessage(`${this.lives} ${this.lives === 1 ? 'Life' : 'Lives'} Left`, 'Press SPACE to continue');
            }
            return;
        }

        // Paddle collision
        if (
            this.ball.y + this.ball.radius > this.paddle.y &&
            this.ball.y - this.ball.radius < this.paddle.y + this.paddle.height &&
            this.ball.x > this.paddle.x &&
            this.ball.x < this.paddle.x + this.paddle.width
        ) {
            // Calculate bounce angle based on where ball hits paddle
            const hitPos = (this.ball.x - this.paddle.x) / this.paddle.width;
            const angle = (hitPos - 0.5) * (Math.PI * 0.7); // Max 70% of PI for playability
            const speed = Math.sqrt(this.ball.dx * this.ball.dx + this.ball.dy * this.ball.dy);
            
            this.ball.dx = speed * Math.sin(angle);
            this.ball.dy = -Math.abs(speed * Math.cos(angle));
            this.ball.y = this.paddle.y - this.ball.radius;
            
            audioManager.playPaddleHit();
        }

        // Brick collisions
        for (let brick of this.bricks) {
            if (!brick.visible) continue;

            if (
                this.ball.x + this.ball.radius > brick.x &&
                this.ball.x - this.ball.radius < brick.x + brick.width &&
                this.ball.y + this.ball.radius > brick.y &&
                this.ball.y - this.ball.radius < brick.y + brick.height
            ) {
                brick.visible = false;
                this.score += CONFIG.game.pointsPerBrick;
                this.updateUI();
                this.ball.increaseSpeed();
                audioManager.playBrickHit();

                // Determine which side of brick was hit
                const ballBottom = this.ball.y + this.ball.radius;
                const ballTop = this.ball.y - this.ball.radius;
                const ballRight = this.ball.x + this.ball.radius;
                const ballLeft = this.ball.x - this.ball.radius;

                const brickBottom = brick.y + brick.height;
                const brickRight = brick.x + brick.width;

                const bottomCollision = Math.abs(ballBottom - brick.y);
                const topCollision = Math.abs(ballTop - brickBottom);
                const leftCollision = Math.abs(ballRight - brick.x);
                const rightCollision = Math.abs(ballLeft - brickRight);

                const minCollision = Math.min(bottomCollision, topCollision, leftCollision, rightCollision);

                if (minCollision === leftCollision || minCollision === rightCollision) {
                    this.ball.reverseX();
                } else {
                    this.ball.reverseY();
                }

                // Check win condition
                if (this.bricks.every(b => !b.visible)) {
                    this.endGame(true);
                }

                break; // Only handle one brick collision per frame
            }
        }
    }

    endGame(won) {
        this.gameStarted = false;
        if (won) {
            this.gameWon = true;
            this.showMessage('YOU WIN!', `Final Score: ${this.score} | Press SPACE to play again`);
            audioManager.playWin();
        } else {
            this.gameOver = true;
            this.showMessage('GAME OVER', `Final Score: ${this.score} | Press SPACE to try again`);
            audioManager.playGameOver();
        }
    }

    updateUI() {
        document.getElementById('score').textContent = this.score;
        document.getElementById('lives').textContent = this.lives;
    }

    showMessage(title, subtitle) {
        const messageDiv = document.getElementById('gameMessage');
        document.getElementById('messageText').textContent = title;
        document.getElementById('messageSubtext').textContent = subtitle;
        messageDiv.classList.remove('hidden');
    }

    hideMessage() {
        document.getElementById('gameMessage').classList.add('hidden');
    }

    draw() {
        // Clear canvas
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

        // Draw all game objects
        this.paddle.draw(this.ctx);
        this.ball.draw(this.ctx);
        
        for (let brick of this.bricks) {
            brick.draw(this.ctx);
        }
    }

    update() {
        if (!this.gameStarted || this.gameOver || this.gameWon) return;

        this.paddle.update();
        this.ball.update();
        this.checkCollisions();
    }

    gameLoop() {
        this.update();
        this.draw();
        requestAnimationFrame(() => this.gameLoop());
    }
}

// Initialize game when page loads
window.addEventListener('load', () => {
    new Game();
});
