# Packaging — paket menejerlari orqali tarqatish

Aidevix CLI'ni turli paket menejerlari orqali tarqatish uchun manifestlar.

| Menejer | Fayl | Buyruq |
|---------|------|--------|
| **npm** | `../package.json` + `../bin/cli.js` | `npm install -g aidevix` |
| **Homebrew** | `homebrew/aidevix.rb` | `brew install SUNNATBEE/tap/aidevix` |
| **Scoop** | `scoop/aidevix.json` | `scoop install aidevix` |

## npm

Yadro `bin/ai-selector.sh` (bash). `bin/cli.js` bash'ni topib, skriptni ishga
tushiradi (Windows'da Git Bash). Nashr:

```bash
npm publish          # "aidevix" nomi band bo'lsa: @sunnatbee/aidevix
```

> ⚠️ npm orqali ishga tushganda `.git` bo'lmaydi — avtomatik yangilanish jim
> o'tkazib yuboriladi. Yangilash: `npm update -g aidevix`.

## Homebrew

`homebrew/aidevix.rb` ni o'z tap'ingizga joylang:
`SUNNATBEE/homebrew-tap/Formula/aidevix.rb`. Har relizda `url` tegini va
`sha256` ni yangilang:

```bash
curl -fsSL https://github.com/SUNNATBEE/sunnatbeeCLI/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

## Scoop

`scoop/aidevix.json` ni bucket repozitoriyasiga joylang. `checkver` + `autoupdate`
yangi relizlarni avtomatik kuzatadi. Foydalanuvchi:

```powershell
scoop bucket add aidevix https://github.com/SUNNATBEE/sunnatbeeCLI
scoop install aidevix
```

> Scoop o'rnatilgandan keyin `aidevix` ishlashi uchun Git Bash kerak
> (`scoop install git`).
