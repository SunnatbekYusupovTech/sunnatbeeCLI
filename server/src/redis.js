// redis.js — ioredis klientini yaratadi (faqat haqiqiy server uchun;
// testlarda ioredis-mock injeksiya qilinadi).

import Redis from 'ioredis';
import { config } from './config.js';

export function createRedis() {
  const client = new Redis(config.redisUrl, {
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    // Ulanish uzilsa qayta urinadi, lekin so'rovni cheksiz osib qo'ymaydi.
    retryStrategy: (times) => Math.min(times * 200, 2000),
  });
  return client;
}
