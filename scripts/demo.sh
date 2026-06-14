#!/usr/bin/env bash
#
# scripts/demo.sh — Aidevix CLI uchun deterministik, yozib olinadigan demo.
#
# Bu skript interaktiv fzf menyusiga TEGINMAYDI (uni yozib bo'lmaydi) — buning
# o'rniga `--version`, `--list`, `--doctor` kabi NON-INTERAKTIV, lekin rangli va
# chiroyli buyruqlarni "yozilayotgandek" ko'rsatadi.
#
# Foydalanish (qo'lda ko'rish uchun):
#   bash scripts/demo.sh
# Yozib olish uchun:
#   bash scripts/record-demo.sh   # → assets/demo.gif
#
# Sozlash: DEMO_SPEED (yozish tezligi, sekund/harf — std 0.03).

set -Eeuo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
AIDEVIX="$PROJECT_ROOT/bin/ai-selector.sh"

# Ranglarni MAJBURAN yoqamiz (yozib olishda quvur orqali ishlaydi).
export FORCE_COLOR=1
# Spinner/banner animatsiyasi yoqilsin (demo jonli ko'rinishi uchun).
unset AI_NO_ANIM CI NO_COLOR 2>/dev/null || true
# Avtomatik yangilanish demo paytida ishlamasin.
export AIDEVIX_NO_AUTOUPDATE=1

DEMO_SPEED="${DEMO_SPEED:-0.03}"

C_PROMPT=$'\033[38;5;213m'
C_CMD=$'\033[1;38;5;87m'
C_DIM=$'\033[90m'
C_RST=$'\033[0m'

pause() { sleep "${1:-0.7}"; }

# type_cmd <buyruq> — terminal prompt + buyruqni harfma-harf "yozadi".
type_cmd() {
  local cmd="$1" i
  printf '%s❯ %s%s' "$C_PROMPT" "$C_CMD" "$C_RST"
  for ((i = 0; i < ${#cmd}; i++)); do
    printf '%s%s%s' "$C_CMD" "${cmd:i:1}" "$C_RST"
    sleep "$DEMO_SPEED"
  done
  printf '\n'
  pause 0.4
}

# run <buyruq...> — sarlavhani yozadi va haqiqiy buyruqni bajaradi.
run() {
  type_cmd "aidevix $*"
  bash "$AIDEVIX" "$@" || true
  printf '\n'
  pause 1.0
}

clear 2>/dev/null || printf '\033[2J\033[H'

printf '%s  # Aidevix CLI — terminaldagi barcha AI agentlar bitta menyuda%s\n\n' "$C_DIM" "$C_RST"
pause 0.8

run --version
run --list
run --doctor

type_cmd "aidevix            # interaktiv menyuni ochadi (fzf + preview)"
printf '%s  … ↑/↓ tanlang · yozib qidiring · ENTER ishga tushiradi%s\n\n' "$C_DIM" "$C_RST"
pause 1.5

printf '%s  ✦ aidevix — pip qaysi, npm qaysi buyruq edi… deb eslab o'\''tirmang.%s\n' "$C_PROMPT" "$C_RST"
printf '%s    github.com/SUNNATBEE/sunnatbeeCLI%s\n\n' "$C_DIM" "$C_RST"
pause 1.5
