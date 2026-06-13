#!/usr/bin/env bash
#
# bootstrap.sh — AI CLI Pult'ni BITTA BUYRUQ bilan o'rnatish.
#
# Foydalanish (o'quvchilar uchun):
#   curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/ai-cli/main/bootstrap.sh | bash
#
# Nima qiladi:
#   1. git va curl mavjudligini tekshiradi.
#   2. Repozitoriyani ~/.ai-cli'ga klonlaydi (mavjud bo'lsa yangilaydi).
#   3. install.sh'ni ishga tushiradi.
#
# Sozlanadigan muhit o'zgaruvchilari:
#   AI_CLI_REPO   — repozitoriya URL'i (standart: SUNNATBEE/ai-cli)
#   AI_CLI_HOME   — o'rnatish katalogi (standart: ~/.ai-cli)
#
# Exit kodlari: 0 — muvaffaqiyat, 1 — xato, 127 — kerakli vosita yo'q.

set -Eeuo pipefail

REPO="${AI_CLI_REPO:-https://github.com/SUNNATBEE/ai-cli.git}"
DEST="${AI_CLI_HOME:-$HOME/.ai-cli}"

info()  { printf '\033[0;34m[i]\033[0m %s\n' "$*" >&2; }
ok()    { printf '\033[0;32m[✓]\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[0;31m[x]\033[0m %s\n' "$*" >&2; }
die()   { local c="$1"; shift; err "$*"; exit "$c"; }

trap 'die 1 "Bootstrap xato bilan to\047xtadi (qator: $LINENO)."' ERR

# --- 1) Kerakli vositalar -------------------------------------------------
command -v git  >/dev/null 2>&1 || die 127 "git topilmadi. Iltimos, git'ni o'rnating."
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 \
  || die 127 "curl yoki wget topilmadi. Iltimos, birortasini o'rnating."

printf '\n\033[1m🤖 AI CLI Pult — bitta buyruq bilan o\047rnatish\033[0m\n\n'

# --- 2) Klonlash yoki yangilash -------------------------------------------
if [[ -d "$DEST/.git" ]]; then
  info "Mavjud o'rnatma topildi, yangilanmoqda: $DEST"
  git -C "$DEST" pull --ff-only --quiet || die 1 "Yangilash muvaffaqiyatsiz: $DEST"
  ok "Yangilandi."
else
  info "Repozitoriya klonlanmoqda: $REPO"
  git clone --depth 1 "$REPO" "$DEST" --quiet || die 1 "Klonlash muvaffaqiyatsiz: $REPO"
  ok "Klonlandi: $DEST"
fi

# --- 3) O'rnatishni ishga tushirish ---------------------------------------
[[ -r "$DEST/install.sh" ]] || die 1 "install.sh topilmadi: $DEST/install.sh"
info "O'rnatish skripti ishga tushirilmoqda..."
bash "$DEST/install.sh"
