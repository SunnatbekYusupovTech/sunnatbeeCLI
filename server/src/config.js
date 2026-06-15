// config.js — muhit o'zgaruvchilaridan sozlamalarni o'qiydi.
// Railway REDIS_URL va PORT'ni avtomatik beradi.

const toInt = (v, def) => {
  const n = Number.parseInt(v ?? '', 10);
  return Number.isFinite(n) ? n : def;
};

export const config = {
  port: toInt(process.env.PORT, 3000),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',

  // Redis ulanishi (Railway "Redis" plugini REDIS_URL'ni o'zi beradi).
  redisUrl: process.env.REDIS_URL || 'redis://127.0.0.1:6379',

  // Rate-limit: bir IP uchun oynadagi maksimal so'rovlar.
  rateMax: toInt(process.env.RATE_LIMIT_MAX, 60),
  rateWindow: process.env.RATE_LIMIT_WINDOW || '1 minute',

  // So'rov tanasi hajmi (telemetriya juda kichik bo'lishi kerak).
  bodyLimit: toInt(process.env.BODY_LIMIT, 1024),

  // Ixtiyoriy yozish tokeni. Bo'sh bo'lsa — ochiq (faqat rate-limit + validatsiya).
  // OGOHLANTIRISH: ochiq manbali klientda token yashirin qolmaydi — bu faqat
  // yengil to'siq, haqiqiy autentifikatsiya emas.
  ingestToken: process.env.INGEST_TOKEN || '',
};

// Qabul qilinadigan hodisa turlari va agent nomi formati (validatsiya uchun).
export const EVENT_TYPES = ['install', 'launch'];
export const AGENT_NAME_PATTERN = '^[A-Za-z0-9 ._+-]{1,40}$';
