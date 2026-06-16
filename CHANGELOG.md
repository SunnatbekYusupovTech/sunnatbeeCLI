# O'zgarishlar tarixi (Changelog)

Barcha muhim o'zgarishlar shu faylda hujjatlanadi.

Format [Keep a Changelog](https://keepachangelog.com/uz/1.1.0/) asosida,
loyiha [Semantik versiyalash](https://semver.org/lang/uz/) (SemVer)ga amal qiladi.

## [Nashr qilinmagan]

## [1.4.0] — 2026-06-16

### Qo'shildi
- **🌐 Ilk ishga tushishda til tanlash** — `aidevix` birinchi marta ishga tushganda
  ikki tilda "English / Oʻzbekcha" so'raydi; tanlov saqlanadi (`~/.local/state/ai-cli/lang`)
  va keyingi safar so'ralmaydi. `aidevix --lang [en|uz]` bilan istalgan vaqtda
  o'zgartirish/qayta tanlash mumkin. `choose_language`, `lang_cmd`, `load_saved_lang`,
  `aidevix_set_lang`.
- **🈯 To'liq bir tilli interfeys** — agent **izohlari (desc)** va **login izohlari
  (auth)** ham tanlangan tilga tarjima qilinadi (`parse_agents`'da `t()`), shu tufayli
  menyu/preview/`--list` endi aralash emas, to'liq inglizcha yoki o'zbekcha chiqadi.
  EN katalogga 28 agent izohi + 23 auth qatori qo'shildi.
- **⏳ Ishga tushirish loaderi** — menyu tayyorlanayotganda (agentlar tekshiruvi +
  menyu qurish) fonda aylanuvchi yuklash ko'rsatkichi chiqadi, terminal "muzlab
  qolgandek" tuyulmaydi. `ui_spin_start`/`ui_spin_stop` (`lib/common.sh`).
- **ℹ️ "Aidevix nima — va nima EMAS" tanishtiruvi** — ilk ishga tushishda BIR MARTA:
  Aidevix faqat launcher (uchinchi-tomon CLI'larni o'rnatib/ochib beradi), savollarga
  javob bermaydi va token/kalit bermaydi; ba'zi CLI'lar pullik, ba'zilari bepul.
  `--help` va README'da ham aniq eslatma.
- **📦 npm `postinstall` yo'riqnomasi** — `npm i -g aidevix` dan keyin ikki tilli
  qisqa xabar chiqadi: "ishga tushirish uchun `aidevix` deb yozing" (`bin/postinstall.js`).

### Tuzatildi
- **Windows fzf fork xatosi** — fzf preview har siljishda `bash` qism-jarayonini
  ochib, Git Bash/MSYS'da `cygheap`/`child_copy` (Win32 error 299) xatolarini
  keltirardi. Endi Windows'da preview standart **o'chiq** (`AIDEVIX_FZF_PREVIEW=1`
  bilan yoqiladi); menyu toza ko'rinadi.

## [1.3.0] — 2026-06-16

### Qo'shildi
- **🌐 Ko'p tillilik (i18n) — inglizcha interfeys** — endi Aidevix o'zbekcha
  (standart) va inglizcha ishlaydi. Til `LANG`/locale'dan avtomatik aniqlanadi
  (`en*`/boshqa → en; `uz*`/`C`/bo'sh → uz) yoki `AIDEVIX_LANG=en|uz` bilan
  majburlanadi. Yengil gettext qatlami: `lib/i18n.sh` (`aidevix_detect_lang`,
  `t()`) + `lib/i18n/en.sh` katalog (o'zbekcha manba = kalit; tarjima topilmasa
  o'zbekchaga qaytadi — hech narsa buzilmaydi). Butun CLI interfeysi (yordam,
  menyu, doctor, stats, o'rnatish/xato xabarlari, auth eslatmalari) tarjima
  qilingan. Testlar: `tests/i18n.bats` (15). Agent izohlari (`agents.conf`)
  hozircha o'zbekcha.

## [1.2.0] — 2026-06-15

### Qo'shildi
<!-- ── 2026-06-15 sessiyasi ─────────────────────────────────────────── -->
- **🎬 3D ishga tushirish loaderi** — agent ishga tushirilishidan oldin "AD"
  monogrammasi gradient "sweep" (yorug'lik harakati, 3D his) va to'lib boruvchi
  bar bilan animatsiya qiladi (`loader_3d`). TTY yo'q / `CI` / `NO_COLOR` /
  `AI_NO_ANIM` da — oddiy bir qatorli matn. O'rnatish allaqachon `spin_run` bilan
  animatsiyali edi.
- **📊 Lokal ishlatish statistikasi** — har agent necha marta ishga tushirilgani
  `~/.local/state/ai-cli/usage` da saqlanadi (`record_usage`/`read_usage`). Menyu
  va `--list` eng ko'p ishlatilgan bo'yicha tartiblanadi; har agent yonida `· N×`.
  `--list` ga "MARTA" ustuni. Faqat shu kompyuterda — hech qayoqqa yuborilmaydi.
  Testlar: `tests/usage.bats` (7).
- **🌍 Global statistika (OPT-IN, standart o'CHIQ)** — `aidevix --stats [on|off]`.
  Yoqilganda menyuda `🔥 #reyting · son` ko'rinadi va agent ishga tushganda FAQAT
  agent nomi + hodisa turi (`install`/`launch`) serverga yuboriladi (IP/ID/kalit
  YO'Q). `report_usage_global` (fonda, jim, bloklamaydi), `fetch_global_stats`
  (keshli, throttled), `global_install_tsv`, `maybe_global_hint`, `doctor`da holat.
  Testlar: `tests/global_stats.bats` (9). Klyent↔server e2e jonli tasdiqlandi.
- **🛰️ Global statistika backend (`server/`)** — Fastify 5 + ioredis +
  `@fastify/rate-limit`; Redis sorted-set (`ZINCRBY`/`ZREVRANGE`) bilan atomik
  sanoq va reyting. Endpoint'lar: `POST /v1/events`, `GET /v1/stats`, `GET /health`.
  Dockerfile (non-root, healthcheck) + `railway.json`. Railway'ga deploy qilingan
  (`https://sunnatbeecli-production.up.railway.app`). CI: `.github/workflows/server-ci.yml`.
  Testlar: `node --test` (6, ioredis-mock).
- **🤖 5 yangi agent** — Freebuff, Codebuff, gptme, Shell GPT (sgpt), Mods
  (jami 23 → 28). `--top` ro'yxatiga Codebuff va Freebuff qo'shildi.
- **⌨️ `--stats` completion** (bash/zsh/fish) + man sahifa yozuvi + `SECURITY.md`
  da OPT-IN telemetriya bo'limi (nima yuboriladi/yuborilmaydi).
- **📦 npm yangilanish eslatmasi (notify)** — `npm install -g aidevix` bilan
  o'rnatilganlarda (`.git` yo'q) git auto-update ishlamaydi. Endi `aidevix` npm
  registry'dan eng so'nggi versiyani fonda tekshiradi va yangisi chiqsa
  `npm update -g aidevix` ni har versiya uchun BIR MARTA eslatadi
  (`is_npm_install`, `version_gt`, `fetch_npm_latest`, `maybe_npm_update_hint`).
  Throttled, `AIDEVIX_NO_AUTOUPDATE`/`CI` hurmat qilinadi. Testlar:
  `tests/npm_update.bats` (13).
<!-- ── oldingi sessiyalar ───────────────────────────────────────────── -->
- **🧪 Test to'plami (Bats)** — `tests/` ostida 38 ta avtomatlashtirilgan test:
  config parsing (`parse_agents`, `build_rows`, `trim`, `detect_install_tool`),
  CLI xulq-atvori (`--version`/`--help`/`--list`, noto'g'ri argumentlar,
  `quick_launch` resolutsiyasi) va `lib/common.sh` yordamchilari. CI har push/PR'da
  ishga tushiradi. Lokal: `bats tests/` yoki `make check`.
- **`Makefile`** — `make test` / `lint` / `syntax` / `check` qulayliklari.
- **`SECURITY.md`** — xavfsizlik siyosati, ishonch chegaralari (uchinchi-tomon
  o'rnatuvchilar, `curl | bash`, auto-update) va zaiflik xabari yo'riqnomasi.
- **`CLAUDE.md`** — loyiha xaritasi (fayl/funksiya/konventsiya) — AI yordamchilari
  kodni qaytadan o'qimasdan kontekstni tez tiklashi uchun.
- **🌍 Inglizcha hujjat (`README.en.md`)** + ikkala README tepasida til
  almashtirgich (🇺🇿 / 🇬🇧) — xalqaro auditoriya uchun.
- **📦 Paket menejer manifestlari** — npm (`package.json` + `bin/cli.js`
  cross-platform Node launcher), Homebrew formula (`packaging/homebrew/aidevix.rb`),
  Scoop manifest (`packaging/scoop/aidevix.json`). Endi `npm i -g aidevix`,
  `brew install ...`, `scoop install aidevix` mumkin.
- **⌨️ zsh + fish completion** — `completions/_aidevix` (zsh native) va
  `completions/aidevix.fish`; `completions/README.md` qo'llanmasi.
- **🖥️ man sahifa** — `man/aidevix.1` (`man aidevix`).
- **🧹 Repo gigiyenasi** — `.editorconfig`, `.github/dependabot.yml`
  (Actions versiyalari), `.github/CODEOWNERS`.
- **🎬 Demo** — `assets/demo.svg` (README posteri) + `scripts/demo.sh`
  (deterministik, non-interaktiv demo) va `scripts/record-demo.sh`
  (asciinema → agg → `assets/demo.gif`).
- **Qo'shimcha README badge'lari** — platform, PRs welcome, Conventional Commits,
  GitHub stars (UZ va EN).

### O'zgardi
<!-- ── 2026-06-15 sessiyasi ─────────────────────────────────────────── -->
- **Menyu tartibi** — "oxirgi tanlov tepada" o'rniga "**eng ko'p ishlatilgan
  tepada**" (lokal statistika bo'yicha; teng bo'lsa config tartibi saqlanadi).
- README'da agent soni **23 → 28**; "oxirgi tanlovni eslaydi" xususiyat qatori
  "**lokal statistika**" bilan almashtirildi (uz/en).
- `usage()` config formati hujjati 8-maydonli (`...|AUTH|URL`) qilib to'g'rilandi.
<!-- ── oldingi sessiyalar ───────────────────────────────────────────── -->
- `bin/ai-selector.sh` oxiriga `source`-qorovuli qo'shildi (`BASH_SOURCE` ==
  `$0`) — endi skriptni testda `source` qilganda `main()` ishga tushmaydi;
  xulq-atvor o'zgarmaydi.

### Tuzatildi
<!-- ── 2026-06-15 sessiyasi ─────────────────────────────────────────── -->
- **Tab-completion** endi repo config'dan ham agent nomlarini taklif qiladi.
  Ilgari faqat (o'rnatuvchi bo'sh yaratadigan) foydalanuvchi config'ni o'qib,
  `aidevix <TAB>` hech qanday agent ko'rsatmasdi. Testlar: `tests/completion.bats` (5).
- **server:** Railway private Redis FAQAT IPv6 (AAAA) bergani uchun ioredis
  standart `family:4` bilan ulana olmasdi → `family:0` (dual-stack) qo'shildi.
- **server:** redis `error` hodisasi ishlovchisi qo'shildi (ilgari ulanish
  bo'roni `[ioredis] Unhandled error event` log'ni to'ldirardi) — endi throttled.
- `--stats` status matnidagi kirill harf xatosi (`yoqilганда` → `yoqilganda`).

## [1.1.0] — 2026-06-14

### Qo'shildi
- **🔄 Avtomatik yangilanish** — `main`ga push qilingan o'zgarishlar
  foydalanuvchilarga avtomatik yetadi: `aidevix` ishga tushganda (throttled,
  3 soat) remote'ni tekshiradi, yangi commit bo'lsa jim yuklab oladi, "nima
  yangilangani"ni ko'rsatadi va yangi versiyani qayta ishga tushiradi. Lokal
  o'zgarishlar bo'lsa clobbering qilinmaydi. O'chirish: `AIDEVIX_NO_AUTOUPDATE=1`.
- **Konfiguratsiya birlashtirildi** — agentlar repo'dan (`config/agents.conf`)
  o'qiladi (doimo yangi), foydalanuvchi configi faqat o'zi qo'shgan agentlarni
  saqlaydi. Shu tufayli yangi agentlar/tuzatishlar mavjud foydalanuvchilarga ham
  darrov ko'rinadi (avval foydalanuvchi nusxasi eski qolib ketardi).
- **8 ta yangi agent** (jami 23 ta): Open Interpreter, OpenHands, SWE-agent,
  Cline CLI, Kilo CLI, Grok Build, Antigravity, GitHub CLI.
  Ochiq manbali / bepullar `🆓 bepul` statusi bilan belgilandi va
  `aidevix --free`da chiqadi (endi 11+ bepul agent).

### Tuzatildi
- **Windows curl/git `CRYPT_E_NO_REVOCATION_CHECK` (schannel)** — ichki yuklab
  olishlar `curl --ssl-no-revoke`, git esa `-c http.schannelCheckRevoke=false`
  bilan ishlaydi. Boshlang'ich buyruq uchun README/TROUBLESHOOTING'da yechim.

### Tuzatildi (paket nomlari rasmiy manbalardan tekshirildi)
- Cline CLI: `cline-cli` → **`cline`** (npm).
- Kilo CLI: `kilo-cli` → **`@kilocode/cli`** (npm).
- SWE-agent: `swe-agent` → **`sweagent`** (PyPI).
- Grok Build: `npm grok-build` → rasmiy **xAI installer** (`x.ai/cli/install.sh`,
  buyruq `grok`, SuperGrok/X Premium obunasi).
- Roo Code CLI **olib tashlandi** — rasmiy terminal CLI'si yo'q (faqat VS Code
  kengaytmasi).

### O'zgartirildi
- **CLI o'rnatish animatsiyasi yangilandi** — endi o'rnatish davomida chiroyli,
  gradientli "komet" progress-bar (chap-o'ngга sakraydigan, izli) + spinner va
  o'tgan vaqt ko'rinadi; tugagach to'liq yashil/qizil bar.

## [1.0.0] — 2026-06-14

Birinchi barqaror (production) nashr. 🎉

### Qo'shildi
- **Saralangan 15 ta top AI CLI agenti** — Claude Code, OpenAI Codex, Gemini CLI,
  GitHub Copilot, OpenCode, Crush, Qwen Code, Continue, Cursor Agent, Plandex,
  Aider, Goose, Ollama, llm, AIChat — barchasi `@latest` versiya bilan.
- **Login/auth belgisi** — har bir agent uchun qaysi login yoki API kalit
  kerakligi (🔑/🌐/💳/🆓) menyu preview'sida, `--list`da va menyu qatorida.
- **Login havolasi** — har agentга login/kalit sahifasi linki. Brauzer **faqat
  zarur bo'lganda** ochiladi: agent o'zingiz API kalit (🔑) olishingizni talab
  qilsa va kalit hali muhitda yo'q bo'lsa. Brauzer-login (🌐), obuna (💳), bepul
  (🆓) yoki kalit allaqachon bor bo'lsa — brauzer ochilmaydi, faqat qisqa
  eslatma. (Bir martalik; kalitlar saqlanmaydi.)
- **`aidevix --free`** — faqat bepul agentlar menyusi (Gemini, Qwen, Ollama,
  Continue). **`aidevix --top`** — faqat eng mashhur agentlar.
- **`aidevix --version`** — versiyani ko'rsatadi (`VERSION` faylidan o'qiladi).
- **O'rnatishdan keyin katta, aniq yo'riqnoma** — `source ~/.bashrc && aidevix`
  bilan o'sha oynaning o'zida ishlatish yoki Git Bash'ni qayta ochish.
- **fzf avtomatik o'rnatish** — o'rnatishda fzf GitHub releases'dan yuklab
  olinadi (sudo kerak emas), bo'lmasa paket-menejer.
- **AD logosi + animatsiyali banner** — "Aidevix CLI" brendi.
- **CI (ShellCheck), CHANGELOG, CONTRIBUTING, issue/PR shablonlari va
  release avtomatlashtirish** — open-source standartlari.

### O'zgartirildi
- Buyruq nomi `ai` → **`aidevix`**.
- Brend `AI CLI Pult` → **Aidevix CLI**.

### Tuzatildi
- **Windows/Git Bash'da npm CLI'lar ishga tushmasligi** — PATH'ga Windows-shakl
  (`C:\Users\...`) yo'l tushib, `:` ajratgich uni buzardi va "Cannot find module
  C:\Program Files\Git\Users\..." xatosini berardi. Endi yo'llar POSIX shaklga
  o'tkaziladi va PATH har ishga tushganda tozalanadi (o'z-o'zini davolash).
- **Qo'llab-quvvatlanmaydigan OS** (masalan Cursor Windows'da) — adashtiruvchi
  "internet/sudo" o'rniga halol, aniq xabar ko'rsatiladi.

[Nashr qilinmagan]: https://github.com/SUNNATBEE/sunnatbeeCLI/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/SUNNATBEE/sunnatbeeCLI/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/SUNNATBEE/sunnatbeeCLI/releases/tag/v1.0.0
