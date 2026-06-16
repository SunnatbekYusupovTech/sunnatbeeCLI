# CLAUDE.md — Aidevix CLI

> Bu fayl Claude Code uchun loyiha xaritasi. Maqsad: kodni qaytadan o'qimasdan
> kontekstni tez tiklash. Yangi sessiyada AVVAL shuni o'qing.

## Loyiha nima qiladi
Aidevix — **terminaldagi AI CLI agentlarini (Claude Code, Codex, Gemini, Aider, ...)
bitta menyudan boshqaradigan launcher**. `config/agents.conf` dan agentlar ro'yxatini
o'qiydi, `fzf` (yoki raqamli) menyu ko'rsatadi, tanlangan agentni ishga tushiradi;
o'rnatilmagan bo'lsa — ruxsat so'rab o'rnatadi. Sof **Bash** loyihasi (build yo'q).

- Til: manba matnlar **o'zbekcha** (standart). **i18n** orqali inglizcha ham qo'llab-quvvatlanadi (`AIDEVIX_LANG=en` yoki `LANG`). Qarang `lib/i18n.sh`.
- Platformalar: Linux, macOS, Windows (Git Bash / MINGW64).
- Buyruq nomi: `aidevix`.

## Fayl xaritasi
| Yo'l | Vazifa |
|------|--------|
| `bin/ai-selector.sh` | **Asosiy skript** (~920 qator). Barcha mantiq shu yerda: menyu, parsing, o'rnatish, doctor, auto-update. |
| `lib/common.sh` | Umumiy yordamchilar: ranglar, `log_*`, `die`, `require_cmd`, `panel`, `banner`, `spin_run`, `tool_hint`, `open_url`. STDERR'ga yozadi. Boshida `lib/i18n.sh` ni `source` qiladi. |
| `lib/i18n.sh` | **Ko'p tillilik (i18n)** — `aidevix_detect_lang` (AIDEVIX_LANG > LANG/LC_* > uz), `t()` gettext-uslubidagi lookup. Manba o'zbekcha = kalit; tarjima topilmasa o'zbekchaga qaytadi. |
| `lib/i18n/en.sh` | Inglizcha tarjima katalogi (`MSG_EN["uz manba"]="en"`). Faqat "en" rejimida yuklanadi. Yangi `t "..."` qo'shsang — kalitni shu yerga ham qo'sh. |
| `config/agents.conf` | Agentlar ro'yxati. Format: `NAME\|BINARY\|COMMAND\|INSTALL\|DESC\|CATEGORY\|AUTH\|URL` (5–7 ta `\|`). |
| `bin/aidevix.cmd`, `bin/aidevix.ps1` | Windows wrapperlari — Git Bash topib `ai-selector.sh`ni chaqiradi. |
| `bin/cli.js` | npm uchun Node launcher — bash'ni topib `ai-selector.sh`ni `spawnSync` bilan ishga tushiradi (`package.json` `bin`). |
| `completions/` | `aidevix.bash` (bash/zsh), `_aidevix` (zsh native), `aidevix.fish` (fish). |
| `packaging/` | `homebrew/aidevix.rb` (formula), `scoop/aidevix.json` (manifest). Relizda `url`/`sha256`/`version` yangilanadi. |
| `man/aidevix.1` | man sahifa. |
| `scripts/` | `demo.sh` (deterministik, non-interaktiv demo) + `record-demo.sh` (asciinema→agg→`assets/demo.gif`). |
| `assets/demo.svg` | README demo posteri (statik). `log.jpg` — AD logosi. |
| `README.md` / `README.en.md` | O'zbekcha / inglizcha hujjat (til almashtirgich tepada). |
| `install.sh` | Lokal o'rnatish (symlink → `~/.local/bin`, rc zaxira, idempotent, sudosiz). |
| `bootstrap.sh` | `curl \| bash` bitta-buyruqli o'rnatuvchi (repo'ni `~/.ai-cli`ga klonlaydi). |
| `uninstall.sh` | O'chirish. |
| `tests/` | Bats testlari (`*.bats`, `test_helper.bash`, `fixtures/`). Qarang `tests/README.md`. |
| `server/` | **Global statistika backend'i** (alohida Node loyihasi, npm paketiga kirmaydi). Fastify 5 + ioredis + `@fastify/rate-limit`; Redis sorted-set'lari (`ZINCRBY`/`ZREVRANGE`). Endpoint'lar: `POST /v1/events`, `GET /v1/stats`, `GET /health`. Railway'ga Dockerfile + `railway.json` bilan deploy. Testlar: `node --test` (ioredis-mock). CI: `.github/workflows/server-ci.yml` (faqat `server/**`). Klyent (aidevix) integratsiyasi hali ulanmagan — opt-in bo'lib qo'shiladi. |
| `VERSION` | Yagona haqiqat manbai (SemVer). Release teg `vX.Y.Z` shunga mos bo'lishi shart. |
| `.github/workflows/ci.yml` | CI: shellcheck · `bash -n` · agents.conf validatsiya · bats. |
| `.github/workflows/release.yml` | Teg push'da GitHub Release. |

## `ai-selector.sh` — asosiy funksiyalar (qidiruv uchun)
- `main()` — argument dispatch (qator ~887). `__preview` subkomandasi, so'ng `augment_tool_path`, `auto_update`, keyin flag'lar.
- `resolve_config` / `build_merged_config` — repo + foydalanuvchi config birlashtirish (repo ustun).
- `parse_agents` — config → TAB-ajratilgan qatorlar (8 maydon). `build_rows` — unga `status` (✓/✗) qo'shadi.
- `run_menu` (filter: `free`/`top`), `select_with_fzf`, `select_with_numbers`, `build_menu`, `preview_agent`.
- `quick_launch` (nomdan agent topish) → `launch_selected` → `ensure_installed` → `maybe_show_auth_note` → `launch_agent` (`exec`).
- `ensure_installed` — yo'q bo'lsa ruxsat so'rab o'rnatadi; OS-qo'llab-quvvatlamaslik / xato uchun aniq `panel` xabarlari.
- `should_open_login_link` — 🔑 kalit kerak VA muhitda yo'q bo'lsagina login sahifa ochadi.
- `doctor`, `update_agents`, `add_agent`, `auto_update` (git `fetch`+`reset --hard`, throttled).
- **npm yangilanish eslatmasi (notify):** `is_npm_install` (PROJECT_ROOT `node_modules` ichidami), `version_gt` (semver taqqoslash, tashqi dastursiz), `fetch_npm_latest` (registry `dist-tags`'dan eng so'nggi versiyani FONDA keshlaydi, throttled), `maybe_npm_update_hint` (yangisi chiqsa `npm update -g aidevix`ni BIR MARTA eslatadi). Git o'rnatishlar uchun `auto_update` ishlaydi; npm uchun esa bu — chunki `.git` yo'q. `AIDEVIX_NO_AUTOUPDATE`/`CI` hurmat qilinadi.
- **Lokal statistika:** `record_usage`/`read_usage` (`STATS_FILE`); `build_menu`/`list_agents` lokal sanoq bo'yicha saralaydi.
- **Global statistika (opt-in):** `global_stats_enabled`, `set_global_stats`, `stats_cmd` (`--stats on|off`), `report_usage_global` (fonda POST), `fetch_global_stats` (fonda kesh, throttled), `global_install_tsv` (JSON→TSV reyting), `maybe_global_hint`. Backend: `server/`.

## Konventsiyalar (PRga ta'sir qiladi)
- Har skript boshida `set -Eeuo pipefail`. ERR tutqich `die` qiladi; TTY o'qishdan oldin tutqich vaqtincha o'chiriladi.
- Har funksiya ustida qisqa **o'zbekcha** izoh. Foydalanuvchiga ko'rinadigan yangi matnni **`t "..."`** bilan o'rab yoz (manba o'zbekcha) va o'sha kalitni **`lib/i18n/en.sh`** ga inglizcha tarjimasi bilan qo'sh. `%s` joy egalari `t`ga argument sifatida beriladi.
- `lib/common.sh` log/UI'lari **STDERR**'ga yozadi — stdout faqat qaytariladigan qiymat uchun.
- Ranglar `UI_TTY`ga bog'liq; `NO_COLOR` hurmat qilinadi.
- Commit: Conventional Commits (`feat:`, `fix:`, `docs:`, ...). Release qo'lda emas — teg orqali.
- Test: yangi funksiya/xulq qo'shsang → `tests/` ga test ham qo'sh.

## Muhim env o'zgaruvchilar
| O'zgaruvchi | Ta'siri |
|-------------|---------|
| `AI_PULT_CONFIG` | Aniq config yo'li (test/maxsus). Berilsa — faqat o'sha. |
| `AIDEVIX_LANG` | Interfeys tili: `uz` yoki `en`. Berilmasa `LANG`/`LC_*` locale'idan aniqlanadi (uz*/C/bo'sh → uz; en*/boshqa → en). |
| `AIDEVIX_NO_AUTOUPDATE=1` | Avtomatik yangilanish (git) **va** npm yangilanish eslatmasini o'chiradi. |
| `AIDEVIX_UPDATE_INTERVAL` | Tekshirish oralig'i (sekund, std 10800). |
| `CI=1` | Animatsiya + auto_update **+ global statistika** o'chiq. |
| `NO_COLOR` / `AI_NO_ANIM` | Rang / animatsiyani o'chiradi. |
| `AIDEVIX_GLOBAL_STATS` | Global statistika opt-in (`1`/`0`) — `GLOBAL_OPTIN_FILE`dan ustun. |
| `AIDEVIX_STATS_URL` | Global statistika backend URL'i (std: Railway server, `server/`). |
| `AIDEVIX_STATS_TTL` | Global kesh yangilash oralig'i (sekund, std 10800). |

## Buyruqlar
```bash
make test          # bats tests/        — testlar
make lint          # shellcheck
make syntax        # bash -n barcha skript
make check         # syntax + lint + test (CI bilan bir xil)
bats tests/foo.bats   # bitta fayl
```

## Tez-tez uchraydigan tuzoqlar (gotchas)
- **Windows PATH buzilishi:** Git Bash'da `npm config get prefix` `C:\...` qaytaradi; `augment_tool_path` PATH'ni tozalaydi va `cygpath -u` bilan POSIX shaklga o'tkazadi. Bunga tegishda ehtiyot bo'l.
- **TAB vs bo'sh maydon:** `build_rows` ichida TAB o'rniga `\037` (US) ishlatiladi — bo'sh maydonlar "yutilmasligi" uchun.
- **fzf stdin'ni band qiladi:** TTY o'qishlar `/dev/tty`dan, bo'lmasa `&2`/stdin'dan (qarang `ensure_installed`, `prompt_tty`).
- **`source`-qorovuli:** `ai-selector.sh` oxiri `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` bilan himoyalangan — testda `source` qilsa `main` ishlamaydi. BUNI O'CHIRMA.
- **Repo nomi:** GitHub'da `SUNNATBEE/sunnatbeeCLI`, buyruq nomi esa `aidevix`.

## Reliz vaqtidagi qo'lda yangilanadigan joylar (versiya bump)
`VERSION` + `package.json:version` + `packaging/homebrew/aidevix.rb` (`url` teg + `sha256`) + `packaging/scoop/aidevix.json` (`version` + `extract_dir`) + `man/aidevix.1` (`.TH` qatori). Release teg `vX.Y.Z` `VERSION`ga mos bo'lishi shart (CI tekshiradi).
