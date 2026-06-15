// app.js — Fastify ilovasini quradi (testlarda app.inject() bilan ishlatiladi).
//
// buildApp({ redis, rateLimit }) — redis injeksiya qilinadi (testda ioredis-mock),
// rateLimit=false bo'lsa rate-limit o'chiriladi (testlarda tez inject uchun).

import Fastify from 'fastify';
import rateLimit from '@fastify/rate-limit';
import { config, EVENT_TYPES, AGENT_NAME_PATTERN } from './config.js';
import { recordEvent, getStats } from './stats.js';

export function buildApp({ redis, rateLimit: enableRateLimit = true, logger = false } = {}) {
  if (!redis) throw new Error('buildApp: redis klienti majburiy');

  const app = Fastify({
    logger,
    bodyLimit: config.bodyLimit,
    trustProxy: true, // Railway proxy ortida — to'g'ri IP rate-limit uchun.
    // additionalProperties:false sxemasi ortiqcha maydonni jim o'chirmasin,
    // balki RAD ETSIN (qat'iy validatsiya).
    ajv: { customOptions: { removeAdditional: false } },
  });

  app.decorate('redis', redis);

  // --- Rate-limit (spamni cheklash) ---------------------------------------
  if (enableRateLimit) {
    app.register(rateLimit, {
      max: config.rateMax,
      timeWindow: config.rateWindow,
      redis, // bir nechta instansiyada ham izchil ishlashi uchun.
    });
  }

  // --- Ixtiyoriy yozish tokeni (yengil to'siq) ----------------------------
  // INGEST_TOKEN o'rnatilgan bo'lsa, POST /v1/events uchun x-aidevix-token
  // sarlavhasi mos kelishi kerak.
  app.addHook('onRequest', async (req, reply) => {
    if (req.method !== 'POST' || !config.ingestToken) return;
    if (req.headers['x-aidevix-token'] !== config.ingestToken) {
      reply.code(401).send({ error: 'unauthorized' });
    }
  });

  // --- Health-check (Railway shu yo'lni tekshiradi) -----------------------
  app.get('/health', async () => ({ status: 'ok' }));

  app.get('/', async () => ({
    service: 'aidevix-stats',
    endpoints: ['POST /v1/events', 'GET /v1/stats', 'GET /health'],
  }));

  // --- Hodisa qabul qilish: sanoqni +1 ------------------------------------
  app.post(
    '/v1/events',
    {
      schema: {
        body: {
          type: 'object',
          required: ['agent', 'type'],
          additionalProperties: false,
          properties: {
            agent: { type: 'string', pattern: AGENT_NAME_PATTERN },
            type: { type: 'string', enum: EVENT_TYPES },
          },
        },
      },
    },
    async (req, reply) => {
      const { agent, type } = req.body;
      const count = await recordEvent(app.redis, agent, type);
      reply.code(202).send({ ok: true, agent, type, count: Number(count) });
    }
  );

  // --- Statistika: reyting + yig'indilar ----------------------------------
  app.get('/v1/stats', async (req, reply) => {
    const stats = await getStats(app.redis, EVENT_TYPES);
    // Klyent baribir lokal keshlaydi; qisqa CDN/proxy keshiga ruxsat beramiz.
    reply.header('cache-control', 'public, max-age=60');
    return stats;
  });

  // --- Toza xato javobi (stack oshkor qilinmaydi) -------------------------
  app.setErrorHandler((err, req, reply) => {
    const status = err.statusCode && err.statusCode >= 400 ? err.statusCode : 500;
    if (status >= 500) req.log.error(err);
    reply.code(status).send({ error: status >= 500 ? 'internal_error' : err.message });
  });

  return app;
}
