#!/usr/bin/env bats
# i18n.bats — ko'p tillilik (uz/en) qatlami uchun testlar.
#
# Til aniqlash (aidevix_detect_lang), t() fallback va qora-quti EN/UZ render.

load test_helper

setup() {
  setup_env
  load_selector
}

# --- aidevix_detect_lang: til aniqlash ------------------------------------
@test "detect_lang: AIDEVIX_LANG=en → en" {
  AIDEVIX_LANG=en run aidevix_detect_lang
  [ "$output" = "en" ]
}

@test "detect_lang: AIDEVIX_LANG=uz → uz" {
  AIDEVIX_LANG=uz run aidevix_detect_lang
  [ "$output" = "uz" ]
}

@test "detect_lang: LANG=en_US.UTF-8 → en" {
  AIDEVIX_LANG="" LC_ALL="" LC_MESSAGES="" LANG="en_US.UTF-8" run aidevix_detect_lang
  [ "$output" = "en" ]
}

@test "detect_lang: LANG=uz_UZ.UTF-8 → uz" {
  AIDEVIX_LANG="" LC_ALL="" LC_MESSAGES="" LANG="uz_UZ.UTF-8" run aidevix_detect_lang
  [ "$output" = "uz" ]
}

@test "detect_lang: LC_ALL=C → uz (standart/minimal)" {
  AIDEVIX_LANG="" LC_MESSAGES="" LANG="" LC_ALL="C" run aidevix_detect_lang
  [ "$output" = "uz" ]
}

@test "detect_lang: bo'sh locale → uz" {
  AIDEVIX_LANG="" LC_ALL="" LC_MESSAGES="" LANG="" run aidevix_detect_lang
  [ "$output" = "uz" ]
}

@test "detect_lang: boshqa locale (ru_RU) → en (xalqaro)" {
  AIDEVIX_LANG="" LC_ALL="" LC_MESSAGES="" LANG="ru_RU.UTF-8" run aidevix_detect_lang
  [ "$output" = "en" ]
}

# --- t(): fallback va formatlash ------------------------------------------
@test "t: uz rejimida manbani o'zgarishsiz qaytaradi" {
  # setup LC_ALL=C → uz; MSG_EN yuklanmaydi.
  run t "Bekor qilindi."
  [ "$output" = "Bekor qilindi." ]
}

@test "t: printf argumentlarini formatlaydi" {
  run t "Salom %s, raqam %s" "dunyo" "42"
  [ "$output" = "Salom dunyo, raqam 42" ]
}

@test "t: noma'lum kalit — manbaning o'zi qaytadi" {
  run t "Bunday kalit yo'q 12345"
  [ "$output" = "Bunday kalit yo'q 12345" ]
}

# --- Qora-quti: EN va UZ render -------------------------------------------
@test "EN: --help inglizcha (USAGE:)" {
  AIDEVIX_LANG=en run bash "$SELECTOR" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE:"* ]]
  [[ "$output" == *"manage your terminal AI CLI agents"* ]]
}

@test "UZ: --help o'zbekcha (FOYDALANISH:)" {
  AIDEVIX_LANG=uz run bash "$SELECTOR" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"FOYDALANISH:"* ]]
}

@test "EN: noma'lum tanlov inglizcha xato beradi" {
  AIDEVIX_LANG=en run bash "$SELECTOR" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown option:"* ]]
}

@test "EN: --stats holati inglizcha" {
  AIDEVIX_LANG=en run bash "$SELECTOR" --stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Global stats"* ]]
}

@test "EN katalog: har bir tarjima qiymati bo'sh emas" {
  AIDEVIX_LANG=en load_selector
  local k empty=0
  for k in "${!MSG_EN[@]}"; do
    [[ -z "${MSG_EN[$k]}" ]] && empty=$((empty + 1))
  done
  [ "$empty" -eq 0 ]
}

# --- EN katalog: izoh/auth tarjimalari ------------------------------------
@test "EN katalog: agent izohi (desc) tarjimasi bor" {
  AIDEVIX_LANG=en load_selector
  run t "🧠 Anthropic'ning rasmiy Claude kod agenti"
  [ "$output" = "🧠 Anthropic's official Claude coding agent" ]
}

@test "EN katalog: login izohi (auth) tarjimasi bor" {
  AIDEVIX_LANG=en load_selector
  run t "🔑 ANTHROPIC_API_KEY yoki 💳 Claude Pro/Max"
  [ "$output" = "🔑 ANTHROPIC_API_KEY or 💳 Claude Pro/Max" ]
}

@test "build_rows: EN rejimda agent izohlari tarjima qilinadi" {
  AIDEVIX_LANG=en load_selector
  run build_rows "$REPO_CONFIG"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Anthropic's official Claude coding agent"* ]]
}

@test "build_rows: UZ rejimda izohlar o'zbekcha qoladi" {
  run build_rows "$REPO_CONFIG"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Anthropic'ning rasmiy Claude kod agenti"* ]]
}

# --- --lang (qora-quti) ---------------------------------------------------
@test "--lang en: LANG_FILE'ga yozadi" {
  AIDEVIX_LANG="" run bash "$SELECTOR" --lang en
  [ "$status" -eq 0 ]
  [ "$(cat "$LANG_FILE")" = "en" ]
}

@test "--lang: saqlangan til keyingi ishga tushishga ta'sir qiladi" {
  AIDEVIX_LANG="" run bash "$SELECTOR" --lang en
  AIDEVIX_LANG="" run bash "$SELECTOR" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE:"* ]]
}
