#!/usr/bin/env node
/*
 * bin/cli.js — npm orqali o'rnatilganda `aidevix` buyrug'i uchun
 * cross-platform Node.js launcher.
 *
 * Aidevix yadrosi — `bin/ai-selector.sh` (bash skripti). Bu fayl shunchaki
 * bash'ni topib, skriptni o'sha bash bilan ishga tushiradi va argumentlar +
 * stdio + exit-kodni uzatadi. Windows'da bash Git for Windows bilan keladi.
 */
'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SCRIPT = path.join(__dirname, 'ai-selector.sh');

// bash'ni topish: avval PATH, so'ng Windows'dagi odatiy Git joylari.
function findBash() {
  // PATH'da bash bormi? (which/where o'rniga spawnSync bilan tekshiramiz)
  const probe = spawnSync(process.platform === 'win32' ? 'where' : 'which', ['bash'], {
    encoding: 'utf8',
  });
  if (probe.status === 0 && probe.stdout) {
    const first = probe.stdout.split(/\r?\n/).find((l) => l.trim());
    if (first && fs.existsSync(first.trim())) return first.trim();
  }

  if (process.platform === 'win32') {
    const candidates = [
      path.join(process.env['ProgramFiles'] || 'C:\\Program Files', 'Git', 'bin', 'bash.exe'),
      path.join(process.env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)', 'Git', 'bin', 'bash.exe'),
      path.join(process.env['LOCALAPPDATA'] || '', 'Programs', 'Git', 'bin', 'bash.exe'),
    ];
    for (const c of candidates) {
      if (c && fs.existsSync(c)) return c;
    }
    return null;
  }

  // Unix: oxirgi chora.
  for (const c of ['/bin/bash', '/usr/bin/bash', '/usr/local/bin/bash']) {
    if (fs.existsSync(c)) return c;
  }
  return 'bash';
}

function main() {
  const bash = findBash();
  if (!bash) {
    process.stderr.write(
      '[x] bash topilmadi. Aidevix bash talab qiladi.\n' +
        '    Windows: Git for Windows o\'rnating — https://git-scm.com/download/win\n'
    );
    process.exit(127);
  }

  const args = [SCRIPT, ...process.argv.slice(2)];
  const res = spawnSync(bash, args, { stdio: 'inherit' });

  if (res.error) {
    process.stderr.write('[x] Ishga tushirib bo\'lmadi: ' + res.error.message + '\n');
    process.exit(1);
  }
  // Signal bilan to'xtagan bo'lsa ham mantiqiy exit-kod qaytaramiz.
  process.exit(res.status === null ? 1 : res.status);
}

main();
