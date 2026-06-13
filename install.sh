#!/usr/bin/env bash
#
# install.sh — AI CLI Pult'ni o'rnatish skripti.
#
# Nima qiladi:
#   1. Kerakli vositalarni (fzf) tekshiradi.
#   2. Foydalanuvchi shell konfiguratsiyasini (.bashrc / .zshrc) ZAXIRALAYDI.
#   3. `ai` buyrug'ini ~/.local/bin'ga symlink qilib joylaydi.
#   4. ~/.local/bin'ni PATH'ga qo'shadi (kerak bo'lsa).
#   5. Agentlar konfiguratsiyasini ~/.config/ai-cli'ga ko'chiradi.
#
# Xavfsizlik tamoyillari:
#   • set -Eeuo pipefail — har qanday xatoda darhol to'xtaydi.
#   • sudo TALAB QILMAYDI; faqat $HOME ichida ishlaydi.
#   • rc fayllarni o'zgartirishdan OLDIN zaxira oladi.
#   • Idempotent — qayta ishga tushirsa ham buzilmaydi.
#
# Exit kodlari: 0 — muvaffaqiyat, 1 — umumiy xato, 127 — kerakli vosita yo'q.

set -Eeuo pipefail

INSTALL_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -r "$INSTALL_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$INSTALL_DIR/lib/common.sh"
else
  log_info()    { printf '[i] %s\n' "$*" >&2; }
  log_warn()    { printf '[!] %s\n' "$*" >&2; }
  log_error()   { printf '[x] %s\n' "$*" >&2; }
  log_success() { printf '[✓] %s\n' "$*" >&2; }
  die() { local c="$1"; shift; log_error "$*"; exit "$c"; }
fi

trap 'die 1 "O\047rnatish xato bilan to\047xtadi (qator: $LINENO)."' ERR

readonly BIN_SRC="$INSTALL_DIR/bin/ai-selector.sh"
readonly CONFIG_SRC="$INSTALL_DIR/config/agents.conf"
readonly USER_CONFIG_DIR="$HOME/.config/ai-cli"
readonly USER_CONFIG="$USER_CONFIG_DIR/agents.conf"
readonly BIN_DIR="$HOME/.local/bin"
readonly CMD_NAME="ai"
readonly CMD_LINK="$BIN_DIR/$CMD_NAME"
readonly MARK_BEGIN="# >>> ai-cli (boshlanish) >>>"
readonly MARK_END="# <<< ai-cli (oxir) <<<"

# --- 1) Kerakli vositalar -------------------------------------------------
check_prerequisites() {
  log_info "Kerakli vositalar tekshirilmoqda..."
  [[ -r "$BIN_SRC" ]]    || die 1 "Asosiy skript topilmadi: $BIN_SRC"
  [[ -r "$CONFIG_SRC" ]] || die 1 "Konfiguratsiya topilmadi: $CONFIG_SRC"

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf o'rnatilmagan — bu vosita ishlashi uchun majburiy."
    log_error "O'rnatish:"
    log_error "  • macOS:         brew install fzf"
    log_error "  • Debian/Ubuntu: sudo apt install fzf"
    log_error "  • Arch:          sudo pacman -S fzf"
    log_error "  • Boshqalar:     https://github.com/junegunn/fzf#installation"
    die 127 "fzf topilmadi. O'rnatib, install.sh'ni qayta ishga tushiring."
  fi
  log_success "fzf topildi: $(command -v fzf)"
}

detect_shell_rc() {
  local shell_name; shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  printf '%s\n' "$HOME/.zshrc" ;;
    bash) printf '%s\n' "$HOME/.bashrc" ;;
    *)    printf '%s\n' "$HOME/.profile" ;;
  esac
}

# --- 2) rc faylni zaxiralash ----------------------------------------------
backup_file() {
  local target="$1"
  [[ -e "$target" ]] || { log_info "Zaxira shart emas (fayl yo'q): $target"; return 0; }
  local ts backup
  ts="$(date +%Y%m%d-%H%M%S)"
  backup="${target}.aicli-backup-${ts}"
  cp -p -- "$target" "$backup"
  log_success "Zaxira yaratildi: $backup"
}

# --- 3) `ai` buyrug'ini wrapper sifatida joylash --------------------------
# Symlink o'rniga kichik wrapper yozamiz: u barcha platformalarda bir xil
# ishlaydi (Windows'da symlink huquqi talab qilinmaydi) va asl skriptga
# to'g'ridan-to'g'ri yo'l ko'rsatadi — shu sababli lib/common.sh doimo topiladi.
install_command() {
  chmod +x "$BIN_SRC"
  mkdir -p "$BIN_DIR"
  cat >"$CMD_LINK" <<EOF
#!/usr/bin/env bash
# AI CLI Pult — avtomatik yaratilgan wrapper. Qo'lda tahrirlamang.
exec bash "$BIN_SRC" "\$@"
EOF
  chmod +x "$CMD_LINK"
  log_success "'$CMD_NAME' buyrug'i o'rnatildi: $CMD_LINK -> $BIN_SRC"
}

# --- 4) Foydalanuvchi konfiguratsiyasi ------------------------------------
install_user_config() {
  mkdir -p "$USER_CONFIG_DIR"
  if [[ -e "$USER_CONFIG" ]]; then
    log_info "Mavjud konfiguratsiya saqlanib qoldi: $USER_CONFIG"
  else
    cp -- "$CONFIG_SRC" "$USER_CONFIG"
    log_success "Konfiguratsiya o'rnatildi: $USER_CONFIG"
  fi
}

# --- 5) rc'ga PATH bloki (idempotent) -------------------------------------
install_shell_block() {
  local rc="$1"
  touch "$rc"
  if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
    log_info "Mavjud ai-cli bloki yangilanmoqda: $rc"
    local tmp; tmp="$(mktemp)"
    sed "/${MARK_BEGIN//\//\\/}/,/${MARK_END//\//\\/}/d" "$rc" >"$tmp"
    mv -- "$tmp" "$rc"
  fi
  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"'
    printf '%s\n' "$MARK_END"
  } >>"$rc"
  log_success "PATH yozuvi qo'shildi: $rc"
}

main() {
  printf '\n%s🤖 AI CLI Pult — o\047rnatish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"

  check_prerequisites
  local rc; rc="$(detect_shell_rc)"
  log_info "Aniqlangan shell konfiguratsiyasi: $rc"

  backup_file "$rc"
  install_command
  install_user_config
  install_shell_block "$rc"

  printf '\n'
  log_success "O'rnatish tugadi! 🎉"
  printf '\nKeyingi qadam — terminalni qayta oching yoki quyidagini ishga tushiring:\n'
  printf '   %ssource %s%s\n'  "${C_BOLD:-}" "$rc" "${C_RESET:-}"
  printf 'So\047ngra menyuni oching:\n'
  printf '   %s%s%s\n\n'       "${C_BOLD:-}" "$CMD_NAME" "${C_RESET:-}"
}

main "$@"
