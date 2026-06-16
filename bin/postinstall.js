#!/usr/bin/env node
/*
 * bin/postinstall.js — `npm i -g aidevix` dan keyin ishga tushadi.
 *
 * Ko'p foydalanuvchilar paketni o'rnatgach qanday ishga tushirishni bilmaydi.
 * Shuning uchun qisqa, ikki tilli (uz/en) yo'riqnoma chiqaramiz: `aidevix` deb
 * yozing, so'ng tilni tanlang. Hech qachon xato bilan tugamaydi (npm'ni buzmaydi).
 */
'use strict';

try {
  // Avtomatlashtirilgan/CI muhitlarida jim turamiz (faqat odam ko'rsa foydali).
  if (process.env.CI || process.env.AIDEVIX_NO_POSTINSTALL) process.exit(0);

  const g = (s) => `\x1b[32m${s}\x1b[0m`;   // yashil
  const b = (s) => `\x1b[1m${s}\x1b[0m`;    // qalin
  const d = (s) => `\x1b[90m${s}\x1b[0m`;   // kulrang
  const color = process.stdout.isTTY && !process.env.NO_COLOR;
  const c = color ? { g, b, d } : { g: (s) => s, b: (s) => s, d: (s) => s };

  const line = '────────────────────────────────────────────';
  const out = [
    '',
    c.g(line),
    `  ${c.b('✓ Aidevix o\'rnatildi!  /  Aidevix installed!')}`,
    '',
    `  ${c.b('Ishga tushirish  /  To start:')}   ${c.g('aidevix')}`,
    c.d('  Ilk marta til so\'raladi (English / O\'zbek).'),
    c.d('  On first run you\'ll choose a language (English / Uzbek).'),
    '',
    c.d('  Til o\'zgartirish / change language:  aidevix --lang'),
    c.d('  Yordam / help:                       aidevix --help'),
    c.g(line),
    '',
  ].join('\n');

  process.stdout.write(out);
} catch (_) {
  /* hech qachon o'rnatishni buzmaymiz */
}
process.exit(0);
