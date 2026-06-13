#!/usr/bin/env bash
#
# ai-selector.sh — AI CLI Pult'ning asosiy skripti (buyruq: `ai`).
#
# Vazifasi: config/agents.conf faylidan AI CLI agentlarini o'qiydi, ularni
# FZF interfeysi orqali ko'rsatadi va tanlangan agentni ishga tushiradi.
# Agar tanlangan CLI o'rnatilmagan bo'lsa — ruxsat so'rab, o'zi o'rnatadi.
#
# Foydalanish:
#   ai            # interaktiv FZF menyusi
#   ai --list     # agentlar ro'yxati + o'rnatilgan/yo'q holati
#   ai --help     # yordam
#
# Exit kodlari:
#   0   — muvaffaqiyat (yoki foydalanuvchi bekor qildi)
#   1   — umumiy/konfiguratsiya xatosi
#   2   — noto'g'ri argument
#   127 — kerakli buyruq (fzf yoki tanlangan agent) topilmadi

set -Eeuo pipefail

# --- Loyiha ildizini aniqlash (symlink orqali chaqirilsa ham) -------------
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  dir="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$dir/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

# Foydalanuvchi konfiguratsiyasi ustun, bo'lmasa repodagisi.
USER_CONFIG="${AI_PULT_CONFIG:-$HOME/.config/ai-cli/agents.conf}"
REPO_CONFIG="$PROJECT_ROOT/config/agents.conf"

# --- Umumiy yordamchilarni yuklash ----------------------------------------
LIB="$PROJECT_ROOT/lib/common.sh"
if [[ ! -r "$LIB" ]]; then
  printf '[x] Kutubxona topilmadi: %s\n' "$LIB" >&2
  exit 1
fi
# shellcheck source=../lib/common.sh
source "$LIB"

trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

# --- Yordam matni ---------------------------------------------------------
usage() {
  cat <<'EOF'
AI CLI Pult — terminaldagi AI CLI agentlarini bitta menyudan boshqaring.

FOYDALANISH:
  ai [TANLOV]

TANLOVLAR:
  (argumentsiz)   Interaktiv FZF menyusini ochadi
  -l, --list      Agentlar ro'yxati va ularning holatini ko'rsatadi
  -h, --help      Ushbu yordam matnini ko'rsatadi

KONFIGURATSIYA:
  Agentlar quyidagi fayldan o'qiladi (birinchi topilgani ishlatiladi):
    1) $AI_PULT_CONFIG (muhit o'zgaruvchisi)
    2) ~/.config/ai-cli/agents.conf
    3) <repo>/config/agents.conf

  Yangi agent qo'shish — faylga quyidagi formatda bitta qator yozing:
    NOM|BINARY|BUYRUQ|INSTALL|IZOH
EOF
}

# --- Ishlatiladigan konfiguratsiyani tanlash ------------------------------
resolve_config() {
  if [[ -r "$USER_CONFIG" ]]; then
    printf '%s\n' "$USER_CONFIG"
  elif [[ -r "$REPO_CONFIG" ]]; then
    printf '%s\n' "$REPO_CONFIG"
  else
    die 1 "Konfiguratsiya topilmadi. Tekshirildi: '$USER_CONFIG', '$REPO_CONFIG'"
  fi
}

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# --- Konfiguratsiyani o'qib, TAB bilan ajratilgan qatorlar chiqarish -------
# Chiqish formati: NAME\tDESC\tBINARY\tCOMMAND\tINSTALL
parse_agents() {
  local config="$1"
  local line name binary command install desc lineno=0 found=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    IFS='|' read -r name binary command install desc <<<"$line"
    name="$(trim "${name:-}")"
    binary="$(trim "${binary:-}")"
    command="$(trim "${command:-}")"
    install="$(trim "${install:-}")"
    desc="$(trim "${desc:-}")"

    if [[ -z "$name" || -z "$binary" || -z "$command" ]]; then
      log_warn "Noto'g'ri qator o'tkazib yuborildi (#$lineno): $line"
      continue
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$desc" "$binary" "$command" "$install"
    found=1
  done <"$config"

  [[ "$found" -eq 1 ]] || die 1 "Konfiguratsiyada yaroqli agent topilmadi: $config"
}

# --- --list rejimi --------------------------------------------------------
list_agents() {
  local config; config="$(resolve_config)"
  log_info "Konfiguratsiya: $config"
  printf '\n%s%-20s %-12s %s%s\n' "$C_BOLD" "AGENT" "HOLAT" "IZOH" "$C_RESET"
  printf '%s\n' "----------------------------------------------------------------------"
  local name desc binary command install status
  while IFS=$'\t' read -r name desc binary command install; do
    if command -v "$binary" >/dev/null 2>&1; then
      status="${C_GREEN}✓ o'rnatilgan${C_RESET}"
    else
      status="${C_RED}✗ yo'q${C_RESET}       "
    fi
    printf '%-20s %b %s\n' "$name" "$status" "$desc"
  done < <(parse_agents "$config")
}

# --- Interaktiv menyu -----------------------------------------------------
run_menu() {
  require_cmd fzf "https://github.com/junegunn/fzf#installation"
  local config; config="$(resolve_config)"

  local agents selection name
  agents="$(parse_agents "$config")"

  selection="$(
    printf '%s\n' "$agents" \
      | awk -F'\t' '{ printf "%-20s  %s\n", $1, $2 }' \
      | fzf --ansi \
            --prompt='🤖 AI CLI tanlang › ' \
            --height=70% \
            --reverse \
            --border=rounded \
            --header='ENTER — ishga tushirish · ESC — bekor qilish'
  )" || {
    local rc=$?
    if [[ "$rc" -eq 130 ]]; then log_info "Bekor qilindi."; exit 0; fi
    die "$rc" "fzf kutilmagan kod bilan to'xtadi: $rc"
  }

  [[ -z "$selection" ]] && { log_info "Hech narsa tanlanmadi."; exit 0; }

  # Nomni ajratib olamiz: ikki yoki undan ortiq probelgacha bo'lgan qism.
  # (awk -F ishonchli; [[:space:]] emoji bo'lgan qatorda nojo'ya ishlashi mumkin.)
  name="$(printf '%s' "$selection" | awk -F'  +' '{print $1}')"

  local row binary command install
  row="$(printf '%s\n' "$agents" | awk -F'\t' -v n="$name" '$1 == n { print; exit }')"
  [[ -n "$row" ]] || die 1 "Tanlangan agent topilmadi: $name"

  binary="$(printf '%s'  "$row" | cut -f3)"
  command="$(printf '%s' "$row" | cut -f4)"
  install="$(printf '%s' "$row" | cut -f5)"

  ensure_installed "$name" "$binary" "$install"
  launch_agent "$name" "$binary" "$command"
}

# --- CLI mavjudligini ta'minlash (kerak bo'lsa avtomatik o'rnatish) -------
ensure_installed() {
  local name="$1" binary="$2" install="$3"

  command -v "$binary" >/dev/null 2>&1 && return 0

  log_warn "Agent topilmadi: '$name' (kerakli buyruq: '$binary')."
  if [[ -z "$install" ]]; then
    die 127 "Avtomatik o'rnatish buyrug'i belgilanmagan. Iltimos, '$name'ni qo'lda o'rnating."
  fi

  log_info "O'rnatish buyrug'i: $install"
  local ans="" prompt="❓ '$name' hozir o'rnatilsinmi? [y/N] "
  # Javobni avval /dev/tty'dan o'qishga urinamiz (fzf stdin'ni band qilgan
  # bo'lishi mumkin), bo'lmasa oddiy stdin'ga qaytamiz. Device xatosi ERR
  # tutqichini ishga tushirmasligi uchun tutqichni vaqtincha o'chiramiz.
  trap - ERR
  if { : >/dev/tty; } 2>/dev/null; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r ans </dev/tty || ans=""
  else
    printf '%s' "$prompt" >&2
    IFS= read -r ans || ans=""
  fi
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    die 127 "Bekor qilindi. '$name'ni qo'lda o'rnatish uchun: $install"
  fi

  log_info "O'rnatilmoqda: $name ..."
  # ERR tutqichini vaqtincha o'chirib, o'rnatish xatosini o'zimiz ushlaymiz.
  trap - ERR
  if ! eval "$install"; then
    trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR
    die 1 "O'rnatish muvaffaqiyatsiz tugadi: $name. Buyruqni qo'lda sinab ko'ring: $install"
  fi
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

  # Yangi PATH yozuvlari joriy sessiyada ko'rinishi uchun hash'ni tozalaymiz.
  hash -r 2>/dev/null || true

  if ! command -v "$binary" >/dev/null 2>&1; then
    log_error "O'rnatish tugadi, biroq '$binary' hali PATH'da ko'rinmayapti."
    die 127 "Terminalni qayta oching yoki PATH'ni yangilab, qaytadan urinib ko'ring."
  fi
  log_success "O'rnatildi: $name"
}

# --- Agentni ishga tushirish ----------------------------------------------
launch_agent() {
  local name="$1" binary="$2" command="$3"
  log_success "Ishga tushirilmoqda: $name  ➜  $command"
  trap - ERR
  # shellcheck disable=SC2086
  exec $command
}

# --- Argumentlar ----------------------------------------------------------
main() {
  case "${1:-}" in
    -h|--help) usage ;;
    -l|--list) list_agents ;;
    "")        run_menu ;;
    *)         log_error "Noma'lum tanlov: $1"; echo; usage; exit 2 ;;
  esac
}

main "$@"
