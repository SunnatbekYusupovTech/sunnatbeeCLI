#!/usr/bin/env bash
#
# uninstall.sh — AI CLI Pult'ni olib tashlaydi.
#
# Nima qiladi:
#   1. .bashrc/.zshrc/.profile'dagi ai-cli blokini (avval zaxira olib) olib tashlaydi.
#   2. ~/.local/bin/ai symlink'ini o'chiradi.
#   3. Foydalanuvchi konfiguratsiyasini o'chirishni TAKLIF qiladi (so'ramasdan o'chirmaydi).
#
# Exit kodlari: 0 — muvaffaqiyat, 1 — xato.

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

trap 'die 1 "O\047chirish xato bilan to\047xtadi (qator: $LINENO)."' ERR

readonly USER_CONFIG_DIR="$HOME/.config/ai-cli"
readonly BIN_DIR="$HOME/.local/bin"
readonly CMD_LINK="$BIN_DIR/ai"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-cli"
readonly MARK_BEGIN="# >>> ai-cli (boshlanish) >>>"
readonly MARK_END="# <<< ai-cli (oxir) <<<"

remove_block_from() {
  local rc="$1"
  [[ -e "$rc" ]] || return 0
  grep -qF "$MARK_BEGIN" "$rc" || { log_info "Blok topilmadi: $rc"; return 0; }

  local ts backup tmp
  ts="$(date +%Y%m%d-%H%M%S)"
  backup="${rc}.aicli-backup-${ts}"
  cp -p -- "$rc" "$backup"
  log_success "Zaxira yaratildi: $backup"

  tmp="$(mktemp)"
  sed "/${MARK_BEGIN//\//\\/}/,/${MARK_END//\//\\/}/d" "$rc" >"$tmp"
  mv -- "$tmp" "$rc"
  log_success "ai-cli bloki olib tashlandi: $rc"
}

main() {
  printf '\n%s🧹 AI CLI Pult — o\047chirish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"

  remove_block_from "$HOME/.bashrc"
  remove_block_from "$HOME/.zshrc"
  remove_block_from "$HOME/.profile"

  local f
  for f in "$CMD_LINK" "$CMD_LINK.cmd" "$CMD_LINK.ps1"; do
    if [[ -L "$f" || -e "$f" ]]; then
      rm -f -- "$f"
      log_success "Olib tashlandi: $f"
    fi
  done

  if [[ -d "$STATE_DIR" ]]; then
    rm -rf -- "$STATE_DIR"
    log_success "Holat fayllari olib tashlandi: $STATE_DIR"
  fi

  if [[ -d "$USER_CONFIG_DIR" ]]; then
    log_warn "Foydalanuvchi konfiguratsiyasi hali mavjud: $USER_CONFIG_DIR"
    log_warn "O'chirish uchun: rm -rf '$USER_CONFIG_DIR'"
  fi

  printf '\n'
  log_success "Tugadi. Terminalni qayta oching yoki shell rc'ni qayta yuklang."
}

main "$@"
