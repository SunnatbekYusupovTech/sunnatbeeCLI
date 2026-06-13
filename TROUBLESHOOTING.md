<div align="center">

# 🩺 Muammolar va yechimlar

### *Biror narsa ishlamayaptimi? Vahima yo'q — bu yerda yechimi bor.*

</div>

---

## ⚡ Eng birinchi qadam — `ai --doctor`

Aksariyat muammolarni `ai` o'zi topadi. Terminalga shuni yozing:

```bash
ai --doctor
```

U sizga ko'rsatadi:
- 🧩 Qaysi dasturlar (node, npm, python, fzf) bor yoki yo'q
- 🧭 `PATH` to'g'ri sozlanganmi
- 🤖 Qaysi AI agentlar o'rnatilgan, qaysilari yo'q

> 💡 Yashil ✓ — yaxshi. Qizil/sariq ✗ — shu narsani tuzatish kerak. Quyida har biri tushuntirilgan.

---

## 📋 Mundarija

1. [`ai` buyrug'i topilmadi (`command not found`)](#1-ai-buyrugi-topilmadi)
2. [AI CLI o'rnatildi, lekin ishga tushmayapti](#2-cli-ornatildi-lekin-ishga-tushmayapti)
3. [Har safar "o'rnatish" so'rayapti](#3-har-safar-ornatish-sorayapti)
4. ["npm topilmadi" yoki "node topilmadi"](#4-npm-yoki-node-topilmadi)
5. ["python3 topilmadi"](#5-python3-topilmadi)
6. ["bash topilmadi" (Windows)](#6-bash-topilmadi-windows)
7. [O'rnatish yarmida xato berdi](#7-ornatish-yarmida-xato-berdi)
8. [`bad interpreter` / `'M' is not recognized`](#8-bad-interpreter-yoki-m-xatosi)
9. [Menyu chiroyli emas (raqamli chiqyapti)](#9-menyu-raqamli-chiqyapti)

---

## 1. `ai` buyrug'i topilmadi

> `bash: ai: command not found`

**Nima bo'lgan?** Terminal `ai` buyrug'i qayerdaligini hali bilmaydi.

**Yechim — terminalni qaytadan oching.** Ko'pincha shu yetadi. Bo'lmasa:

```bash
source ~/.bashrc      # bash uchun
source ~/.zshrc       # zsh uchun
```

Hali ham yo'qmi? Qaytadan o'rnating:

```bash
bash ~/.ai-cli/install.sh
```

---

## 2. CLI o'rnatildi, lekin ishga tushmayapti

> O'rnatish tugadi, lekin agent ochilmadi.

**Nima bo'lgan?** Dastur o'rnatildi, lekin terminal uni hali "ko'rmayapti" (`PATH` yangilanmagan).

**Yechim:** Terminalni **butunlay yopib**, qaytadan oching. So'ng yana `ai` deb yozing.

> ✅ `ai` endi paket-menejer papkalarini o'zi topadi, shuning uchun bu kamdan-kam uchraydi. Agar uchrasa — `ai --doctor` aniq sababini ko'rsatadi.

---

## 3. Har safar "o'rnatish" so'rayapti

> Agentni tanlayman, o'rnataman, lekin keyingi safar yana o'rnatish so'rayapti.

**Nima bo'lgan?** Dastur o'rnatilgan, ammo uning papkasi `PATH`'da emas edi.

**Yechim:** Bu muammo **yangi versiyada tuzatilgan** — `ai` endi har ishga tushganda npm/pip papkalarini avtomatik qo'shadi. Eski o'rnatmani yangilang:

```bash
curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
```

So'ng terminalni qayta oching.

---

## 4. "npm" yoki "node" topilmadi

> `❌ '<agent>' o'rnatilmadi — avval bitta dastur kerak`

**Nima bo'lgan?** Ko'p AI CLI'lar **Node.js** orqali o'rnatiladi. U kompyuteringizda yo'q.

**Yechim (oson):**
1. 🌐 [https://nodejs.org](https://nodejs.org) saytiga kiring
2. Katta yashil **"LTS"** tugmasini bosib yuklab oling
3. Faylni ochib, **Next → Next → Finish** bilan o'rnating
4. Terminalni qayta oching va yana `ai` deb yozing

---

## 5. "python3" topilmadi

> Aider kabi agentlar Python orqali o'rnatiladi.

**Yechim:**
1. 🌐 [https://www.python.org/downloads](https://www.python.org/downloads) saytiga kiring
2. **"Download"** tugmasini bosing
3. ⚠️ Windows'da o'rnatishda **"Add Python to PATH"** katagiga **belgi qo'ying** (juda muhim!)
4. O'rnating va terminalni qayta oching

---

## 6. "bash topilmadi" (Windows)

> `bash topilmadi. Git for Windows o'rnating`

**Nima bo'lgan?** Windows'da bu vosita **Git Bash** ustida ishlaydi. U yo'q.

**Yechim:**
1. 🌐 [https://git-scm.com/download/win](https://git-scm.com/download/win) — yuklab oling
2. **Next → Next → Finish** bilan o'rnating (standart sozlamalar yetarli)
3. **"Git Bash"** dasturini oching va o'rnatishni shu yerda davom ettiring

---

## 7. O'rnatish yarmida xato berdi

> `❌ '<agent>' o'rnatishda xatolik yuz berdi`

Eng ko'p uchraydigan **3 ta sabab** va yechimi:

| Sabab | Belgisi | Yechim |
|---|---|---|
| 🌐 **Internet yo'q** | `network`, `ETIMEDOUT`, `could not resolve` | Wi-Fi'ni tekshiring, biroz kutib qaytadan urinib ko'ring |
| 🔒 **Ruxsat yetmadi** | `EACCES`, `permission denied` | Buyruqni `sudo` bilan sinab ko'ring (Linux/macOS) |
| 📦 **Dastur eski** | `unsupported`, `engine` | `npm`/`node`ni yangilang |

> 👉 **Maslahat:** xato xabaridagi buyruqni terminalga **o'zingiz nusxalab** ishga tushiring — o'shanda to'liq xato matni ko'rinadi va sabab aniqlashadi.

---

## 8. `bad interpreter` yoki `'M'` xatosi

> `/usr/bin/env: bash\r: No such file or directory`
> yoki `'M' is not recognized as an internal or external command`

**Nima bo'lgan?** Fayllar Windows uslubidagi qator-tugashi (CRLF) bilan saqlangan.

**Yechim:** Bu **`.gitattributes` orqali avtomatik oldi olingan**. Agar baribir uchrasa, loyihani qaytadan klonlang (zip orqali emas, `git` bilan):

```bash
rm -rf ~/.ai-cli
curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
```

---

## 9. Menyu raqamli chiqyapti

> Chiroyli izlanadigan menyu o'rniga oddiy `1) 2) 3)` ro'yxati chiqyapti.

**Nima bo'lgan?** `fzf` o'rnatilmagan. **Bu xato emas** — `ai` shunchaki oddiy menyuga o'tdi.

**Chiroyli menyu xohlasangiz** `fzf`'ni o'rnating:

```bash
brew install fzf          # macOS
sudo apt install fzf      # Ubuntu / Debian
winget install fzf        # Windows
```

---

<div align="center">

### Yechim topilmadimi?

[**Yangi muammo (issue) oching**](https://github.com/SUNNATBEE/sunnatbeeCLI/issues) — xato matnini va `ai --doctor` natijasini ilova qiling.

</div>
