# Xavfsizlik siyosati (Security Policy)

Aidevix CLI xavfsizligini jiddiy qabul qilamiz. Bu hujjat zaiflik haqida qanday
xabar berishni va loyihaning xavfsizlik modelini tushuntiradi.

## 📌 Qo'llab-quvvatlanadigan versiyalar

Xavfsizlik tuzatishlari faqat eng so'nggi `main` va oxirgi nashr (release) uchun
chiqariladi. Avtomatik yangilanish yoqilgani uchun (`AIDEVIX_NO_AUTOUPDATE` bilan
o'chirilmagan bo'lsa) ko'pchilik foydalanuvchilar doimo eng yangi versiyada bo'ladi.

| Versiya | Qo'llab-quvvatlanadimi |
|---------|------------------------|
| `main` (HEAD) | ✅ ha |
| Oxirgi `vX.Y.Z` release | ✅ ha |
| Eski releaselar | ❌ yo'q |

## 🔐 Zaiflik haqida xabar berish

**Zaifliklarni ommaviy issue sifatida OCHMANG.** Buning o'rniga:

1. **Afzal ko'rilgan yo'l** — GitHub'da
   [Security Advisory](https://github.com/SUNNATBEE/sunnatbeeCLI/security/advisories/new)
   orqali maxfiy xabar yuboring.
2. Yoki to'g'ridan-to'g'ri elektron pochta: **yusupovsunnatbek32@gmail.com**
   (mavzu qatoriga `[SECURITY]` yozing).

Xabaringizda iloji boricha quyidagilarni ko'rsating:
- Zaiflik tavsifi va ta'siri (impact);
- Qayta ishlab chiqarish (reproduce) qadamlari yoki PoC;
- Tegishli versiya / commit va operatsion tizim (Linux / macOS / Windows–Git Bash).

**Javob muddati:** 48 soat ichida tasdiqlash, 7 kun ichida dastlabki baholash.
Tuzatish chiqarilgach, ruxsatingiz bilan sizni mualliflikda (credit) qayd etamiz.

## 🛡️ Xavfsizlik modeli (nimaga ishonasiz)

Aidevix — bu **AI CLI agentlarini tanlash va ishga tushirish uchun yo'naltiruvchi
(launcher)**. Quyidagilarni tushunib ishlatish muhim:

### Aidevix NIMA QILADI
- `config/agents.conf` dagi agentlar ro'yxatini o'qiydi va menyu ko'rsatadi.
- Tanlangan agent o'rnatilmagan bo'lsa, **ruxsatingizni so'rab** (`[y/N]`),
  config'da yozilgan o'rnatish buyrug'ini ishga tushiradi.
- Tanlangan agentni `exec` orqali ishga tushiradi.
- Avtomatik yangilanishda repo'ning `main` branchini `git fetch` + `git reset
  --hard` qiladi.

### Aidevix NIMA QILMAYDI
- **API kalitlaringizni ko'rmaydi va saqlamaydi.** Login/kalitlar to'g'ridan-to'g'ri
  tegishli agent (Claude, Codex, ...) tomonidan boshqariladi; Aidevix faqat eslatma
  ko'rsatadi va kerak bo'lsa rasmiy login sahifasini brauzerda ochadi.
- Hech qanday telemetriya yoki ma'lumotni tashqariga yubormaydi.

### ⚠️ Ishonch chegaralari (trust boundaries) — diqqat
1. **Uchinchi-tomon o'rnatuvchilari.** `config/agents.conf` dagi `INSTALL`
   buyruqlari uchinchi tomon manbalariga tayanadi (`npm install -g ...`,
   `pip install ...`, `bash -c "$(curl ...)"`). Aidevix bu kodni **tekshirmaydi** —
   siz tegishli ta'minotchilarga (npm paketi, `curl | bash` skripti) ishonasiz.
   O'rnatishdan oldin har doim ruxsat so'raladi va buyruq ko'rsatiladi.
2. **`curl | bash` naqshlari.** Ba'zi agentlar (`Cursor`, `Plandex`, `Goose`,
   `Ollama`, `Grok`) o'rnatuvchini to'g'ridan-to'g'ri internetdan ishga tushiradi.
   Bu naqsh qulay, lekin manbaga to'liq ishonishni talab qiladi. Ishonchingiz
   komil bo'lmasa — buyruqni qo'lda, ko'rib chiqib bajaring.
3. **Avtomatik yangilanish (`git reset --hard`).** Aidevix `main`dan kod tortib
   oladi va uni ishga tushiradi. Ya'ni repo'ning `origin`iga ishonasiz. Lokal
   commit qilinmagan o'zgarishlar bo'lsa, yangilanish **o'tkazib yuboriladi**
   (ma'lumotingiz o'chmaydi). O'chirish: `AIDEVIX_NO_AUTOUPDATE=1`.
4. **Foydalanuvchi config'i.** `~/.config/ai-cli/agents.conf` ga qo'shilgan har
   qanday agent ishonchli deb hisoblanadi — uni faqat o'zingiz tahrirlaysiz.

## ✅ Loyihada qo'llanadigan xavfsizlik amaliyotlari
- Barcha skriptlar `set -Eeuo pipefail` bilan ishlaydi (jim xatolar oldini oladi).
- CI'da `shellcheck` + `bash -n` + `bats` testlari har push/PR'da ishlaydi.
- O'rnatish/yangilash har doim **aniq ruxsat** so'raydi; buyruq oldindan ko'rsatiladi.
- Avtomatik yangilanish lokal o'zgarishlarni hech qachon ustidan yozmaydi.
- Maxfiy ma'lumot (kalit/parol) repo'da saqlanmaydi.

## 🧰 Foydalanuvchi uchun tavsiyalar
- `aidevix --doctor` bilan muhitingizni tekshiring.
- Faqat o'zingiz tanigan agentlarni o'rnating; notanish `INSTALL` buyrug'i
  ko'rsatilsa — avval o'qib chiqing.
- Korporativ/maxfiy muhitda avtomatik yangilanishni o'chiring:
  `export AIDEVIX_NO_AUTOUPDATE=1`.
