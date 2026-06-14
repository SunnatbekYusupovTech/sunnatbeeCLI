#!/usr/bin/env bash
#
# scripts/record-demo.sh — demo.sh'ni asciinema bilan yozib, agg orqali GIF qiladi.
#
# Natija:
#   assets/demo.cast  — asciinema yozuvi (asciinema.org'ga yuklash uchun)
#   assets/demo.gif   — README'da ko'rsatiladigan GIF
#
# Talablar (Linux/macOS — terminal TTY kerak):
#   • asciinema  — https://asciinema.org/docs/installation
#   • agg        — https://github.com/asciinema/agg (cargo install agg)
#
# Foydalanish:
#   bash scripts/record-demo.sh

set -Eeuo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
ASSETS="$PROJECT_ROOT/assets"
CAST="$ASSETS/demo.cast"
GIF="$ASSETS/demo.gif"

mkdir -p "$ASSETS"

note() { printf '\033[36m[i]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[31m[x]\033[0m %s\n' "$*" >&2; }

if ! command -v asciinema >/dev/null 2>&1; then
  err "asciinema topilmadi."
  cat >&2 <<'EOF'
    O'rnatish:
      • macOS:        brew install asciinema
      • Debian/Ubuntu: sudo apt install asciinema
      • pipx:         pipx install asciinema
    So'ng yana ishga tushiring: bash scripts/record-demo.sh
EOF
  exit 127
fi

# 1) Yozib olish.
note "Demo yozilmoqda → $CAST"
asciinema rec --overwrite \
  --cols 100 --rows 30 \
  --title "Aidevix CLI" \
  -c "bash '$SCRIPT_DIR/demo.sh'" \
  "$CAST"

note "Yozuv tayyor: $CAST"

# 2) GIF'ga aylantirish (agg bo'lsa).
if command -v agg >/dev/null 2>&1; then
  note "GIF yaratilmoqda → $GIF"
  agg --theme asciinema --font-size 18 --speed 1.0 "$CAST" "$GIF"
  note "✓ Tayyor: $GIF — README'da ko'rinadi."
else
  err "agg topilmadi — GIF yaratilmadi (cast esa tayyor)."
  cat >&2 <<'EOF'
    agg o'rnatish (Rust kerak):
      cargo install --git https://github.com/asciinema/agg
    Yoki cast'ni to'g'ridan-to'g'ri yuklang:
      asciinema upload assets/demo.cast
EOF
  exit 1
fi
