// redis.js — ioredis klientini yaratadi (faqat haqiqiy server uchun;
// testlarda ioredis-mock injeksiya qilinadi).

import Redis from 'ioredis';
import { config } from './config.js';

export function createRedis() {
  const client = new Redis(config.redisUrl, {
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    // Railway private tarmog'i (redis.railway.internal) FAQAT IPv6 beradi,
    // ioredis esa standart bo'yicha IPv4 (family:4) ni sinaydi → ulana olmaydi.
    // family:0 ikkalasini ham sinaydi (mahalliy IPv4 uchun ham xavfsiz).
    family: 0,
    // Ulanish uzilsa qayta urinadi, lekin so'rovni cheksiz osib qo'ymaydi.
    retryStrategy: (times) => Math.min(times * 200, 2000),
  });
  return client;
}
