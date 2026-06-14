# Hissa qo'shish qo'llanmasi (Contributing)

Aidevix CLI'ga hissa qo'shmoqchi bo'lganingizdan xursandmiz! 🎉
Bu hujjat jarayonni oson va tushunarli qiladi.

## 🧭 Tezkor boshlash

```bash
git clone https://github.com/SUNNATBEE/sunnatbeeCLI.git
cd sunnatbeeCLI
bash install.sh        # lokal o'rnatish
```

## 🐛 Xato (bug) haqida xabar berish

1. Avval mavjud [issue'lar](https://github.com/SUNNATBEE/sunnatbeeCLI/issues)ni tekshiring.
2. Yangi issue oching va **bug report** shablonini to'ldiring.
3. Iloji bo'lsa `aidevix --doctor` natijasini va to'liq xato matnini ilova qiling.

## ✨ Yangi imkoniyat yoki agent taklif qilish

- **Yangi AI CLI agenti** qo'shish eng oson hissa: `config/agents.conf` oxiriga
  bitta qator qo'shing (format fayl boshida tushuntirilgan) yoki `feature request`
  shablonidan foydalaning.
- Agent qatori formati: `NAME|BINARY|COMMAND|INSTALL|DESCRIPTION|CATEGORY|AUTH`.

## 🔧 Kod o'zgarishlari (Pull Request)

1. **Fork** qiling va yangi **branch** oching: `git checkout -b feat/qisqa-nom`.
2. O'zgartiring. Shell skriptlari uchun qoidalar:
   - Har bir skript boshida `set -Eeuo pipefail`.
   - Foydalanuvchiga ko'rinadigan matnlar — **o'zbek tilida**, sodda va tushunarli.
   - Yangi funksiya ustiga qisqa izoh yozing (kod uslubiga monand).
3. **Tekshiring**:
   ```bash
   bash -n bin/ai-selector.sh          # sintaksis
   shellcheck bin/*.sh lib/*.sh *.sh   # lint (tavsiya etiladi)
   bats tests/                         # testlar (yoki: make check)
   ```
   Yangi funksiya yoki xulq-atvor qo'shsangiz — `tests/` ga test ham qo'shing
   (qarang: [`tests/README.md`](tests/README.md)).
4. **Commit** — [Conventional Commits](https://www.conventionalcommits.org/) uslubida:
   `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`.
5. **Push** qiling va **Pull Request** oching, shablonni to'ldiring.

## ✅ Qabul mezonlari

- `bash -n`, `shellcheck` va `bats tests/` xatosiz o'tadi (CI buni tekshiradi).
- O'zgarish hujjatlangan (kerak bo'lsa `README.md` / `CHANGELOG.md`).
- Mavjud xulq-atvor buzilmagan (idempotentlik, xavfsizlik saqlanadi).

## 📦 Versiyalash

Loyiha [SemVer](https://semver.org/lang/uz/)ga amal qiladi. Versiya `VERSION`
faylida; nashr qo'lda emas, teg orqali (`vX.Y.Z`) avtomatik chiqariladi.

Savol bo'lsa — issue oching. Rahmat! 🙏
