// stats.js — statistika ma'lumot qatlami (Redis sorted-set'lar ustida).
//
// Har hodisa turi uchun bitta sorted set: a'zo = agent nomi, ball = sanoq.
// ZINCRBY — atomik o'sish; ZREVRANGE WITHSCORES — tayyor reyting (kamayish).
// Shu tufayli "eng ko'p o'rnatilgan/ishlatilgan" reytingi DBning o'zidan keladi.

const KEY_PREFIX = 'aidevix';
const keyFor = (type) => `${KEY_PREFIX}:${type}`;

// recordEvent — agentning berilgan tur bo'yicha sanog'ini +1 qiladi.
export async function recordEvent(redis, agent, type) {
  return redis.zincrby(keyFor(type), 1, agent);
}

// rankedList — sorted set'ni [{agent, count}, ...] kamayish tartibida qaytaradi.
async function rankedList(redis, type) {
  const flat = await redis.zrevrange(keyFor(type), 0, -1, 'WITHSCORES');
  const out = [];
  for (let i = 0; i < flat.length; i += 2) {
    out.push({ agent: flat[i], count: Number.parseInt(flat[i + 1], 10) || 0 });
  }
  return out;
}

// getStats — barcha turlar bo'yicha reyting + umumiy yig'indilarni qaytaradi.
export async function getStats(redis, types) {
  const result = { updated_at: new Date().toISOString(), totals: {} };
  for (const type of types) {
    const list = await rankedList(redis, type);
    result[type] = list;
    result.totals[type] = list.reduce((sum, x) => sum + x.count, 0);
  }
  return result;
}
