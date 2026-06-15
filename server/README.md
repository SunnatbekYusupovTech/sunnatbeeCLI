# Aidevix Stats Backend

Aidevix CLI uchun **global foydalanish statistikasi** xizmati. Foydalanuvchilar
qaysi AI CLI agentini o'rnatgani/ishlatganini (faqat **agent nomi + hodisa turi**,
shaxsiy ma'lumotsiz) qabul qiladi, yig'ma sanoqni saqlaydi va reyting qaytaradi.

> ⚠️ **Maxfiylik:** Bu xizmat IP/ID/shaxsiy ma'lumot saqlamaydi — faqat agent
> nomi bo'yicha yig'ma sanoq. Klyent tomonda telemetriya **opt-in** (standart
> o'chiq) bo'lishi tavsiya etiladi.

## Stack
- **Fastify 5** (HTTP), **ioredis** (Redis klient), **@fastify/rate-limit**
- **Redis** sorted-set'lari: `ZINCRBY` (atomik o'sish) + `ZREVRANGE WITHSCORES`
  (DBning o'zidan tayyor reyting)
- Node.js ≥ 20, ESM

## API

| Metod | Yo'l | Tavsif |
|-------|------|--------|
| `GET` | `/health` | Sog'liq tekshiruvi (Railway shuni ishlatadi) → `{"status":"ok"}` |
| `GET` | `/` | Xizmat haqida qisqa ma'lumot |
| `POST` | `/v1/events` | Hodisa qabul qiladi, sanoqni +1 |
| `GET` | `/v1/stats` | Reyting + yig'indilar |

### `POST /v1/events`
```json
{ "agent": "Claude Code", "type": "install" }   // type: "install" | "launch"
```
- `agent`: `^[A-Za-z0-9 ._+-]{1,40}$` ga mos bo'lishi shart (aks holda 400).
- Javob: `202 { "ok": true, "agent": "...", "type": "...", "count": 7 }`

### `GET /v1/stats`
```json
{
  "updated_at": "2026-06-15T10:00:00.000Z",
  "totals": { "install": 1234, "launch": 5678 },
  "install": [ { "agent": "Claude Code", "count": 420 }, ... ],
  "launch":  [ { "agent": "Gemini CLI",  "count": 380 }, ... ]
}
```

## Lokal ishga tushirish
```bash
cd server
cp .env.example .env
docker run -d -p 6379:6379 redis:7-alpine   # Redis
npm install
npm run dev      # http://localhost:3000
npm test         # testlar (ioredis-mock — Redis kerak emas)
```

Sinov:
```bash
curl -XPOST localhost:3000/v1/events -H 'content-type: application/json' \
  -d '{"agent":"Claude Code","type":"install"}'
curl localhost:3000/v1/stats
```

## Railway'ga deploy

1. **Yangi loyiha** → *Deploy from GitHub repo* → `SUNNATBEE/sunnatbeeCLI`.
2. Servis **Settings → Root Directory** = `server` (Dockerfile shu yerda).
3. Loyihaga **Redis** qo'shing: *New → Database → Add Redis*. Railway
   `REDIS_URL` o'zgaruvchisini avtomatik ulaydi.
4. (Ixtiyoriy) **Variables**: `RATE_LIMIT_MAX`, `INGEST_TOKEN`.
5. **Deploy**. Health-check `/health` yashil bo'lgach, **Settings → Networking →
   Generate Domain** bilan ommaviy URL oling (masalan `https://...up.railway.app`).

`railway.json` build/deploy sozlamalarini (Dockerfile + healthcheck) belgilaydi.

## Klyent integratsiyasi (keyingi qadam)

Backend tayyor bo'lgach, `aidevix`ga qo'shiladi (opt-in):
- `report_usage_global` — fonda, `curl -m 2` bilan `POST /v1/events` (jim, bloklamaydi).
- `fetch_global_stats` — `GET /v1/stats`, lokal keshlanadi (auto-update kabi throttle).
- Menyuda global belgi (masalan `🔥 #2 · 9.1k`).

URL `AIDEVIX_STATS_URL` (yoki kodga yozilgan standart) orqali beriladi.
