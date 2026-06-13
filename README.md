<div align="center">

# 🤖 AI Terminal Pult

### *Barcha AI CLI agentlaringizni bitta chiroyli FZF menyusidan boshqaring*

Aider, Claude Code, Goose, Gemini, Ollama va boshqalar — bittagina buyruq bilan.

[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-1f425f.svg?logo=gnu-bash&logoColor=white)](#)
[![Powered by fzf](https://img.shields.io/badge/powered%20by-fzf-00b894.svg)](https://github.com/junegunn/fzf)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-hissa-qoshish)

</div>

---

## 📖 Loyiha haqida

**AI Terminal Pult** — bu terminaldagi turli xil AI CLI vositalarini (Aider,
Claude Code, Goose va h.k.) yagona, qulay **FZF** interfeysi orqali tezda topib
ishga tushiruvchi yengil "boshqaruv pulti".

Endi har bir agent buyrug'ini eslab yurish shart emas — bitta menyu, bitta
`ENTER`, va tanlangan agent ishga tushadi.

---

## ✨ Imkoniyatlar (Features)

| | Imkoniyat | Tavsif |
|---|---|---|
| 🎛️ | **Yagona menyu** | Barcha AI agentlar bitta interaktiv FZF ro'yxatida |
| 🔌 | **Kengaytiriluvchi** | Yangi agent qo'shish — kod yozmasdan, faqat bitta qator |
| 🛡️ | **Xavfsiz o'rnatish** | `.bashrc`/`.zshrc` o'zgartirilishidan oldin **zaxiralanadi** |
| 🧯 | **Aqlli xatoliklar** | Agent o'rnatilmagan bo'lsa — aniq, tushunarli xabar |
| 🔍 | **Holat ko'rsatkichi** | `--list` har bir agent o'rnatilgan/yo'qligini ko'rsatadi |
| ♻️ | **Idempotent** | Qayta o'rnatish konfiguratsiyani buzmaydi |
| 🧹 | **Toza o'chirish** | `uninstall.sh` hamma narsani izsiz qaytaradi |

---

## 📂 Loyiha tuzilmasi

```text
ai-terminal-pult/
├── README.md             # Ushbu hujjat
├── LICENSE               # MIT litsenziyasi
├── install.sh            # Xavfsiz o'rnatuvchi (zaxira + fzf tekshiruvi)
├── uninstall.sh          # Toza o'chiruvchi
├── bin/
│   └── ai-selector.sh    # Asosiy FZF menyu skripti
├── lib/
│   └── common.sh         # Umumiy funksiyalar (loglar, ranglar, xato boshqaruvi)
└── config/
    └── agents.conf       # Agentlar ro'yxati — bu yerga o'zingiznikini qo'shing
```

---

## 🚀 O'rnatish (Installation)

### Talablar (Prerequisites)

- 🐚 **bash** yoki **zsh**
- 🔍 [**fzf**](https://github.com/junegunn/fzf) — fuzzy-finder (majburiy)

> `fzf` o'rnatilmagan bo'lsa, `install.sh` buni aniqlab, o'rnatish bo'yicha
> ko'rsatma beradi va xavfsiz to'xtaydi.

<details>
<summary><b>fzf'ni qanday o'rnatish kerak?</b></summary>

```bash
# macOS
brew install fzf

# Debian / Ubuntu
sudo apt install fzf

# Arch Linux
sudo pacman -S fzf

# Boshqa platformalar
# https://github.com/junegunn/fzf#installation
```
</details>

### Qadamlar

```bash
# 1) Repozitoriyani klonlang
git clone https://github.com/<foydalanuvchi>/ai-terminal-pult.git
cd ai-terminal-pult

# 2) O'rnatish skriptini ishga tushiring
bash install.sh

# 3) Shell konfiguratsiyasini qayta yuklang (yoki terminalni qayta oching)
source ~/.bashrc      # yoki: source ~/.zshrc
```

✅ Tayyor! `install.sh` quyidagilarni bajaradi:
- `fzf` mavjudligini tekshiradi
- `~/.bashrc` / `~/.zshrc` faylini **zaxiralaydi**
- agentlar konfiguratsiyasini `~/.config/ai-terminal-pult/` ga ko'chiradi
- `aipult` aliasini qo'shadi

---

## 🎮 Foydalanish (Usage)

```bash
# Interaktiv menyuni oching
aipult
```

```text
🤖 AI agent tanlang › █
┌──────────────────────────────────────────────────────────┐
│ Aider                  🤝 AI juftlik dasturlash terminalda  │
│ Claude Code            🧠 Anthropic'ning rasmiy Claude CLI   │
│ Goose                  🦢 Block'ning lokal AI agenti         │
│ Gemini CLI             ✨ Google Gemini terminal agenti      │
└──────────────────────────────────────────────────────────┘
  ENTER — ishga tushirish · ESC — bekor qilish
```

Klaviaturadan yozib qidiring, `↑/↓` bilan tanlang, `ENTER` bilan ishga tushiring.

### Boshqa buyruqlar

| Buyruq | Vazifasi |
|---|---|
| `aipult` | Interaktiv FZF menyusini ochadi |
| `aipult --list` | Barcha agentlarni va ularning **o'rnatilgan/yo'q** holatini ko'rsatadi |
| `aipult --help` | Yordam matnini chiqaradi |

> ℹ️ Agar tanlangan agent tizimda topilmasa, vosita aniq xabar beradi:
> *"Agent topilmadi, iltimos o'rnatib oling"* — va `127` exit-code bilan to'xtaydi.

---

## ➕ Qanday qilib o'z agentlaringizni qo'shish mumkin?

Eng kuchli tomoni shundaki — **kod yozish shart emas**. Agentlar oddiy matnli
konfiguratsiya faylida saqlanadi:

```bash
~/.config/ai-terminal-pult/agents.conf
```

Har bir agent **bitta qator** va `|` bilan ajratilgan **4 ta maydon**dan iborat:

```text
NOM | BINARY | BUYRUQ | IZOH
```

| Maydon | Ma'nosi |
|---|---|
| **NOM** | Menyuda ko'rinadigan nom |
| **BINARY** | PATH'da tekshiriladigan bajariluvchi fayl (`command -v` orqali) |
| **BUYRUQ** | Haqiqatda ishga tushiriladigan buyruq (argumentlar bilan bo'lishi mumkin) |
| **IZOH** | Qisqacha tavsif |

### Misol

`agents.conf` fayli oxiriga shunchaki yangi qator qo'shing:

```text
# Mening shaxsiy agentim
Cursor Agent|cursor-agent|cursor-agent chat|🎯 Cursor'ning terminal agenti
```

Saqlang — keyingi `aipult` ishga tushishida u menyuda paydo bo'ladi. 🎉

> 💡 **Maslahat:** `AI_PULT_CONFIG` muhit o'zgaruvchisi orqali boshqa
> konfiguratsiya faylini ko'rsatishingiz mumkin:
> ```bash
> export AI_PULT_CONFIG="$HOME/ish/agents.conf"
> ```

---

## 🗑️ O'chirish (Uninstall)

```bash
bash uninstall.sh
```

Bu skript `.bashrc`/`.zshrc` dan qo'shilgan blokni **(avval zaxira olib)**
olib tashlaydi. Foydalanuvchi konfiguratsiyasini esa o'zingiz xohlasangiz
o'chirasiz:

```bash
rm -rf ~/.config/ai-terminal-pult
```

---

## 🤝 Hissa qo'shish

PR'lar mamnuniyat bilan qabul qilinadi! Yangi agent qo'shsangiz yoki
yaxshilanish kiritsangiz:

1. Repozitoriyani **fork** qiling
2. Yangi **branch** yarating (`git checkout -b feat/yangi-agent`)
3. O'zgartirishlaringizni **commit** qiling
4. **Push** qilib, **Pull Request** oching

Shell skriptlarini [shellcheck](https://www.shellcheck.net/) bilan tekshirib
yuborganingiz — alohida rahmatga sazovor. 🙏

---

## 📜 Litsenziya

[MIT](./LICENSE) — erkin foydalaning, o'zgartiring va tarqating.

<div align="center">

**⭐ Agar loyiha foydali bo'lsa, repozitoriyaga yulduzcha qo'ying!**

</div>
