#!/usr/bin/env bash
# shellcheck shell=bash
#
# lib/common.sh — AI Terminal Pult uchun umumiy yordamchi funksiyalar.
# Bu fayl mustaqil ishga tushirilmaydi; boshqa skriptlar `source` qiladi.
#
# Mazmuni:
#   • Rang konstantalari (terminal TTY bo'lganda)
#   • Log funksiyalari: log_info / log_warn / log_error / log_success
#   • die()  — xabar chiqarib, berilgan exit-code bilan to'xtaydi
#   • require_cmd() — kerakli buyruq mavjudligini tekshiradi

# --- Ranglar (faqat interaktiv terminalda yoqiladi) -----------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  C_RESET="$(tput sgr0)"
  C_RED="$(tput setaf 1)"
  C_GREEN="$(tput setaf 2)"
  C_YELLOW="$(tput setaf 3)"
  C_BLUE="$(tput setaf 4)"
  C_BOLD="$(tput bold)"
else
  C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_BOLD=""
fi

# --- Log funksiyalari (barchasi stderr'ga yozadi) -------------------------
log_info()    { printf '%s[i]%s %s\n'  "$C_BLUE"   "$C_RESET" "$*" >&2; }
log_warn()    { printf '%s[!]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error()   { printf '%s[x]%s %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; }
log_success() { printf '%s[✓]%s %s\n'  "$C_GREEN"  "$C_RESET" "$*" >&2; }

# die <exit_code> <message...>
#   Xato xabarini chiqaradi va skriptni berilgan exit-code bilan to'xtatadi.
die() {
  local code="$1"; shift
  log_error "$*"
  exit "$code"
}

# require_cmd <command> [installation_hint]
#   Buyruq PATH'da mavjudligini tekshiradi; yo'q bo'lsa die() qiladi.
require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ -n "$hint" ]]; then
      die 127 "'$cmd' topilmadi. O'rnatish uchun: $hint"
    else
      die 127 "'$cmd' topilmadi. Iltimos, uni o'rnatib, qaytadan urinib ko'ring."
    fi
  fi
}
