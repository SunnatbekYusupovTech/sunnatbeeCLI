#!/usr/bin/env bash
#
# install.sh — AI Terminal Pult'ni o'rnatish skripti.
#
# Nima qiladi:
#   1. Kerakli vositalarni (fzf, bash) tekshiradi.
#   2. Foydalanuvchi shell konfiguratsiyasini (.bashrc / .zshrc) ZAXIRALAYDI.
#   3. ai-selector skriptini bajariluvchi qiladi.
#   4. Agentlar konfiguratsiyasini ~/.config'ga ko'chiradi (mavjudini saqlaydi).
#   5. PATH'ga / shell rc'ga `aipult` aliasini qo'shadi (takrorlamasdan).
#
# Xavfsizlik tamoyillari:
#   • set -Eeuo pipefail — har qanday xatoda darhol to'xtaydi.
#   • Hech qachon `sudo` talab qilmaydi; faqat $HOME ichida ishlaydi.
#   • Konfiguratsiya fayllarini O'ZGARTIRISHDAN OLDIN zaxira oladi.
#   • Idempotent — qayta-qayta ishga tushirsa ham buzilmaydi.
#
# Exit kodlari:
#   0   — muvaffaqiyatli o'rnatildi
#   1   — umumiy xato
#   127 — kerakli vosita topilmadi

set -Eeuo pipefail

# --- Loyiha ildizi --------------------------------------------------------
INSTALL_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# --- Umumiy yordamchilar (mavjud bo'lsa yuklaymiz, bo'lmasa minimal) ------
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
readonly USER_CONFIG_DIR="$HOME/.config/ai-terminal-pult"
readonly USER_CONFIG="$USER_CONFIG_DIR/agents.conf"
readonly ALIAS_NAME="aipult"
# Boshlanish/oxir markerlari — qayta o'rnatishda blokni topib yangilash uchun.
readonly MARK_BEGIN="# >>> ai-terminal-pult (boshlanish) >>>"
readonly MARK_END="# <<< ai-terminal-pult (oxir) <<<"

# --- 1) Kerakli vositalarni tekshirish ------------------------------------
check_prerequisites() {
  log_info "Kerakli vositalar tekshirilmoqda..."

  [[ -r "$BIN_SRC" ]]    || die 1 "Asosiy skript topilmadi: $BIN_SRC"
  [[ -r "$CONFIG_SRC" ]] || die 1 "Konfiguratsiya topilmadi: $CONFIG_SRC"

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf o'rnatilmagan — bu vosita ishlashi uchun majburiy."
    log_error "O'rnatish bo'yicha qo'llanma:"
    log_error "  • macOS:         brew install fzf"
    log_error "  • Debian/Ubuntu: sudo apt install fzf"
    log_error "  • Arch:          sudo pacman -S fzf"
    log_error "  • Boshqalar:     https://github.com/junegunn/fzf#installation"
    die 127 "fzf topilmadi. Iltimos, uni o'rnatib, install.sh'ni qayta ishga tushiring."
  fi
  log_success "fzf topildi: $(command -v fzf)"
}

# --- Shell rc faylini aniqlash --------------------------------------------
detect_shell_rc() {
  # Foydalanuvchining joriy login-shell'iga qarab rc faylni tanlaymiz.
  local shell_name; shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  printf '%s\n' "$HOME/.zshrc" ;;
    bash) printf '%s\n' "$HOME/.bashrc" ;;
    *)    printf '%s\n' "$HOME/.profile" ;;
  esac
}

# --- 2) Shell rc faylini ZAXIRALASH ---------------------------------------
backup_file() {
  local target="$1"
  [[ -e "$target" ]] || { log_info "Zaxira shart emas (fayl yo'q): $target"; return 0; }

  local ts backup
  ts="$(date +%Y%m%d-%H%M%S)"
  backup="${target}.aipult-backup-${ts}"
  cp -p -- "$target" "$backup"
  log_success "Zaxira yaratildi: $backup"
}

# --- 3) Skriptni bajariluvchi qilish --------------------------------------
make_executable() {
  chmod +x "$BIN_SRC"
  log_success "Skript bajariluvchi qilindi: $BIN_SRC"
}

# --- 4) Foydalanuvchi konfiguratsiyasini joylash --------------------------
install_user_config() {
  mkdir -p "$USER_CONFIG_DIR"
  if [[ -e "$USER_CONFIG" ]]; then
    log_info "Mavjud foydalanuvchi konfiguratsiyasi saqlanib qoldi: $USER_CONFIG"
  else
    cp -- "$CONFIG_SRC" "$USER_CONFIG"
    log_success "Konfiguratsiya o'rnatildi: $USER_CONFIG"
  fi
}

# --- 5) Shell rc'ga alias/PATH qo'shish (idempotent) ----------------------
install_shell_block() {
  local rc="$1"
  touch "$rc"

  # Eski blokni (markerlar orasidagi) olib tashlab, yangisini yozamiz.
  if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
    log_info "Mavjud ai-terminal-pult bloki yangilanmoqda: $rc"
    local tmp; tmp="$(mktemp)"
    sed "/${MARK_BEGIN//\//\\/}/,/${MARK_END//\//\\/}/d" "$rc" >"$tmp"
    mv -- "$tmp" "$rc"
  fi

  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf '%s\n' "alias ${ALIAS_NAME}='$BIN_SRC'"
    printf '%s\n' "$MARK_END"
  } >>"$rc"

  log_success "'$ALIAS_NAME' aliasi qo'shildi: $rc"
}

# --- Asosiy oqim ----------------------------------------------------------
main() {
  printf '\n%s🤖 AI Terminal Pult — o\047rnatish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"

  check_prerequisites

  local rc; rc="$(detect_shell_rc)"
  log_info "Aniqlangan shell konfiguratsiyasi: $rc"

  backup_file "$rc"          # rc'ni o'zgartirishdan OLDIN zaxira
  make_executable
  install_user_config
  install_shell_block "$rc"

  printf '\n'
  log_success "O'rnatish tugadi! 🎉"
  printf '\nKeyingi qadam — quyidagini ishga tushiring yoki terminalni qayta oching:\n'
  printf '   %ssource %s%s\n'  "${C_BOLD:-}" "$rc" "${C_RESET:-}"
  printf 'So\047ngra menyuni oching:\n'
  printf '   %s%s%s\n\n'       "${C_BOLD:-}" "$ALIAS_NAME" "${C_RESET:-}"
}

main "$@"
