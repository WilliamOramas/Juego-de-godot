import { existsSync, mkdirSync, writeFileSync } from 'fs';

const sampleRate = 44100;
const duration = 0.12; // 120ms (a bit shorter)
const numSamples = Math.floor(sampleRate * duration);

const buffer = Buffer.alloc(44 + numSamples * 2);

buffer.write('RIFF', 0);
buffer.writeUInt32LE(36 + numSamples * 2, 4);
buffer.write('WAVE', 8);
buffer.write('fmt ', 12);
buffer.writeUInt32LE(16, 16);
buffer.writeUInt16LE(1, 20);
buffer.writeUInt16LE(1, 22);
buffer.writeUInt32LE(sampleRate, 24);
buffer.writeUInt32LE(sampleRate * 2, 28);
buffer.writeUInt16LE(2, 32);
buffer.writeUInt16LE(16, 34);
buffer.write('data', 36);
buffer.writeUInt32LE(numSamples * 2, 40);

let prevNoise = 0;
for (let i = 0; i < numSamples; i++) {
    const t = i / sampleRate;

    // Softer envelope: slightly slower attack (10ms) to avoid click, fast decay
    const envelope = t < 0.01 ? (t / 0.01) : Math.exp(-(t - 0.01) * 35);

    // Very low-pass filtered noise (subtle shoe scuff)
    const noise = (Math.random() * 2 - 1);
    const filteredNoise = prevNoise + 0.05 * (noise - prevNoise); // Heavy lowpass
    prevNoise = filteredNoise;

    // Low frequency thump (sine wave sweeping down slightly, e.g., from 90Hz to 50Hz)
    const freq = 90 - (40 * t / duration);
    const thump = Math.sin(2 * Math.PI * freq * t);

    // Mix them together: soft thump + subtle noise
    let sample = (thump * 0.4 + filteredNoise * 0.2) * envelope;

    let intSample = Math.floor(sample * 32767);
    if (intSample > 32767) intSample = 32767;
    if (intSample < -32768) intSample = -32768;

    buffer.writeInt16LE(intSample, 44 + i * 2);
}

const dir = './src/assets/sounds';
if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
}

writeFileSync(`${dir}/step.wav`, buffer);
console.log('step.wav created');
