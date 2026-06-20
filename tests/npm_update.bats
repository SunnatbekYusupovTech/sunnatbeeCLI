#!/usr/bin/env bats
# npm_update.bats — npm orqali o'rnatilganlar uchun yangilanish eslatmasi (notify).
#
# Tarmoq chaqiruvi (fetch_npm_latest) CI=1 yoki throttle tufayli o'chiq —
# testlar tarmoqqa chiqmaydi. Faqat versiya taqqoslash, npm-aniqlash va
# eslatma mantig'i tekshiriladi.

load test_helper

setup() {
  setup_env
  load_selector
}

# --- version_gt: semver taqqoslash ----------------------------------------
@test "version_gt: 1.2.0 > 1.1.0" {
  run version_gt 1.2.0 1.1.0
  [ "$status" -eq 0 ]
}

@test "version_gt: 1.1.0 > 1.2.0 emas" {
  run version_gt 1.1.0 1.2.0
  [ "$status" -ne 0 ]
}

@test "version_gt: teng versiyalar — katta emas" {
  run version_gt 1.1.0 1.1.0
  [ "$status" -ne 0 ]
}

@test "version_gt: major ustun (2.0.0 > 1.9.9)" {
  run version_gt 2.0.0 1.9.9
  [ "$status" -eq 0 ]
}

@test "version_gt: turli uzunlik (1.1.1 > 1.1)" {
  run version_gt 1.1.1 1.1
  [ "$status" -eq 0 ]
}

@test "version_gt: octal tuzog'i yo'q (1.08 > 1.07)" {
  run version_gt 1.08 1.07
  [ "$status" -eq 0 ]
}

# --- is_npm_install: o'rnatish manbasini aniqlash -------------------------
@test "is_npm_install: oddiy repo yo'li — npm emas" {
  run is_npm_install
  [ "$status" -ne 0 ]
}

@test "is_npm_install: node_modules ichidagi yo'l — npm" {
  PROJECT_ROOT="/usr/lib/node_modules/aidevix"
  run is_npm_install
  [ "$status" -eq 0 ]
}

# --- fetch_npm_latest: xavfsiz no-op (tarmoqsiz) --------------------------
@test "fetch_npm_latest: CI'da darrov 0 qaytaradi (tarmoqqa chiqmaydi)" {
  CI=1 run fetch_npm_latest
  [ "$status" -eq 0 ]
}

# --- maybe_npm_update_hint: eslatma mantig'i ------------------------------
@test "maybe_npm_update_hint: AIDEVIX_NO_AUTOUPDATE bo'lsa jim" {
  AIDEVIX_NO_AUTOUPDATE=1 run maybe_npm_update_hint
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "maybe_npm_update_hint: npm emas bo'lsa jim" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  run maybe_npm_update_hint
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "maybe_npm_update_hint: yangi versiya bo'lsa HAR safar eslatadi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  PROJECT_ROOT="/usr/lib/node_modules/aidevix"
  mkdir -p "$STATE_DIR"
  # Yangi versiya keshi (joriy AIDEVIX_VERSION'dan kattaroq).
  printf '%s\n' "999.0.0" > "$NPM_LATEST_CACHE"
  # fetch_npm_latest tarmoqqa chiqmasligi uchun throttle'ni yangi qilamiz.
  printf '%s\n' "$(date +%s)" > "$NPM_CHECK_STAMP"

  # `</dev/null`: stdin'ni TTY-emas qilamiz → interaktiv auto-update gate'i
  # ([[ -t 0 ]]) o'tmaydi, faqat passiv eslatma chiqadi (deterministik, osilmaydi).
  run maybe_npm_update_hint </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm i -g aidevix@latest"* ]]
  [[ "$output" == *"999.0.0"* ]]

  # Ikkinchi chaqiruv ham eslatadi (agressiv — yangilaguncha har safar).
  run maybe_npm_update_hint </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"999.0.0"* ]]
}

@test "maybe_npm_update_hint: kesh joriy versiyaga teng/eski bo'lsa jim" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  PROJECT_ROOT="/usr/lib/node_modules/aidevix"
  mkdir -p "$STATE_DIR"
  printf '%s\n' "0.0.1" > "$NPM_LATEST_CACHE"
  printf '%s\n' "$(date +%s)" > "$NPM_CHECK_STAMP"
  run maybe_npm_update_hint
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- auto-update: nointeraktiv holatda npm CHAQIRILMAYDI -------------------
# Yangi versiya bor bo'lsa ham, stdin TTY emas (bats/quvur/CI) bo'lganda
# avtomatik yangilashni TAKLIF QILMAYMIZ — passiv eslatma ko'rsatamiz, xolos.
# Aks holda promptда osilib qolardi yoki userning ixtiyorisiz npm ishga tushardi.
@test "maybe_npm_update_hint: nointeraktivda npm i -g chaqirmaydi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  PROJECT_ROOT="/usr/lib/node_modules/aidevix"
  mkdir -p "$STATE_DIR"
  printf '%s\n' "999.0.0" > "$NPM_LATEST_CACHE"
  printf '%s\n' "$(date +%s)" > "$NPM_CHECK_STAMP"

  # npm'ni qalbaki stub bilan almashtiramiz: chaqirilsa marker fayl yozadi.
  local stub="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$stub"
  cat > "$stub/npm" <<EOF
#!/usr/bin/env bash
echo called > "$BATS_TEST_TMPDIR/npm_called"
exit 0
EOF
  chmod +x "$stub/npm"
  # `</dev/null`: nointeraktiv → [[ -t 0 ]] yolg'on → gate o'tmaydi.
  PATH="$stub:$PATH" run maybe_npm_update_hint </dev/null

  [ "$status" -eq 0 ]
  # npm hech qachon chaqirilmasligi kerak (stdin tty emas).
  [ ! -f "$BATS_TEST_TMPDIR/npm_called" ]
  # Passiv eslatma esa ko'rsatilishi kerak.
  [[ "$output" == *"npm i -g aidevix@latest"* ]]
}
