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

# --- Strelka navigatsiyasi: baytlar termios (stty+dd) orqali o'qiladi -------
# Bug (Windows): bash `read -t` select()/poll() ga tayanadi; MINGW/MSYS konsol
# deskriptorida select ISHONCHSIZ — timeout darhol bo'sh qaytib, ESC'dan keyingi
# `[A` baytlari "kelmadi" deb hisoblanardi → har strelka "cancel" deb o'qilib menyu
# yopilib qolardi (baytma-bayt `read -rsn1 -t` ham shu sababdan yetarli bo'lmadi).
# Fix: bash `read` o'rniga stty min/time (VTIME) + dd — kernel read() VTIME'ni
# haqiqatan kutadi, har joyda (Linux/mac/MSYS) ishonchli ishlaydi.
@test "select_with_arrows: asosiy o'qish bloklovchi, 'read -t' faqat _rb zaxirasi" {
  local body; body="$(_arrows_body)"
  # Tsikldagi BIRINCHI bayt bloklovchi builtin read bilan o'qiladi (-t'siz).
  printf '%s\n' "$body" | grep -vE '^\s*#' | grep -q 'IFS= read -rsn1 key </dev/tty'
  # `read -t` faqat _rb ichidagi VTIME-yolg'on zaxirasida — bittadan oshmasin
  # (unga TAYANILMAYDI: VTIME asosiy, read -t esa 2-qatlam).
  local n
  n="$(printf '%s\n' "$body" | grep -vE '^\s*#' | grep -cE 'read -rsn?[0-9]* -t' || true)"
  [ "$n" -le 1 ]
}

@test "select_with_arrows: baytlarni stty min/time + dd (termios) bilan o'qiydi" {
  local body; body="$(_arrows_body)"
  # _rb yordamchisi: dd bilan bitta bayt o'qiydi.
  printf '%s\n' "$body" | grep -qE 'dd bs=1 count=1'
  # Timeout TTY drayveri orqali (stty min 0 time ...).
  printf '%s\n' "$body" | grep -qE 'stty min 0 time'
  # Bloklash rejimi (stty min 1 time 0) ham o'rnatiladi.
  printf '%s\n' "$body" | grep -qE 'stty .* min 1 time 0|stty min 1 time 0'
}

@test "select_with_arrows: ESC tarmog'ida kamida ikki marta seq-o'qish (c1,c2)" {
  # ESC'dan keyin c1 va c2 baytlari _rq (VTIME yoki bloklovchi) bilan o'qiladi;
  # _rq esa timeout ishlaydigan muhitda _rb'ni escds bilan chaqiradi.
  local body n
  body="$(_arrows_body)"
  n="$(printf '%s\n' "$body" | grep -vE '^\s*#' | grep -cE '_rq [a-z0-9_]+')"
  [ "$n" -ge 2 ]
  printf '%s\n' "$body" | grep -qE '_rb "\$1" "\$escds"'
}

@test "select_with_arrows: timeout'lar o'lik muhitda bloklovchi rejimga o'tadi" {
  # Ba'zi Windows konsol tty'larida VTIME ham, select ham kutmasdan bo'sh
  # qaytadi — strelkalar "yolg'iz ESC = bekor" deb o'qilib menyu yopilardi.
  # TIMERS_BROKEN aniqlanishi va bloklovchi qayta o'qish mavjudligini tekshiramiz.
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -q 'TIMERS_BROKEN=1'      # aniqlash (o'lchov)
  printf '%s\n' "$body" | grep -q 'TIMERS_BROKEN=0'      # boshlang'ich holat
  # Aniqlangach c1 bloklab qayta o'qiladi (ESC-ESC → bekor yo'li ham bor).
  printf '%s\n' "$body" | grep -qE '^\s*_rb c1$'
}

@test "select_with_arrows: chiqishda TTY holatini tiklaydi (stty restore + EXIT trap)" {
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -qE 'stty -g'                 # eski holatni saqlaydi
  printf '%s\n' "$body" | grep -qE "trap '.*stty .*' EXIT"   # EXIT'da tiklaydi
}

@test "select_with_arrows: strelka baytlari up/down/left/right ga bog'lanadi" {
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -qE '^\s*A\) action=up'
  printf '%s\n' "$body" | grep -qE '^\s*B\) action=down'
  printf '%s\n' "$body" | grep -qE '^\s*C\) action=right'
  printf '%s\n' "$body" | grep -qE '^\s*D\) action=left'
}

# --- Scroll/g'ildirak va notanish klavishlar tuzatishlari -------------------
@test "select_with_arrows: alt-screen + alternate-scroll (g'ildirak bilan scroll)" {
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -q '1049h'    # alt-screen'ga kirish
  printf '%s\n' "$body" | grep -q '1007h'    # g'ildirak → ↑/↓ strelka
  printf '%s\n' "$body" | grep -q '1049l'    # chiqishda tiklash
}

@test "select_with_arrows: notanish CSI ketma-ketlik menyuni YOPMAYDI (skip)" {
  local body; body="$(_arrows_body)"
  printf '%s\n' "$body" | grep -qE 'action=skip'
  # Eski xulq (har notanish c2 → cancel) qaytib kelmaganini tekshiramiz.
  ! printf '%s\n' "$body" | grep -vE '^\s*#' | grep -qE '^\s*\*\) action=cancel'
}

@test "select_with_arrows: klavish tsiklida awk chaqirilmaydi (Windows fork sekinligi)" {
  # Datafile bir marta oldindan o'qiladi; har siljishda awk/subshell ochish
  # MSYS'da bitta strelkani soniyagacha cho'zib, "scroll ishlamayapti"ga sabab edi.
  local n
  n="$(_arrows_body | grep -vE '^\s*#' | grep -c 'awk ' || true)"
  [ "$n" -eq 0 ]
}

@test "select_with_fzf: fzf xatosida die emas — ichki menyuga fallback (rc=3)" {
  awk '/^select_with_fzf\(\) \{/{f=1} f{print} f&&/^\}$/{exit}' "$SELECTOR" | grep -q 'return 3'
  grep -q "fzf ishga tushmadi" "$SELECTOR"
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
