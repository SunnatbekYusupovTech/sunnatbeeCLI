#!/usr/bin/env bash
#
# bootstrap.sh — AI CLI Pult'ni BITTA BUYRUQ bilan o'rnatish.
#
# Foydalanish (o'quvchilar uchun):
#   curl -fsSL https://raw.githubusercontent.com/SUNNATBEE/sunnatbeeCLI/main/bootstrap.sh | bash
#
# Nima qiladi:
#   1. git va curl mavjudligini tekshiradi.
#   2. Repozitoriyani ~/.ai-cli'ga klonlaydi (mavjud bo'lsa yangilaydi).
#   3. install.sh'ni ishga tushiradi.
#
# Sozlanadigan muhit o'zgaruvchilari:
#   AI_CLI_REPO   — repozitoriya URL'i (standart: SUNNATBEE/sunnatbeeCLI)
#   AI_CLI_HOME   — o'rnatish katalogi (standart: ~/.ai-cli)
#
# Exit kodlari: 0 — muvaffaqiyat, 1 — xato, 127 — kerakli vosita yo'q.

set -Eeuo pipefail

REPO="${AI_CLI_REPO:-https://github.com/SUNNATBEE/sunnatbeeCLI.git}"
DEST="${AI_CLI_HOME:-$HOME/.ai-cli}"

info()  { printf '\033[0;34m[i]\033[0m %s\n' "$*" >&2; }
ok()    { printf '\033[0;32m[✓]\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[0;31m[x]\033[0m %s\n' "$*" >&2; }
die()   { local c="$1"; shift; err "$*"; exit "$c"; }

trap 'die 1 "Bootstrap xato bilan to\047xtadi (qator: $LINENO)."' ERR

# --- 1) Kerakli vositalar -------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
  err "──────────────────────────────────────────────"
  err "❌ \"git\" topilmadi — u loyihani yuklab olishga kerak."
  err "👉 https://git-scm.com/downloads saytidan yuklab olib o'rnating."
  err "   So'ng terminalni qayta oching va shu buyruqni takrorlang."
  err "──────────────────────────────────────────────"
  exit 127
fi
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  err "──────────────────────────────────────────────"
  err "❌ \"curl\" ham, \"wget\" ham topilmadi — fayl yuklash uchun biri kerak."
  err "👉 Ubuntu/Debian: \"sudo apt install curl\"  ·  macOS'da curl oldindan bor."
  err "──────────────────────────────────────────────"
  exit 127
fi

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  printf '\n  \033[38;5;51m━━━━━━━━━━━━━━━\033[38;5;39m━━━━━━━━━━━━━━━\033[38;5;201m━━━━━━━━━━━━━━━━\033[0m\n' >&2
  printf '  \033[1m🤖  \033[38;5;87mAI CLI PULT\033[0m\n' >&2
  printf '  \033[90mbitta buyruq bilan o'\''rnatish\033[0m\n' >&2
  printf '  \033[38;5;201m━━━━━━━━━━━━━━━\033[38;5;39m━━━━━━━━━━━━━━━\033[38;5;51m━━━━━━━━━━━━━━━━\033[0m\n\n' >&2
else
  printf '\n🤖 AI CLI Pult — bitta buyruq bilan o\047rnatish\n\n' >&2
fi

# --- 2) Klonlash yoki yangilash -------------------------------------------
if [[ -d "$DEST/.git" ]]; then
  info "Mavjud o'rnatma topildi, yangilanmoqda: $DEST"
  if ! git -C "$DEST" pull --ff-only --quiet; then
    err "❌ Yangilab bo'lmadi: $DEST"
    err "👉 Internet ulanishini tekshiring yoki shu papkani o'chirib qayta urinib ko'ring:"
    err "   rm -rf \"$DEST\"   (so'ng buyruqni qaytadan ishga tushiring)"
    exit 1
  fi
  ok "Yangilandi."
else
  info "Repozitoriya klonlanmoqda: $REPO"
  if ! git clone --depth 1 "$REPO" "$DEST" --quiet; then
    err "❌ Yuklab bo'lmadi: $REPO"
    err "👉 Eng ko'p sabab — internet yo'q yoki manzil noto'g'ri."
    err "   Wi-Fi'ni tekshiring va biroz kutib qaytadan urinib ko'ring."
    exit 1
  fi
  ok "Klonlandi: $DEST"
fi

# --- 3) O'rnatishni ishga tushirish ---------------------------------------
[[ -r "$DEST/install.sh" ]] || die 1 "install.sh topilmadi: $DEST/install.sh"
info "O'rnatish skripti ishga tushirilmoqda..."
bash "$DEST/install.sh"
