// server.js — ishlab chiqarish kirish nuqtasi: redis + app yaratadi, tinglaydi,
// signallarda chiroyli to'xtaydi (Railway SIGTERM yuboradi).

import { buildApp } from './app.js';
import { createRedis } from './redis.js';
import { config } from './config.js';

const redis = createRedis();
const app = buildApp({
  redis,
  rateLimit: true,
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: config.nodeEnv === 'development' ? { target: 'pino-pretty' } : undefined,
  },
});

// Redis hodisalarini ishlaymiz — aks holda ioredis "Unhandled error event" deb
// log'ni to'ldiradi. Xato xabarini throttle qilamiz (qayta-ulanish bo'ronida
// log toshib ketmasligi uchun).
let lastRedisErrorAt = 0;
redis.on('error', (err) => {
  const now = Date.now();
  if (now - lastRedisErrorAt > 10000) {
    lastRedisErrorAt = now;
    app.log.warn({ err: err.message }, 'Redis ulanish xatosi — qayta urinilmoqda');
  }
});
redis.on('ready', () => app.log.info('Redis ulandi'));

async function shutdown(signal) {
  app.log.info({ signal }, 'to\'xtatilmoqda...');
  try {
    await app.close();
    await redis.quit();
  } catch (err) {
    app.log.error(err);
  } finally {
    process.exit(0);
  }
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

app.listen({ port: config.port, host: config.host }).catch((err) => {
  app.log.error(err);
  process.exit(1);
});
