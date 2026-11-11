export const C = {
  ink: '#080A12',
  ink2: '#0E1020',
  night: '#0B0E1C',
  indigo: '#5B4FCF',
  indigoGlow: '#8C82F0',
  indigoDeep: '#2A2460',
  coral: '#E8746A',
  coralSoft: '#F6A79F',
  teal: '#2F9E8F',
  tealSoft: '#6FD3C4',
  amber: '#E8A24A',
  paper: '#FAF8F5',
  surface: '#FFFFFF',
  surfaceAlt: '#F2EFEA',
  border: '#E4DFD8',
  text: '#1D1B26',
  text2: '#5E5A6B',
  text3: '#8E8999',
  skinWarm: '#E9C9A8',
};

export const clamp01 = (t: number) => (t < 0 ? 0 : t > 1 ? 1 : t);

export const lerp = (a: number, b: number, t: number) => a + (b - a) * clamp01(t);

export const easeInOut = (t: number) => {
  const x = clamp01(t);
  return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
};

export const easeOut = (t: number) => 1 - Math.pow(1 - clamp01(t), 3);
export const easeIn = (t: number) => Math.pow(clamp01(t), 3);
export const easeOutQuint = (t: number) => 1 - Math.pow(1 - clamp01(t), 5);

/** deterministic pseudo random, stable per frame */
export const rand = (seed: number) => {
  const x = Math.sin(seed * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
};

export const S = {
  W: 1080,
  H: 1920,
};
