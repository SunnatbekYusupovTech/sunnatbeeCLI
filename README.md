<div align="center">

<img src="assets/log.jpg" alt="Aidevix logosi" width="120" />

# ✦ Aidevix CLI

### *Bitta buyruq. 23 ta top AI CLI. Cheksiz imkoniyat.*

`aidevix` deb yozing → ro'yxatdan tanlang → CLI avtomatik ishga tushadi.
O'rnatilmagan bo'lsa — o'zi o'rnatadi. 🪄

**🇺🇿 O'zbekcha** · [🇬🇧 English](./README.en.md)

[![Release](https://img.shields.io/github/v/release/SUNNATBEE/sunnatbeeCLI?label=release&logo=github&color=8a2be2&sort=semver)](https://github.com/SUNNATBEE/sunnatbeeCLI/releases/latest)
[![CI](https://github.com/SUNNATBEE/sunnatbeeCLI/actions/workflows/ci.yml/badge.svg)](https://github.com/SUNNATBEE/sunnatbeeCLI/actions/workflows/ci.yml)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-1f425f.svg?logo=gnu-bash&logoColor=white)](#)
[![Powered by fzf](https://img.shields.io/badge/powered%20by-fzf-00b894.svg)](https://github.com/junegunn/fzf)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

[![⚡ Hoziroq o'rnatish](https://img.shields.io/badge/⚡_Hoziroq_o'rnatish-bir_buyruq-ff69b4?style=for-the-badge)](#-ornatish-installation)
[![📦 Eng so'nggi reliz](https://img.shields.io/badge/📦_Eng_so'nggi_reliz-v1.1.0-8a2be2?style=for-the-badge&logo=github)](https://github.com/SUNNATBEE/sunnatbeeCLI/releases/latest)

</div>

> **⚡ Tezkor o'rnatish** — Git Bash (Windows) yoki terminal (Linux/macOS)da:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
> ```
>
> So'ng `source ~/.bashrc && aidevix`. To'liq qo'llanma: [**O'rnatish**](#-ornatish-installation) · Yuklab olish: [**Releases**](https://github.com/SUNNATBEE/sunnatbeeCLI/releases/latest)

---

## 📖 Loyiha haqida

**Aidevix CLI** — terminaldagi 23 ta top AI CLI agentini (Claude Code, Codex,
Gemini, Copilot, Aider, Ollama va h.k.) yagona interaktiv menyu orqali bitta
buyruq bilan boshqarish vositasi. `bash`, `zsh`, `cmd` va `PowerShell`'da ishlaydi.

> 🎓 Bu loyiha **o'quvchilar uchun** maxsus tuzilgan: ular bitta buyruq bilan
> o'rnatadi va istalgan AI CLI'dan darrov foydalana boshlaydi — qaysi paket
> qaysi buyruq bilan o'rnatilishini eslab o'tirish shart emas.

---

## ✨ Imkoniyatlar (Features)

| | Imkoniyat | Tavsif |
|---|---|---|
| 🎨 | **Professional dizayn** | AD logosi + gradientli banner, jonli **spinner** animatsiyasi, rangli preview — toza va zamonaviy |
| ⚡ | **Bir buyruq bilan o'rnatish** | `curl ... \| bash` — qolgani avtomatik |
| 🎛️ | **Yagona `aidevix` menyusi** | 23 ta top AI CLI bitta interaktiv ro'yxatda (status + preview) |
| 🪄 | **Avtomatik o'rnatish** | Tanlangan CLI yo'q bo'lsa — ruxsat so'rab o'zi o'rnatadi |
| 🔐 | **Login yo'riqnomasi** | Har agent uchun qaysi login/API kalit kerakligi ko'rsatiladi; kalitlar saqlanmaydi |
| 🚀 | **Tezkor ishga tushirish** | `aidevix claude` — menyusiz, to'g'ridan-to'g'ri |
| 🕘 | **Oxirgi tanlovni eslaydi** | Eng so'nggi ishlatilgan agent ro'yxat tepasida |
| 🪄 | **fzf avtomatik o'rnatiladi** | O'rnatishda fzf'ni o'zi yuklab oladi (sudo kerak emas); bo'lmasa raqamli menyuga o'tadi |
| 🔄 | **Avtomatik yangilanish** | Loyiha yangilansa — `aidevix` o'zini jim yangilaydi va "nima yangilangani"ni ko'rsatadi (qo'lda hech narsa qilish shart emas) |
| ♻️ | **`aidevix --update`** | O'rnatilgan barcha agentlarni bir buyruq bilan yangilaydi |
| 🩺 | **`aidevix --doctor`** | Muhitni (node/npm/python/fzf, PATH) tekshiradi |
| ➕ | **`aidevix --add`** | Interaktiv tarzda yangi agent qo'shadi (faylni qo'lda tahrirlamasdan) |
| 🧭 | **PATH avtomatik tuzatish** | npm/pip global bin papkasini o'zi topadi — yangi kompyuterda ham ishlaydi |
| 🩺 | **Tushunarli xato xabarlari** | Xato bo'lsa — sababini va yechimini **oddiy tilda** aytadi (bolalar ham tushunadi) |
| ⌨️ | **Shell completion** | `aidevix <TAB>` agent nomlarini to'ldiradi (bash/zsh) |
| 🪟 | **Windows wrapper** | `aidevix.cmd` / `aidevix.ps1` — PowerShell/cmd'dan ham ishlaydi |
| 🔌 | **Kengaytiriluvchi** | Yangi agent qo'shish — kod yozmasdan, bitta qator |
| 🛡️ | **Xavfsiz** | `.bashrc`/`.zshrc` o'zgartirishdan oldin **zaxiralanadi** |
| 🧹 | **Toza o'chirish** | `uninstall.sh` hammasini izsiz qaytaradi |

---

## 🤖 Qo'llab-quvvatlanadigan AI CLI agentlar

| # | Agent | Buyruq | Guruh | Login |
|---|---|---|---|---|
| 1 | 🧠 Claude Code | `claude` | Coding | 🔑 / 💳 |
| 2 | ⚡ OpenAI Codex | `codex` | Coding | 🌐 / 🔑 |
| 3 | ✨ Gemini CLI | `gemini` | Coding | 🌐 / 🔑 |
| 4 | 🐙 GitHub Copilot | `copilot` | Coding | 💳 |
| 5 | 🟢 OpenCode | `opencode` | Coding | 🔑 |
| 6 | 💅 Crush | `crush` | Coding | 🔑 |
| 7 | 🐉 Qwen Code | `qwen` | Coding | 🌐 / 🔑 |
| 8 | 🔁 Continue | `cn` | Coding | 🌐 / 🔑 |
| 9 | 🎯 Cursor Agent | `cursor-agent` | Coding | 🌐 |
| 10 | 🗺️ Plandex | `plandex` | Coding | 🌐 / 🔑 |
| 11 | 🤝 Aider | `aider` | Pair | 🔑 |
| 12 | 🦢 Goose | `goose` | Agent | 🔑 |
| 13 | 🦙 Ollama | `ollama` | Local | 🆓 |
| 14 | 💬 llm | `llm` | Chat | 🔑 |
| 15 | 🗨️ AIChat | `aichat` | Chat | 🔑 |
| 16 | 💻 Open Interpreter | `interpreter` | Agent | 🆓 **bepul** |
| 17 | 🙌 OpenHands | `openhands` | Agent | 🆓 **bepul** |
| 18 | 🛠️ SWE-agent | `sweagent` | Agent | 🆓 **bepul** |
| 19 | 🧩 Cline CLI | `cline` | Coding | 🆓 **bepul** |
| 20 | 🦘 Kilo CLI | `kilo` | Coding | 🆓 **bepul** |
| 21 | 🤖 Grok Build | `grok` | Coding | 💳 / 🌐 |
| 22 | 🚀 Antigravity | `antigravity` | Coding | 🆓 **bepul** |
| 23 | 🐙 GitHub CLI | `gh` | Tools | 🆓 **bepul** |

> **Login belgilari:** 🔑 API kalit · 🌐 brauzer orqali login · 💳 obuna · 🆓 **bepul** (ochiq manba / bepul tier).
> 💡 **`aidevix --free`** — faqat bepul agentlarni ko'rsatadi (11+ ta).
> Ro'yxat `config/agents.conf`'da — istalgancha o'zgartirish/qo'shish mumkin.
> ⚠️ Cursor Agent hozircha Windows'da ishlamaydi; Antigravity — qo'lda yuklab olinadi
> (IDE); GitHub CLI Windows'da `winget install GitHub.cli` bilan ham o'rnatiladi.

---

## 🎬 Video qo'llanma (O'quvchilar uchun)

> 🎥 O'rnatish va foydalanishning **to'liq jarayonini** video orqali ko'rib
> o'rganing — ayniqsa birinchi marta o'rnatayotgan bo'lsangiz tavsiya etiladi.

<div align="center">

<!--
  📌 VIDEO HAVOLASINI SHU YERGA QO'YING.
  Havola tayyor bo'lganda quyidagi qatordagi "#" o'rniga to'liq manzilni yozing
  (masalan: https://youtu.be/XXXXXXXX yoki Telegram post havolasi).
-->
[![Video qo'llanma](https://img.shields.io/badge/▶_Video_qo'llanma-tez_orada-lightgrey?style=for-the-badge&logo=youtube&logoColor=white)](#)

*📌 Video havolasi tez orada shu yerga qo'shiladi.*

</div>

---

## 🚀 O'rnatish (Installation)

O'rnatish atigi **bir necha daqiqa**. Quyidagi 3 qadamni ketma-ket bajaring.

> 💡 Pastdagi yozma yo'riqnoma bilan birga yuqoridagi **video qo'llanma**ni ham
> ko'rsangiz, jarayon yanada oson kechadi.

### 1️⃣-qadam — Kerakli dasturlar (Prerequisites)

O'rnatishdan oldin kompyuteringizda quyidagilar bo'lishi kerak:

| Dastur | Majburiymi? | Nima uchun | Qanday o'rnatish |
|---|:---:|---|---|
| **git** | ✅ Ha | Loyihani yuklab olish uchun | [git-scm.com/downloads](https://git-scm.com/downloads) |
| **curl** yoki **wget** | ✅ Ha | O'rnatuvchini yuklab olish | macOS/Linux'da odatda bor; Windows'da Git Bash bilan keladi |
| **fzf** | 🪄 Avtomatik | Chiroyli izlanadigan menyu | O'rnatuvchi **o'zi yuklab oladi** (sudo kerak emas) |
| **Node.js / Python** | ❌ Yo'q | Faqat tanlangan AI CLI uchun | `aidevix` keraklisini o'zi taklif qiladi |

> 🪟 **Windows foydalanuvchilari diqqat!** Bu vosita **Git Bash** ichida ishlaydi.
> Avval [**Git for Windows**](https://git-scm.com/download/win) ni o'rnating
> (Next → Next → Finish), so'ng **"Git Bash"** dasturini oching va quyidagi
> buyruqlarni **o'sha oynada** yozing — oddiy `cmd` yoki PowerShell'da emas.

### 2️⃣-qadam — O'z terminalingizga mos buyruqni tanlang

Qaysi dasturda ishlayotganingizga qarab quyidagilardan **birini** nusxalab,
**Enter** bosing. (Hamma yo'l bir xil natijaga olib keladi.)

> 🧠 **Qisqacha qoida:** yadro `bash` skripti. Linux/macOS'da to'g'ridan-to'g'ri,
> Windows'da esa **Git Bash** oynasida ishlaydi. ⚠️ Oddiy `cmd` yoki PowerShell'dan
> foydalanmang — ularda `bash` PATH'da bo'lmaganligi sababli `"bash" topilmadi`
> xatosi chiqadi. **Git Bash dasturini oching.**

#### 🐧 Linux / 🍎 macOS — `bash` yoki `zsh`

```bash
curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
```

<sub>`curl` yo'q bo'lsa, `wget` bilan:</sub>

```bash
wget -qO- https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
```

#### 🪟 Windows — Git Bash

Start menyudan **"Git Bash"** dasturini oching (oddiy `cmd`/PowerShell EMAS) va
xuddi yuqoridagi buyruqni yozing:

```bash
curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
```

> ❓ **"bash" topilmadi degan xato?** Demak siz `cmd` yoki PowerShell'dasiz.
> Ularni yoping va **Git Bash** dasturini oching — buyruq o'sha oynada ishlaydi.

> ⚠️ **`curl: (35) ... CRYPT_E_NO_REVOCATION_CHECK` xatosi?** Bu Windows'da curl
> sertifikat-otzыv serveriga ulana olmaganda chiqadi (internetdagi muammo, sizda
> emas). Yechimi — buyruqqa `--ssl-no-revoke` qo'shing:
>
> ```bash
> curl --ssl-no-revoke -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
> ```

> 💡 **Windows'da `aidevix` buyrug'ini ishlatish:** o'rnatishdan keyin `aidevix`
> Git Bash'da darrov ishlaydi. PowerShell/cmd'da ham ishlashi uchun
> `%USERPROFILE%\.local\bin` papkasini Windows **PATH**'iga qo'shing (yoki
> shunchaki Git Bash'dan foydalaning).

#### 📦 Paket menejerlari orqali

```bash
# npm (cross-platform — Node.js va ishga tushish uchun bash kerak)
npm install -g aidevix

# Homebrew (macOS / Linux)
brew install SUNNATBEE/tap/aidevix

# Scoop (Windows)
scoop bucket add aidevix https://github.com/SUNNATBEE/sunnatbeeCLI
scoop install aidevix
```

> Manifestlar [`packaging/`](./packaging) papkasida (Homebrew formula + Scoop manifest).

---

Yuqoridagi buyruq qaysi terminalda bo'lsa ham, hamma narsani **avtomatik** bajaradi:

1. 📥 Loyihani `~/.ai-cli` papkasiga yuklab oladi
2. 🔍 Kerakli dasturlarni tekshiradi va **`fzf`'ni avtomatik o'rnatadi** (chiroyli menyu uchun)
3. 💾 `~/.bashrc` / `~/.zshrc` faylini **zaxiralaydi** (xavfsizlik uchun)
4. 🔗 `aidevix` buyrug'ini o'rnatadi (+ Windows uchun `aidevix.cmd` / `aidevix.ps1`)
5. ⚙️ Agentlar ro'yxatini `~/.config/ai-cli/` ga ko'chiradi
6. ⌨️ `PATH` va avtomatik to'ldirishni (completion) sozlaydi

<details>
<summary><b>🛠️ Variant B — Qo'lda o'rnatish (git clone bilan)</b></summary>

Avtomatik buyruqni ishlatishni xohlamasangiz:

```bash
git clone https://github.com/SUNNATBEE/sunnatbeeCLI.git ~/.ai-cli
bash ~/.ai-cli/install.sh
```

</details>

### 3️⃣-qadam — Terminalni qayta oching va tekshiring

O'rnatish tugagach, **terminalni butunlay yopib, qaytadan oching**
(yoki `source ~/.bashrc`). So'ng tekshiring:

```bash
aidevix --doctor     # muhit to'g'ri sozlanganini tekshiradi
aidevix              # menyuni ochadi 🎉
```

✅ Menyu ochildimi? Tabriklaymiz — tayyor! Endi istalgan AI CLI'ni tanlang.

---

> 📌 **Eslatma:** repozitoriyaning standart branchi `master` bo'lsa, URL'dagi
> `main` so'zini `master` ga almashtiring.
>
> 🩺 **Muammo chiqdimi?** Avval **`aidevix --doctor`** ni ishga tushiring — u
> muammoni topib, oddiy tilda nima qilish kerakligini aytadi. To'liq qo'llanma:
> [**TROUBLESHOOTING.md**](./TROUBLESHOOTING.md).

<details>
<summary><b>fzf qo'lda o'rnatish (agar avtomatik o'rnatilmasa)</b></summary>

```bash
brew install fzf            # macOS
sudo apt install fzf        # Debian / Ubuntu
sudo pacman -S fzf          # Arch Linux
winget install fzf          # Windows
# Boshqalar: https://github.com/junegunn/fzf#installation
```
</details>

---

## 🎮 Foydalanish (Usage)

```bash
aidevix
```

```text
     █████╗ ██████╗
    ██╔══██╗██╔══██╗
    ███████║██║  ██║
    ██╔══██║██║  ██║
    ██║  ██║██████╔╝
    ╚═╝  ╚═╝╚═════╝

  ✦  Aidevix CLI
  barcha AI agentlar — bitta pultda
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╭─ ✦ Aidevix CLI ────────────────────────────────────────────╮
│                                          ╭── tafsilot ────╮ │
│ ▶ ✓  Claude Code     🧠 Claude CLI       │ Claude Code    │ │
│   ✓  Aider           🤝 pair programming │ ───────────    │ │
│   ✗  Gemini CLI      ✨ Gemini agenti    │ ● o'rnatilgan  │ │
│   ✗  GitHub Copilot  🐙 Copilot CLI      │ Binar: claude  │ │
│   ...                                    ╰────────────────╯ │
│   ↑/↓ tanlang · yozib qidiring · ENTER · ESC               │
╰────────────────────────────────────────────────────────────╯
```

Yozib qidiring → `↑/↓` bilan tanlang → `ENTER`. O'ng tomonda tanlangan
agentning tafsiloti (holati, buyrug'i, o'rnatish usuli) jonli ko'rinadi.

> 💡 `fzf` yo'q bo'lsa, xuddi shu narsa oddiy **raqamli menyu** sifatida chiqadi —
> hech narsa yo'qolmaydi.

### 🪄 O'rnatishda jonli animatsiya

CLI o'rnatilayotganda quruq kutish o'rniga — aylanuvchi **spinner** va o'tgan vaqt:

```text
⠹ 📦 Claude Code o'rnatilmoqda  3s
✓ 📦 Claude Code o'rnatilmoqda  (8s)
🚀 Ishga tushirilmoqda  Claude Code
```

### 🪄 Avtomatik o'rnatish

Agar tanlangan CLI tizimda yo'q bo'lsa, `aidevix` shunchaki xato bermaydi — u o'zi
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
| `aidevix` | Interaktiv menyuni ochadi (fzf bo'lsa fzf + preview, bo'lmasa raqamli) |
| `aidevix <agent>` | Agentni nomi/binari bo'yicha **to'g'ridan-to'g'ri** ishga tushiradi (masalan `aidevix claude`) |
| `aidevix --list` | Barcha CLI'lar va ularning **o'rnatilgan/yo'q** holatini ko'rsatadi |
| `aidevix --free` | 🆓 **Faqat bepul** agentlar menyusi (sinab ko'rish uchun eng yaxshisi) |
| `aidevix --top` | ⭐ **Faqat eng mashhur** (top) agentlar menyusi |
| `aidevix --update` | O'rnatilgan barcha agentlarni yangilaydi |
| `aidevix --doctor` | Muhitni tekshiradi (vositalar, PATH, agentlar holati) |
| `aidevix --add` | Interaktiv tarzda yangi agent qo'shadi |
| `aidevix --version` | Aidevix CLI versiyasini ko'rsatadi |
| `aidevix --help` | Yordam matnini chiqaradi |

> 💡 `aidevix <TAB>` — agent nomlarini avtomatik to'ldiradi (o'rnatishdan keyin).

---

## 🔐 Login / API kalitlar

Ko'pchilik AI CLI'lar ishlashidan oldin **hisobga kirish (login)** yoki **API
kalit** talab qiladi. Aidevix buni siz uchun soddalashtiradi:

- 📋 Menyuda har agent yonida belgi (🆓/🔑/🌐/💳), preview'da to'liq login talabi
  va **havola** ko'rinadi.
- 🌐 Login sahifasi brauzerда **faqat zarur bo'lganda** ochiladi — ya'ni agent
  o'zingiz API kalit olishingizni talab qilsa **va** o'sha kalit hali
  o'rnatilmagan bo'lsa. Agar agent o'zi login qilsa (brauzer-login), obuna yoki
  bepul bo'lsa, **yoki kalit allaqachon bor bo'lsa** — brauzer ochilmaydi, faqat
  qisqa eslatma chiqadi.
- 🔒 Kalitlarni o'zingiz, agentning o'z ko'rsatmasi bo'yicha kiritasiz. **Aidevix
  hech qanday parol yoki kalitni ko'rmaydi va saqlamaydi** — ular faqat sizning
  kompyuteringizda qoladi.

> 💡 **Bepulini sinab ko'rmoqchimisiz?** `aidevix --free` — faqat bepul agentlarni
> (Gemini, Qwen, Ollama, Continue, Open Interpreter, OpenHands, SWE-agent, Cline,
> Kilo, GitHub CLI, Antigravity — 11 ta) ko'rsatadi. `aidevix --top` — eng
> mashhurlarini.

| Belgi | Ma'nosi | Misol |
|:---:|---|---|
| 🔑 | **API kalit** kerak | `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, OpenRouter |
| 🌐 | **Brauzer orqali login** | Google / ChatGPT / Cursor hisobi |
| 💳 | **Obuna** kerak | GitHub Copilot, Claude Pro/Max |
| 🆓 | **Bepul** — login shart emas | Ollama (lokal modellar) |

> 💡 Masalan, Claude Code'ni tanlasangiz, u birinchi ishga tushganda
> `ANTHROPIC_API_KEY` so'raydi yoki brauzerda Claude hisobingizga kirishni
> taklif qiladi — ekrandagi ko'rsatmaga amal qiling.

---

## ➕ O'z agentlaringizni qo'shish

Eng kuchli tomoni — **kod yozish shart emas**. Agentlar oddiy matnli faylda:

```bash
~/.config/ai-cli/agents.conf
```

Eng oson yo'li — interaktiv qo'shuvchi:

```bash
aidevix --add
```

Yoki qo'lda — har bir agent **bitta qator**, `|` bilan ajratilgan **5 majburiy + 1
ixtiyoriy maydon**:

```text
NOM | BINARY | BUYRUQ | INSTALL | IZOH | KATEGORIYA
```

| Maydon | Ma'nosi |
|---|---|
| **NOM** | Menyuda ko'rinadigan nom |
| **BINARY** | PATH'da tekshiriladigan bajariluvchi fayl (`command -v`) |
| **BUYRUQ** | Ishga tushiriladigan buyruq (argumentlar bilan) |
| **INSTALL** | CLI yo'q bo'lsa ishlatiladigan o'rnatish buyrug'i |
| **IZOH** | Qisqacha tavsif |
| **KATEGORIYA** | *(ixtiyoriy)* Guruh nomi: `Coding`, `Chat`, `Local` va h.k. |

### Misol

`agents.conf` oxiriga yangi qator qo'shing:

```text
Continue|cn|cn|npm install -g @continuedev/cli|🔁 Continue terminal agenti|Coding
```

> 💡 **Eslatma:** `INSTALL` maydonida `|` (pipe) ishlatmang — u maydon ajratgichi.
> `curl ... | bash` o'rniga pipe-siz shakldan foydalaning:
> ```text
> ...|bash -c "$(curl -fsSL https://example.com/install.sh)"|...
> ```

Saqlang — keyingi `aidevix` ishga tushishida agent menyuda paydo bo'ladi. 🎉

> 🔧 **Muhit o'zgaruvchilari:**
> | O'zgaruvchi | Vazifasi |
> |---|---|
> | `AI_PULT_CONFIG` | Boshqa konfiguratsiya faylini ko'rsatish |
> | `AI_NO_ANIM=1` | Animatsiyalarni o'chirish (spinner/banner) |
> | `NO_COLOR=1` | Ranglarni butunlay o'chirish |
> | `AIDEVIX_NO_AUTOUPDATE=1` | Avtomatik yangilanishni o'chirish |
> | `AIDEVIX_UPDATE_INTERVAL` | Yangilanish tekshiruvi oralig'i (sekund, standart 10800 = 3 soat) |

---

## 🔄 Avtomatik yangilanish

`aidevix` **o'zini avtomatik yangilab turadi** — qo'lda hech narsa qilish shart emas.
Loyihaga yangi imkoniyat yoki agent qo'shilsa (ya'ni `main` branchга push qilinsa),
keyingi safar `aidevix` ishga tushganda:

```text
  🔄 Aidevix CLI — yangi versiya topildi, yangilanmoqda...
  Yangi o'zgarishlar:
    • feat: 3 yangi bepul agent qo'shildi
  ✓ Yangilandi! Yangi imkoniyatlar tayyor.
```

- 🔒 **Xavfsiz:** lokal o'zgarishlaringiz bo'lsa, ular ustidan yozilmaydi.
- ⏱️ **Tejamkor:** har 3 soatda bir marta tekshiriladi (sozlanadi).
- 🆕 **Yangi agentlar darrov ko'rinadi:** ro'yxat repo'dan o'qiladi, siz qo'shgan
  agentlar esa saqlanib qoladi.
- ⛔ O'chirish: `export AIDEVIX_NO_AUTOUPDATE=1`.

---

## 🗑️ O'chirish (Uninstall)

```bash
bash ~/.ai-cli/uninstall.sh
```

Bu `.bashrc`/`.zshrc` blokini (zaxira olib) olib tashlaydi va `aidevix`
buyrug'ini o'chiradi. Konfiguratsiyani esa xohlasangiz qo'lda o'chirasiz:

```bash
rm -rf ~/.config/ai-cli ~/.ai-cli
```

---

## 📂 Loyiha tuzilmasi

```text
aidevix-cli/
├── README.md             # Ushbu hujjat
├── TROUBLESHOOTING.md    # Muammolar va sodda yechimlar
├── CHANGELOG.md          # O'zgarishlar tarixi (SemVer)
├── CONTRIBUTING.md       # Hissa qo'shish qo'llanmasi
├── CODE_OF_CONDUCT.md    # Xulq-atvor kodeksi
├── SECURITY.md           # Xavfsizlik siyosati va zaiflik xabari
├── CLAUDE.md             # Loyiha xaritasi (AI yordamchilar uchun konteks)
├── README.en.md          # English README
├── Makefile              # make test / lint / syntax / check
├── package.json          # npm paketi (aidevix)
├── VERSION               # Joriy versiya (masalan 1.0.0)
├── LICENSE               # MIT
├── bootstrap.sh          # Bir buyruq bilan o'rnatuvchi (curl | bash)
├── install.sh            # Asosiy o'rnatuvchi (zaxira + symlink + completion)
├── uninstall.sh          # Toza o'chiruvchi
├── .editorconfig         # Izchil kod uslubi
├── .github/              # CI, release, issue/PR shablonlari
│   ├── workflows/        #   ci.yml (shellcheck · bash -n · bats) · release.yml
│   ├── ISSUE_TEMPLATE/   #   bug / feature shablonlari
│   ├── dependabot.yml    #   Actions versiyalarini avtomatik yangilash
│   ├── CODEOWNERS
│   └── PULL_REQUEST_TEMPLATE.md
├── tests/                # Bats testlari (unit + CLI + common)
│   ├── *.bats            #   unit_parse · cli · common
│   ├── test_helper.bash  #   umumiy setup
│   └── fixtures/         #   test agents.conf
├── packaging/            # Paket menejer manifestlari
│   ├── homebrew/aidevix.rb
│   └── scoop/aidevix.json
├── man/
│   └── aidevix.1         # man sahifa (man aidevix)
├── assets/
│   └── log.jpg           # Aidevix "AD" logosi
├── bin/
│   ├── ai-selector.sh    # `aidevix` buyrug'i — menyu + avtomatik o'rnatish
│   ├── cli.js            # npm uchun Node launcher (bash'ni topib chaqiradi)
│   ├── aidevix.cmd       # Windows (cmd.exe) wrapper
│   └── aidevix.ps1       # Windows (PowerShell) wrapper
├── lib/
│   └── common.sh         # Umumiy funksiyalar (log, rang, xato boshqaruvi)
├── completions/
│   ├── aidevix.bash      # bash/zsh (bashcompinit) avtomatik to'ldirish
│   ├── _aidevix          # zsh native completion
│   └── aidevix.fish      # fish completion
└── config/
    └── agents.conf       # Agentlar ro'yxati (23 ta top AI CLI)
```

---

## 🤝 Hissa qo'shish

PR'lar mamnuniyat bilan! To'liq qo'llanma: [**CONTRIBUTING.md**](./CONTRIBUTING.md).

Qisqacha: Fork → branch → commit ([Conventional Commits](https://www.conventionalcommits.org/))
→ Pull Request. Yangi AI CLI qo'shish eng oson hissa — `config/agents.conf` oxiriga
bitta qator. Shell skriptlarini [shellcheck](https://www.shellcheck.net/) bilan
tekshirib yuborganingiz — alohida rahmat (CI buni avtomatik tekshiradi). 🙏

Loyihada qatnashuvchilar [Xulq-atvor kodeksi](./CODE_OF_CONDUCT.md)ga amal qiladi.

### 🧪 Testlar

```bash
make test     # yoki: bats tests/
make check    # syntax + lint + test (CI bilan bir xil)
```

Tafsilot: [`tests/README.md`](./tests/README.md). Har push/PR'da CI avtomatik ishlatadi.

---

## 🔐 Xavfsizlik

Aidevix uchinchi-tomon o'rnatuvchilarini (`npm`, `pip`, `curl | bash`) **ruxsatingiz
bilan** ishga tushiradi va API kalitlaringizni **ko'rmaydi/saqlamaydi**. To'liq
xavfsizlik modeli va zaiflik haqida xabar berish: [**SECURITY.md**](./SECURITY.md).

---

## 📜 Litsenziya

[MIT](./LICENSE) — erkin foydalaning, o'zgartiring, tarqating.

<div align="center">

**⭐ Foydali bo'lsa, repozitoriyaga yulduzcha qo'ying!**

</div>
