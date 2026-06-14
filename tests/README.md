# Testlar (Bats)

Aidevix CLI'ning avtomatlashtirilgan testlari — [Bats](https://github.com/bats-core/bats-core)
(Bash Automated Testing System) yordamida.

## Ishga tushirish

```bash
# Bats o'rnatish (bir marta)
npm install -g bats        # yoki: brew install bats-core / apt install bats

# Barcha testlar
bats tests/

# Yoki Makefile orqali
make test

# Bitta fayl
bats tests/unit_parse.bats

# Xato bo'lganda to'liq chiqishni ko'rsatish
bats --print-output-on-failure tests/
```

## Tuzilma

| Fayl | Nimani tekshiradi |
|------|-------------------|
| `unit_parse.bats` | Sof funksiyalar: `trim`, `detect_install_tool`, `parse_agents`, `build_rows`, `should_open_login_link`, `resolve_config` |
| `cli.bats` | CLI xulq-atvori (qora-quti): `--version`, `--help`, `--list`, noto'g'ri argumentlar, `__preview`, `quick_launch` resolutsiyasi |
| `common.bats` | `lib/common.sh`: `die`, `require_cmd`, `hr`, `tool_hint`, `panel` |
| `test_helper.bash` | Umumiy setup — deterministik muhit + funksiyalarni source qilish |
| `fixtures/agents.conf` | Testlar uchun barqaror agentlar ro'yxati (real config'dan mustaqil) |

## Qanday ishlaydi

- **Determinizm:** `setup_env` ranglarni (`NO_COLOR`), animatsiyani (`AI_NO_ANIM`, `CI`)
  va avto-yangilanishni (`AIDEVIX_NO_AUTOUPDATE`) o'chiradi; `HOME`/state'ni har bir
  test uchun vaqtinchalik papkaga oladi — real foydalanuvchi fayllariga tegmaydi.
- **Funksiyalarni izolyatsiyalash:** `bin/ai-selector.sh` oxiridagi
  `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]` qorovuli tufayli skriptni `source`
  qilganda `main()` ishga tushmaydi — funksiyalarni alohida chaqirib bo'ladi.
- **CI:** har push/PR'da `.github/workflows/ci.yml` ichidagi `bats` jobi bu
  testlarni avtomatik ishga tushiradi.

## Yangi test qo'shish

```bash
@test "qisqa tavsif (o'zbekcha)" {
  load_selector                 # yoki load_common
  run my_function "argument"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kutilgan"* ]]
}
```
