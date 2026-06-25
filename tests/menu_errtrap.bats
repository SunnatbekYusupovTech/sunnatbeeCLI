#!/usr/bin/env bats
# menu_errtrap.bats — fzf'siz ↑/↓ menyudagi ERR-trap crash'i (v1.5.0 bug'i)
# QAYTIB KELMASLIGI uchun regressiya testlari.
#
# Bug: skript `set -Eeuo pipefail` + ERR-tutqich bilan ishlaydi. `select_with_arrows`
# ichidagi standalone `(( cur < 0 ))` kabi arifmetik ifoda FALSE bo'lsa exit code 1
# qaytaradi; ERR-tutqich uni "Kutilmagan xato" deb `die` qiladi → menyu qulaydi
# (Windows Git Bash userlarida ommaviy crash). Fix (eb56c6b, v1.5.1):
# `select_with_arrows` boshida `set +e; trap - ERR` — subshell ichida tutqichni
# o'chiradi, chegaralarni funksiya o'zi boshqaradi.
#
# Bu yerda tarmoq/TTY shart emas: STRUKTURAVIY tekshiruv — fix joyida ekanini va
# o'sha sinf bug (himoyalanmagan standalone `(( ))`) qaytib kelmaganini kafolatlaydi.

load test_helper

setup() {
  setup_env
}

# select_with_arrows tanasini ajratib oladi (funksiya boshidan birinchi ustun-0 `}` gacha).
_arrows_body() {
  awk '/^select_with_arrows\(\) \{/{f=1} f{print} f&&/^\}$/{exit}' "$SELECTOR"
}

# --- Fix joyidaligi: ERR-tutqich va errexit o'chirilgan -------------------
@test "select_with_arrows: ERR-tutqichni o'chiradi (trap - ERR)" {
  _arrows_body | grep -qE '^\s*trap - ERR\s*$'
}

@test "select_with_arrows: errexit'ni o'chiradi (set +e)" {
  _arrows_body | grep -qE '^\s*set \+e\s*$'
}

@test "select_with_arrows: read-tsikldan OLDIN himoya o'rnatiladi" {
  # `set +e` qatori interaktiv `while :` tsiklidan oldin kelishi shart, aks holda
  # tsikl ichidagi `(( cur ... ))` lar himoyasiz qoladi.
  local body se wl
  body="$(_arrows_body)"
  se="$(printf '%s\n' "$body" | grep -nE '^\s*set \+e\s*$' | head -1 | cut -d: -f1)"
  wl="$(printf '%s\n' "$body" | grep -nE '^\s*while :;\s*do' | head -1 | cut -d: -f1)"
  [ -n "$se" ] && [ -n "$wl" ]
  [ "$se" -lt "$wl" ]
}

# --- Sinf-bug: himoyalanmagan standalone `(( ))` qolmaganligi --------------
# --- crash(): kutilmagan xatoda KATTA yangilash eslatmasi -----------------
@test "barcha ERR-tutqichlar crash() ni chaqiradi (die-Kutilmagan emas)" {
  # ERR-tutqichlar endi crash() ga o'tgan; eski 'die 1 ... Kutilmagan' qolmagan.
  run grep -c "trap 'crash \"\$BASH_COMMAND\"" "$SELECTOR"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
  run grep -n "die 1.*Kutilmagan xato" "$SELECTOR"
  [ "$status" -ne 0 ]    # topilmasligi kerak
}

@test "crash: npm o'rnatishda 'npm i -g aidevix@latest' ni KATTA ko'rsatadi" {
  load_selector
  PROJECT_ROOT="/usr/lib/node_modules/aidevix"    # is_npm_install → ha
  run crash "false" "42"
  [ "$status" -eq 1 ]
  [[ "$output" == *"npm i -g aidevix@latest"* ]]
  [[ "$output" == *"YANGILANG"* || "$output" == *"UPDATE"* ]]
  [[ "$output" == *"42"* ]]    # xato qatori ham ko'rinadi
}

@test "crash: git checkout'da 'aidevix --update' ko'rsatadi" {
  load_selector
  # PROJECT_ROOT — repo (test PROJECT_ROOT'da .git bor).
  [ -d "$PROJECT_ROOT/.git" ] || skip "test PROJECT_ROOT git emas"
  run crash "false" "7"
  [ "$status" -eq 1 ]
  [[ "$output" == *"aidevix --update"* ]]
}

# --- Strelka navigatsiyasi: ESC ketma-ketligi baytma-bayt o'qiladi --------
# Bug (Windows): `read -rsn2 -t "$esctmo" seq` IKKALA seq baytini bitta timeout
# oynasida kutardi. MINGW/MSYS konsolida baytlar bo'lak-bo'lak kelgani uchun read
# timeout bo'lib qisman natija TASHLANARDI → har strelka "cancel" deb o'qilib menyu
# yopilib qolardi. Fix: ESC'dan keyin har baytni ALOHIDA `read -rsn1 -t` bilan o'qish.
@test "select_with_arrows: ESC ketma-ketligini fragile 'read -rsn2' bilan o'qimaydi" {
  local n
  # Izoh qatorlarini (#...) chiqarib tashlab, faqat KOD'da qidiramiz.
  n="$(_arrows_body | grep -vE '^\s*#' | grep -cE 'read -rsn2' || true)"
  [ "$n" -eq 0 ]
}

@test "select_with_arrows: ESC'dan keyin baytma-bayt 'read -rsn1 -t' o'qiydi" {
  # ESC tarmog'ida kamida ikkita bir-baytli timeoutli o'qish bo'lishi shart (c1, c2).
  local n
  n="$(_arrows_body | grep -cE 'read -rsn1 -t "\$esctmo"')"
  [ "$n" -ge 2 ]
}

@test "select_with_arrows: strelka baytlari up/down/left/right ga bog'lanadi" {
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -qE '^\s*A\) action=up'
  printf '%s\n' "$body" | grep -qE '^\s*B\) action=down'
  printf '%s\n' "$body" | grep -qE '^\s*C\) action=right'
  printf '%s\n' "$body" | grep -qE '^\s*D\) action=left'
}

@test "bin/lib: himoyalanmagan standalone (( )) yo'q (ERR-trap tuzog'i)" {
  # Statement-pozitsiyadagi `(( ifoda ))` set -e ostida XAVFLI: ifoda false bo'lsa
  # 1 qaytaradi → die. Har bunday qator `&&` yoki `||` bilan o'ralgan bo'lishi
  # SHART (yoki set +e zonasida). `for ((` / `while ((` / `if ((` bular emas.
  run grep -rnE '^[[:space:]]*\(\(' "$PROJECT_ROOT/bin" "$PROJECT_ROOT/lib"
  if [ "$status" -eq 0 ]; then
    # Topilganlarning HAMMASI &&/|| bilan o'ralgan bo'lishi kerak. O'ralmagani bo'lsa — fail.
    local unguarded
    unguarded="$(printf '%s\n' "$output" | grep -vE '\)\)[[:space:]]*(&&|\|\|)' || true)"
    if [ -n "$unguarded" ]; then
      echo "Himoyalanmagan standalone (( )) topildi:"
      echo "$unguarded"
      false
    fi
  fi
}
