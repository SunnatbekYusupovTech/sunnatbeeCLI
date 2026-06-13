<div align="center">

# 🤖 AI CLI Pult

### *Bitta buyruq. 10 ta professional AI CLI. Cheksiz imkoniyat.*

`ai` deb yozing → ro'yxatdan tanlang → CLI avtomatik ishga tushadi.
O'rnatilmagan bo'lsa — o'zi o'rnatadi. 🪄

[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-1f425f.svg?logo=gnu-bash&logoColor=white)](#)
[![Powered by fzf](https://img.shields.io/badge/powered%20by-fzf-00b894.svg)](https://github.com/junegunn/fzf)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![One-line install](https://img.shields.io/badge/install-one--line-ff69b4.svg)](#-bir-buyruq-bilan-örnatish-one-click)

</div>

---

## 📖 Loyiha haqida

**AI CLI Pult** — terminaldagi 10 ta professional AI CLI agentini (Claude Code,
Aider, Codex, Gemini, Copilot va h.k.) yagona **FZF** menyusi orqali bitta
buyruq bilan boshqarish vositasi.

> 🎓 Bu loyiha **o'quvchilar uchun** maxsus tuzilgan: ular bitta buyruq bilan
> o'rnatadi va istalgan AI CLI'dan darrov foydalana boshlaydi — qaysi paket
> qaysi buyruq bilan o'rnatilishini eslab o'tirish shart emas.

---

## ✨ Imkoniyatlar (Features)

| | Imkoniyat | Tavsif |
|---|---|---|
| ⚡ | **Bir buyruq bilan o'rnatish** | `curl ... \| bash` — qolgani avtomatik |
| 🎛️ | **Yagona `ai` menyusi** | 10 ta AI CLI bitta interaktiv FZF ro'yxatida |
| 🪄 | **Avtomatik o'rnatish** | Tanlangan CLI yo'q bo'lsa — ruxsat so'rab o'zi o'rnatadi |
| 🔌 | **Kengaytiriluvchi** | Yangi agent qo'shish — kod yozmasdan, bitta qator |
| 🛡️ | **Xavfsiz** | `.bashrc`/`.zshrc` o'zgartirishdan oldin **zaxiralanadi** |
| 🔍 | **Holat ko'rsatkichi** | `ai --list` har bir CLI o'rnatilgan/yo'qligini ko'rsatadi |
| ♻️ | **Idempotent** | Qayta o'rnatish hech narsani buzmaydi |
| 🧹 | **Toza o'chirish** | `uninstall.sh` hammasini izsiz qaytaradi |

---

## 🤖 Qo'llab-quvvatlanadigan AI CLI agentlar

| # | Agent | Buyruq | Tavsif |
|---|---|---|---|
| 1 | 🧠 Claude Code | `claude` | Anthropic'ning rasmiy Claude CLI |
| 2 | 🤝 Aider | `aider` | AI juftlik dasturlash (pair programming) |
| 3 | ⚡ OpenAI Codex | `codex` | OpenAI Codex terminal agenti |
| 4 | ✨ Gemini CLI | `gemini` | Google Gemini terminal agenti |
| 5 | 🐙 GitHub Copilot | `copilot` | GitHub Copilot CLI |
| 6 | 🦢 Goose | `goose` | Block'ning lokal AI agenti |
| 7 | 🟢 OpenCode | `opencode` | Ochiq manbali terminal coding agenti |
| 8 | 💅 Crush | `crush` | Charm'ning AI coding agenti |
| 9 | 🐉 Qwen Code | `qwen` | Alibaba Qwen Code CLI |
| 10 | 🎯 Cursor Agent | `cursor-agent` | Cursor'ning terminal agenti |

> Ro'yxat `config/agents.conf`'da — istalgancha o'zgartirish/qo'shish mumkin.

---

## 🚀 Bir buyruq bilan o'rnatish (One-Click)

```bash
curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/ai-cli/main/bootstrap.sh | bash
```

<sub>`wget` ishlatuvchilar uchun:</sub>

```bash
wget -qO- https://raw.githubusercontent.com/SUNNATBEE/ai-cli/main/bootstrap.sh | bash
```

Shu bitta buyruq quyidagilarni avtomatik bajaradi:

1. 📥 Repozitoriyani `~/.ai-cli`'ga klonlaydi
2. 🔍 `fzf` mavjudligini tekshiradi
3. 💾 `~/.bashrc` / `~/.zshrc` faylini **zaxiralaydi**
4. 🔗 `ai` buyrug'ini `~/.local/bin`'ga o'rnatadi
5. ⚙️ Agentlar ro'yxatini `~/.config/ai-cli/`'ga ko'chiradi

So'ngra terminalni qayta oching (yoki `source ~/.bashrc`) — va tayyor:

```bash
ai
```

> ⚠️ **Talab:** `git`, `curl`/`wget` va [`fzf`](https://github.com/junegunn/fzf).
> `fzf` yo'q bo'lsa, o'rnatuvchi buni aniqlab, ko'rsatma beradi.
>
> 📌 Agar repozitoriyangizning standart branchi `main` emas, `master` bo'lsa —
> URL'dagi `main` so'zini `master`'ga almashtiring.

<details>
<summary><b>fzf'ni qanday o'rnatish kerak?</b></summary>

```bash
brew install fzf            # macOS
sudo apt install fzf        # Debian / Ubuntu
sudo pacman -S fzf          # Arch Linux
# Boshqalar: https://github.com/junegunn/fzf#installation
```
</details>

---

## 🎮 Foydalanish (Usage)

```bash
ai
```

```text
🤖 AI CLI tanlang › █
╭──────────────────────────────────────────────────────────╮
│ Claude Code           🧠 Anthropic'ning rasmiy Claude CLI   │
│ Aider                 🤝 AI juftlik dasturlash              │
│ OpenAI Codex          ⚡ OpenAI Codex terminal agenti       │
│ Gemini CLI            ✨ Google Gemini terminal agenti       │
│ GitHub Copilot        🐙 GitHub Copilot CLI                 │
│ ...                                                        │
╰──────────────────────────────────────────────────────────╯
  ENTER — ishga tushirish · ESC — bekor qilish
```

Yozib qidiring → `↑/↓` bilan tanlang → `ENTER`. CLI darhol ishga tushadi.

### 🪄 Avtomatik o'rnatish

Agar tanlangan CLI tizimda yo'q bo'lsa, `ai` shunchaki xato bermaydi — u o'zi
o'rnatishni taklif qiladi:

```text
[!] Agent topilmadi: 'Claude Code' (kerakli buyruq: 'claude').
[i] O'rnatish buyrug'i: npm install -g @anthropic-ai/claude-code
❓ 'Claude Code' hozir o'rnatilsinmi? [y/N] y
[i] O'rnatilmoqda: Claude Code ...
[✓] O'rnatildi: Claude Code
[✓] Ishga tushirilmoqda: Claude Code  ➜  claude
```

### Boshqa buyruqlar

| Buyruq | Vazifasi |
|---|---|
| `ai` | Interaktiv FZF menyusini ochadi |
| `ai --list` | Barcha CLI'lar va ularning **o'rnatilgan/yo'q** holatini ko'rsatadi |
| `ai --help` | Yordam matnini chiqaradi |

---

## ➕ O'z agentlaringizni qo'shish

Eng kuchli tomoni — **kod yozish shart emas**. Agentlar oddiy matnli faylda:

```bash
~/.config/ai-cli/agents.conf
```

Har bir agent **bitta qator**, `|` bilan ajratilgan **5 ta maydon**:

```text
NOM | BINARY | BUYRUQ | INSTALL | IZOH
```

| Maydon | Ma'nosi |
|---|---|
| **NOM** | Menyuda ko'rinadigan nom |
| **BINARY** | PATH'da tekshiriladigan bajariluvchi fayl (`command -v`) |
| **BUYRUQ** | Ishga tushiriladigan buyruq (argumentlar bilan) |
| **INSTALL** | CLI yo'q bo'lsa ishlatiladigan o'rnatish buyrug'i |
| **IZOH** | Qisqacha tavsif |

### Misol

`agents.conf` oxiriga yangi qator qo'shing:

```text
Continue|cn|cn|npm install -g @continuedev/cli|🔁 Continue terminal agenti
```

> 💡 **Eslatma:** `INSTALL` maydonida `|` (pipe) ishlatmang — u maydon ajratgichi.
> `curl ... | bash` o'rniga pipe-siz shakldan foydalaning:
> ```text
> ...|bash -c "$(curl -fsSL https://example.com/install.sh)"|...
> ```

Saqlang — keyingi `ai` ishga tushishida agent menyuda paydo bo'ladi. 🎉

> 🔧 Boshqa konfiguratsiya faylini ko'rsatish: `export AI_PULT_CONFIG=...`

---

## 🗑️ O'chirish (Uninstall)

```bash
bash ~/.ai-cli/uninstall.sh
```

Bu `.bashrc`/`.zshrc` blokini (zaxira olib) olib tashlaydi va `ai` buyrug'ini
o'chiradi. Konfiguratsiyani esa xohlasangiz qo'lda o'chirasiz:

```bash
rm -rf ~/.config/ai-cli ~/.ai-cli
```

---

## 📂 Loyiha tuzilmasi

```text
ai-cli/
├── README.md             # Ushbu hujjat
├── LICENSE               # MIT
├── bootstrap.sh          # Bir buyruq bilan o'rnatuvchi (curl | bash)
├── install.sh            # Asosiy o'rnatuvchi (zaxira + fzf + symlink)
├── uninstall.sh          # Toza o'chiruvchi
├── bin/
│   └── ai-selector.sh    # `ai` buyrug'i — FZF menyu + avtomatik o'rnatish
├── lib/
│   └── common.sh         # Umumiy funksiyalar (log, rang, xato boshqaruvi)
└── config/
    └── agents.conf       # Agentlar ro'yxati
```

---

## 🤝 Hissa qo'shish

PR'lar mamnuniyat bilan! Fork → branch → commit → Pull Request.
Shell skriptlarini [shellcheck](https://www.shellcheck.net/) bilan
tekshirib yuborganingiz — alohida rahmat. 🙏

---

## 📜 Litsenziya

[MIT](./LICENSE) — erkin foydalaning, o'zgartiring, tarqating.

<div align="center">

**⭐ Foydali bo'lsa, repozitoriyaga yulduzcha qo'ying!**

</div>
