// Audio Manager using Web Audio API
class AudioManager {
    constructor() {
        // Create audio context
        this.audioContext = null;
        this.initialized = false;
    }

    // Initialize audio context (must be called after user interaction)
    init() {
        if (!this.initialized && (window.AudioContext || window.webkitAudioContext)) {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            this.initialized = true;
        }
    }

    // Play a beep sound with specified frequency and duration
    playBeep(frequency, duration, volume = 0.3) {
        if (!this.initialized) this.init();
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        oscillator.frequency.value = frequency;
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(volume, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + duration);

        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + duration);
    }

    // Paddle hit sound - low pitch beep
    playPaddleHit() {
        this.playBeep(200, 0.1, 0.2);
    }

    // Brick destruction sound - medium pitch beep
    playBrickHit() {
        this.playBeep(440, 0.1, 0.25);
    }

    // Wall hit sound - higher pitch, shorter
    playWallHit() {
        this.playBeep(600, 0.05, 0.15);
    }

    // Game over sound - descending tone
    playGameOver() {
        if (!this.initialized) this.init();
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        const now = this.audioContext.currentTime;
        oscillator.frequency.setValueAtTime(440, now);
        oscillator.frequency.exponentialRampToValueAtTime(220, now + 0.5);
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(0.3, now);
        gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.5);

        oscillator.start(now);
        oscillator.stop(now + 0.5);
    }

    // Win sound - ascending tone
    playWin() {
        if (!this.initialized) this.init();
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        const now = this.audioContext.currentTime;
        oscillator.frequency.setValueAtTime(440, now);
        oscillator.frequency.exponentialRampToValueAtTime(880, now + 0.3);
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(0.3, now);
        gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.3);

        oscillator.start(now);
        oscillator.stop(now + 0.3);
    }

    // Life lost sound - quick descending beep
    playLifeLost() {
        if (!this.initialized) this.init();
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        const now = this.audioContext.currentTime;
        oscillator.frequency.setValueAtTime(800, now);
        oscillator.frequency.exponentialRampToValueAtTime(200, now + 0.2);
        oscillator.type = 'sawtooth';

        gainNode.gain.setValueAtTime(0.2, now);
        gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.2);

        oscillator.start(now);
        oscillator.stop(now + 0.2);
    }
}

// Create global audio manager instance
const audioManager = new AudioManager();
