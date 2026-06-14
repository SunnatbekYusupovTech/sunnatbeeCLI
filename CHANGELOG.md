# O'zgarishlar tarixi (Changelog)

Barcha muhim o'zgarishlar shu faylda hujjatlanadi.

Format [Keep a Changelog](https://keepachangelog.com/uz/1.1.0/) asosida,
loyiha [Semantik versiyalash](https://semver.org/lang/uz/) (SemVer)ga amal qiladi.

## [Nashr qilinmagan]

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

[Nashr qilinmagan]: https://github.com/SUNNATBEE/sunnatbeeCLI/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/SUNNATBEE/sunnatbeeCLI/releases/tag/v1.0.0
