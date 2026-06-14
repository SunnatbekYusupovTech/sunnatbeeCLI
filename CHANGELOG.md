# O'zgarishlar tarixi (Changelog)

Barcha muhim o'zgarishlar shu faylda hujjatlanadi.

Format [Keep a Changelog](https://keepachangelog.com/uz/1.1.0/) asosida,
loyiha [Semantik versiyalash](https://semver.org/lang/uz/) (SemVer)ga amal qiladi.

## [Nashr qilinmagan]

### Qo'shildi
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

### O'zgardi
- `bin/ai-selector.sh` oxiriga `source`-qorovuli qo'shildi (`BASH_SOURCE` ==
  `$0`) — endi skriptni testda `source` qilganda `main()` ishga tushmaydi;
  xulq-atvor o'zgarmaydi.

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
