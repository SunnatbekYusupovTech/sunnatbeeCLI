// app.test.js — backend marshrutlari uchun testlar (node:test + ioredis-mock).
// Haqiqiy Redis kerak emas: ioredis-mock injeksiya qilinadi va app.inject()
// orqali HTTP sathida sinab ko'riladi.

import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import RedisMock from 'ioredis-mock';
import { buildApp } from '../src/app.js';

function makeApp() {
  const redis = new RedisMock();
  const app = buildApp({ redis, rateLimit: false });
  return { app, redis };
}

beforeEach(() => {
  // Har test toza holatdan boshlanishi uchun mock'ni tozalaymiz.
  new RedisMock().flushall();
});

test('GET /health → 200 ok', async () => {
  const { app } = makeApp();
  const res = await app.inject({ method: 'GET', url: '/health' });
  assert.equal(res.statusCode, 200);
  assert.equal(res.json().status, 'ok');
  await app.close();
});

test('POST /v1/events sanoqni oshiradi, GET /v1/stats reyting beradi', async () => {
  const { app } = makeApp();
  await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'Gemini CLI', type: 'install' } });
  await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'Claude Code', type: 'install' } });
  await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'Claude Code', type: 'install' } });

  const res = await app.inject({ method: 'GET', url: '/v1/stats' });
  assert.equal(res.statusCode, 200);
  const body = res.json();
  // Claude Code 2 marta → reyting tepasida.
  assert.equal(body.install[0].agent, 'Claude Code');
  assert.equal(body.install[0].count, 2);
  assert.equal(body.install[1].agent, 'Gemini CLI');
  assert.equal(body.totals.install, 3);
  await app.close();
});

test('POST /v1/events javobida yangi sanoq qaytadi (202)', async () => {
  const { app } = makeApp();
  const res = await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'Aider', type: 'launch' } });
  assert.equal(res.statusCode, 202);
  assert.equal(res.json().count, 1);
  await app.close();
});

test('noto\'g\'ri "type" → 400', async () => {
  const { app } = makeApp();
  const res = await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'X', type: 'hack' } });
  assert.equal(res.statusCode, 400);
  await app.close();
});

test('noto\'g\'ri agent nomi (taqiqlangan belgilar) → 400', async () => {
  const { app } = makeApp();
  const res = await app.inject({ method: 'POST', url: '/v1/events', payload: { agent: 'a|b\tc', type: 'install' } });
  assert.equal(res.statusCode, 400);
  await app.close();
});

test('ortiqcha maydon → 400 (additionalProperties false)', async () => {
  const { app } = makeApp();
  const res = await app.inject({
    method: 'POST',
    url: '/v1/events',
    payload: { agent: 'X', type: 'install', evil: 1 },
  });
  assert.equal(res.statusCode, 400);
  await app.close();
});
